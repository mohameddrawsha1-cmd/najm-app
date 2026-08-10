<?php $errors = flash('errors', []); ?>
<div class="form-page">
  <div class="panel form-card">
    <div class="section-head compact-head">
      <div><p class="eyebrow">طلب جديد</p><h2>ما الذي تحتاج مساعدتنا فيه؟</h2><p class="muted">اكتب التفاصيل بوضوح لتصل المهمة إلى الشخص المناسب بسرعة.</p></div>
      <span class="large-icon">✦</span>
    </div>
    <form class="form grid-form" method="post" action="<?= e(url('/tickets')) ?>">
      <?= csrf_field() ?>
      <label>نوع الطلب
        <select name="ticket_kind" required>
          <option value="">اختر النوع</option>
          <?php foreach ([
            'INCIDENT'=>'عطل أو مشكلة','SERVICE_REQUEST'=>'طلب خدمة','ONBOARDING'=>'تجهيز موظف جديد',
            'OFFBOARDING'=>'إنهاء خدمات موظف','GENERAL_REQUEST'=>'طلب عام أو داخلي'
          ] as $value=>$label): ?><option value="<?= e($value) ?>" <?= old('ticket_kind')===$value?'selected':'' ?>><?= e($label) ?></option><?php endforeach; ?>
        </select>
        <?php if(isset($errors['ticket_kind'])):?><small class="field-error"><?= e($errors['ticket_kind']) ?></small><?php endif;?>
      </label>
      <label>التصنيف
        <select name="category_id" required>
          <option value="">اختر التصنيف</option>
          <?php foreach ($options['categories'] as $option): ?><option value="<?= e($option['id']) ?>" <?= (string)old('category_id')===(string)$option['id']?'selected':'' ?>><?= e($option['name_ar']) ?></option><?php endforeach; ?>
        </select>
      </label>
      <label class="span-2">عنوان مختصر
        <input name="title" maxlength="220" value="<?= e(old('title')) ?>" required placeholder="مثال: الطابعة لا تظهر على جهاز المحاسبة">
      </label>
      <label>الأولوية
        <select name="priority_id" required>
          <?php foreach ($options['priorities'] as $option): ?><option value="<?= e($option['id']) ?>" <?= (string)old('priority_id')===(string)$option['id']?'selected':'' ?>><?= e($option['name_ar']) ?></option><?php endforeach; ?>
        </select>
      </label>
      <label>الموقع
        <select name="location_id"><option value="">غير محدد</option><?php foreach($options['locations'] as $option):?><option value="<?= e($option['id']) ?>"><?= e($option['name_ar']) ?></option><?php endforeach;?></select>
      </label>
      <label class="span-2">الجهاز المرتبط
        <select name="device_id"><option value="">لا يوجد جهاز محدد</option><?php foreach($options['devices'] as $option):?><option value="<?= e($option['id']) ?>"><?= e($option['asset_tag'] . ($option['hostname'] ? ' — '.$option['hostname'] : '')) ?></option><?php endforeach;?></select>
      </label>
      <label class="span-2">شرح المشكلة أو المطلوب
        <textarea name="description" rows="7" maxlength="10000" required placeholder="متى بدأت المشكلة؟ ما الرسالة التي تظهر؟ وما الذي جربته؟"><?= e(old('description')) ?></textarea>
      </label>
      <div class="span-2 form-actions">
        <a class="btn btn-dark" href="<?= e(url('/tickets')) ?>">إلغاء</a>
        <button class="btn btn-gold" type="submit">إرسال الطلب</button>
      </div>
    </form>
  </div>
  <aside class="panel tips">
    <span class="tips-icon">i</span><h3>لنتيجة أسرع</h3>
    <ul><li>اذكر اسم الجهاز أو رقمه.</li><li>انسخ رسالة الخطأ كما تظهر.</li><li>حدد مدى تأثير المشكلة.</li><li>لا تكتب كلمة المرور داخل الطلب.</li></ul>
  </aside>
</div>
