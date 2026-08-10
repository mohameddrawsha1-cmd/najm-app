<?php
declare(strict_types=1);

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Controller;
use App\Repositories\DirectoryRepository;

final class UserController extends Controller
{
    public function index(): void
    {
        Auth::requireRole('SYSTEM_ADMIN', 'SUPPORT_MANAGER', 'AUDITOR');
        $this->view('users/index', ['title' => 'المستخدمون', 'users' => (new DirectoryRepository())->users()]);
    }
}
