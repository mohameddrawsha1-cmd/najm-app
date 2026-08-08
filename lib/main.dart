import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

const bg = Color(0xFF05070A);
const panel = Color(0xFF11151B);
const panel2 = Color(0xFF181D25);
const gold = Color(0xFFE8B84E);
const gold2 = Color(0xFFFFD978);
const border = Color(0xFF343A44);
const danger = Color(0xFFE16A6A);
const success = Color(0xFF61C98B);

String dayKey([DateTime? d]) {
  final x = d ?? DateTime.now();
  return '${x.year}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}';
}

String dateLabel(DateTime? d) {
  if (d == null) return 'بدون موعد';
  return '${d.day}/${d.month}/${d.year}';
}

String timeLabel(int h, int m) {
  final hour = h % 12 == 0 ? 12 : h % 12;
  return '${hour.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} ${h >= 12 ? 'م' : 'ص'}';
}

class GoalStep {
  GoalStep({required this.id, required this.title, this.done = false});
  final String id;
  String title;
  bool done;

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'done': done};
  factory GoalStep.fromJson(Map<String, dynamic> j) => GoalStep(
        id: '${j['id']}',
        title: '${j['title']}',
        done: j['done'] == true,
      );
}

class GoalData {
  GoalData({
    required this.id,
    required this.title,
    required this.why,
    required this.createdAt,
    required this.notificationId,
    this.deadline,
    this.progress = 0,
    this.reminderHour = 19,
    this.reminderMinute = 0,
    this.reminderEnabled = true,
    List<GoalStep>? steps,
  }) : steps = steps ?? [];

  final String id;
  String title;
  String why;
  DateTime createdAt;
  DateTime? deadline;
  double progress;
  int reminderHour;
  int reminderMinute;
  bool reminderEnabled;
  final int notificationId;
  List<GoalStep> steps;

  bool get completed => progress >= 1;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'why': why,
        'createdAt': createdAt.toIso8601String(),
        'deadline': deadline?.toIso8601String(),
        'progress': progress,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'reminderEnabled': reminderEnabled,
        'notificationId': notificationId,
        'steps': steps.map((e) => e.toJson()).toList(),
      };

  factory GoalData.fromJson(Map<String, dynamic> j) => GoalData(
        id: '${j['id']}',
        title: '${j['title']}',
        why: '${j['why'] ?? ''}',
        createdAt: DateTime.tryParse('${j['createdAt']}') ?? DateTime.now(),
        deadline: j['deadline'] == null ? null : DateTime.tryParse('${j['deadline']}'),
        progress: (j['progress'] as num?)?.toDouble() ?? 0,
        reminderHour: (j['reminderHour'] as num?)?.toInt() ?? 19,
        reminderMinute: (j['reminderMinute'] as num?)?.toInt() ?? 0,
        reminderEnabled: j['reminderEnabled'] != false,
        notificationId: (j['notificationId'] as num?)?.toInt() ?? Random().nextInt(800000) + 10000,
        steps: ((j['steps'] as List?) ?? [])
            .map((e) => GoalStep.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class HabitData {
  HabitData({
    required this.id,
    required this.name,
    required this.replacement,
    this.streak = 0,
    this.best = 0,
    this.lastCheckDate,
    this.lastCheckSuccess,
  });

  final String id;
  String name;
  String replacement;
  int streak;
  int best;
  String? lastCheckDate;
  bool? lastCheckSuccess;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'replacement': replacement,
        'streak': streak,
        'best': best,
        'lastCheckDate': lastCheckDate,
        'lastCheckSuccess': lastCheckSuccess,
      };

  factory HabitData.fromJson(Map<String, dynamic> j) => HabitData(
        id: '${j['id']}',
        name: '${j['name']}',
        replacement: '${j['replacement'] ?? ''}',
        streak: (j['streak'] as num?)?.toInt() ?? 0,
        best: (j['best'] as num?)?.toInt() ?? 0,
        lastCheckDate: j['lastCheckDate']?.toString(),
        lastCheckSuccess: j['lastCheckSuccess'] as bool?,
      );
}

class ReminderService {
  ReminderService._();
  static final instance = ReminderService._();
  final plugin = FlutterLocalNotificationsPlugin();
  bool ready = false;

  static const details = NotificationDetails(
    android: AndroidNotificationDetails(
      'najm_reminders',
      'تذكيرات نجم',
      channelDescription: 'تذكيرات الأهداف والتحفيز والمراجعة اليومية',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  Future<void> init() async {
    if (ready) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Etc/UTC'));
    }
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await plugin.initialize(settings: settings);
    await plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    ready = true;
  }

  tz.TZDateTime _next(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var target = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!target.isAfter(now)) target = target.add(const Duration(days: 1));
    return target;
  }

  Future<void> daily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    if (!ready) await init();
    await plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _next(hour, minute),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancel(int id) async {
    if (!ready) await init();
    await plugin.cancel(id: id);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ReminderService.instance.init();
  runApp(const NajmApp());
}

class NajmApp extends StatelessWidget {
  const NajmApp({super.key});

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
        snackBarTheme: const SnackBarThemeData(backgroundColor: panel2),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0D1117),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: gold)),
        ),
      ),
      home: const NajmShell(),
    );
  }
}

class NajmShell extends StatefulWidget {
  const NajmShell({super.key});
  @override
  State<NajmShell> createState() => _NajmShellState();
}

class _NajmShellState extends State<NajmShell> {
  int tab = 0;
  bool loading = true;
  String userName = 'صديقي';
  List<GoalData> goals = [];
  List<HabitData> habits = [];
  int morningHour = 8;
  int morningMinute = 0;
  int eveningHour = 20;
  int eveningMinute = 30;
  String reflection = '';
  int focusSessions = 0;
  String lastFocusDay = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final g = p.getString('goals_v2');
    final h = p.getString('habits_v2');
    if (g != null) {
      goals = (jsonDecode(g) as List).map((e) => GoalData.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    }
    if (h != null) {
      habits = (jsonDecode(h) as List).map((e) => HabitData.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    }
    userName = p.getString('user_name') ?? 'صديقي';
    morningHour = p.getInt('morning_h') ?? 8;
    morningMinute = p.getInt('morning_m') ?? 0;
    eveningHour = p.getInt('evening_h') ?? 20;
    eveningMinute = p.getInt('evening_m') ?? 30;
    reflection = p.getString('reflection_${dayKey()}') ?? '';
    focusSessions = p.getInt('focus_sessions') ?? 0;
    lastFocusDay = p.getString('last_focus_day') ?? '';
    await _scheduleGlobalReminders();
    if (!mounted) return;
    setState(() => loading = false);
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('goals_v2', jsonEncode(goals.map((e) => e.toJson()).toList()));
    await p.setString('habits_v2', jsonEncode(habits.map((e) => e.toJson()).toList()));
    await p.setString('user_name', userName);
    await p.setInt('morning_h', morningHour);
    await p.setInt('morning_m', morningMinute);
    await p.setInt('evening_h', eveningHour);
    await p.setInt('evening_m', eveningMinute);
    await p.setString('reflection_${dayKey()}', reflection);
    await p.setInt('focus_sessions', focusSessions);
    await p.setString('last_focus_day', lastFocusDay);
  }

  Future<void> _scheduleGlobalReminders() async {
    await ReminderService.instance.daily(
      id: 900001,
      hour: morningHour,
      minute: morningMinute,
      title: 'صباح الإنجاز مع نجم ✦',
      body: 'لا تحتاج يوماً مثالياً. اختر أهم خطوة وابدأ بها الآن.',
    );
    await ReminderService.instance.daily(
      id: 900002,
      hour: eveningHour,
      minute: eveningMinute,
      title: 'مراجعة نجم اليومية',
      body: 'ماذا أنجزت اليوم؟ افتح نجم وسجّل تقدمك قبل أن ينتهي اليوم.',
    );
  }

  double get overallProgress {
    if (goals.isEmpty) return 0;
    return goals.fold<double>(0, (s, g) => s + g.progress) / goals.length;
  }

  int get cleanHabitCount => habits.where((h) => h.lastCheckDate == dayKey() && h.lastCheckSuccess == true).length;
  int get completedSteps => goals.expand((g) => g.steps).where((s) => s.done).length;
  int get totalSteps => goals.expand((g) => g.steps).length;
  int get bestHabitStreak => habits.isEmpty ? 0 : habits.map((e) => e.best).reduce(max);

  int get successScore {
    final goalPart = (overallProgress * 55).round();
    final stepPart = totalSteps == 0 ? 0 : ((completedSteps / totalSteps) * 20).round();
    final habitPart = habits.isEmpty ? 15 : ((cleanHabitCount / habits.length) * 15).round();
    final focusPart = lastFocusDay == dayKey() ? min(focusSessions, 2) * 5 : 0;
    return min(100, goalPart + stepPart + habitPart + focusPart);
  }

  String get coachMessage {
    if (goals.isEmpty) return 'أول انتصار هو أن تحدد وجهتك. أضف هدفاً واحداً مهماً لك اليوم.';
    if (successScore >= 80) return 'أنت في يوم قوي جداً. لا تشتت الزخم؛ أكمل خطوة واحدة نوعية قبل أن ترتاح.';
    if (successScore >= 50) return 'تقدمك واضح. اختر خطوة معلّقة صغيرة وأغلقها الآن لتحافظ على الزخم.';
    if (habits.any((h) => h.lastCheckDate == dayKey() && h.lastCheckSuccess == false)) {
      return 'التعثر ليس نهاية السلسلة. عد فوراً لسلوك بديل صغير ولا تنتظر الغد.';
    }
    return 'لا تنتظر الحماس. ابدأ بعشر دقائق فقط، والحماس غالباً يلحق بك بعد البداية.';
  }

  GoalStep? get nextStep {
    for (final g in goals.where((e) => !e.completed)) {
      for (final s in g.steps) {
        if (!s.done) return s;
      }
    }
    return null;
  }

  GoalData? get mainGoal {
    final active = goals.where((e) => !e.completed).toList();
    if (active.isEmpty) return goals.isEmpty ? null : goals.first;
    active.sort((a, b) {
      if (a.deadline == null && b.deadline == null) return b.progress.compareTo(a.progress);
      if (a.deadline == null) return 1;
      if (b.deadline == null) return -1;
      return a.deadline!.compareTo(b.deadline!);
    });
    return active.first;
  }

  Widget _card(Widget child, {EdgeInsets padding = const EdgeInsets.all(16)}) => Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF141922), Color(0xFF0C1016)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 8))],
        ),
        child: child,
      );

  Widget _logo() => Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(colors: [gold2, gold]),
          boxShadow: const [BoxShadow(color: Color(0x55E8B84E), blurRadius: 20)],
          border: Border.all(color: const Color(0xFFFFE7A6), width: 1.2),
        ),
        alignment: Alignment.center,
        child: const Text('نجم', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w900)),
      );

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: Center(child: CircularProgressIndicator(color: gold))),
      );
    }
    final pages = [_home(), _goalsPage(), _habitsPage(), FocusPage(onComplete: _focusComplete), _coachPage()];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(child: pages[tab]),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(color: Color(0xFF080B0F), border: Border(top: BorderSide(color: border))),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _nav(0, Icons.home_rounded, 'اليوم'),
            _nav(1, Icons.track_changes_rounded, 'أهدافي'),
            _nav(2, Icons.shield_outlined, 'عاداتي'),
            _nav(3, Icons.timer_outlined, 'تركيز'),
            _nav(4, Icons.auto_awesome_rounded, 'نجم'),
          ]),
        ),
      ),
    );
  }

  Widget _nav(int i, IconData icon, String label) => InkWell(
        onTap: () => setState(() => tab = i),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 23, color: tab == i ? gold : Colors.white54),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 11, color: tab == i ? gold : Colors.white54)),
          ]),
        ),
      );

  Widget _header(String title, {String? subtitle, Widget? action}) => Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        _logo(),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
          if (subtitle != null) Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ])),
        if (action != null) action,
      ]);

  Widget _home() {
    final mg = mainGoal;
    final step = nextStep;
    return RefreshIndicator(
      color: gold,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
        children: [
          _header('مساء الإنجاز، $userName', subtitle: 'نجم يتابع معك هدفاً بخطوة'),
          const SizedBox(height: 22),
          _card(Row(children: [
            SizedBox(
              width: 92,
              height: 92,
              child: Stack(alignment: Alignment.center, children: [
                SizedBox(width: 86, height: 86, child: CircularProgressIndicator(value: successScore / 100, strokeWidth: 8, backgroundColor: border, color: gold)),
                Text('$successScore', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: gold)),
              ]),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('مؤشر نجاح اليوم', style: TextStyle(color: gold, fontWeight: FontWeight.w800)),
              const SizedBox(height: 7),
              Text(coachMessage, style: const TextStyle(height: 1.5, color: Colors.white70)),
            ])),
          ])),
          const SizedBox(height: 14),
          if (mg == null)
            _emptyGoalCard()
          else
            _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [const Icon(Icons.star_rounded, color: gold), const SizedBox(width: 8), const Text('هدفك الأهم الآن', style: TextStyle(color: gold, fontWeight: FontWeight.w800)), const Spacer(), Text('${(mg.progress * 100).round()}%', style: const TextStyle(color: gold, fontWeight: FontWeight.w900))]),
              const SizedBox(height: 12),
              Text(mg.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              if (mg.why.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text('لماذا؟ ${mg.why}', style: const TextStyle(color: Colors.white60))),
              const SizedBox(height: 13),
              ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: mg.progress, minHeight: 8, backgroundColor: border, color: gold)),
              const SizedBox(height: 10),
              Row(children: [Text('الموعد: ${dateLabel(mg.deadline)}', style: const TextStyle(color: Colors.white54, fontSize: 12)), const Spacer(), Text('تذكير ${timeLabel(mg.reminderHour, mg.reminderMinute)}', style: const TextStyle(color: Colors.white54, fontSize: 12))]),
            ])),
          const SizedBox(height: 14),
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('خطوتك التالية', style: TextStyle(color: gold, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text(step?.title ?? (goals.isEmpty ? 'أضف أول هدف وحدد له خطوة صغيرة.' : 'أضف خطوة تنفيذية لهدفك حتى يعرف نجم ماذا يقترح عليك.'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 13),
            SizedBox(width: double.infinity, child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: step == null ? () => setState(() => tab = 1) : () => _completeStep(step),
              icon: Icon(step == null ? Icons.add : Icons.check_rounded),
              label: Text(step == null ? 'جهّز خطتك' : 'أنجزت هذه الخطوة', style: const TextStyle(fontWeight: FontWeight.w900)),
            )),
          ])),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _miniStat('الأهداف', '${goals.where((g) => !g.completed).length}', Icons.flag_outlined)),
            const SizedBox(width: 9),
            Expanded(child: _miniStat('خطوات منجزة', '$completedSteps', Icons.check_circle_outline)),
            const SizedBox(width: 9),
            Expanded(child: _miniStat('أفضل سلسلة', '$bestHabitStreak', Icons.local_fire_department_outlined)),
          ]),
          const SizedBox(height: 14),
          if (habits.isNotEmpty) _habitQuickCard(),
        ],
      ),
    );
  }

  Widget _miniStat(String title, String value, IconData icon) => _card(Column(children: [
        Icon(icon, color: gold, size: 22),
        const SizedBox(height: 7),
        Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ]), padding: const EdgeInsets.all(11));

  Widget _emptyGoalCard() => _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('ابدأ نجاحك بهدف واضح', style: TextStyle(color: gold, fontSize: 19, fontWeight: FontWeight.w900)),
        const SizedBox(height: 7),
        const Text('أضف هدفك، سبب أهميته، موعده، ووقت التذكير. نجم سيحوّله لرحلة قابلة للتتبع.', style: TextStyle(color: Colors.white60, height: 1.5)),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: _addGoal, icon: const Icon(Icons.add), label: const Text('أضف أول هدف')),
      ]));

  Widget _habitQuickCard() {
    final pending = habits.where((h) => h.lastCheckDate != dayKey()).toList();
    final h = pending.isEmpty ? habits.first : pending.first;
    return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Icon(Icons.shield_rounded, color: gold), const SizedBox(width: 8), const Text('حماية عاداتك اليوم', style: TextStyle(color: gold, fontWeight: FontWeight.w800)), const Spacer(), Text('${h.streak} أيام', style: const TextStyle(color: gold))]),
      const SizedBox(height: 8),
      Text('تحدي: ترك ${h.name}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text('البديل: ${h.replacement}', style: const TextStyle(color: Colors.white60)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: OutlinedButton.icon(onPressed: () => _habitCheck(h, false), icon: const Icon(Icons.refresh_rounded), label: const Text('تعثرت'))),
        const SizedBox(width: 9),
        Expanded(child: FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black), onPressed: () => _habitCheck(h, true), icon: const Icon(Icons.check), label: const Text('نجحت اليوم'))),
      ]),
    ]));
  }

  Future<void> _completeStep(GoalStep step) async {
    GoalData? owner;
    for (final g in goals) {
      if (g.steps.contains(step)) owner = g;
    }
    setState(() {
      step.done = true;
      if (owner != null && owner!.steps.isNotEmpty) {
        owner!.progress = owner!.steps.where((s) => s.done).length / owner!.steps.length;
      }
    });
    if (owner != null && owner!.completed) await ReminderService.instance.cancel(owner!.notificationId);
    await _save();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🔥 ممتاز! خطوة أخرى اقتربت بك من هدفك.')));
  }

  Widget _goalsPage() => Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(18, 14, 18, 10), child: _header('أهدافي', subtitle: 'أهداف حقيقية، تقدم واضح، وتذكير يومي', action: IconButton.filled(style: IconButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black), onPressed: _addGoal, icon: const Icon(Icons.add)))),
        Expanded(child: goals.isEmpty
            ? Center(child: Padding(padding: const EdgeInsets.all(22), child: _emptyGoalCard()))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                itemCount: goals.length,
                itemBuilder: (_, i) => _goalCard(goals[i]),
              )),
      ]);

  Widget _goalCard(GoalData g) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () => _openGoal(g),
          borderRadius: BorderRadius.circular(20),
          child: _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 43, height: 43, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF292317)), child: Icon(g.completed ? Icons.emoji_events_rounded : Icons.track_changes_rounded, color: gold)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(g.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), Text(g.completed ? 'تم تحقيق الهدف 🏆' : '${g.steps.where((s) => s.done).length}/${g.steps.length} خطوات', style: const TextStyle(color: Colors.white54, fontSize: 12))])),
              Text('${(g.progress * 100).round()}%', style: const TextStyle(color: gold, fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 12),
            ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: g.progress, minHeight: 8, backgroundColor: border, color: gold)),
            const SizedBox(height: 9),
            Row(children: [Icon(g.reminderEnabled ? Icons.notifications_active_outlined : Icons.notifications_off_outlined, size: 15, color: Colors.white54), const SizedBox(width: 5), Text(g.reminderEnabled ? timeLabel(g.reminderHour, g.reminderMinute) : 'التذكير متوقف', style: const TextStyle(color: Colors.white54, fontSize: 11)), const Spacer(), Text(dateLabel(g.deadline), style: const TextStyle(color: Colors.white54, fontSize: 11))]),
          ])),
        ),
      );

  Future<void> _addGoal() async {
    final title = TextEditingController();
    final why = TextEditingController();
    DateTime? deadline;
    TimeOfDay reminder = const TimeOfDay(hour: 19, minute: 0);
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: panel,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('هدف جديد', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            const Text('اجعله واضحاً ومهماً بالنسبة لك.', style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 16),
            TextField(controller: title, autofocus: true, decoration: const InputDecoration(labelText: 'ما الهدف الذي تريد تحقيقه؟')),
            const SizedBox(height: 10),
            TextField(controller: why, maxLines: 2, decoration: const InputDecoration(labelText: 'لماذا هذا الهدف مهم لك؟')),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: () async { final d = await showDatePicker(context: ctx, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 3650))); if (d != null) setLocal(() => deadline = d); }, icon: const Icon(Icons.calendar_month), label: Text(deadline == null ? 'حدد موعداً' : dateLabel(deadline)))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(onPressed: () async { final t = await showTimePicker(context: ctx, initialTime: reminder); if (t != null) setLocal(() => reminder = t); }, icon: const Icon(Icons.notifications_active_outlined), label: Text(timeLabel(reminder.hour, reminder.minute)))),
            ]),
            const SizedBox(height: 14),
            FilledButton(style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 15)), onPressed: () => Navigator.pop(ctx, true), child: const Text('أنشئ الهدف', style: TextStyle(fontWeight: FontWeight.w900))),
          ])),
        ),
      )),
    );
    if (result != true || title.text.trim().isEmpty) return;
    final now = DateTime.now();
    final id = now.microsecondsSinceEpoch.toString();
    final g = GoalData(
      id: id,
      title: title.text.trim(),
      why: why.text.trim(),
      createdAt: now,
      deadline: deadline,
      reminderHour: reminder.hour,
      reminderMinute: reminder.minute,
      notificationId: (now.microsecondsSinceEpoch % 800000).toInt() + 10000,
    );
    setState(() => goals.insert(0, g));
    await _scheduleGoal(g);
    await _save();
    if (mounted) _openGoal(g);
  }

  Future<void> _scheduleGoal(GoalData g) async {
    if (!g.reminderEnabled || g.completed) {
      await ReminderService.instance.cancel(g.notificationId);
      return;
    }
    await ReminderService.instance.daily(
      id: g.notificationId,
      hour: g.reminderHour,
      minute: g.reminderMinute,
      title: 'هدفك ينتظرك ✦ ${g.title}',
      body: g.steps.any((s) => !s.done) ? 'خطوتك التالية: ${g.steps.firstWhere((s) => !s.done).title}' : 'افتح نجم وأضف خطوة صغيرة تحركك اليوم.',
    );
  }

  Future<void> _openGoal(GoalData g) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => GoalDetailPage(
      goal: g,
      onChanged: () async {
        if (g.steps.isNotEmpty) g.progress = g.steps.where((s) => s.done).length / g.steps.length;
        if (g.completed) await ReminderService.instance.cancel(g.notificationId); else await _scheduleGoal(g);
        await _save();
        if (mounted) setState(() {});
      },
      onDelete: () async {
        await ReminderService.instance.cancel(g.notificationId);
        goals.remove(g);
        await _save();
        if (mounted) setState(() {});
      },
    )));
    if (mounted) setState(() {});
  }

  Widget _habitsPage() => Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(18, 14, 18, 10), child: _header('اترك ما يعيقك', subtitle: 'نحوّل العادة السيئة إلى بديل عملي', action: IconButton.filled(style: IconButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black), onPressed: _addHabit, icon: const Icon(Icons.add)))),
        Expanded(child: habits.isEmpty
            ? ListView(padding: const EdgeInsets.all(18), children: [_card(const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('ابنِ نسخة أقوى منك', style: TextStyle(color: gold, fontSize: 20, fontWeight: FontWeight.w900)), SizedBox(height: 8), Text('أضف عادة تريد تركها وحدد سلوكاً بديلاً. كل يوم سجّل نجاحك، وإذا تعثرت استخدم خطة الإنقاذ بدل جلد الذات.', style: TextStyle(color: Colors.white60, height: 1.5))])), const SizedBox(height: 12), FilledButton.icon(onPressed: _addHabit, icon: const Icon(Icons.add), label: const Text('أضف عادة أريد تركها'))])
            : ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 24), children: [
                _rescueCard(),
                const SizedBox(height: 13),
                for (final h in habits) _habitCard(h),
              ])),
      ]);

  Widget _rescueCard() => _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [Icon(Icons.bolt_rounded, color: gold), SizedBox(width: 8), Text('زر الإنقاذ', style: TextStyle(color: gold, fontWeight: FontWeight.w900))]),
        const SizedBox(height: 7),
        const Text('تشعر أنك على وشك العودة لعادتك؟ لا تفاوض نفسك طويلاً.', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 11),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _showRescue, icon: const Icon(Icons.health_and_safety_outlined), label: const Text('أنقذني الآن — خطة 10 دقائق'))),
      ]));

  Widget _habitCard(HabitData h) {
    final checked = h.lastCheckDate == dayKey();
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 45, height: 45, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF292317)), child: const Icon(Icons.shield_rounded, color: gold)),
        const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('ترك ${h.name}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), Text('بديلك: ${h.replacement}', style: const TextStyle(color: Colors.white54, fontSize: 12))])),
        Column(children: [Text('${h.streak}', style: const TextStyle(color: gold, fontSize: 22, fontWeight: FontWeight.w900)), const Text('يوم', style: TextStyle(color: Colors.white54, fontSize: 10))]),
      ]),
      const SizedBox(height: 12),
      Row(children: [const Text('أفضل سلسلة', style: TextStyle(color: Colors.white54)), const SizedBox(width: 6), Text('${h.best} أيام', style: const TextStyle(color: gold, fontWeight: FontWeight.w700)), const Spacer(), if (checked) Text(h.lastCheckSuccess == true ? 'اليوم ناجح ✓' : 'اليوم تعثر — نبدأ من جديد', style: TextStyle(color: h.lastCheckSuccess == true ? success : danger, fontSize: 11))]),
      const SizedBox(height: 11),
      Row(children: [
        Expanded(child: OutlinedButton.icon(onPressed: () => _habitCheck(h, false), icon: const Icon(Icons.close_rounded, color: danger), label: const Text('تعثرت'))),
        const SizedBox(width: 8),
        Expanded(child: FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black), onPressed: () => _habitCheck(h, true), icon: const Icon(Icons.check), label: const Text('نجحت اليوم'))),
      ]),
      Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () => _deleteHabit(h), icon: const Icon(Icons.delete_outline, size: 17), label: const Text('حذف'))),
    ])));
  }

  Future<void> _addHabit() async {
    final name = TextEditingController();
    final replacement = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(
      backgroundColor: panel,
      title: const Text('عادة أريد تركها'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, autofocus: true, decoration: const InputDecoration(labelText: 'العادة السيئة')),
        const SizedBox(height: 10),
        TextField(controller: replacement, decoration: const InputDecoration(labelText: 'ماذا سأفعل بدلاً منها؟ مثال: أمشي 5 دقائق')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ابدأ التحدي'))],
    )));
    if (ok != true || name.text.trim().isEmpty) return;
    setState(() => habits.insert(0, HabitData(id: DateTime.now().microsecondsSinceEpoch.toString(), name: name.text.trim(), replacement: replacement.text.trim().isEmpty ? 'توقف 90 ثانية وخذ نفساً عميقاً' : replacement.text.trim())));
    await _save();
  }

  Future<void> _habitCheck(HabitData h, bool successToday) async {
    final today = dayKey();
    setState(() {
      if (h.lastCheckDate == today) {
        if (h.lastCheckSuccess == successToday) return;
        if (h.lastCheckSuccess == true && successToday == false) h.streak = max(0, h.streak - 1);
        if (h.lastCheckSuccess == false && successToday == true) h.streak += 1;
      } else {
        if (successToday) h.streak += 1; else h.streak = 0;
      }
      h.lastCheckDate = today;
      h.lastCheckSuccess = successToday;
      h.best = max(h.best, h.streak);
    });
    await _save();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successToday ? '🔥 أحسنت. أنت تثبت لنفسك أنك تستطيع الاختيار.' : 'لا جلد للذات. التعثر معلومة، والعودة تبدأ من القرار التالي.')));
  }

  Future<void> _deleteHabit(HabitData h) async {
    setState(() => habits.remove(h));
    await _save();
  }

  void _showRescue() {
    final replacement = habits.isEmpty ? 'ابتعد عن المحفّز واشرب ماء وامشِ دقيقتين.' : habits.first.replacement;
    showModalBottomSheet(context: context, backgroundColor: panel, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('خطة إنقاذ 10 دقائق', style: TextStyle(color: gold, fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),
        const Text('1. غيّر مكانك فوراً وأبعد المحفّز عنك.\n2. خذ 10 أنفاس بطيئة.\n3. قل: أنا لا أحتاج أن أحسم حياتي الآن، فقط أتجاوز هذه الدقائق.\n4. نفّذ السلوك البديل:', style: TextStyle(height: 1.7, color: Colors.white70)),
        const SizedBox(height: 8),
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF292317), borderRadius: BorderRadius.circular(14)), child: Text(replacement, style: const TextStyle(color: gold, fontWeight: FontWeight.w800))),
        const SizedBox(height: 14),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black), onPressed: () => Navigator.pop(ctx), child: const Text('سأتجاوز هذه الموجة')),
      ]),
    ))));
  }

  Future<void> _focusComplete() async {
    final today = dayKey();
    setState(() {
      if (lastFocusDay != today) focusSessions = 0;
      focusSessions++;
      lastFocusDay = today;
    });
    await _save();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🏆 جلسة تركيز مكتملة. التنفيذ هو الفارق.')));
  }

  Widget _coachPage() => ListView(padding: const EdgeInsets.fromLTRB(18, 14, 18, 24), children: [
        _header('نجم معك', subtitle: 'مساعدك اليومي للتركيز والاستمرار'),
        const SizedBox(height: 20),
        _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [Icon(Icons.auto_awesome_rounded, color: gold), SizedBox(width: 8), Text('رسالة نجم لك الآن', style: TextStyle(color: gold, fontWeight: FontWeight.w900))]),
          const SizedBox(height: 13),
          Text(coachMessage, style: const TextStyle(fontSize: 18, height: 1.6, fontWeight: FontWeight.w600)),
        ])),
        const SizedBox(height: 13),
        _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('مراجعة اليوم', style: TextStyle(color: gold, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('اكتب جملة واحدة: ما أهم شيء فعلته اليوم ليقربك من الشخص الذي تريد أن تصبحه؟', style: TextStyle(color: Colors.white60, height: 1.5)),
          const SizedBox(height: 10),
          TextFormField(initialValue: reflection, maxLines: 3, onChanged: (v) { reflection = v; _save(); }, decoration: const InputDecoration(hintText: 'مثال: أنجزت أول خطوة رغم أني لم أكن متحمساً...')),
        ])),
        const SizedBox(height: 13),
        _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('تذكيرات المتابعة', style: TextStyle(color: gold, fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          const Text('نجم يذكّرك فعلياً حتى لو كان التطبيق مغلقاً.', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 11),
          ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.wb_sunny_outlined, color: gold), title: const Text('دفعة الصباح'), subtitle: Text(timeLabel(morningHour, morningMinute)), trailing: const Icon(Icons.chevron_left), onTap: () => _pickGlobalTime(true)),
          ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.nights_stay_outlined, color: gold), title: const Text('مراجعة المساء'), subtitle: Text(timeLabel(eveningHour, eveningMinute)), trailing: const Icon(Icons.chevron_left), onTap: () => _pickGlobalTime(false)),
        ])),
        const SizedBox(height: 13),
        _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('لوحة الإنجاز', style: TextStyle(color: gold, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          _achievement('أول هدف', goals.isNotEmpty, 'حددت وجهتك'),
          _achievement('صانع الخطوات', completedSteps >= 5, 'أنجز 5 خطوات'),
          _achievement('تركيز حقيقي', focusSessions >= 2 && lastFocusDay == dayKey(), 'جلستان تركيز في يوم واحد'),
          _achievement('سيطرة', bestHabitStreak >= 7, '7 أيام بعيداً عن عادة تعيقك'),
          _achievement('الـ 100%', goals.any((g) => g.completed), 'حقق هدفاً كاملاً'),
        ])),
        const SizedBox(height: 13),
        OutlinedButton.icon(onPressed: _editName, icon: const Icon(Icons.person_outline), label: const Text('غيّر الاسم الذي يناديك به نجم')),
      ]);

  Widget _achievement(String title, bool unlocked, String subtitle) => Padding(padding: const EdgeInsets.only(bottom: 9), child: Row(children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(shape: BoxShape.circle, color: unlocked ? const Color(0xFF292317) : const Color(0xFF14171B)), child: Icon(unlocked ? Icons.emoji_events_rounded : Icons.lock_outline_rounded, color: unlocked ? gold : Colors.white24, size: 20)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: unlocked ? Colors.white : Colors.white38)), Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11))])),
        if (unlocked) const Text('مفتوح ✓', style: TextStyle(color: gold, fontSize: 11)),
      ]));

  Future<void> _pickGlobalTime(bool morning) async {
    final old = TimeOfDay(hour: morning ? morningHour : eveningHour, minute: morning ? morningMinute : eveningMinute);
    final t = await showTimePicker(context: context, initialTime: old);
    if (t == null) return;
    setState(() {
      if (morning) { morningHour = t.hour; morningMinute = t.minute; } else { eveningHour = t.hour; eveningMinute = t.minute; }
    });
    await _scheduleGlobalReminders();
    await _save();
  }

  Future<void> _editName() async {
    final c = TextEditingController(text: userName == 'صديقي' ? '' : userName);
    final ok = await showDialog<bool>(context: context, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(backgroundColor: panel, title: const Text('ما اسمك؟'), content: TextField(controller: c, autofocus: true, decoration: const InputDecoration(labelText: 'اسمك')), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حفظ'))])));
    if (ok == true && c.text.trim().isNotEmpty) { setState(() => userName = c.text.trim()); await _save(); }
  }
}

class GoalDetailPage extends StatefulWidget {
  const GoalDetailPage({super.key, required this.goal, required this.onChanged, required this.onDelete});
  final GoalData goal;
  final Future<void> Function() onChanged;
  final Future<void> Function() onDelete;
  @override
  State<GoalDetailPage> createState() => _GoalDetailPageState();
}

class _GoalDetailPageState extends State<GoalDetailPage> {
  GoalData get g => widget.goal;

  Widget _card(Widget child) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF141922), Color(0xFF0C1016)]), borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
        child: child,
      );

  Future<void> _addStep() async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(backgroundColor: panel, title: const Text('خطوة جديدة'), content: TextField(controller: c, autofocus: true, decoration: const InputDecoration(labelText: 'ما الخطوة القابلة للتنفيذ؟')), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('إضافة'))])));
    if (ok == true && c.text.trim().isNotEmpty) {
      setState(() => g.steps.add(GoalStep(id: DateTime.now().microsecondsSinceEpoch.toString(), title: c.text.trim())));
      await widget.onChanged();
    }
  }

  Future<void> _editReminder() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: g.reminderHour, minute: g.reminderMinute));
    if (t == null) return;
    setState(() { g.reminderHour = t.hour; g.reminderMinute = t.minute; g.reminderEnabled = true; });
    await widget.onChanged();
  }

  Future<void> _editDeadline() async {
    final d = await showDatePicker(context: context, initialDate: g.deadline ?? DateTime.now().add(const Duration(days: 30)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 3650)));
    if (d == null) return;
    setState(() => g.deadline = d);
    await widget.onChanged();
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(backgroundColor: bg, title: const Text('تفاصيل الهدف'), actions: [IconButton(onPressed: () async { await widget.onDelete(); if (context.mounted) Navigator.pop(context); }, icon: const Icon(Icons.delete_outline))]),
          body: ListView(padding: const EdgeInsets.all(18), children: [
            _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [const Icon(Icons.track_changes_rounded, color: gold), const SizedBox(width: 9), Expanded(child: Text(g.title, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900))), Text('${(g.progress * 100).round()}%', style: const TextStyle(color: gold, fontSize: 22, fontWeight: FontWeight.w900))]),
              if (g.why.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text('السبب الذي سيعيدك عندما تقل طاقتك:\n${g.why}', style: const TextStyle(color: Colors.white60, height: 1.5))),
              const SizedBox(height: 14),
              ClipRRect(borderRadius: BorderRadius.circular(12), child: LinearProgressIndicator(value: g.progress, minHeight: 10, backgroundColor: border, color: gold)),
              const SizedBox(height: 12),
              Row(children: [Expanded(child: OutlinedButton.icon(onPressed: _editDeadline, icon: const Icon(Icons.calendar_month), label: Text(dateLabel(g.deadline)))), const SizedBox(width: 8), Expanded(child: OutlinedButton.icon(onPressed: _editReminder, icon: const Icon(Icons.notifications_active_outlined), label: Text(timeLabel(g.reminderHour, g.reminderMinute))))]),
              SwitchListTile(contentPadding: EdgeInsets.zero, activeTrackColor: gold, title: const Text('تذكير يومي حقيقي'), subtitle: const Text('يعمل حتى عند إغلاق التطبيق', style: TextStyle(color: Colors.white54, fontSize: 11)), value: g.reminderEnabled, onChanged: (v) async { setState(() => g.reminderEnabled = v); await widget.onChanged(); }),
            ])),
            const SizedBox(height: 14),
            Row(children: [const Text('خطة التنفيذ', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)), const Spacer(), IconButton.filled(style: IconButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black), onPressed: _addStep, icon: const Icon(Icons.add))]),
            const SizedBox(height: 8),
            if (g.steps.isEmpty) _card(const Text('لا توجد خطوات بعد. اضغط + واكتب أول خطوة صغيرة يمكن تنفيذها خلال جلسة واحدة.', style: TextStyle(color: Colors.white60, height: 1.5))),
            for (final s in g.steps) Padding(padding: const EdgeInsets.only(bottom: 9), child: _card(Row(children: [
              IconButton(onPressed: () async { setState(() => s.done = !s.done); await widget.onChanged(); }, icon: Icon(s.done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: s.done ? gold : Colors.white54)),
              Expanded(child: Text(s.title, style: TextStyle(decoration: s.done ? TextDecoration.lineThrough : null, color: s.done ? Colors.white38 : Colors.white))),
              IconButton(onPressed: () async { setState(() => g.steps.remove(s)); await widget.onChanged(); }, icon: const Icon(Icons.close, size: 18, color: Colors.white38)),
            ]))),
            const SizedBox(height: 8),
            _card(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('تقدم يدوي', style: TextStyle(color: gold, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Slider(value: g.progress.clamp(0, 1), activeColor: gold, onChanged: (v) => setState(() => g.progress = v), onChangeEnd: (_) => widget.onChanged()),
              FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: g.completed ? success : gold, foregroundColor: Colors.black), onPressed: () async { setState(() { g.progress = 1; for (final s in g.steps) { s.done = true; } }); await widget.onChanged(); }, icon: const Icon(Icons.emoji_events_rounded), label: Text(g.completed ? 'تم تحقيق الهدف 🏆' : 'أعلن تحقيق الهدف', style: const TextStyle(fontWeight: FontWeight.w900))),
            ])),
          ]),
        ),
      );
}

class FocusPage extends StatefulWidget {
  const FocusPage({super.key, required this.onComplete});
  final Future<void> Function() onComplete;
  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> {
  Timer? timer;
  int selectedMinutes = 25;
  int seconds = 25 * 60;
  bool running = false;

  void _toggle() {
    if (running) {
      timer?.cancel();
      setState(() => running = false);
      return;
    }
    setState(() => running = true);
    timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (seconds <= 1) {
        timer?.cancel();
        setState(() { seconds = 0; running = false; });
        await widget.onComplete();
      } else {
        setState(() => seconds--);
      }
    });
  }

  void _setMinutes(int m) {
    timer?.cancel();
    setState(() { selectedMinutes = m; seconds = m * 60; running = false; });
  }

  @override
  void dispose() { timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final mm = (seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    final progress = selectedMinutes == 0 ? 0.0 : 1 - seconds / (selectedMinutes * 60);
    return Directionality(textDirection: TextDirection.rtl, child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(children: [
        const SizedBox(height: 4),
        const Text('وضع الإنجاز العميق', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
        const Text('جلسة واحدة بلا مشتتات قد تغيّر يومك كله.', style: TextStyle(color: Colors.white54)),
        const Spacer(),
        SizedBox(width: 275, height: 275, child: Stack(alignment: Alignment.center, children: [
          SizedBox(width: 265, height: 265, child: CircularProgressIndicator(value: progress, strokeWidth: 9, backgroundColor: border, color: gold)),
          Container(width: 225, height: 225, decoration: const BoxDecoration(shape: BoxShape.circle, color: panel, boxShadow: [BoxShadow(color: Color(0x443D321A), blurRadius: 35)]), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('ركز على خطوة واحدة', style: TextStyle(color: gold)), const SizedBox(height: 8), Text('$mm:$ss', style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w300)), Text('$selectedMinutes دقيقة', style: const TextStyle(color: Colors.white54))])),
        ])),
        const SizedBox(height: 25),
        Wrap(spacing: 8, children: [for (final m in [10, 25, 50]) ChoiceChip(label: Text('$m د'), selected: selectedMinutes == m, selectedColor: gold, labelStyle: TextStyle(color: selectedMinutes == m ? Colors.black : Colors.white), onSelected: (_) => _setMinutes(m))]),
        const SizedBox(height: 18),
        SizedBox(width: double.infinity, child: FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16)), onPressed: seconds == 0 ? () => _setMinutes(selectedMinutes) : _toggle, icon: Icon(seconds == 0 ? Icons.refresh : running ? Icons.pause : Icons.play_arrow), label: Text(seconds == 0 ? 'جلسة جديدة' : running ? 'إيقاف مؤقت' : 'ابدأ الآن', style: const TextStyle(fontWeight: FontWeight.w900)))),
        const Spacer(),
        const Text('أبعد الهاتف عن المشتتات. لا تحتاج أن تنجز كل شيء؛ فقط هذه الجلسة.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
      ]),
    ));
  }
}
