<?php
declare(strict_types=1);

if (PHP_SAPI !== 'cli') {
    http_response_code(404);
    exit;
}

require dirname(__DIR__) . '/app/bootstrap.php';

use App\Core\Database;

function ask(string $label): string
{
    fwrite(STDOUT, $label . ': ');
    return trim((string) fgets(STDIN));
}

$email = mb_strtolower(ask('Admin email'));
$firstName = ask('First name');
$lastName = ask('Last name');
$password = ask('Password (minimum 12 characters)');

if (!filter_var($email, FILTER_VALIDATE_EMAIL) || mb_strlen($password) < 12 || $firstName === '' || $lastName === '') {
    fwrite(STDERR, "Invalid data. Use a valid email, names, and a password of at least 12 characters.\n");
    exit(1);
}

$pdo = Database::connection();
$roleId = $pdo->query('SELECT id FROM roles WHERE code = "SYSTEM_ADMIN" LIMIT 1')->fetchColumn();
if (!$roleId) {
    fwrite(STDERR, "Database seed is missing. Import database/database.sql first.\n");
    exit(1);
}

$statement = $pdo->prepare(
    'INSERT INTO users (user_type, role_id, first_name, last_name, email, password_hash, is_active, created_at, updated_at)
     VALUES ("INTERNAL", ?, ?, ?, ?, ?, 1, UTC_TIMESTAMP(), UTC_TIMESTAMP())'
);
try {
    $statement->execute([$roleId, $firstName, $lastName, $email, password_hash($password, PASSWORD_DEFAULT)]);
    fwrite(STDOUT, "Administrator created successfully.\n");
} catch (Throwable $exception) {
    fwrite(STDERR, "Could not create administrator. The email may already exist.\n");
    exit(1);
}
