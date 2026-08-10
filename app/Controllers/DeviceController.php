<?php
declare(strict_types=1);

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Controller;
use App\Repositories\DirectoryRepository;

final class DeviceController extends Controller
{
    public function index(): void
    {
        Auth::requireRole('SYSTEM_ADMIN', 'SUPPORT_MANAGER', 'SUPPORT_AGENT', 'AUDITOR');
        $this->view('devices/index', ['title' => 'الأجهزة', 'devices' => (new DirectoryRepository())->devices()]);
    }
}
