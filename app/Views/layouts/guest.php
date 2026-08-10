<?php
$error = flash('error');
$errors = flash('errors', []);
?>
<!doctype html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title><?= e($title ?? '') ?> | <?= e(config('app.name')) ?></title>
  <link rel="stylesheet" href="<?= e(asset('css/app.css')) ?>">
</head>
<body class="guest-body">
  <main class="login-shell">
    <section class="login-art">
      <span class="orbit orbit-one"></span><span class="orbit orbit-two"></span>
      <div class="login-brand">
        <div class="hero-star">✦</div>
        <p class="eyebrow">خدمة أسرع • متابعة أوضح</p>
        <h1>كل طلب تقني<br><em>في مكان واحد</em></h1>
        <p>سجّل الأعطال والطلبات، تابع المسؤول عنها، واحتفظ بتاريخ كامل للحل.</p>
      </div>
    </section>
    <section class="login-panel">
      <div class="login-card">
        <a class="brand compact" href="<?= e(url('/')) ?>"><span class="brand-mark">✦</span><strong><?= e(config('app.name')) ?></strong></a>
        <h2>أهلًا بعودتك</h2>
        <p class="muted">أدخل بيانات حسابك للوصول إلى مركز الخدمة.</p>
        <?php if ($error): ?><div class="alert danger"><?= e($error) ?></div><?php endif; ?>
        <?= $content ?>
      </div>
    </section>
  </main>
</body>
</html>
