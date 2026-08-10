<?php
declare(strict_types=1);

namespace App\Core;

final class Router
{
    private array $routes = [];

    public function get(string $path, array|callable $handler): void
    {
        $this->add('GET', $path, $handler);
    }

    public function post(string $path, array|callable $handler): void
    {
        $this->add('POST', $path, $handler);
    }

    public function add(string $method, string $path, array|callable $handler): void
    {
        $pattern = preg_replace('#\{([a-zA-Z_][a-zA-Z0-9_]*)\}#', '(?P<$1>[0-9]+)', rtrim($path, '/') ?: '/');
        $this->routes[] = [$method, '#^' . $pattern . '/?$#', $handler];
    }

    public function dispatch(string $method, string $path): void
    {
        $method = strtoupper($_POST['_method'] ?? $method);
        foreach ($this->routes as [$routeMethod, $pattern, $handler]) {
            if ($routeMethod !== $method || !preg_match($pattern, $path, $matches)) {
                continue;
            }
            $params = array_filter($matches, 'is_string', ARRAY_FILTER_USE_KEY);
            if ($method !== 'GET') {
                Csrf::enforce();
            }
            if (is_callable($handler)) {
                $handler(...array_values($params));
                return;
            }
            [$class, $action] = $handler;
            (new $class())->{$action}(...array_values($params));
            return;
        }
        http_response_code(404);
        View::render('errors/404', ['title' => 'الصفحة غير موجودة']);
    }
}
