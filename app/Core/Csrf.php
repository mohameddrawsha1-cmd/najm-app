<?php
declare(strict_types=1);

namespace App\Core;

final class Csrf
{
    public static function token(): string
    {
        if (empty($_SESSION['_csrf'])) {
            $_SESSION['_csrf'] = bin2hex(random_bytes(32));
        }
        return $_SESSION['_csrf'];
    }

    public static function verify(?string $token): bool
    {
        return is_string($token) && hash_equals((string) ($_SESSION['_csrf'] ?? ''), $token);
    }

    public static function enforce(): void
    {
        if (!self::verify($_POST['_token'] ?? ($_SERVER['HTTP_X_CSRF_TOKEN'] ?? null))) {
            http_response_code(419);
            exit('انتهت صلاحية الجلسة. ارجع للصفحة وحاول مرة أخرى.');
        }
    }

    public static function rotate(): void
    {
        $_SESSION['_csrf'] = bin2hex(random_bytes(32));
    }
}
