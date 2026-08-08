import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'v3_models.dart';

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

int stableId(String input, int base) {
  var h = 7;
  for (final c in input.codeUnits) {
    h = ((h * 31) + c) & 0x7fffffff;
  }
  return base + (h % 90000);
}

class ProfileStore {
  static Future<List<ProfileData>> loadProfiles() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('profiles_v3');
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).map((e) => ProfileData.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveProfiles(List<ProfileData> profiles) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('profiles_v3', jsonEncode(profiles.map((e) => e.toJson()).toList()));
  }

  static Future<String?> currentId() async => (await SharedPreferences.getInstance()).getString('current_profile_v3');
  static Future<void> setCurrent(String id) async => (await SharedPreferences.getInstance()).setString('current_profile_v3', id);
}

class UserStore {
  UserStore(this.profileId);
  final String profileId;
  String key(String name) => 'najm_v3_${profileId}_$name';

  Future<List<T>> _loadList<T>(String name, T Function(Map<String, dynamic>) fromJson) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(key(name));
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).map((e) => fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveList(String name, List<Map<String, dynamic>> data) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(key(name), jsonEncode(data));
  }

  Future<List<DreamData>> dreams() => _loadList('dreams', DreamData.fromJson);
  Future<List<GoalData>> goals() => _loadList('goals', GoalData.fromJson);
  Future<List<TaskData>> tasks() => _loadList('tasks', TaskData.fromJson);
  Future<List<HabitData>> habits() => _loadList('habits', HabitData.fromJson);

  Future<void> saveDreams(List<DreamData> x) => _saveList('dreams', x.map((e) => e.toJson()).toList());
  Future<void> saveGoals(List<GoalData> x) => _saveList('goals', x.map((e) => e.toJson()).toList());
  Future<void> saveTasks(List<TaskData> x) => _saveList('tasks', x.map((e) => e.toJson()).toList());
  Future<void> saveHabits(List<HabitData> x) => _saveList('habits', x.map((e) => e.toJson()).toList());

  Future<int> morningHour() async => (await SharedPreferences.getInstance()).getInt(key('morning_h')) ?? 8;
  Future<int> morningMinute() async => (await SharedPreferences.getInstance()).getInt(key('morning_m')) ?? 0;
  Future<int> eveningHour() async => (await SharedPreferences.getInstance()).getInt(key('evening_h')) ?? 20;
  Future<int> eveningMinute() async => (await SharedPreferences.getInstance()).getInt(key('evening_m')) ?? 30;
  Future<void> setMorning(int h, int m) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(key('morning_h'), h);
    await p.setInt(key('morning_m'), m);
  }
  Future<void> setEvening(int h, int m) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(key('evening_h'), h);
    await p.setInt(key('evening_m'), m);
  }

  Future<String> reflection() async => (await SharedPreferences.getInstance()).getString(key('reflection_${dayKey()}')) ?? '';
  Future<void> setReflection(String text) async => (await SharedPreferences.getInstance()).setString(key('reflection_${dayKey()}'), text);
}

class NajmNotifications {
  NajmNotifications._();
  static final instance = NajmNotifications._();
  final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();
  bool initialized = false;

  static const NotificationDetails details = NotificationDetails(
    android: AndroidNotificationDetails(
      'najm_v3_main',
      'نجم - التذكيرات الذكية',
      channelDescription: 'تذكيرات الرؤية والأهداف والمهام والعادات والمراجعة اليومية',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    ),
  );

  Future<void> init() async {
    if (initialized) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Etc/UTC'));
    }
    const settings = InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher'));
    await plugin.initialize(settings: settings);
    initialized = true;
  }

  AndroidFlutterLocalNotificationsPlugin? get android => plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  Future<bool> requestPermission() async {
    await init();
    return await android?.requestNotificationsPermission() ?? true;
  }

  Future<bool> enabled() async {
    await init();
    return await android?.areNotificationsEnabled() ?? true;
  }

  Future<int> pendingCount() async {
    await init();
    return (await plugin.pendingNotificationRequests()).length;
  }

  Future<void> testNow(String name) async {
    await init();
    await plugin.show(
      id: 990001,
      title: 'نجم معك الآن ✦',
      body: '$name، الإشعارات تعمل. اختر خطوة صغيرة ونفذها الآن.',
      notificationDetails: details,
    );
  }

  tz.TZDateTime _next(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var target = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!target.isAfter(now)) target = target.add(const Duration(days: 1));
    return target;
  }

  Future<void> daily({required int id, required int hour, required int minute, required String title, required String body}) async {
    await init();
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

  Future<void> cancelAll() async {
    await init();
    await plugin.cancelAll();
  }

  Future<void> scheduleForProfile({
    required ProfileData profile,
    required List<DreamData> dreams,
    required List<GoalData> goals,
    required List<TaskData> tasks,
    required int morningHour,
    required int morningMinute,
    required int eveningHour,
    required int eveningMinute,
  }) async {
    await cancelAll();
    final base = stableId(profile.id, 500000);
    await daily(
      id: base,
      hour: morningHour,
      minute: morningMinute,
      title: 'صباح الرؤية يا ${profile.name} ✦',
      body: dreams.isEmpty ? 'ابدأ يومك بسؤال: ما الحياة التي أريد بناءها؟ ثم اختر خطوة واحدة.' : 'اقرأ رؤيتك اليوم، تخيّل مستقبلك لدقيقتين، ثم حوّل الحلم إلى فعل واحد.',
    );
    await daily(
      id: base + 1,
      hour: 13,
      minute: 0,
      title: 'نجم يسألك: ما أهم شيء الآن؟',
      body: tasks.where((e) => !e.done).isEmpty ? 'أنشئ مهمة صغيرة تقرّبك من هدفك.' : 'لا تشتت نفسك. افتح نجم ونفّذ أهم مهمة متبقية.',
    );
    await daily(
      id: base + 2,
      hour: eveningHour,
      minute: eveningMinute,
      title: 'مراجعة نجم اليومية',
      body: 'قيّم يومك: ماذا أنجزت؟ أين تعثرت؟ وما الخطوة التي ستبدأ بها غداً؟',
    );
    for (final g in goals.where((e) => e.reminderEnabled && !e.completed)) {
      await daily(
        id: g.notificationId,
        hour: g.reminderHour,
        minute: g.reminderMinute,
        title: 'هدفك يناديك: ${g.title}',
        body: g.why.isEmpty ? 'نفّذ خطوة واحدة الآن؛ الاستمرار أهم من الحماس.' : 'تذكّر لماذا بدأت: ${g.why}',
      );
    }
  }
}
