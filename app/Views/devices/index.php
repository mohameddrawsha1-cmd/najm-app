<div class="section-head"><div><p class="eyebrow">سجل الأصول</p><h2>الأجهزة المسجلة</h2></div><span class="count"><?= e(count($devices)) ?> جهاز</span></div>
<div class="table-card"><div class="table-scroll"><table>
<thead><tr><th>رقم الأصل</th><th>النوع</th><th>الاسم</th><th>الحالة</th><th>المستخدم</th><th>الموقع</th><th>الرقم التسلسلي</th><th>الضمان</th></tr></thead>
<tbody><?php if(!$devices):?><tr><td colspan="8" class="empty">لا توجد أجهزة مسجلة.</td></tr><?php endif;?>
<?php foreach($devices as $device):?><tr>
<td class="ticket-no"><?= e($device['asset_tag']) ?></td><td><?= e($device['type_name']) ?></td><td><?= e($device['hostname'] ?: $device['model']) ?></td>
<td><span class="badge status"><?= e($device['status_name']) ?></span></td><td><?= e($device['assigned_name'] ?: 'غير مسند') ?></td>
<td><?= e($device['location_name'] ?: '—') ?></td><td dir="ltr"><?= e($device['serial_number'] ?: '—') ?></td><td><?= e($device['warranty_end_date'] ?: '—') ?></td>
</tr><?php endforeach;?></tbody>
</table></div></div>
