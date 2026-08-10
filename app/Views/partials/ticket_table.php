<div class="table-card">
  <div class="table-scroll">
    <table>
      <thead><tr><th>رقم الطلب</th><th>العنوان</th><th>التصنيف</th><th>مقدم الطلب</th><th>الأولوية</th><th>الحالة</th><th>المسؤول</th><th>التاريخ</th></tr></thead>
      <tbody>
      <?php if (!$tickets): ?>
        <tr><td class="empty" colspan="8">لا توجد طلبات مطابقة.</td></tr>
      <?php endif; ?>
      <?php foreach ($tickets as $ticket): ?>
        <tr>
          <td><a class="ticket-no" href="<?= e(url('/tickets/' . $ticket['id'])) ?>"><?= e($ticket['ticket_number']) ?></a></td>
          <td><strong><?= e($ticket['title']) ?></strong></td>
          <td><?= e($ticket['category_name']) ?></td>
          <td><?= e($ticket['requester_name']) ?></td>
          <td><span class="badge priority-<?= e(strtolower($ticket['priority_code'])) ?>"><?= e($ticket['priority_name']) ?></span></td>
          <td><span class="badge status"><?= e($ticket['status_name']) ?></span></td>
          <td><?= e($ticket['assignee_name'] ?: 'غير مسند') ?></td>
          <td><time><?= e(date('Y/m/d', strtotime($ticket['created_at']))) ?></time></td>
        </tr>
      <?php endforeach; ?>
      </tbody>
    </table>
  </div>
</div>
