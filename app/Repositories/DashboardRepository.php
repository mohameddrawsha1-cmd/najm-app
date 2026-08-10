<?php
declare(strict_types=1);

namespace App\Repositories;

use App\Core\Auth;
use App\Core\Database;

final class DashboardRepository
{
    public function data(): array
    {
        $pdo = Database::connection();
        $scope = Auth::hasRole('SYSTEM_ADMIN', 'SUPPORT_MANAGER', 'SUPPORT_AGENT', 'AUDITOR')
            ? ['sql' => '1=1', 'params' => []]
            : ['sql' => '(requester_user_id = :uid OR created_by_user_id = :uid)', 'params' => ['uid' => Auth::id()]];
        $statement = $pdo->prepare(
            'SELECT
                COUNT(*) total,
                SUM(status_id = (SELECT id FROM ticket_statuses WHERE code = "NEW")) new_count,
                SUM(status_id = (SELECT id FROM ticket_statuses WHERE code = "IN_PROGRESS")) progress_count,
                SUM(status_id = (SELECT id FROM ticket_statuses WHERE code = "RESOLVED")) resolved_count,
                SUM(priority_id = (SELECT id FROM ticket_priorities WHERE code = "CRITICAL")
                    AND status_id NOT IN (SELECT id FROM ticket_statuses WHERE code IN ("CLOSED","CANCELLED"))) critical_count,
                SUM(due_at < UTC_TIMESTAMP()
                    AND status_id NOT IN (SELECT id FROM ticket_statuses WHERE code IN ("RESOLVED","CLOSED","CANCELLED"))) overdue_count
             FROM tickets WHERE ' . $scope['sql']
        );
        $statement->execute($scope['params']);
        $stats = $statement->fetch() ?: [];
        $recent = (new TicketRepository())->list([]);
        return ['stats' => $stats, 'recent' => array_slice($recent, 0, 8)];
    }
}
