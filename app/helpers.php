<?php
declare(strict_types=1);

use App\Core\Env;
use App\Core\Flash;

function env(string $key, mixed $default = null): mixed
{
    return Env::get($key, $default);
}

function config(string $key, mixed $default = null): mixed
{
    static $config;
    $config ??= require __DIR__ . '/Config/app.php';
    $value = $config;
    foreach (explode('.', $key) as $segment) {
        if (!is_array($value) || !array_key_exists($segment, $value)) {
            return $default;
        }
        $value = $value[$segment];
    }
    return $value;
}

function e(mixed $value): string
{
    return htmlspecialchars((string) $value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}

function url(string $path = ''): string
{
    $base = rtrim((string) config('app.url', ''), '/');
    return $base . '/' . ltrim($path, '/');
}

function asset(string $path): string
{
    return url('assets/' . ltrim($path, '/'));
}

function old(string $key, mixed $default = ''): mixed
{
    return $_SESSION['_old'][$key] ?? $default;
}

function flash(string $key, mixed $default = null): mixed
{
    return Flash::get($key, $default);
}

function csrf_field(): string
{
    return '<input type="hidden" name="_token" value="' . e(\App\Core\Csrf::token()) . '">';
}

function redirect(string $path): never
{
    header('Location: ' . url($path));
    exit;
}

function request_path(): string
{
    $path = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
    $base = parse_url((string) config('app.url', ''), PHP_URL_PATH) ?: '';
    if ($base && str_starts_with($path, $base)) {
        $path = substr($path, strlen($base)) ?: '/';
    }
    return '/' . ltrim($path, '/');
}

function ar_status(string $code): string
{
    return [
        'NEW' => 'جديدة', 'TRIAGED' => 'تم الفرز', 'ASSIGNED' => 'مُسندة',
        'IN_PROGRESS' => 'قيد العمل', 'PENDING_REQUESTER' => 'بانتظار مقدم الطلب',
        'PENDING_INTERNAL' => 'بانتظار جهة داخلية', 'PENDING_PROVIDER' => 'بانتظار المزود',
        'PROVIDER_ON_SITE' => 'المزود في الموقع', 'RESOLVED' => 'تم الحل',
        'CLOSED' => 'مغلقة', 'CANCELLED' => 'ملغاة',
    ][$code] ?? $code;
}

function ar_priority(string $code): string
{
    return ['LOW' => 'منخفضة', 'MEDIUM' => 'متوسطة', 'HIGH' => 'عالية', 'CRITICAL' => 'حرجة'][$code] ?? $code;
}
