<?php
use App\Core\Auth;
use App\Core\Csrf;
$user = Auth::user();
$success = flash('success');
$error = flash('error');
$errors = flash('errors', []);
?>
<!doctype html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <meta name="csrf-token" content="<?= e(Csrf::token()) ?>">
  <title><?= e($title ?? '') ?> | <?= e(config('app.name')) ?></title>
  <link rel="stylesheet" href="<?= e(asset('css/app.css')) ?>">
</head>
<body>
<div class="app-shell">
  <aside class="sidebar" id="sidebar">
    <a class="brand" href="<?= e(url('/')) ?>">
      <span class="brand-mark">✦</span>
      <span><strong><?= e(config('app.name')) ?></strong><small>إدارة خدمات الـ IT</small></span>
    </a>
    <nav class="nav">
      <a class="<?= request_path() === '/' ? 'active' : '' ?>" href="<?= e(url('/')) ?>"><span>⌂</span> لوحة التحكم</a>
      <a class="<?= str_starts_with(request_path(), '/tickets') ? 'active' : '' ?>" href="<?= e(url('/tickets')) ?>"><span>▤</span> الطلبات</a>
      <a href="<?= e(url('/tickets/create')) ?>"><span>＋</span> طلب جديد</a>
      <?php if (Auth::hasRole('SYSTEM_ADMIN','SUPPORT_MANAGER','SUPPORT_AGENT','AUDITOR')): ?>
        <a class="<?= request_path() === '/devices' ? 'active' : '' ?>" href="<?= e(url('/devices')) ?>"><span>▣</span> الأجهزة</a>
      <?php endif; ?>
      <?php if (Auth::hasRole('SYSTEM_ADMIN','SUPPORT_MANAGER','AUDITOR')): ?>
        <a class="<?= request_path() === '/users' ? 'active' : '' ?>" href="<?= e(url('/users')) ?>"><span>♟</span> المستخدمون</a>
        <a class="<?= str_starts_with(request_path(), '/reports') ? 'active' : '' ?>" href="<?= e(url('/reports')) ?>"><span>◫</span> التقارير</a>
      <?php endif; ?>
    </nav>
    <div class="sidebar-user">
      <div class="avatar"><?= e(mb_substr($user['first_name'] ?? 'م', 0, 1)) ?></div>
      <div><strong><?= e(($user['first_name'] ?? '') . ' ' . ($user['last_name'] ?? '')) ?></strong><small><?= e($user['role_name'] ?? '') ?></small></div>
      <form action="<?= e(url('/logout')) ?>" method="post">
        <?= csrf_field() ?>
        <button class="icon-btn" type="submit" title="تسجيل الخروج">↪</button>
      </form>
    </div>
  </aside>

  <main class="main">
    <header class="topbar">
      <button class="menu-btn" type="button" data-menu>☰</button>
      <div>
        <p class="eyebrow">مركز الخدمة</p>
        <h1><?= e($title ?? '') ?></h1>
      </div>
      <a class="btn btn-gold top-action" href="<?= e(url('/tickets/create')) ?>">＋ طلب جديد</a>
    </header>

    <section class="page">
      <?php if ($success): ?><div class="alert success"><?= e($success) ?></div><?php endif; ?>
      <?php if ($error): ?><div class="alert danger"><?= e($error) ?></div><?php endif; ?>
      <?php if ($errors): ?><div class="alert danger">يرجى مراجعة الحقول المطلوبة.</div><?php endif; ?>
      <?= $content ?>
    </section>
  </main>
</div>
<div class="sidebar-overlay" data-overlay></div>
<script src="<?= e(asset('js/app.js')) ?>" defer></script>
</body>
</html>
