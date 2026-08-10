<?php
declare(strict_types=1);

namespace App\Core;

final class Flash
{
    public static function put(string $key, mixed $value): void
    {
        $_SESSION['_flash'][$key] = $value;
    }

    public static function get(string $key, mixed $default = null): mixed
    {
        if (!array_key_exists($key, $_SESSION['_flash'] ?? [])) {
            return $default;
        }
        $value = $_SESSION['_flash'][$key];
        unset($_SESSION['_flash'][$key]);
        return $value;
    }

    public static function old(array $input): void
    {
        $_SESSION['_old'] = $input;
    }

    public static function clearOld(): void
    {
        unset($_SESSION['_old']);
    }
}
