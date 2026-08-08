import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const bg = Color(0xFF06080C);
const panel = Color(0xFF11151B);
const panel2 = Color(0xFF181D25);
const gold = Color(0xFFE8B84E);
const goldSoft = Color(0xFFFFD978);
const border = Color(0xFF343A44);

void main() => runApp(const NajmApp());

class NajmApp extends StatelessWidget {
  const NajmApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'نَجْم',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(seedColor: gold, brightness: Brightness.dark),
        useMaterial3: true,
        fontFamilyFallback: const ['Arial'],
      ),
      home: const NajmHome(),
    );
  }
}

class TaskItem {
  TaskItem(this.title, this.minutes, {this.done = false});
  String title;
  int minutes;
  bool done;
}

class NajmHome extends StatefulWidget {
  const NajmHome({super.key});
  @override
  State<NajmHome> createState() => _NajmHomeState();
}

class _NajmHomeState extends State<NajmHome> {
  int tab = 0;
  int streak = 7;
  final tasks = <TaskItem>[
    TaskItem('إنهاء الجزء الأول من الخطة', 25),
    TaskItem('مراجعة الميزانية', 20),
    TaskItem('التواصل مع المصمم', 15),
    TaskItem('الرد على الرسائل المهمة', 10),
    TaskItem('قراءة 20 صفحة', 20),
  ];

  int get completed => tasks.where((e) => e.done).length;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      streak = p.getInt('streak') ?? 7;
      for (var i = 0; i < tasks.length; i++) {
        tasks[i].done = p.getBool('task_$i') ?? false;
      }
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('streak', streak);
    for (var i = 0; i < tasks.length; i++) {
      await p.setBool('task_$i', tasks[i].done);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_dashboard(), _goals(), _tasksPage(), const FocusPage(), _companion()];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(child: pages[tab]),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(color: Color(0xFF090C10), border: Border(top: BorderSide(color: border))),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _nav(0, Icons.home_rounded, 'الرئيسية'),
              _nav(1, Icons.track_changes_rounded, 'الأهداف'),
              _nav(2, Icons.check_circle_outline_rounded, 'المهام'),
              _nav(3, Icons.timer_outlined, 'تركيز'),
              _nav(4, Icons.auto_awesome_rounded, 'رفيقك'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nav(int i, IconData icon, String text) => InkWell(
        onTap: () => setState(() => tab = i),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 23, color: tab == i ? gold : Colors.white54),
            const SizedBox(height: 3),
            Text(text, style: TextStyle(fontSize: 11, color: tab == i ? gold : Colors.white54)),
          ]),
        ),
      );

  Widget _luxCard(Widget child) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF131821), Color(0xFF0E1218)]),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
          boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 14, offset: Offset(0, 8))],
        ),
        child: child,
      );

  Widget _dashboard() {
    final progress = tasks.isEmpty ? 0.0 : completed / tasks.length;
    final current = tasks.firstWhere((e) => !e.done, orElse: () => tasks.first);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(shape: BoxShape.circle, color: panel2, border: Border.all(color: border)),
            child: const Icon(Icons.notifications_none_rounded, color: gold),
          ),
          const Spacer(),
          const Column(children: [
            Text('✦ نَجْم', style: TextStyle(color: gold, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
            Text('NAJM', style: TextStyle(fontSize: 9, color: Colors.white38, letterSpacing: 4)),
          ]),
          const Spacer(),
          const CircleAvatar(radius: 21, backgroundColor: Color(0xFF2A2418), child: Text('ن', style: TextStyle(color: gold, fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 28),
        const Text('مساء الخير 👋', style: TextStyle(color: Colors.white60, fontSize: 16)),
        const SizedBox(height: 5),
        const Text('جاهز تكمل تقدمك؟', style: TextStyle(fontSize: 29, fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),
        _luxCard(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.local_fire_department_rounded, color: gold),
            const SizedBox(width: 8),
            const Text('سلسلة الإنجاز', style: TextStyle(color: gold, fontWeight: FontWeight.w700)),
            const Spacer(),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: const Color(0xFF2A2418), borderRadius: BorderRadius.circular(20)), child: const Text('مستمر 🔥', style: TextStyle(color: gold, fontSize: 12))),
          ]),
          const SizedBox(height: 12),
          Text('$streak أيام', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
          const Text('كل يوم صغير يصنع فرقاً كبيراً.', style: TextStyle(color: Colors.white54)),
        ])),
        const SizedBox(height: 14),
        _luxCard(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [Icon(Icons.flag_outlined, color: gold, size: 20), SizedBox(width: 7), Text('هدفك الرئيسي', style: TextStyle(color: gold, fontWeight: FontWeight.w700))]),
          const SizedBox(height: 12),
          const Row(children: [Expanded(child: Text('إطلاق مشروعي الخاص', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))), Text('72%', style: TextStyle(color: gold, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 12),
          ClipRRect(borderRadius: BorderRadius.circular(9), child: const LinearProgressIndicator(value: .72, minHeight: 8, backgroundColor: border, valueColor: AlwaysStoppedAnimation(gold))),
        ])),
        const SizedBox(height: 14),
        _luxCard(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('مهمتك الآن', style: TextStyle(color: gold, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(children: [
            Container(width: 39, height: 39, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF292317)), child: const Icon(Icons.star_rounded, color: gold, size: 21)),
            const SizedBox(width: 12),
            Expanded(child: Text(current.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600))),
            Text('${current.minutes} د', style: const TextStyle(color: Colors.white54)),
          ]),
        ])),
        const SizedBox(height: 14),
        _luxCard(Column(children: [
          Row(children: [const Text('تقدم اليوم', style: TextStyle(color: gold, fontWeight: FontWeight.w700)), const Spacer(), Text('$completed / ${tasks.length} مهام')]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(9), child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: border, valueColor: const AlwaysStoppedAnimation(gold)))),
            const SizedBox(width: 12),
            Text('${(progress * 100).round()}%', style: const TextStyle(color: gold, fontWeight: FontWeight.bold)),
          ]),
        ])),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () => setState(() => tab = 3),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('ابدأ جلسة التركيز', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 17), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        ),
      ]),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Text(text, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
      );

  Widget _goals() => SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _sectionTitle('أهدافي'),
          _goal('إطلاق مشروعي الخاص', .72, Icons.rocket_launch_outlined),
          _goal('تحسين لياقتي', .45, Icons.fitness_center_rounded),
          _goal('تعلم لغة جديدة', .30, Icons.translate_rounded),
          _goal('قراءة 12 كتاباً', .60, Icons.auto_stories_outlined),
        ]),
      );

  Widget _goal(String name, double value, IconData icon) => Padding(
        padding: const EdgeInsets.only(bottom: 13),
        child: _luxCard(Column(children: [
          Row(children: [Icon(icon, color: gold), const SizedBox(width: 12), Expanded(child: Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700))), Text('${(value * 100).round()}%', style: const TextStyle(color: gold))]),
          const SizedBox(height: 12),
          ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: value, minHeight: 7, backgroundColor: border, valueColor: const AlwaysStoppedAnimation(gold))),
        ])),
      );

  Widget _tasksPage() => Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(18, 18, 18, 8), child: Row(children: [const Text('مهامي', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)), const Spacer(), IconButton(onPressed: _addTask, icon: const CircleAvatar(backgroundColor: gold, child: Icon(Icons.add, color: Colors.black)))])),
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.all(18),
          itemCount: tasks.length,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () async { setState(() => tasks[i].done = !tasks[i].done); await _save(); },
              borderRadius: BorderRadius.circular(18),
              child: _luxCard(Row(children: [
                Icon(tasks[i].done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: tasks[i].done ? gold : Colors.white54),
                const SizedBox(width: 12),
                Expanded(child: Text(tasks[i].title, style: TextStyle(fontSize: 16, decoration: tasks[i].done ? TextDecoration.lineThrough : null, color: tasks[i].done ? Colors.white38 : Colors.white))),
                Text('${tasks[i].minutes} د', style: const TextStyle(color: Colors.white45)),
              ])),
            ),
          ),
        )),
      ]);

  Future<void> _addTask() async {
    final c = TextEditingController();
    final m = TextEditingController(text: '25');
    final ok = await showDialog<bool>(context: context, builder: (_) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(
      backgroundColor: panel,
      title: const Text('مهمة جديدة'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: c, autofocus: true, decoration: const InputDecoration(labelText: 'اسم المهمة')), TextField(controller: m, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المدة بالدقائق'))]),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('إضافة'))],
    )));
    if (ok == true && c.text.trim().isNotEmpty) setState(() => tasks.add(TaskItem(c.text.trim(), int.tryParse(m.text) ?? 25)));
  }

  Widget _companion() => SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _sectionTitle('رفيقك ✦'),
          _luxCard(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('رسالة نَجْم لك', style: TextStyle(color: gold, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            _bubble('لا تحتاج أن تكون مثالياً اليوم. تحتاج فقط أن تتحرك خطوة واحدة للأمام.'),
            _bubble(completed > 0 ? 'أحسنت! أنجزت $completed مهام اليوم. حافظ على الزخم 🔥' : 'ابدأ بخمس دقائق فقط. غالباً أصعب جزء هو البداية.'),
            _bubble('إذا شعرت أن المهمة كبيرة، صغّرها حتى تصبح سهلة للبدء.'),
          ])),
          const SizedBox(height: 14),
          _luxCard(const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('نصيحة اليوم', style: TextStyle(color: gold, fontWeight: FontWeight.w800)), SizedBox(height: 10), Text('ركّز على المهمة الأهم قبل أن تملأ يومك بالمهام الصغيرة.', style: TextStyle(height: 1.6, fontSize: 16))])),
        ]),
      );

  Widget _bubble(String text) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: panel2, borderRadius: BorderRadius.circular(15), border: Border.all(color: border)),
        child: Text(text, style: const TextStyle(height: 1.55)),
      );
}

class FocusPage extends StatefulWidget {
  const FocusPage({super.key});
  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> {
  Timer? timer;
  int seconds = 25 * 60;
  bool running = false;

  void toggle() {
    if (running) {
      timer?.cancel();
      setState(() => running = false);
      return;
    }
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (seconds <= 0) {
        timer?.cancel();
        setState(() => running = false);
      } else {
        setState(() => seconds--);
      }
    });
    setState(() => running = true);
  }

  void reset() {
    timer?.cancel();
    setState(() { seconds = 25 * 60; running = false; });
  }

  @override
  void dispose() { timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final mm = (seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    return Column(children: [
      const SizedBox(height: 22),
      const Text('جلسة تركيز', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
      const Spacer(),
      Container(
        width: 270,
        height: 270,
        decoration: BoxDecoration(shape: BoxShape.circle, color: panel, border: Border.all(color: gold, width: 2), boxShadow: const [BoxShadow(color: Color(0x443A2C10), blurRadius: 40)]),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('ركز على هدفك', style: TextStyle(color: gold, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text('$mm:$ss', style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w300)),
          const Text('جلسة 25 دقيقة', style: TextStyle(color: Colors.white45)),
        ]),
      ),
      const SizedBox(height: 32),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        OutlinedButton(onPressed: reset, child: const Text('إعادة')),
        const SizedBox(width: 12),
        FilledButton(onPressed: toggle, style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 38, vertical: 15)), child: Text(running ? 'إيقاف مؤقت' : 'ابدأ التركيز', style: const TextStyle(fontWeight: FontWeight.w800))),
      ]),
      const Spacer(),
      const Padding(padding: EdgeInsets.all(24), child: Text('خطوة واحدة. تركيز كامل. ثم راحة.', style: TextStyle(color: Colors.white45))),
    ]);
  }
}
