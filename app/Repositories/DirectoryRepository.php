<?php
declare(strict_types=1);

namespace App\Repositories;

use App\Core\Database;

final class DirectoryRepository
{
    public function devices(): array
    {
        return Database::connection()->query(
            'SELECT d.*, dt.name_ar type_name, ds.name_ar status_name,
                    CONCAT(u.first_name, " ", u.last_name) assigned_name, l.name_ar location_name
             FROM devices d JOIN device_types dt ON dt.id = d.device_type_id
             JOIN device_statuses ds ON ds.id = d.status_id
             LEFT JOIN users u ON u.id = d.assigned_user_id
             LEFT JOIN locations l ON l.id = d.location_id
             WHERE d.is_active = 1 ORDER BY d.updated_at DESC LIMIT 500'
        )->fetchAll();
    }

    public function users(): array
    {
        return Database::connection()->query(
            'SELECT u.id, u.employee_number, u.first_name, u.last_name, u.email, u.phone, u.job_title,
                    u.is_active, u.last_login_at, r.name_ar role_name, d.name_ar department_name
             FROM users u JOIN roles r ON r.id = u.role_id
             LEFT JOIN departments d ON d.id = u.department_id
             ORDER BY u.is_active DESC, u.first_name, u.last_name LIMIT 500'
        )->fetchAll();
    }
}
