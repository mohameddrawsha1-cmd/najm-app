import 'dart:math';

import 'package:flutter/material.dart';

import 'v3_models.dart';
import 'v3_services.dart';

const bg = Color(0xFF05070A);
const panel = Color(0xFF11151B);
const panel2 = Color(0xFF181D25);
const gold = Color(0xFFE8B84E);
const gold2 = Color(0xFFFFD978);
const border = Color(0xFF343A44);
const success = Color(0xFF61C98B);
const danger = Color(0xFFE16A6A);

class NajmV3App extends StatelessWidget {
  const NajmV3App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'نجم',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(seedColor: gold, brightness: Brightness.dark),
        useMaterial3: true,
        fontFamilyFallback: const ['Arial'],
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0D1117),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: gold)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
      home: const NajmV3Shell(),
    );
  }
}

class NajmV3Shell extends StatefulWidget {
  const NajmV3Shell({super.key});
  @override
  State<NajmV3Shell> createState() => _NajmV3ShellState();
}

class _NajmV3ShellState extends State<NajmV3Shell> {
  int tab = 0;
  bool loading = true;
  bool planGoals = true;
  List<ProfileData> profiles = [];
  ProfileData? profile;
  List<DreamData> dreams = [];
  List<GoalData> goals = [];
  List<TaskData> tasks = [];
  List<HabitData> habits = [];
  int morningHour = 8;
  int morningMinute = 0;
  int eveningHour = 20;
  int eveningMinute = 30;
  String reflection = '';
  bool notificationsEnabled = false;
  int pendingNotifications = 0;

  UserStore get store => UserStore(profile!.id);

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await NajmNotifications.instance.init();
    profiles = await ProfileStore.loadProfiles();
    if (profiles.isEmpty) {
      final first = ProfileData(id: 'p_${DateTime.now().millisecondsSinceEpoch}', name: 'أنا', createdAt: DateTime.now());
      profiles = [first];
      await ProfileStore.saveProfiles(profiles);
      await ProfileStore.setCurrent(first.id);
    }
    final current = await ProfileStore.currentId();
    profile = profiles.where((e) => e.id == current).firstOrNull ?? profiles.first;
    await _loadUser();
    if (!mounted) return;
    setState(() => loading = false);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refreshNotificationState(requestIfNeeded: true);
      await _reschedule();
    });
  }

  Future<void> _loadUser() async {
    dreams = await store.dreams();
    goals = await store.goals();
    tasks = await store.tasks();
    habits = await store.habits();
    morningHour = await store.morningHour();
    morningMinute = await store.morningMinute();
    eveningHour = await store.eveningHour();
    eveningMinute = await store.eveningMinute();
    reflection = await store.reflection();
  }

  Future<void> _saveAll() async {
    await store.saveDreams(dreams);
    await store.saveGoals(goals);
    await store.saveTasks(tasks);
    await store.saveHabits(habits);
  }

  Future<void> _refreshNotificationState({bool requestIfNeeded = false}) async {
    var enabled = await NajmNotifications.instance.enabled();
    if (!enabled && requestIfNeeded) {
      enabled = await NajmNotifications.instance.requestPermission();
    }
    final pending = await NajmNotifications.instance.pendingCount();
    if (!mounted) return;
    setState(() {
      notificationsEnabled = enabled;
      pendingNotifications = pending;
    });
  }

  Future<void> _reschedule() async {
    if (profile == null) return;
    await NajmNotifications.instance.scheduleForProfile(
      profile: profile!,
      dreams: dreams,
      goals: goals,
      tasks: tasks,
      morningHour: morningHour,
      morningMinute: morningMinute,
      eveningHour: eveningHour,
      eveningMinute: eveningMinute,
    );
    await _refreshNotificationState();
  }

  double get overallGoalProgress {
    if (goals.isEmpty) return 0;
    return goals.fold<double>(0, (a, b) => a + b.progress) / goals.length;
  }

  int get tasksDoneToday => tasks.where((e) => e.done && (e.dueDate == null || dayKey(e.dueDate) == dayKey())).length;
  List<TaskData> get openTasks {
    final x = tasks.where((e) => !e.done).toList();
    x.sort((a, b) {
      final p = b.priority.compareTo(a.priority);
      if (p != 0) return p;
      if (a.dueDate == null && b.dueDate == null) return a.createdAt.compareTo(b.createdAt);
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });
    return x;
  }

  int get dreamReadsToday => dreams.where((e) => e.readDates.contains(dayKey())).length;
  int get habitWinsToday => habits.where((e) => e.lastCheckDate == dayKey() && e.lastCheckSuccess == true).length;

  int get successScore {
    final goalPart = (overallGoalProgress * 35).round();
    final taskPart = tasks.isEmpty ? 10 : min(25, tasksDoneToday * 8);
    final dreamPart = dreams.isEmpty ? 5 : ((dreamReadsToday / dreams.length) * 15).round();
    final habitPart = habits.isEmpty ? 10 : ((habitWinsToday / habits.length) * 25).round();
    return min(100, goalPart + taskPart + dreamPart + habitPart);
  }

  String get coachMessage {
    if (dreams.isEmpty) return 'ابدأ بتحديد صورة واضحة للحياة التي تريدها. الرؤية تعطي العمل اتجاهاً.';
    if (goals.isEmpty) return 'رؤيتك جميلة، لكن الحلم يحتاج جسراً. حوّل أهم حلم إلى هدف قابل للقياس.';
    if (tasks.isEmpty) return 'الهدف بلا مهمة اليوم يبقى فكرة. أضف أصغر خطوة يمكنك تنفيذها خلال 20 دقيقة.';
    if (habits.any((h) => h.lastCheckDate == dayKey() && h.lastCheckSuccess == false)) return 'تعثّرت؟ لا تحوّل لحظة إلى يوم كامل. أوقف السلسلة الآن ونفّذ السلوك البديل.';
    if (successScore >= 80) return 'يوم قوي. لا تبحث عن المزيد من الخطط؛ أغلق أهم مهمة متبقية وحافظ على الزخم.';
    if (openTasks.isNotEmpty) return 'لا تحتاج حماساً إضافياً. نفّذ الآن: ${openTasks.first.title}.';
    return 'أنجزت ما عليك اليوم. راجع رؤيتك، سجّل امتنانك، وجهّز أول خطوة للغد.';
  }

  Widget _card(Widget child, {EdgeInsets padding = const EdgeInsets.all(16)}) => Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF141922), Color(0xFF0C1016)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 8))],
        ),
        child: child,
      );

  Widget _logo({double size = 54}) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(colors: [gold2, gold]),
          border: Border.all(color: const Color(0xFFFFE9AB)),
          boxShadow: const [BoxShadow(color: Color(0x44E8B84E), blurRadius: 18)],
        ),
        alignment: Alignment.center,
        child: Text('نجم', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: size * .29)),
      );

  Widget _header(String title, String subtitle, {Widget? action}) => Row(children: [
        _logo(),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ])),
        action ?? IconButton(onPressed: _showProfiles, icon: const Icon(Icons.person_outline_rounded, color: gold)),
      ]);

  @override
  Widget build(BuildContext context) {
    if (loading || profile == null) {
      return const Directionality(textDirection: TextDirection.rtl, child: Scaffold(body: Center(child: CircularProgressIndicator(color: gold))));
    }
    final pages = [_todayPage(), _visionPage(), _planPage(), _habitsPage(), _coachPage()];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(bottom: false, child: IndexedStack(index: tab, children: pages)),
        bottomNavigationBar: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 4),
          child: Container(
            decoration: const BoxDecoration(color: Color(0xFF090C10), border: Border(top: BorderSide(color: border))),
            child: NavigationBar(
              height: 68,
              backgroundColor: const Color(0xFF090C10),
              indicatorColor: const Color(0xFF2A2418),
              selectedIndex: tab,
              onDestinationSelected: (i) => setState(() => tab = i),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded, color: gold), label: 'اليوم'),
                NavigationDestination(icon: Icon(Icons.visibility_outlined), selectedIcon: Icon(Icons.visibility_rounded, color: gold), label: 'رؤيتي'),
                NavigationDestination(icon: Icon(Icons.route_outlined), selectedIcon: Icon(Icons.route_rounded, color: gold), label: 'خطتي'),
                NavigationDestination(icon: Icon(Icons.loop_rounded), selectedIcon: Icon(Icons.local_fire_department_rounded, color: gold), label: 'عاداتي'),
                NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome_rounded, color: gold), label: 'نجم'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _todayPage() {
    final top = openTasks.take(3).toList();
    final mainGoal = goals.where((e) => !e.completed).firstOrNull;
    return RefreshIndicator(
      color: gold,
      onRefresh: () async { await _loadUser(); await _refreshNotificationState(); if (mounted) setState(() {}); },
      child: ListView(padding: const EdgeInsets.fromLTRB(18, 14, 18, 28), children: [
        _header('مرحباً ${profile!.name}', 'نجم ينظم يومك ويربطه بمستقبلك'),
        const SizedBox(height: 20),
        _card(Row(children: [
          SizedBox(width: 92, height: 92, child: Stack(alignment: Alignment.center, children: [
            SizedBox(width: 86, height: 86, child: CircularProgressIndicator(value: successScore / 100, strokeWidth: 8, color: gold, backgroundColor: border)),
            Text('$successScore', style: const TextStyle(color: gold, fontSize: 26, fontWeight: FontWeight.w900)),
          ])),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('مؤشر يومك', style: TextStyle(color: gold, fontWeight: FontWeight.w900)),
            const SizedBox(height: 7),
            Text(coachMessage, style: const TextStyle(color: Colors.white70, height: 1.5)),
          ])),
        ])),
        const SizedBox(height: 14),
        _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const Icon(Icons.visibility_rounded, color: gold), const SizedBox(width: 8), const Text('طقس الرؤية اليومي', style: TextStyle(color: gold, fontWeight: FontWeight.w900)), const Spacer(), Text('$dreamReadsToday/${dreams.length}', style: const TextStyle(color: Colors.white54))]),
          const SizedBox(height: 10),
          Text(dreams.isEmpty ? 'أضف حلمك وصِف مستقبلك كما تريد أن تعيشه.' : 'اقرأ أحلامك ببطء، تخيّل المشهد لدقيقتين، ثم اسأل: ما الفعل الذي يثبت أنني أتحرك نحوه؟', style: const TextStyle(height: 1.5)),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => setState(() => tab = 1), icon: const Icon(Icons.visibility_outlined), label: const Text('افتح رؤيتي'))),
        ])),
        const SizedBox(height: 14),
        if (mainGoal != null) _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const Text('هدفك الرئيسي', style: TextStyle(color: gold, fontWeight: FontWeight.w900)), const Spacer(), Text('${(mainGoal.progress * 100).round()}%', style: const TextStyle(color: gold))]),
          const SizedBox(height: 9),
          Text(mainGoal.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: mainGoal.progress, minHeight: 8, color: gold, backgroundColor: border)),
        ])),
        if (mainGoal != null) const SizedBox(height: 14),
        _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const Text('أهم 3 مهام', style: TextStyle(color: gold, fontWeight: FontWeight.w900)), const Spacer(), IconButton(onPressed: _addTask, icon: const Icon(Icons.add_circle_outline, color: gold))]),
          if (top.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('لا توجد مهام مفتوحة. أضف خطوة حقيقية لليوم.', style: TextStyle(color: Colors.white60))),
          for (final t in top) _taskTile(t, compact: true),
        ])),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _mini('الأهداف', '${goals.where((e) => !e.completed).length}', Icons.flag_outlined)),
          const SizedBox(width: 8),
          Expanded(child: _mini('مهام منجزة', '$tasksDoneToday', Icons.task_alt_rounded)),
          const SizedBox(width: 8),
          Expanded(child: _mini('انتصار عادات', '$habitWinsToday', Icons.local_fire_department_outlined)),
        ]),
      ]),
    );
  }

  Widget _mini(String title, String value, IconData icon) => _card(Column(children: [Icon(icon, color: gold), const SizedBox(height: 6), Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 11))]), padding: const EdgeInsets.all(12));

  Widget _visionPage() => ListView(padding: const EdgeInsets.fromLTRB(18, 14, 18, 28), children: [
        _header('رؤيتي وأحلامي', 'درّب انتباهك على المستقبل الذي تبنيه', action: IconButton(onPressed: _addDream, icon: const Icon(Icons.add_circle, color: gold, size: 30))),
        const SizedBox(height: 18),
        _card(const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('قاعدة نجم للرؤية', style: TextStyle(color: gold, fontWeight: FontWeight.w900)),
          SizedBox(height: 8),
          Text('التخيّل ليس بديلاً عن العمل. اقرأ رؤيتك، اشعر بمعناها، ثم اربطها دائماً بفعل صغير في العالم الحقيقي.', style: TextStyle(color: Colors.white70, height: 1.5)),
        ])),
        const SizedBox(height: 14),
        if (dreams.isEmpty) _empty('لا توجد أحلام مسجلة', 'أضف حلماً واكتب كيف يبدو يوم من حياتك عندما يتحقق.', _addDream),
        for (final d in dreams) Padding(padding: const EdgeInsets.only(bottom: 12), child: _dreamCard(d)),
      ]);

  Widget _dreamCard(DreamData d) {
    final read = d.readDates.contains(dayKey());
    return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        CircleAvatar(backgroundColor: const Color(0xFF2A2418), child: Icon(read ? Icons.check_rounded : Icons.star_rounded, color: gold)),
        const SizedBox(width: 11),
        Expanded(child: Text(d.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900))),
        if (read) const Text('قُرئت اليوم', style: TextStyle(color: success, fontSize: 11)),
      ]),
      if (d.futureScene.isNotEmpty) ...[
        const SizedBox(height: 12),
        const Text('مشهد مستقبلي', style: TextStyle(color: gold, fontSize: 12, fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        Text(d.futureScene, style: const TextStyle(height: 1.55, color: Colors.white70)),
      ],
      if (d.identityStatement.isNotEmpty) ...[
        const SizedBox(height: 12),
        Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF292317), borderRadius: BorderRadius.circular(14)), child: Text('أنا أختار أن أكون: ${d.identityStatement}', style: const TextStyle(color: gold, fontWeight: FontWeight.w800))),
      ],
      const SizedBox(height: 13),
      SizedBox(width: double.infinity, child: FilledButton.icon(
        onPressed: read ? null : () async {
          setState(() => d.readDates.add(dayKey()));
          await store.saveDreams(dreams);
        },
        style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black),
        icon: const Icon(Icons.visibility_rounded),
        label: Text(read ? 'تم طقس الرؤية اليوم' : 'قرأتها وتخيّلتها اليوم', style: const TextStyle(fontWeight: FontWeight.w900)),
      )),
    ]));
  }

  Widget _planPage() => ListView(padding: const EdgeInsets.fromLTRB(18, 14, 18, 28), children: [
        _header('الخطة والتنفيذ', 'حوّل الأحلام إلى أهداف والأهداف إلى مهام'),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: ChoiceChip(label: const Text('الأهداف'), selected: planGoals, onSelected: (_) => setState(() => planGoals = true), selectedColor: const Color(0xFF2A2418), labelStyle: TextStyle(color: planGoals ? gold : Colors.white70))),
          const SizedBox(width: 8),
          Expanded(child: ChoiceChip(label: const Text('المهام'), selected: !planGoals, onSelected: (_) => setState(() => planGoals = false), selectedColor: const Color(0xFF2A2418), labelStyle: TextStyle(color: !planGoals ? gold : Colors.white70))),
        ]),
        const SizedBox(height: 16),
        if (planGoals) ...[
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _addGoal, style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black), icon: const Icon(Icons.add), label: const Text('أضف هدفاً', style: TextStyle(fontWeight: FontWeight.w900)))),
          const SizedBox(height: 14),
          if (goals.isEmpty) _empty('لا توجد أهداف بعد', 'اختر هدفاً يخدم رؤيتك ويستحق وقتك.', _addGoal),
          for (final g in goals) Padding(padding: const EdgeInsets.only(bottom: 12), child: _goalCard(g)),
        ] else ...[
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _addTask, style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black), icon: const Icon(Icons.add), label: const Text('أضف مهمة', style: TextStyle(fontWeight: FontWeight.w900)))),
          const SizedBox(height: 14),
          if (tasks.isEmpty) _empty('لا توجد مهام', 'اكتب مهمة صغيرة واضحة يمكن تنفيذها، لا مشروعاً غامضاً.', _addTask),
          for (final t in [...openTasks, ...tasks.where((e) => e.done)]) Padding(padding: const EdgeInsets.only(bottom: 8), child: _taskTile(t)),
        ],
      ]);

  Widget _goalCard(GoalData g) => _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(g.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900))),
          Text('${(g.progress * 100).round()}%', style: const TextStyle(color: gold, fontWeight: FontWeight.w900)),
        ]),
        if (g.why.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 5), child: Text('لماذا: ${g.why}', style: const TextStyle(color: Colors.white60))),
        const SizedBox(height: 11),
        ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: g.progress, minHeight: 8, color: gold, backgroundColor: border)),
        const SizedBox(height: 9),
        Row(children: [Text('الموعد: ${dateLabel(g.deadline)}', style: const TextStyle(color: Colors.white54, fontSize: 11)), const Spacer(), Text('🔔 ${timeLabel(g.reminderHour, g.reminderMinute)}', style: const TextStyle(color: Colors.white54, fontSize: 11))]),
        const Divider(height: 24, color: border),
        if (g.steps.isEmpty) const Text('أضف خطوات حتى يصبح الهدف قابلاً للتنفيذ.', style: TextStyle(color: Colors.white54)),
        for (final s in g.steps) CheckboxListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          activeColor: gold,
          checkColor: Colors.black,
          value: s.done,
          title: Text(s.title, style: TextStyle(decoration: s.done ? TextDecoration.lineThrough : null, color: s.done ? Colors.white38 : Colors.white)),
          onChanged: (v) async {
            setState(() => s.done = v == true);
            await store.saveGoals(goals);
            await _reschedule();
          },
        ),
        Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () => _addGoalStep(g), icon: const Icon(Icons.add, color: gold), label: const Text('إضافة خطوة', style: TextStyle(color: gold)))),
      ]));

  Widget _taskTile(TaskData t, {bool compact = false}) => InkWell(
        onTap: () async {
          setState(() => t.done = !t.done);
          await store.saveTasks(tasks);
          await _reschedule();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: compact ? 8 : 12),
          decoration: BoxDecoration(color: panel2, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
          child: Row(children: [
            Icon(t.done ? Icons.check_circle_rounded : Icons.radio_button_unchecked, color: t.done ? success : (t.priority == 3 ? gold : Colors.white54)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.title, style: TextStyle(fontWeight: FontWeight.w700, decoration: t.done ? TextDecoration.lineThrough : null, color: t.done ? Colors.white38 : Colors.white)),
              if (!compact && t.dueDate != null) Text('موعد: ${dateLabel(t.dueDate)}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ])),
            if (!compact) Text(t.priority == 3 ? 'عالية' : t.priority == 2 ? 'متوسطة' : 'خفيفة', style: TextStyle(fontSize: 10, color: t.priority == 3 ? gold : Colors.white38)),
          ]),
        ),
      );

  Widget _habitsPage() => ListView(padding: const EdgeInsets.fromLTRB(18, 14, 18, 28), children: [
        _header('نظام العادات', 'ابنِ ما يخدمك واترك ما يسرق مستقبلك', action: IconButton(onPressed: _addHabit, icon: const Icon(Icons.add_circle, color: gold, size: 30))),
        const SizedBox(height: 16),
        _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('عند لحظة الضعف', style: TextStyle(color: gold, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('لا تفاوض العادة طويلاً. غيّر مكانك، أبعد المحفّز، نفّذ البديل، وانتظر 10 دقائق قبل أي قرار.', style: TextStyle(color: Colors.white70, height: 1.5)),
          const SizedBox(height: 11),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _rescue, icon: const Icon(Icons.shield_outlined, color: gold), label: const Text('أحتاج خطة إنقاذ الآن'))),
        ])),
        const SizedBox(height: 14),
        if (habits.isEmpty) _empty('لا توجد عادات', 'أضف عادة تريد بناءها أو عادة تريد تركها.', _addHabit),
        for (final h in habits) Padding(padding: const EdgeInsets.only(bottom: 12), child: _habitCard(h)),
      ]);

  Widget _habitCard(HabitData h) {
    final checked = h.lastCheckDate == dayKey();
    return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(h.kind == 'quit' ? Icons.shield_outlined : Icons.trending_up_rounded, color: gold),
        const SizedBox(width: 10),
        Expanded(child: Text(h.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
        Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF2A2418), borderRadius: BorderRadius.circular(30)), child: Text(h.kind == 'quit' ? 'أتركها' : 'أبنيها', style: const TextStyle(color: gold, fontSize: 10))),
      ]),
      if (h.replacement.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('البديل: ${h.replacement}', style: const TextStyle(color: Colors.white60))),
      const SizedBox(height: 10),
      Row(children: [Text('🔥 ${h.streak} أيام', style: const TextStyle(color: gold, fontWeight: FontWeight.w800)), const Spacer(), Text('الأفضل ${h.best}', style: const TextStyle(color: Colors.white54))]),
      const SizedBox(height: 12),
      if (checked)
        Text(h.lastCheckSuccess == true ? '✅ انتصار اليوم مسجل' : '↩️ تعثر مسجل — المهم العودة الآن', style: TextStyle(color: h.lastCheckSuccess == true ? success : danger))
      else
        Row(children: [
          Expanded(child: FilledButton(onPressed: () => _checkHabit(h, true), style: FilledButton.styleFrom(backgroundColor: success, foregroundColor: Colors.black), child: const Text('نجحت اليوم'))),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton(onPressed: () => _checkHabit(h, false), child: const Text('تعثرت'))),
        ]),
    ]));
  }

  Widget _coachPage() => ListView(padding: const EdgeInsets.fromLTRB(18, 14, 18, 28), children: [
        _header('نجم معك', 'مرشد يومي مبني على بياناتك وتقدمك'),
        const SizedBox(height: 16),
        _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [Icon(Icons.auto_awesome, color: gold), SizedBox(width: 8), Text('رسالة نجم الآن', style: TextStyle(color: gold, fontWeight: FontWeight.w900))]),
          const SizedBox(height: 12),
          Text(coachMessage, style: const TextStyle(fontSize: 18, height: 1.6, fontWeight: FontWeight.w600)),
        ])),
        const SizedBox(height: 14),
        _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('مراجعة نهاية اليوم', style: TextStyle(color: gold, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('اكتب: ما أهم انتصار؟ ما الشيء الذي سأحسنه غداً؟', style: TextStyle(color: Colors.white60)),
          const SizedBox(height: 10),
          TextField(
            controller: TextEditingController(text: reflection)..selection = TextSelection.collapsed(offset: reflection.length),
            maxLines: 4,
            onChanged: (v) => reflection = v,
            decoration: const InputDecoration(hintText: 'اكتب مراجعتك هنا...'),
          ),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () async { await store.setReflection(reflection); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ مراجعة اليوم ✦'))); }, style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black), child: const Text('حفظ المراجعة', style: TextStyle(fontWeight: FontWeight.w900)))),
        ])),
        const SizedBox(height: 14),
        _notificationCard(),
        const SizedBox(height: 14),
        _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('مواعيد نجم', style: TextStyle(color: gold, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          ListTile(contentPadding: EdgeInsets.zero, title: const Text('طقس الرؤية الصباحي'), subtitle: Text(timeLabel(morningHour, morningMinute)), trailing: const Icon(Icons.schedule, color: gold), onTap: () => _changeTime(true)),
          ListTile(contentPadding: EdgeInsets.zero, title: const Text('المراجعة المسائية'), subtitle: Text(timeLabel(eveningHour, eveningMinute)), trailing: const Icon(Icons.schedule, color: gold), onTap: () => _changeTime(false)),
        ])),
      ]);

  Widget _notificationCard() => _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(notificationsEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_outlined, color: notificationsEnabled ? success : danger),
          const SizedBox(width: 9),
          Expanded(child: Text(notificationsEnabled ? 'الإشعارات مفعّلة' : 'الإشعارات متوقفة', style: const TextStyle(fontWeight: FontWeight.w900))),
          Text('$pendingNotifications مجدولة', style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ]),
        const SizedBox(height: 10),
        Text(notificationsEnabled ? 'جرّب الاختبار الآن. إذا ظهر، فالتذكيرات داخل نجم جاهزة.' : 'اضغط تفعيل. إذا كنت رفضت الإذن سابقاً قد تحتاج السماح لنجم من إعدادات إشعارات Android.', style: const TextStyle(color: Colors.white60, height: 1.4)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: FilledButton(onPressed: () async { await NajmNotifications.instance.requestPermission(); await _refreshNotificationState(); await _reschedule(); }, style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black), child: const Text('تفعيل'))),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton(onPressed: () async { await NajmNotifications.instance.testNow(profile!.name); await _refreshNotificationState(); }, child: const Text('اختبار الآن'))),
        ]),
      ]));

  Widget _empty(String title, String text, VoidCallback action) => _card(Column(children: [const Icon(Icons.auto_awesome, color: gold, size: 36), const SizedBox(height: 8), Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), const SizedBox(height: 5), Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60, height: 1.4)), const SizedBox(height: 12), OutlinedButton(onPressed: action, child: const Text('ابدأ الآن'))]));

  Future<void> _addDream() async {
    final title = TextEditingController();
    final scene = TextEditingController();
    final identity = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(
      backgroundColor: panel,
      title: const Text('أضف حلماً إلى رؤيتك'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, autofocus: true, decoration: const InputDecoration(labelText: 'الحلم / النتيجة التي تريدها')),
        const SizedBox(height: 10),
        TextField(controller: scene, maxLines: 4, decoration: const InputDecoration(labelText: 'صف مشهداً من حياتك بعد تحققه', hintText: 'أين أنت؟ ماذا تفعل؟ كيف يبدو يومك؟')),
        const SizedBox(height: 10),
        TextField(controller: identity, maxLines: 2, decoration: const InputDecoration(labelText: 'من الشخص الذي تحتاج أن تصبحه؟', hintText: 'مثال: منضبط، شجاع، يهتم بصحته...')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حفظ'))],
    )));
    if (ok == true && title.text.trim().isNotEmpty) {
      setState(() => dreams.add(DreamData(id: 'd_${DateTime.now().microsecondsSinceEpoch}', title: title.text.trim(), futureScene: scene.text.trim(), identityStatement: identity.text.trim(), createdAt: DateTime.now())));
      await store.saveDreams(dreams);
      await _reschedule();
    }
  }

  Future<void> _addGoal() async {
    final title = TextEditingController();
    final why = TextEditingController();
    DateTime? deadline;
    TimeOfDay reminder = const TimeOfDay(hour: 19, minute: 0);
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(
      backgroundColor: panel,
      title: const Text('هدف جديد'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, autofocus: true, decoration: const InputDecoration(labelText: 'ما الهدف؟')),
        const SizedBox(height: 10),
        TextField(controller: why, maxLines: 3, decoration: const InputDecoration(labelText: 'لماذا يهمك؟')),
        const SizedBox(height: 10),
        ListTile(contentPadding: EdgeInsets.zero, title: const Text('الموعد النهائي'), subtitle: Text(dateLabel(deadline)), trailing: const Icon(Icons.calendar_month, color: gold), onTap: () async { final d = await showDatePicker(context: ctx, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 3650))); if (d != null) setLocal(() => deadline = d); }),
        ListTile(contentPadding: EdgeInsets.zero, title: const Text('تذكير يومي للهدف'), subtitle: Text(reminder.format(ctx)), trailing: const Icon(Icons.notifications_active_outlined, color: gold), onTap: () async { final t = await showTimePicker(context: ctx, initialTime: reminder); if (t != null) setLocal(() => reminder = t); }),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('إنشاء'))],
    ))));
    if (ok == true && title.text.trim().isNotEmpty) {
      final id = 'g_${DateTime.now().microsecondsSinceEpoch}';
      setState(() => goals.add(GoalData(id: id, title: title.text.trim(), why: why.text.trim(), createdAt: DateTime.now(), deadline: deadline, reminderHour: reminder.hour, reminderMinute: reminder.minute, notificationId: stableId(id, 200000))));
      await store.saveGoals(goals);
      await _reschedule();
    }
  }

  Future<void> _addGoalStep(GoalData g) async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(backgroundColor: panel, title: const Text('خطوة تنفيذية'), content: TextField(controller: c, autofocus: true, decoration: const InputDecoration(hintText: 'ما الخطوة الواضحة التالية؟')), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('إضافة'))])));
    if (ok == true && c.text.trim().isNotEmpty) {
      setState(() => g.steps.add(GoalStep(id: 's_${DateTime.now().microsecondsSinceEpoch}', title: c.text.trim())));
      await store.saveGoals(goals);
    }
  }

  Future<void> _addTask() async {
    final c = TextEditingController();
    int priority = 2;
    DateTime? due = DateTime.now();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(
      backgroundColor: panel,
      title: const Text('مهمة جديدة'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: c, autofocus: true, decoration: const InputDecoration(labelText: 'ماذا ستنفذ؟')),
        const SizedBox(height: 10),
        DropdownButtonFormField<int>(initialValue: priority, decoration: const InputDecoration(labelText: 'الأولوية'), items: const [DropdownMenuItem(value: 3, child: Text('عالية')), DropdownMenuItem(value: 2, child: Text('متوسطة')), DropdownMenuItem(value: 1, child: Text('خفيفة'))], onChanged: (v) => setLocal(() => priority = v ?? 2)),
        const SizedBox(height: 10),
        ListTile(contentPadding: EdgeInsets.zero, title: const Text('موعد المهمة'), subtitle: Text(dateLabel(due)), trailing: const Icon(Icons.calendar_today, color: gold), onTap: () async { final d = await showDatePicker(context: ctx, firstDate: DateTime.now().subtract(const Duration(days: 1)), lastDate: DateTime.now().add(const Duration(days: 3650)), initialDate: due ?? DateTime.now()); if (d != null) setLocal(() => due = d); }),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('إضافة'))],
    ))));
    if (ok == true && c.text.trim().isNotEmpty) {
      setState(() => tasks.add(TaskData(id: 't_${DateTime.now().microsecondsSinceEpoch}', title: c.text.trim(), createdAt: DateTime.now(), priority: priority, dueDate: due)));
      await store.saveTasks(tasks);
      await _reschedule();
    }
  }

  Future<void> _addHabit() async {
    final name = TextEditingController();
    final replacement = TextEditingController();
    String kind = 'build';
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(
      backgroundColor: panel,
      title: const Text('عادة جديدة'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        SegmentedButton<String>(segments: const [ButtonSegment(value: 'build', label: Text('أبني عادة')), ButtonSegment(value: 'quit', label: Text('أترك عادة'))], selected: {kind}, onSelectionChanged: (s) => setLocal(() => kind = s.first)),
        const SizedBox(height: 12),
        TextField(controller: name, autofocus: true, decoration: InputDecoration(labelText: kind == 'quit' ? 'ما العادة التي تريد تركها؟' : 'ما العادة التي تريد بناءها؟')),
        const SizedBox(height: 10),
        TextField(controller: replacement, maxLines: 2, decoration: InputDecoration(labelText: kind == 'quit' ? 'ما السلوك البديل عند الرغبة؟' : 'متى وأين ستفعلها؟')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حفظ'))],
    ))));
    if (ok == true && name.text.trim().isNotEmpty) {
      setState(() => habits.add(HabitData(id: 'h_${DateTime.now().microsecondsSinceEpoch}', name: name.text.trim(), kind: kind, replacement: replacement.text.trim())));
      await store.saveHabits(habits);
    }
  }

  Future<void> _checkHabit(HabitData h, bool successToday) async {
    final yesterday = dayKey(DateTime.now().subtract(const Duration(days: 1)));
    setState(() {
      if (successToday) {
        h.streak = h.lastCheckDate == yesterday && h.lastCheckSuccess == true ? h.streak + 1 : 1;
        h.best = max(h.best, h.streak);
      } else {
        h.streak = 0;
      }
      h.lastCheckDate = dayKey();
      h.lastCheckSuccess = successToday;
    });
    await store.saveHabits(habits);
  }

  void _rescue() {
    final quit = habits.where((e) => e.kind == 'quit').firstOrNull;
    final replacement = quit?.replacement.isNotEmpty == true ? quit!.replacement : 'امشِ 5 دقائق، اشرب ماء، واتصل بشخص داعم أو ابدأ مهمة بديلة.';
    showModalBottomSheet(context: context, backgroundColor: panel, isScrollControlled: true, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: SafeArea(child: Padding(padding: const EdgeInsets.all(22), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('خطة إنقاذ 10 دقائق', style: TextStyle(color: gold, fontSize: 24, fontWeight: FontWeight.w900)),
      const SizedBox(height: 12),
      const Text('1) غيّر مكانك فوراً.\n2) أبعد المحفّز عن متناولك.\n3) تنفّس ببطء 10 مرات.\n4) لا تقل "لن أفعلها أبداً"؛ قل "لن أفعلها خلال الـ10 دقائق القادمة".\n5) نفّذ البديل:', style: TextStyle(height: 1.7, color: Colors.white70)),
      const SizedBox(height: 9),
      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF292317), borderRadius: BorderRadius.circular(14)), child: Text(replacement, style: const TextStyle(color: gold, fontWeight: FontWeight.w900))),
      const SizedBox(height: 14),
      FilledButton(onPressed: () => Navigator.pop(ctx), style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black), child: const Text('سأتجاوز هذه الموجة', style: TextStyle(fontWeight: FontWeight.w900))),
    ])))));
  }

  Future<void> _changeTime(bool morning) async {
    final initial = TimeOfDay(hour: morning ? morningHour : eveningHour, minute: morning ? morningMinute : eveningMinute);
    final t = await showTimePicker(context: context, initialTime: initial);
    if (t == null) return;
    setState(() {
      if (morning) { morningHour = t.hour; morningMinute = t.minute; } else { eveningHour = t.hour; eveningMinute = t.minute; }
    });
    if (morning) await store.setMorning(t.hour, t.minute); else await store.setEvening(t.hour, t.minute);
    await _reschedule();
  }

  Future<void> _showProfiles() async {
    await showModalBottomSheet(context: context, backgroundColor: panel, isScrollControlled: true, builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) => Directionality(textDirection: TextDirection.rtl, child: SafeArea(child: Padding(padding: const EdgeInsets.all(18), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [const Text('المستخدمون', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: gold)), const Spacer(), IconButton(onPressed: () async { Navigator.pop(ctx); await _addProfile(); }, icon: const Icon(Icons.person_add_alt_1, color: gold))]),
      const Text('كل ملف على هذا الجهاز له أحلامه وأهدافه ومهامه وعاداته الخاصة.', style: TextStyle(color: Colors.white60)),
      const SizedBox(height: 12),
      for (final p in profiles) ListTile(
        leading: CircleAvatar(backgroundColor: p.id == profile!.id ? gold : panel2, child: Icon(Icons.person, color: p.id == profile!.id ? Colors.black : Colors.white54)),
        title: Text(p.name),
        trailing: p.id == profile!.id ? const Icon(Icons.check_circle, color: success) : null,
        onTap: () async { Navigator.pop(ctx); await _switchProfile(p); },
      ),
    ]))))));
  }

  Future<void> _addProfile() async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(backgroundColor: panel, title: const Text('مستخدم جديد'), content: TextField(controller: c, autofocus: true, decoration: const InputDecoration(labelText: 'الاسم')), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('إضافة'))])));
    if (ok == true && c.text.trim().isNotEmpty) {
      final p = ProfileData(id: 'p_${DateTime.now().microsecondsSinceEpoch}', name: c.text.trim(), createdAt: DateTime.now());
      profiles.add(p);
      await ProfileStore.saveProfiles(profiles);
      await _switchProfile(p);
    }
  }

  Future<void> _switchProfile(ProfileData p) async {
    setState(() { loading = true; profile = p; });
    await ProfileStore.setCurrent(p.id);
    await _loadUser();
    await _reschedule();
    if (!mounted) return;
    setState(() { loading = false; tab = 0; });
  }
}

extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
