<form class="form stack" method="post" action="<?= e(url('/login')) ?>">
  <?= csrf_field() ?>
  <label>البريد الإلكتروني
    <input type="email" name="email" value="<?= e(old('email')) ?>" autocomplete="email" required autofocus placeholder="name@company.com">
  </label>
  <label>كلمة المرور
    <div class="password-wrap">
      <input id="password" type="password" name="password" autocomplete="current-password" required placeholder="••••••••">
      <button type="button" class="password-toggle" data-password-toggle>إظهار</button>
    </div>
  </label>
  <button class="btn btn-gold btn-block" type="submit">تسجيل الدخول</button>
  <small class="form-hint">عند تكرار المحاولة الخاطئة خمس مرات يُقفل الحساب مؤقتًا لحمايته.</small>
</form>
