<?php
declare(strict_types=1);

namespace App\Core;

use PDO;

final class Auth
{
    private static ?array $user = null;
    private static bool $loaded = false;

    public static function attempt(string $email, string $password): bool
    {
        $pdo = Database::connection();
        $statement = $pdo->prepare(
            'SELECT u.*, r.code AS role_code, r.name_ar AS role_name
             FROM users u JOIN roles r ON r.id = u.role_id
             WHERE u.email = :email AND u.is_active = 1 LIMIT 1'
        );
        $statement->execute(['email' => mb_strtolower(trim($email))]);
        $user = $statement->fetch();

        if (!$user || !password_verify($password, $user['password_hash'])) {
            self::recordAttempt($email, false);
            return false;
        }
        if (!empty($user['locked_until']) && strtotime($user['locked_until']) > time()) {
            return false;
        }

        session_regenerate_id(true);
        $_SESSION['user_id'] = (int) $user['id'];
        self::$user = $user;
        self::$loaded = true;
        $pdo->prepare('UPDATE users SET last_login_at = UTC_TIMESTAMP(), failed_login_count = 0, locked_until = NULL WHERE id = ?')
            ->execute([$user['id']]);
        self::recordAttempt($email, true);
        self::audit('auth.login', 'user', (int) $user['id']);
        return true;
    }

    public static function user(): ?array
    {
        if (self::$loaded) {
            return self::$user;
        }
        self::$loaded = true;
        $id = (int) ($_SESSION['user_id'] ?? 0);
        if (!$id) {
            return null;
        }
        $statement = Database::connection()->prepare(
            'SELECT u.*, r.code AS role_code, r.name_ar AS role_name
             FROM users u JOIN roles r ON r.id = u.role_id
             WHERE u.id = ? AND u.is_active = 1 LIMIT 1'
        );
        $statement->execute([$id]);
        self::$user = $statement->fetch() ?: null;
        return self::$user;
    }

    public static function id(): ?int
    {
        return self::user() ? (int) self::$user['id'] : null;
    }

    public static function check(): bool
    {
        return self::user() !== null;
    }

    public static function requireLogin(): void
    {
        if (!self::check()) {
            Flash::put('error', 'يرجى تسجيل الدخول أولًا.');
            redirect('/login');
        }
    }

    public static function hasRole(string ...$roles): bool
    {
        return self::check() && in_array(self::$user['role_code'], $roles, true);
    }

    public static function requireRole(string ...$roles): void
    {
        self::requireLogin();
        if (!self::hasRole(...$roles)) {
            http_response_code(403);
            View::render('errors/403', ['title' => 'غير مصرح']);
            exit;
        }
    }

    public static function logout(): void
    {
        if (self::id()) {
            self::audit('auth.logout', 'user', self::id());
        }
        $_SESSION = [];
        if (ini_get('session.use_cookies')) {
            $params = session_get_cookie_params();
            setcookie(session_name(), '', time() - 42000, $params['path'], $params['domain'], $params['secure'], $params['httponly']);
        }
        session_destroy();
        self::$user = null;
        self::$loaded = true;
    }

    public static function audit(string $action, ?string $entityType = null, ?int $entityId = null, ?array $old = null, ?array $new = null): void
    {
        try {
            Database::connection()->prepare(
                'INSERT INTO audit_logs (actor_user_id, action, entity_type, entity_id, old_values, new_values, ip_address, user_agent, created_at)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, UTC_TIMESTAMP())'
            )->execute([
                self::id(), $action, $entityType, $entityId,
                $old ? json_encode($old, JSON_UNESCAPED_UNICODE) : null,
                $new ? json_encode($new, JSON_UNESCAPED_UNICODE) : null,
                $_SERVER['REMOTE_ADDR'] ?? null,
                mb_substr($_SERVER['HTTP_USER_AGENT'] ?? '', 0, 500),
            ]);
        } catch (\Throwable) {
        }
    }

    private static function recordAttempt(string $email, bool $success): void
    {
        $pdo = Database::connection();
        $pdo->prepare('INSERT INTO login_attempts (email, ip_address, was_successful, attempted_at) VALUES (?, ?, ?, UTC_TIMESTAMP())')
            ->execute([mb_strtolower(trim($email)), $_SERVER['REMOTE_ADDR'] ?? null, (int) $success]);
        if (!$success) {
            $pdo->prepare(
                'UPDATE users SET locked_until = CASE WHEN failed_login_count + 1 >= 5 THEN DATE_ADD(UTC_TIMESTAMP(), INTERVAL 15 MINUTE) ELSE locked_until END,
                 failed_login_count = failed_login_count + 1
                 WHERE email = ?'
            )->execute([mb_strtolower(trim($email))]);
        }
    }
}
