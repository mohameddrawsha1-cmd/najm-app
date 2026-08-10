<?php
$cards = [
  ['label'=>'إجمالي الطلبات','value'=>$stats['total'] ?? 0,'icon'=>'▤','tone'=>'gold'],
  ['label'=>'طلبات جديدة','value'=>$stats['new_count'] ?? 0,'icon'=>'✦','tone'=>'blue'],
  ['label'=>'قيد العمل','value'=>$stats['progress_count'] ?? 0,'icon'=>'◌','tone'=>'purple'],
  ['label'=>'تم حلها','value'=>$stats['resolved_count'] ?? 0,'icon'=>'✓','tone'=>'green'],
  ['label'=>'حرجة ومفتوحة','value'=>$stats['critical_count'] ?? 0,'icon'=>'!','tone'=>'red'],
  ['label'=>'متأخرة','value'=>$stats['overdue_count'] ?? 0,'icon'=>'◷','tone'=>'orange'],
];
?>
<div class="welcome panel glow">
  <div>
    <p class="eyebrow">صباح الإنجاز</p>
    <h2>مرحبًا، <?= e(\App\Core\Auth::user()['first_name'] ?? '') ?> <span>✦</span></h2>
    <p>هذه صورة سريعة لحالة العمل. ابدأ بالطلبات الحرجة أو المتأخرة.</p>
  </div>
  <a class="btn btn-gold" href="<?= e(url('/tickets/create')) ?>">إنشاء طلب</a>
</div>
<div class="stat-grid">
  <?php foreach ($cards as $card): ?>
    <article class="stat-card">
      <span class="stat-icon <?= e($card['tone']) ?>"><?= e($card['icon']) ?></span>
      <div><strong><?= e((int)$card['value']) ?></strong><p><?= e($card['label']) ?></p></div>
    </article>
  <?php endforeach; ?>
</div>
<div class="section-head">
  <div><p class="eyebrow">آخر النشاط</p><h2>الطلبات الحديثة</h2></div>
  <a class="text-link" href="<?= e(url('/tickets')) ?>">عرض الجميع ←</a>
</div>
<?php $tickets = $recent; require BASE_PATH . '/app/Views/partials/ticket_table.php'; ?>
