<?php
declare(strict_types=1);

use App\Core\Env;

define('BASE_PATH', dirname(__DIR__));

require BASE_PATH . '/app/Core/Env.php';
Env::load(BASE_PATH . '/.env');

$autoload = BASE_PATH . '/vendor/autoload.php';
if (is_file($autoload)) {
    require $autoload;
} else {
    require BASE_PATH . '/app/helpers.php';
    spl_autoload_register(static function (string $class): void {
        $prefix = 'App\\';
        if (!str_starts_with($class, $prefix)) {
            return;
        }
        $file = BASE_PATH . '/app/' . str_replace('\\', '/', substr($class, strlen($prefix))) . '.php';
        if (is_file($file)) {
            require $file;
        }
    });
}

date_default_timezone_set((string) config('app.timezone', 'Asia/Kuwait'));

session_name((string) config('session.name', 'najm_it_session'));
session_set_cookie_params([
    'lifetime' => 0,
    'path' => '/',
    'secure' => (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off'),
    'httponly' => true,
    'samesite' => 'Lax',
]);
if (session_status() !== PHP_SESSION_ACTIVE) {
    session_start();
}
