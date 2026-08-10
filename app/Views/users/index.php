<div class="section-head"><div><p class="eyebrow">دليل المؤسسة</p><h2>المستخدمون والصلاحيات</h2></div><span class="count"><?= e(count($users)) ?> مستخدم</span></div>
<div class="table-card"><div class="table-scroll"><table>
<thead><tr><th>الموظف</th><th>الرقم</th><th>البريد</th><th>الوظيفة</th><th>القسم</th><th>الصلاحية</th><th>الحالة</th><th>آخر دخول</th></tr></thead>
<tbody><?php foreach($users as $user):?><tr>
<td><strong><?= e($user['first_name'].' '.$user['last_name']) ?></strong></td><td><?= e($user['employee_number'] ?: '—') ?></td><td dir="ltr"><?= e($user['email']) ?></td>
<td><?= e($user['job_title'] ?: '—') ?></td><td><?= e($user['department_name'] ?: '—') ?></td><td><?= e($user['role_name']) ?></td>
<td><span class="badge <?= $user['is_active']?'success-badge':'danger-badge' ?>"><?= $user['is_active']?'نشط':'موقوف' ?></span></td><td><?= e($user['last_login_at'] ?: 'لم يدخل') ?></td>
</tr><?php endforeach;?></tbody></table></div></div>
