<?php
declare(strict_types=1);

namespace App\Repositories;

use App\Core\Auth;
use App\Core\Database;
use PDO;
use RuntimeException;

final class TicketRepository
{
    public function list(array $filters = []): array
    {
        $where = ['1=1'];
        $params = [];
        if (!Auth::hasRole('SYSTEM_ADMIN', 'SUPPORT_MANAGER', 'SUPPORT_AGENT', 'AUDITOR')) {
            $where[] = '(t.requester_user_id = :viewer OR t.created_by_user_id = :viewer)';
            $params['viewer'] = Auth::id();
        }
        if (!empty($filters['status'])) {
            $where[] = 's.code = :status';
            $params['status'] = $filters['status'];
        }
        if (!empty($filters['priority'])) {
            $where[] = 'p.code = :priority';
            $params['priority'] = $filters['priority'];
        }
        if (!empty($filters['q'])) {
            $where[] = '(t.ticket_number LIKE :q OR t.title LIKE :q OR t.description LIKE :q)';
            $params['q'] = '%' . trim($filters['q']) . '%';
        }
        $sql = 'SELECT t.id, t.ticket_number, t.title, t.ticket_kind, t.created_at, t.due_at,
                       s.code status_code, s.name_ar status_name, p.code priority_code, p.name_ar priority_name,
                       c.name_ar category_name, CONCAT(u.first_name, " ", u.last_name) requester_name,
                       CONCAT(a.first_name, " ", a.last_name) assignee_name
                FROM tickets t
                JOIN ticket_statuses s ON s.id = t.status_id
                JOIN ticket_priorities p ON p.id = t.priority_id
                JOIN ticket_categories c ON c.id = t.category_id
                JOIN users u ON u.id = t.requester_user_id
                LEFT JOIN users a ON a.id = t.assigned_user_id
                WHERE ' . implode(' AND ', $where) . '
                ORDER BY FIELD(p.code, "CRITICAL", "HIGH", "MEDIUM", "LOW"), t.updated_at DESC
                LIMIT 250';
        $statement = Database::connection()->prepare($sql);
        $statement->execute($params);
        return $statement->fetchAll();
    }

    public function find(int $id): ?array
    {
        $statement = Database::connection()->prepare(
            'SELECT t.*, s.code status_code, s.name_ar status_name,
                    p.code priority_code, p.name_ar priority_name, c.name_ar category_name,
                    CONCAT(u.first_name, " ", u.last_name) requester_name, u.email requester_email,
                    CONCAT(cr.first_name, " ", cr.last_name) creator_name,
                    CONCAT(a.first_name, " ", a.last_name) assignee_name,
                    l.name_ar location_name, d.asset_tag device_asset_tag
             FROM tickets t
             JOIN ticket_statuses s ON s.id = t.status_id
             JOIN ticket_priorities p ON p.id = t.priority_id
             JOIN ticket_categories c ON c.id = t.category_id
             JOIN users u ON u.id = t.requester_user_id
             JOIN users cr ON cr.id = t.created_by_user_id
             LEFT JOIN users a ON a.id = t.assigned_user_id
             LEFT JOIN locations l ON l.id = t.location_id
             LEFT JOIN devices d ON d.id = t.device_id
             WHERE t.id = ? LIMIT 1'
        );
        $statement->execute([$id]);
        $ticket = $statement->fetch() ?: null;
        if (!$ticket || !$this->canView($ticket)) {
            return null;
        }
        return $ticket;
    }

    public function messages(int $ticketId): array
    {
        $where = Auth::hasRole('SYSTEM_ADMIN', 'SUPPORT_MANAGER', 'SUPPORT_AGENT', 'AUDITOR')
            ? '' : ' AND m.is_internal = 0';
        $statement = Database::connection()->prepare(
            'SELECT m.*, CONCAT(u.first_name, " ", u.last_name) author_name
             FROM ticket_messages m JOIN users u ON u.id = m.author_user_id
             WHERE m.ticket_id = ?' . $where . ' ORDER BY m.created_at'
        );
        $statement->execute([$ticketId]);
        return $statement->fetchAll();
    }

    public function history(int $ticketId): array
    {
        $statement = Database::connection()->prepare(
            'SELECT h.*, fs.name_ar from_status_name, ts.name_ar to_status_name,
                    CONCAT(u.first_name, " ", u.last_name) actor_name
             FROM ticket_status_history h
             LEFT JOIN ticket_statuses fs ON fs.id = h.from_status_id
             JOIN ticket_statuses ts ON ts.id = h.to_status_id
             JOIN users u ON u.id = h.changed_by_user_id
             WHERE h.ticket_id = ? ORDER BY h.changed_at DESC'
        );
        $statement->execute([$ticketId]);
        return $statement->fetchAll();
    }

    public function formOptions(): array
    {
        $pdo = Database::connection();
        return [
            'categories' => $pdo->query('SELECT id, code, name_ar FROM ticket_categories WHERE is_active = 1 ORDER BY sort_order, name_ar')->fetchAll(),
            'priorities' => $pdo->query('SELECT id, code, name_ar FROM ticket_priorities WHERE is_active = 1 ORDER BY sort_order')->fetchAll(),
            'statuses' => $pdo->query('SELECT id, code, name_ar FROM ticket_statuses WHERE is_active = 1 ORDER BY sort_order')->fetchAll(),
            'locations' => $pdo->query('SELECT id, name_ar FROM locations WHERE is_active = 1 ORDER BY name_ar')->fetchAll(),
            'devices' => $pdo->query('SELECT id, asset_tag, hostname FROM devices WHERE is_active = 1 ORDER BY asset_tag LIMIT 500')->fetchAll(),
            'agents' => $pdo->query(
                'SELECT u.id, CONCAT(u.first_name, " ", u.last_name) name
                 FROM users u JOIN roles r ON r.id = u.role_id
                 WHERE u.is_active = 1 AND r.code IN ("SYSTEM_ADMIN","SUPPORT_MANAGER","SUPPORT_AGENT") ORDER BY name'
            )->fetchAll(),
        ];
    }

    public function create(array $data): int
    {
        return Database::transaction(function (PDO $pdo) use ($data): int {
            $number = $this->nextNumber($pdo);
            $statusId = (int) $pdo->query('SELECT id FROM ticket_statuses WHERE code = "NEW" LIMIT 1')->fetchColumn();
            $statement = $pdo->prepare(
                'INSERT INTO tickets
                 (ticket_number, ticket_scope, ticket_kind, title, description, category_id, priority_id, status_id,
                  requester_user_id, created_by_user_id, location_id, device_id, is_sensitive, created_at, updated_at)
                 VALUES (:number, "INTERNAL", :kind, :title, :description, :category, :priority, :status,
                         :requester, :creator, :location, :device, :sensitive, UTC_TIMESTAMP(), UTC_TIMESTAMP())'
            );
            $statement->execute([
                'number' => $number,
                'kind' => $data['ticket_kind'],
                'title' => $data['title'],
                'description' => $data['description'],
                'category' => $data['category_id'],
                'priority' => $data['priority_id'],
                'status' => $statusId,
                'requester' => $data['requester_user_id'],
                'creator' => Auth::id(),
                'location' => $data['location_id'] ?: null,
                'device' => $data['device_id'] ?: null,
                'sensitive' => (int) in_array($data['ticket_kind'], ['ONBOARDING', 'OFFBOARDING'], true),
            ]);
            $ticketId = (int) $pdo->lastInsertId();
            $pdo->prepare(
                'INSERT INTO ticket_status_history (ticket_id, from_status_id, to_status_id, changed_by_user_id, note, changed_at)
                 VALUES (?, NULL, ?, ?, "إنشاء الطلب", UTC_TIMESTAMP())'
            )->execute([$ticketId, $statusId, Auth::id()]);
            $this->attachChecklist($pdo, $ticketId, $data['ticket_kind']);
            Auth::audit('ticket.created', 'ticket', $ticketId, null, ['ticket_number' => $number]);
            return $ticketId;
        });
    }

    public function addMessage(int $ticketId, string $message, bool $internal): void
    {
        if (!$this->find($ticketId)) {
            throw new RuntimeException('الطلب غير موجود أو غير مسموح.');
        }
        if ($internal && !Auth::hasRole('SYSTEM_ADMIN', 'SUPPORT_MANAGER', 'SUPPORT_AGENT')) {
            throw new RuntimeException('لا تملك صلاحية إضافة ملاحظة داخلية.');
        }
        Database::connection()->prepare(
            'INSERT INTO ticket_messages (ticket_id, author_user_id, message, is_internal, created_at)
             VALUES (?, ?, ?, ?, UTC_TIMESTAMP())'
        )->execute([$ticketId, Auth::id(), $message, (int) $internal]);
        Database::connection()->prepare('UPDATE tickets SET updated_at = UTC_TIMESTAMP() WHERE id = ?')->execute([$ticketId]);
        Auth::audit('ticket.message_added', 'ticket', $ticketId);
    }

    public function updateStatus(int $ticketId, int $statusId, string $note): void
    {
        Auth::requireRole('SYSTEM_ADMIN', 'SUPPORT_MANAGER', 'SUPPORT_AGENT');
        Database::transaction(function (PDO $pdo) use ($ticketId, $statusId, $note): void {
            $statement = $pdo->prepare('SELECT status_id FROM tickets WHERE id = ? FOR UPDATE');
            $statement->execute([$ticketId]);
            $oldStatus = (int) $statement->fetchColumn();
            if (!$oldStatus) {
                throw new RuntimeException('الطلب غير موجود.');
            }
            $codeStatement = $pdo->prepare('SELECT code FROM ticket_statuses WHERE id = ? AND is_active = 1');
            $codeStatement->execute([$statusId]);
            $code = $codeStatement->fetchColumn();
            if (!$code) {
                throw new RuntimeException('الحالة غير صحيحة.');
            }
            if ($code === 'RESOLVED' && trim($note) === '') {
                throw new RuntimeException('ملخص الحل مطلوب قبل حل الطلب.');
            }
            $extra = $code === 'RESOLVED' ? ', resolved_at = UTC_TIMESTAMP(), resolution_summary = :resolution' : '';
            $sql = 'UPDATE tickets SET status_id = :status, updated_at = UTC_TIMESTAMP()' . $extra . ' WHERE id = :id';
            $params = ['status' => $statusId, 'id' => $ticketId];
            if ($code === 'RESOLVED') {
                $params['resolution'] = $note;
            }
            $pdo->prepare($sql)->execute($params);
            $pdo->prepare(
                'INSERT INTO ticket_status_history (ticket_id, from_status_id, to_status_id, changed_by_user_id, note, changed_at)
                 VALUES (?, ?, ?, ?, ?, UTC_TIMESTAMP())'
            )->execute([$ticketId, $oldStatus, $statusId, Auth::id(), $note ?: null]);
            Auth::audit('ticket.status_changed', 'ticket', $ticketId, ['status_id' => $oldStatus], ['status_id' => $statusId]);
        });
    }

    public function assign(int $ticketId, int $agentId): void
    {
        Auth::requireRole('SYSTEM_ADMIN', 'SUPPORT_MANAGER');
        Database::transaction(function (PDO $pdo) use ($ticketId, $agentId): void {
            $pdo->prepare(
                'UPDATE ticket_assignments SET is_current = 0, ended_at = UTC_TIMESTAMP()
                 WHERE ticket_id = ? AND assignment_type = "INTERNAL_USER" AND is_current = 1'
            )->execute([$ticketId]);
            $pdo->prepare(
                'INSERT INTO ticket_assignments
                 (ticket_id, assignment_type, assigned_user_id, assigned_by_user_id, assignment_status, is_current, assigned_at)
                 VALUES (?, "INTERNAL_USER", ?, ?, "ASSIGNED", 1, UTC_TIMESTAMP())'
            )->execute([$ticketId, $agentId, Auth::id()]);
            $pdo->prepare('UPDATE tickets SET assigned_user_id = ?, updated_at = UTC_TIMESTAMP() WHERE id = ?')
                ->execute([$agentId, $ticketId]);
            Auth::audit('ticket.assigned', 'ticket', $ticketId, null, ['agent_id' => $agentId]);
        });
    }

    private function canView(array $ticket): bool
    {
        if (Auth::hasRole('SYSTEM_ADMIN', 'SUPPORT_MANAGER', 'SUPPORT_AGENT', 'AUDITOR')) {
            return true;
        }
        return (int) $ticket['requester_user_id'] === Auth::id() || (int) $ticket['created_by_user_id'] === Auth::id();
    }

    private function nextNumber(PDO $pdo): string
    {
        $year = (int) gmdate('Y');
        $statement = $pdo->prepare('SELECT last_number FROM ticket_sequences WHERE sequence_year = ? FOR UPDATE');
        $statement->execute([$year]);
        $last = $statement->fetchColumn();
        if ($last === false) {
            $next = 1;
            $pdo->prepare('INSERT INTO ticket_sequences (sequence_year, last_number) VALUES (?, ?)')->execute([$year, $next]);
        } else {
            $next = (int) $last + 1;
            $pdo->prepare('UPDATE ticket_sequences SET last_number = ? WHERE sequence_year = ?')->execute([$next, $year]);
        }
        return sprintf('IT-%d-%06d', $year, $next);
    }

    private function attachChecklist(PDO $pdo, int $ticketId, string $kind): void
    {
        $statement = $pdo->prepare(
            'INSERT INTO ticket_checklist_items
             (ticket_id, template_item_id, title_ar, sort_order, is_required, is_completed, created_at)
             SELECT ?, ci.id, ci.title_ar, ci.sort_order, ci.is_required, 0, UTC_TIMESTAMP()
             FROM checklist_templates ct JOIN checklist_template_items ci ON ci.template_id = ct.id
             WHERE ct.ticket_kind = ? AND ct.is_active = 1 AND ci.is_active = 1'
        );
        $statement->execute([$ticketId, $kind]);
    }
}
