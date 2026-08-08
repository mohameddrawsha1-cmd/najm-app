class ProfileData {
  ProfileData({required this.id, required this.name, required this.createdAt});
  final String id;
  String name;
  final DateTime createdAt;
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'createdAt': createdAt.toIso8601String()};
  factory ProfileData.fromJson(Map<String, dynamic> j) => ProfileData(id: '${j['id']}', name: '${j['name'] ?? 'مستخدم'}', createdAt: DateTime.tryParse('${j['createdAt']}') ?? DateTime.now());
}

class DreamData {
  DreamData({required this.id, required this.title, required this.futureScene, required this.identityStatement, required this.createdAt, List<String>? readDates}) : readDates = readDates ?? [];
  final String id;
  String title;
  String futureScene;
  String identityStatement;
  final DateTime createdAt;
  final List<String> readDates;
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'futureScene': futureScene, 'identityStatement': identityStatement, 'createdAt': createdAt.toIso8601String(), 'readDates': readDates};
  factory DreamData.fromJson(Map<String, dynamic> j) => DreamData(id: '${j['id']}', title: '${j['title']}', futureScene: '${j['futureScene'] ?? ''}', identityStatement: '${j['identityStatement'] ?? ''}', createdAt: DateTime.tryParse('${j['createdAt']}') ?? DateTime.now(), readDates: ((j['readDates'] as List?) ?? []).map((e) => '$e').toList());
}

class GoalStep {
  GoalStep({required this.id, required this.title, this.done = false});
  final String id;
  String title;
  bool done;
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'done': done};
  factory GoalStep.fromJson(Map<String, dynamic> j) => GoalStep(id: '${j['id']}', title: '${j['title']}', done: j['done'] == true);
}

class GoalData {
  GoalData({required this.id, required this.title, required this.why, required this.createdAt, required this.notificationId, this.deadline, this.reminderHour = 19, this.reminderMinute = 0, this.reminderEnabled = true, List<GoalStep>? steps}) : steps = steps ?? [];
  final String id;
  String title;
  String why;
  final DateTime createdAt;
  DateTime? deadline;
  int reminderHour;
  int reminderMinute;
  bool reminderEnabled;
  final int notificationId;
  final List<GoalStep> steps;
  double get progress => steps.isEmpty ? 0 : steps.where((e) => e.done).length / steps.length;
  bool get completed => steps.isNotEmpty && steps.every((e) => e.done);
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'why': why, 'createdAt': createdAt.toIso8601String(), 'deadline': deadline?.toIso8601String(), 'reminderHour': reminderHour, 'reminderMinute': reminderMinute, 'reminderEnabled': reminderEnabled, 'notificationId': notificationId, 'steps': steps.map((e) => e.toJson()).toList()};
  factory GoalData.fromJson(Map<String, dynamic> j) => GoalData(id: '${j['id']}', title: '${j['title']}', why: '${j['why'] ?? ''}', createdAt: DateTime.tryParse('${j['createdAt']}') ?? DateTime.now(), deadline: j['deadline'] == null ? null : DateTime.tryParse('${j['deadline']}'), reminderHour: (j['reminderHour'] as num?)?.toInt() ?? 19, reminderMinute: (j['reminderMinute'] as num?)?.toInt() ?? 0, reminderEnabled: j['reminderEnabled'] != false, notificationId: (j['notificationId'] as num?)?.toInt() ?? 300000, steps: ((j['steps'] as List?) ?? []).map((e) => GoalStep.fromJson(Map<String, dynamic>.from(e as Map))).toList());
}

class TaskData {
  TaskData({required this.id, required this.title, required this.createdAt, this.done = false, this.priority = 2, this.goalId, this.dueDate});
  final String id;
  String title;
  final DateTime createdAt;
  bool done;
  int priority;
  String? goalId;
  DateTime? dueDate;
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'createdAt': createdAt.toIso8601String(), 'done': done, 'priority': priority, 'goalId': goalId, 'dueDate': dueDate?.toIso8601String()};
  factory TaskData.fromJson(Map<String, dynamic> j) => TaskData(id: '${j['id']}', title: '${j['title']}', createdAt: DateTime.tryParse('${j['createdAt']}') ?? DateTime.now(), done: j['done'] == true, priority: (j['priority'] as num?)?.toInt() ?? 2, goalId: j['goalId']?.toString(), dueDate: j['dueDate'] == null ? null : DateTime.tryParse('${j['dueDate']}'));
}

class HabitData {
  HabitData({required this.id, required this.name, required this.kind, required this.replacement, this.streak = 0, this.best = 0, this.lastCheckDate, this.lastCheckSuccess});
  final String id;
  String name;
  String kind;
  String replacement;
  int streak;
  int best;
  String? lastCheckDate;
  bool? lastCheckSuccess;
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'kind': kind, 'replacement': replacement, 'streak': streak, 'best': best, 'lastCheckDate': lastCheckDate, 'lastCheckSuccess': lastCheckSuccess};
  factory HabitData.fromJson(Map<String, dynamic> j) => HabitData(id: '${j['id']}', name: '${j['name']}', kind: '${j['kind'] ?? 'build'}', replacement: '${j['replacement'] ?? ''}', streak: (j['streak'] as num?)?.toInt() ?? 0, best: (j['best'] as num?)?.toInt() ?? 0, lastCheckDate: j['lastCheckDate']?.toString(), lastCheckSuccess: j['lastCheckSuccess'] as bool?);
}
