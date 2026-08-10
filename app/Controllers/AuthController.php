<?php
declare(strict_types=1);

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Controller;
use App\Core\Csrf;
use App\Core\Flash;

final class AuthController extends Controller
{
    public function show(): void
    {
        if (Auth::check()) {
            redirect('/');
        }
        $this->view('auth/login', ['title' => 'تسجيل الدخول'], 'layouts/guest');
    }

    public function login(): void
    {
        if ($this->validate(['email' => 'required|email|max:190', 'password' => 'required|max:200'])) {
            redirect('/login');
        }
        if (!Auth::attempt((string) $this->input('email'), (string) $this->input('password'))) {
            Flash::put('error', 'بيانات الدخول غير صحيحة أو الحساب مقفل مؤقتًا.');
            redirect('/login');
        }
        Csrf::rotate();
        Flash::clearOld();
        redirect('/');
    }

    public function logout(): void
    {
        Auth::logout();
        redirect('/login');
    }
}
