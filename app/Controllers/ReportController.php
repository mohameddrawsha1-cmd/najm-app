<?php
declare(strict_types=1);

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Controller;
use App\Core\Database;

final class ReportController extends Controller
{
    public function index(): void
    {
        Auth::requireRole('SYSTEM_ADMIN', 'SUPPORT_MANAGER', 'AUDITOR');
        $pdo = Database::connection();
        $byStatus = $pdo->query(
            'SELECT s.name_ar label, COUNT(t.id) total
             FROM ticket_statuses s LEFT JOIN tickets t ON t.status_id = s.id
             GROUP BY s.id, s.name_ar, s.sort_order ORDER BY s.sort_order'
        )->fetchAll();
        $byCategory = $pdo->query(
            'SELECT c.name_ar label, COUNT(t.id) total
             FROM ticket_categories c LEFT JOIN tickets t ON t.category_id = c.id
             GROUP BY c.id, c.name_ar ORDER BY total DESC LIMIT 12'
        )->fetchAll();
        $this->view('reports/index', ['title' => 'التقارير', 'byStatus' => $byStatus, 'byCategory' => $byCategory]);
    }

    public function export(): void
    {
        Auth::requireRole('SYSTEM_ADMIN', 'SUPPORT_MANAGER', 'AUDITOR');
        $rows = Database::connection()->query(
            'SELECT t.ticket_number, t.title, c.name_ar category, p.name_ar priority, s.name_ar status,
                    t.created_at, t.resolved_at
             FROM tickets t JOIN ticket_categories c ON c.id=t.category_id
             JOIN ticket_priorities p ON p.id=t.priority_id
             JOIN ticket_statuses s ON s.id=t.status_id ORDER BY t.created_at DESC'
        )->fetchAll();
        header('Content-Type: text/csv; charset=UTF-8');
        header('Content-Disposition: attachment; filename="tickets-' . gmdate('Y-m-d') . '.csv"');
        $output = fopen('php://output', 'wb');
        fwrite($output, "\xEF\xBB\xBF");
        fputcsv($output, ['رقم الطلب', 'العنوان', 'التصنيف', 'الأولوية', 'الحالة', 'تاريخ الإنشاء', 'تاريخ الحل']);
        foreach ($rows as $row) {
            fputcsv($output, array_values($row));
        }
        fclose($output);
        exit;
    }
}
