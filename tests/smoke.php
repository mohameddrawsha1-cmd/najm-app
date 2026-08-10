<?php
declare(strict_types=1);

$root = dirname(__DIR__);
$required = [
    'app/bootstrap.php', 'app/Core/Auth.php', 'app/Core/Csrf.php',
    'app/Controllers/TicketController.php', 'app/Repositories/TicketRepository.php',
    'app/Views/layouts/app.php', 'database/database.sql', 'public/index.php', 'routes/web.php',
];
$failures = [];
foreach ($required as $file) {
    if (!is_file($root . '/' . $file)) {
        $failures[] = "Missing: {$file}";
    }
}
$sql = (string) @file_get_contents($root . '/database/database.sql');
foreach (['CREATE TABLE users', 'CREATE TABLE tickets', 'CREATE TABLE audit_logs', 'INSERT INTO roles'] as $needle) {
    if (!str_contains($sql, $needle)) {
        $failures[] = "SQL missing: {$needle}";
    }
}
$routes = (string) @file_get_contents($root . '/routes/web.php');
foreach (['/login', '/tickets', '/devices', '/users', '/reports'] as $route) {
    if (!str_contains($routes, $route)) {
        $failures[] = "Route missing: {$route}";
    }
}
if ($failures) {
    fwrite(STDERR, implode("\n", $failures) . "\n");
    exit(1);
}
fwrite(STDOUT, "Smoke checks passed.\n");
