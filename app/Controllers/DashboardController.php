<?php
declare(strict_types=1);

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Controller;
use App\Repositories\DashboardRepository;

final class DashboardController extends Controller
{
    public function index(): void
    {
        Auth::requireLogin();
        $this->view('dashboard/index', array_merge(
            ['title' => 'لوحة التحكم'],
            (new DashboardRepository())->data()
        ));
    }
}
