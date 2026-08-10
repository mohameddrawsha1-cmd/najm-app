<?php
declare(strict_types=1);

use App\Controllers\AuthController;
use App\Controllers\DashboardController;
use App\Controllers\DeviceController;
use App\Controllers\ReportController;
use App\Controllers\TicketController;
use App\Controllers\UserController;

$router->get('/', [DashboardController::class, 'index']);
$router->get('/login', [AuthController::class, 'show']);
$router->post('/login', [AuthController::class, 'login']);
$router->post('/logout', [AuthController::class, 'logout']);

$router->get('/tickets', [TicketController::class, 'index']);
$router->get('/tickets/create', [TicketController::class, 'create']);
$router->post('/tickets', [TicketController::class, 'store']);
$router->get('/tickets/{id}', [TicketController::class, 'show']);
$router->post('/tickets/{id}/message', [TicketController::class, 'message']);
$router->post('/tickets/{id}/status', [TicketController::class, 'status']);
$router->post('/tickets/{id}/assign', [TicketController::class, 'assign']);

$router->get('/devices', [DeviceController::class, 'index']);
$router->get('/users', [UserController::class, 'index']);
$router->get('/reports', [ReportController::class, 'index']);
$router->get('/reports/export', [ReportController::class, 'export']);
