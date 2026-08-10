<?php
declare(strict_types=1);

return [
    'app' => [
        'name' => env('APP_NAME', 'بوابة تقنية المعلومات'),
        'env' => env('APP_ENV', 'production'),
        'debug' => filter_var(env('APP_DEBUG', false), FILTER_VALIDATE_BOOL),
        'url' => env('APP_URL', ''),
        'timezone' => env('APP_TIMEZONE', 'Asia/Kuwait'),
        'locale' => env('APP_LOCALE', 'ar'),
    ],
    'session' => [
        'name' => env('SESSION_NAME', 'najm_it_session'),
        'lifetime' => (int) env('SESSION_LIFETIME', 120),
    ],
    'database' => [
        'host' => env('DB_HOST', '127.0.0.1'),
        'port' => (int) env('DB_PORT', 3306),
        'name' => env('DB_DATABASE', 'it_service_management'),
        'username' => env('DB_USERNAME', 'root'),
        'password' => env('DB_PASSWORD', ''),
    ],
    'uploads' => [
        'max_mb' => (int) env('UPLOAD_MAX_MB', 10),
        'path' => dirname(__DIR__, 2) . '/storage/uploads',
    ],
];
