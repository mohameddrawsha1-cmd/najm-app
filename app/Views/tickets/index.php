<div class="section-head">
  <div><p class="eyebrow">مركز الطلبات</p><h2>متابعة جميع الأعمال</h2></div>
  <a class="btn btn-gold" href="<?= e(url('/tickets/create')) ?>">＋ طلب جديد</a>
</div>
<form class="filters panel" method="get" action="<?= e(url('/tickets')) ?>">
  <label class="search-field">⌕<input name="q" value="<?= e($filters['q']) ?>" placeholder="ابحث بالرقم أو العنوان..."></label>
  <select name="status">
    <option value="">كل الحالات</option>
    <?php foreach ($options['statuses'] as $option): ?><option value="<?= e($option['code']) ?>" <?= $filters['status']===$option['code']?'selected':'' ?>><?= e($option['name_ar']) ?></option><?php endforeach; ?>
  </select>
  <select name="priority">
    <option value="">كل الأولويات</option>
    <?php foreach ($options['priorities'] as $option): ?><option value="<?= e($option['code']) ?>" <?= $filters['priority']===$option['code']?'selected':'' ?>><?= e($option['name_ar']) ?></option><?php endforeach; ?>
  </select>
  <button class="btn btn-dark" type="submit">تصفية</button>
</form>
<?php require BASE_PATH . '/app/Views/partials/ticket_table.php'; ?>
