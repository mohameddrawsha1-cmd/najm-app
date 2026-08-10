<?php
declare(strict_types=1);

require dirname(__DIR__) . '/app/bootstrap.php';

use App\Core\Router;

$router = new Router();
require BASE_PATH . '/routes/web.php';

try {
    $router->dispatch($_SERVER['REQUEST_METHOD'] ?? 'GET', request_path());
} catch (Throwable $exception) {
    error_log($exception->__toString());
    http_response_code(500);
    if (config('app.debug')) {
        echo '<pre dir="ltr">' . e($exception->__toString()) . '</pre>';
    } else {
        \App\Core\View::render('errors/500', ['title' => 'خطأ في النظام']);
    }
}
