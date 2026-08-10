<?php use App\Core\Auth; ?>
<div class="ticket-head panel">
  <div>
    <div class="inline-meta"><span class="ticket-no"><?= e($ticket['ticket_number']) ?></span><span class="badge priority-<?= e(strtolower($ticket['priority_code'])) ?>"><?= e($ticket['priority_name']) ?></span><span class="badge status"><?= e($ticket['status_name']) ?></span></div>
    <h2><?= e($ticket['title']) ?></h2>
    <p><?= nl2br(e($ticket['description'])) ?></p>
  </div>
  <div class="ticket-side-meta">
    <small>مقدم الطلب</small><strong><?= e($ticket['requester_name']) ?></strong>
    <small>التصنيف</small><strong><?= e($ticket['category_name']) ?></strong>
    <small>المسؤول</small><strong><?= e($ticket['assignee_name'] ?: 'غير مسند') ?></strong>
    <small>تاريخ الإنشاء</small><strong><?= e(date('Y/m/d H:i', strtotime($ticket['created_at']))) ?></strong>
  </div>
</div>

<div class="ticket-layout">
  <section>
    <div class="section-head"><div><p class="eyebrow">سجل التواصل</p><h2>التحديثات</h2></div></div>
    <div class="timeline">
      <?php if(!$messages):?><div class="panel empty">لا توجد تحديثات بعد.</div><?php endif;?>
      <?php foreach($messages as $message):?>
        <article class="message <?= $message['is_internal'] ? 'internal' : '' ?>">
          <div class="avatar"><?= e(mb_substr($message['author_name'],0,1)) ?></div>
          <div class="message-body"><header><strong><?= e($message['author_name']) ?></strong><?php if($message['is_internal']):?><span class="badge note">ملاحظة داخلية</span><?php endif;?><time><?= e(date('Y/m/d H:i',strtotime($message['created_at']))) ?></time></header><p><?= nl2br(e($message['message'])) ?></p></div>
        </article>
      <?php endforeach;?>
    </div>
    <form class="panel form stack" method="post" action="<?= e(url('/tickets/'.$ticket['id'].'/message')) ?>">
      <?= csrf_field() ?>
      <label>إضافة تحديث<textarea name="message" rows="4" maxlength="5000" required placeholder="اكتب ما تم أو أضف معلومات جديدة..."></textarea></label>
      <div class="form-actions">
        <?php if(Auth::hasRole('SYSTEM_ADMIN','SUPPORT_MANAGER','SUPPORT_AGENT')):?><label class="check"><input type="checkbox" name="is_internal" value="1"> ملاحظة داخلية لا تظهر لمقدم الطلب</label><?php endif;?>
        <button class="btn btn-gold" type="submit">إضافة التحديث</button>
      </div>
    </form>
  </section>
  <aside class="ticket-actions">
    <?php if(Auth::hasRole('SYSTEM_ADMIN','SUPPORT_MANAGER','SUPPORT_AGENT')):?>
      <form class="panel form stack" method="post" action="<?= e(url('/tickets/'.$ticket['id'].'/status')) ?>">
        <?= csrf_field() ?><h3>تحديث الحالة</h3>
        <select name="status_id" required><?php foreach($options['statuses'] as $option):?><option value="<?= e($option['id']) ?>" <?= $ticket['status_id']==$option['id']?'selected':'' ?>><?= e($option['name_ar']) ?></option><?php endforeach;?></select>
        <textarea name="note" rows="3" placeholder="ملخص التحديث أو الحل"></textarea>
        <button class="btn btn-gold btn-block" type="submit">حفظ الحالة</button>
      </form>
    <?php endif;?>
    <?php if(Auth::hasRole('SYSTEM_ADMIN','SUPPORT_MANAGER')):?>
      <form class="panel form stack" method="post" action="<?= e(url('/tickets/'.$ticket['id'].'/assign')) ?>">
        <?= csrf_field() ?><h3>إسناد الطلب</h3>
        <select name="agent_id" required><option value="">اختر الفني</option><?php foreach($options['agents'] as $agent):?><option value="<?= e($agent['id']) ?>"><?= e($agent['name']) ?></option><?php endforeach;?></select>
        <button class="btn btn-dark btn-block" type="submit">إسناد</button>
      </form>
    <?php endif;?>
    <div class="panel history">
      <h3>تاريخ الحالات</h3>
      <?php foreach($history as $item):?><div><span></span><p><strong><?= e($item['to_status_name']) ?></strong><small><?= e($item['actor_name'].' • '.date('Y/m/d H:i',strtotime($item['changed_at']))) ?></small></p></div><?php endforeach;?>
    </div>
  </aside>
</div>
