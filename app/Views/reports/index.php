<div class="section-head"><div><p class="eyebrow">ذكاء تشغيلي</p><h2>ملخص الأداء</h2></div><a class="btn btn-gold" href="<?= e(url('/reports/export')) ?>">تنزيل CSV</a></div>
<div class="report-grid">
  <section class="panel"><h3>الطلبات حسب الحالة</h3><div class="bars">
    <?php $max=max(1,...array_column($byStatus,'total')); foreach($byStatus as $row):?><div class="bar-row"><span><?= e($row['label']) ?></span><div><i style="width:<?= e(((int)$row['total']/$max)*100) ?>%"></i></div><strong><?= e($row['total']) ?></strong></div><?php endforeach;?>
  </div></section>
  <section class="panel"><h3>أكثر التصنيفات استخدامًا</h3><div class="rank-list">
    <?php foreach($byCategory as $index=>$row):?><div><span><?= e($index+1) ?></span><p><?= e($row['label']) ?></p><strong><?= e($row['total']) ?></strong></div><?php endforeach;?>
  </div></section>
</div>
