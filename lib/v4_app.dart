import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

const bg = Color(0xFF05070A);
const panel = Color(0xFF11151B);
const panel2 = Color(0xFF181D25);
const gold = Color(0xFFE8B84E);
const gold2 = Color(0xFFFFD978);
const border = Color(0xFF343A44);
const success = Color(0xFF61C98B);
const danger = Color(0xFFE16A6A);

String uid() => '${DateTime.now().microsecondsSinceEpoch}${Random().nextInt(9999)}';
String dayKey([DateTime? d]) { final x=d??DateTime.now(); return '${x.year}-${x.month.toString().padLeft(2,'0')}-${x.day.toString().padLeft(2,'0')}'; }
String fmtTime(DateTime? d) => d==null ? 'بدون وقت' : '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';

class DreamItem {
  DreamItem({required this.id, required this.title, this.scene='', this.identity='', this.readToday=false});
  String id,title,scene,identity; bool readToday;
  Map<String,dynamic> toJson()=>{'id':id,'title':title,'scene':scene,'identity':identity,'readToday':readToday};
  factory DreamItem.fromJson(Map<String,dynamic> j)=>DreamItem(id:'${j['id']}',title:'${j['title']}',scene:'${j['scene']??''}',identity:'${j['identity']??''}',readToday:j['readToday']==true);
}

class GoalItem {
  GoalItem({required this.id, required this.title, this.why='', this.progress=0, List<String>? steps, List<bool>? done});
  String id,title,why; double progress; List<String> steps; List<bool> done;
  GoalItem._({required this.id,required this.title,required this.why,required this.progress,required this.steps,required this.done});
  Map<String,dynamic> toJson()=>{'id':id,'title':title,'why':why,'progress':progress,'steps':steps,'done':done};
  factory GoalItem.fromJson(Map<String,dynamic> j)=>GoalItem._(id:'${j['id']}',title:'${j['title']}',why:'${j['why']??''}',progress:(j['progress'] as num?)?.toDouble()??0,steps:List<String>.from(j['steps']??[]),done:List<bool>.from(j['done']??[]));
}

class TaskItem {
  TaskItem({required this.id, required this.title, this.done=false, this.priority=2, this.remindAt});
  String id,title; bool done; int priority; DateTime? remindAt;
  Map<String,dynamic> toJson()=>{'id':id,'title':title,'done':done,'priority':priority,'remindAt':remindAt?.toIso8601String()};
  factory TaskItem.fromJson(Map<String,dynamic> j)=>TaskItem(id:'${j['id']}',title:'${j['title']}',done:j['done']==true,priority:(j['priority'] as num?)?.toInt()??2,remindAt:j['remindAt']==null?null:DateTime.tryParse('${j['remindAt']}'));
}

class HabitItem {
  HabitItem({required this.id, required this.name, this.quit=false, this.replacement='', this.streak=0, this.checkedDay=''});
  String id,name,replacement,checkedDay; bool quit; int streak;
  Map<String,dynamic> toJson()=>{'id':id,'name':name,'quit':quit,'replacement':replacement,'streak':streak,'checkedDay':checkedDay};
  factory HabitItem.fromJson(Map<String,dynamic> j)=>HabitItem(id:'${j['id']}',name:'${j['name']}',quit:j['quit']==true,replacement:'${j['replacement']??''}',streak:(j['streak'] as num?)?.toInt()??0,checkedDay:'${j['checkedDay']??''}');
}

class NajmStateData {
  String displayName='صديقي';
  List<DreamItem> dreams=[];
  List<GoalItem> goals=[];
  List<TaskItem> tasks=[];
  List<HabitItem> habits=[];
  String todayWin='';
  String todayLesson='';
  String tomorrowFocus='';
  String lastDay='';

  Map<String,dynamic> toJson()=>{
    'displayName':displayName,'dreams':dreams.map((e)=>e.toJson()).toList(),'goals':goals.map((e)=>e.toJson()).toList(),
    'tasks':tasks.map((e)=>e.toJson()).toList(),'habits':habits.map((e)=>e.toJson()).toList(),'todayWin':todayWin,
    'todayLesson':todayLesson,'tomorrowFocus':tomorrowFocus,'lastDay':lastDay,
  };
  factory NajmStateData.fromJson(Map<String,dynamic> j){
    final s=NajmStateData();
    s.displayName='${j['displayName']??'صديقي'}';
    s.dreams=((j['dreams'] as List?)??[]).map((e)=>DreamItem.fromJson(Map<String,dynamic>.from(e))).toList();
    s.goals=((j['goals'] as List?)??[]).map((e)=>GoalItem.fromJson(Map<String,dynamic>.from(e))).toList();
    s.tasks=((j['tasks'] as List?)??[]).map((e)=>TaskItem.fromJson(Map<String,dynamic>.from(e))).toList();
    s.habits=((j['habits'] as List?)??[]).map((e)=>HabitItem.fromJson(Map<String,dynamic>.from(e))).toList();
    s.todayWin='${j['todayWin']??''}'; s.todayLesson='${j['todayLesson']??''}'; s.tomorrowFocus='${j['tomorrowFocus']??''}'; s.lastDay='${j['lastDay']??''}';
    return s;
  }
}

class ExactReminderService {
  ExactReminderService._(); static final instance=ExactReminderService._();
  final plugin=FlutterLocalNotificationsPlugin(); bool ready=false;
  static const details=NotificationDetails(android: AndroidNotificationDetails('najm_exact','تنبيهات نجم الدقيقة',channelDescription:'مهام وتذكيرات يحددها المستخدم بوقت دقيق',importance:Importance.max,priority:Priority.max,playSound:true,enableVibration:true));

  Future<void> init() async {
    if(ready)return;
    tzdata.initializeTimeZones();
    try { final z=await FlutterTimezone.getLocalTimezone(); tz.setLocalLocation(tz.getLocation(z.identifier)); } catch(_){ tz.setLocalLocation(tz.getLocation('Etc/UTC')); }
    const settings=InitializationSettings(android:AndroidInitializationSettings('@mipmap/ic_launcher'));
    await plugin.initialize(settings:settings);
    ready=true;
  }
  Future<Map<String,bool>> requestPermissions() async {
    await init();
    final a=plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final n=await a?.requestNotificationsPermission() ?? true;
    final e=await a?.requestExactAlarmsPermission() ?? true;
    return {'notifications':n,'exact':e};
  }
  Future<bool> notificationsEnabled() async {
    await init();
    final a=plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await a?.areNotificationsEnabled() ?? true;
  }
  Future<void> showNow(String title,String body) async {
    await init();
    await plugin.show(id:999001,title:title,body:body,notificationDetails:details);
  }
  Future<void> schedule({required int id,required DateTime when,required String title,required String body}) async {
    await init();
    final local=tz.TZDateTime.from(when,tz.local);
    await plugin.zonedSchedule(id:id,title:title,body:body,scheduledDate:local,notificationDetails:details,androidScheduleMode:AndroidScheduleMode.exactAllowWhileIdle);
  }
  Future<void> cancel(int id) async { await init(); await plugin.cancel(id:id); }
  int idFor(String s)=>s.codeUnits.fold(17,(a,b)=>(a*31+b)&0x7fffffff)%900000+1000;
}

class NajmV4App extends StatelessWidget {
  const NajmV4App({super.key});
  @override Widget build(BuildContext context)=>MaterialApp(
    debugShowCheckedModeBanner:false,title:'نجم',theme:ThemeData(brightness:Brightness.dark,scaffoldBackgroundColor:bg,colorScheme:ColorScheme.fromSeed(seedColor:gold,brightness:Brightness.dark),useMaterial3:true),home:const AuthGate());
}

class AuthGate extends StatefulWidget { const AuthGate({super.key}); @override State<AuthGate> createState()=>_AuthGateState(); }
class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AuthState>? sub;
  @override void initState(){super.initState(); sub=Supabase.instance.client.auth.onAuthStateChange.listen((_){if(mounted)setState((){});});}
  @override void dispose(){sub?.cancel();super.dispose();}
  @override Widget build(BuildContext context)=>Supabase.instance.client.auth.currentSession==null?const AuthPage():const NajmShell();
}

class AuthPage extends StatefulWidget { const AuthPage({super.key}); @override State<AuthPage> createState()=>_AuthPageState(); }
class _AuthPageState extends State<AuthPage>{
  final email=TextEditingController(),pass=TextEditingController(),name=TextEditingController(); bool signup=false,busy=false;
  Future<void> go() async {
    if(email.text.trim().isEmpty||pass.text.length<6)return;
    setState(()=>busy=true);
    try{
      if(signup){
        final r=await Supabase.instance.client.auth.signUp(email:email.text.trim(),password:pass.text,data:{'display_name':name.text.trim().isEmpty?'صديقي':name.text.trim()});
        if(r.session==null&&mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم إنشاء الحساب. افتح بريدك لتأكيد الحساب ثم سجّل الدخول.')));
      } else { await Supabase.instance.client.auth.signInWithPassword(email:email.text.trim(),password:pass.text); }
    } catch(e){ if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر الدخول: $e'))); }
    finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(body:SafeArea(child:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:480),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    Center(child:Container(width:92,height:92,alignment:Alignment.center,decoration:BoxDecoration(shape:BoxShape.circle,border:Border.all(color:gold,width:2),gradient:const LinearGradient(colors:[Color(0xFF201B10),Color(0xFF090B0F)]),boxShadow:const [BoxShadow(color:Color(0x44E8B84E),blurRadius:30)]),child:const Text('نجم',style:TextStyle(color:gold2,fontSize:26,fontWeight:FontWeight.w900)))),
    const SizedBox(height:24),Text(signup?'اصنع حسابك في نجم':'أهلاً بك في نجم',textAlign:TextAlign.center,style:const TextStyle(fontSize:28,fontWeight:FontWeight.w900)),const SizedBox(height:7),const Text('أحلامك، أهدافك، مهامك وعاداتك محفوظة ومزامنة مع حسابك.',textAlign:TextAlign.center,style:TextStyle(color:Colors.white60,height:1.5)),const SizedBox(height:24),
    if(signup)TextField(controller:name,decoration:const InputDecoration(labelText:'اسمك')),if(signup)const SizedBox(height:10),TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'البريد الإلكتروني')),const SizedBox(height:10),TextField(controller:pass,obscureText:true,decoration:const InputDecoration(labelText:'كلمة المرور - 6 أحرف على الأقل')),const SizedBox(height:18),
    FilledButton(style:FilledButton.styleFrom(backgroundColor:gold,foregroundColor:Colors.black,padding:const EdgeInsets.all(16)),onPressed:busy?null:go,child:Text(busy?'جاري الاتصال...':(signup?'إنشاء حساب':'تسجيل الدخول'),style:const TextStyle(fontWeight:FontWeight.w900))),const SizedBox(height:8),TextButton(onPressed:()=>setState(()=>signup=!signup),child:Text(signup?'لدي حساب بالفعل':'إنشاء حساب جديد')),
  ])))))));
}

class NajmShell extends StatefulWidget { const NajmShell({super.key}); @override State<NajmShell> createState()=>_NajmShellState(); }
class _NajmShellState extends State<NajmShell>{
  final sb=Supabase.instance.client; NajmStateData data=NajmStateData(); int tab=0; bool loading=true,saving=false; Timer? saveTimer; bool notifEnabled=false;
  @override void initState(){super.initState();load();}
  @override void dispose(){saveTimer?.cancel();super.dispose();}

  Future<void> load() async {
    await ExactReminderService.instance.init();
    notifEnabled=await ExactReminderService.instance.notificationsEnabled();
    final u=sb.auth.currentUser!;
    try{
      final row=await sb.from('app_state').select('data').eq('user_id',u.id).maybeSingle();
      if(row!=null&&row['data'] is Map){ data=NajmStateData.fromJson(Map<String,dynamic>.from(row['data'])); }
      else { data.displayName='${u.userMetadata?['display_name']??u.email?.split('@').first??'صديقي'}'; await saveNow(); }
      _newDayReset();
      await _rescheduleFutureTasks();
    }catch(_){
      final p=await SharedPreferences.getInstance(); final raw=p.getString('najm_v4_cache_${u.id}'); if(raw!=null)data=NajmStateData.fromJson(jsonDecode(raw));
    }
    if(mounted)setState(()=>loading=false);
  }
  void _newDayReset(){
    final today=dayKey(); if(data.lastDay==today)return; data.lastDay=today; for(final d in data.dreams)d.readToday=false; data.todayWin='';data.todayLesson='';data.tomorrowFocus='';
  }
  Future<void> saveNow() async {
    final u=sb.auth.currentUser;if(u==null)return; setStateSafe(()=>saving=true);
    final map=data.toJson();
    final p=await SharedPreferences.getInstance(); await p.setString('najm_v4_cache_${u.id}',jsonEncode(map));
    try{ await sb.from('app_state').upsert({'user_id':u.id,'data':map,'updated_at':DateTime.now().toUtc().toIso8601String()}); }catch(_){}
    setStateSafe(()=>saving=false);
  }
  void changed(){setState((){});saveTimer?.cancel();saveTimer=Timer(const Duration(milliseconds:500),saveNow);}
  void setStateSafe(VoidCallback fn){if(mounted)setState(fn);}

  Future<void> _rescheduleFutureTasks() async {
    for(final t in data.tasks){ if(!t.done&&t.remindAt!=null&&t.remindAt!.isAfter(DateTime.now())){try{await ExactReminderService.instance.schedule(id:ExactReminderService.instance.idFor(t.id),when:t.remindAt!,title:'نجم يذكّرك ✦',body:t.title);}catch(_){}} }
  }
  int get doneTasks=>data.tasks.where((e)=>e.done).length;
  int get readDreams=>data.dreams.where((e)=>e.readToday).length;
  int get checkedHabits=>data.habits.where((e)=>e.checkedDay==dayKey()).length;
  int get score{
    var s=0; if(data.tasks.isNotEmpty)s+=(doneTasks/data.tasks.length*35).round(); if(data.dreams.isNotEmpty)s+=(readDreams/data.dreams.length*15).round(); if(data.habits.isNotEmpty)s+=(checkedHabits/data.habits.length*25).round(); if(data.goals.isNotEmpty)s+=(data.goals.fold<double>(0,(a,b)=>a+b.progress)/data.goals.length*25).round(); return min(100,s);
  }
  String get coach{
    if(data.dreams.isEmpty)return 'ابدأ برؤية واضحة: أضف حلماً واكتب كيف تبدو حياتك عندما يتحقق.';
    if(readDreams<data.dreams.length)return 'قبل أن تستهلكك تفاصيل اليوم، اقرأ رؤيتك لدقيقتين ثم اختر فعلاً واحداً يقرّبك منها.';
    final pending=data.tasks.where((e)=>!e.done).toList(); if(pending.isNotEmpty)return 'مهمتك الآن: ${pending.first.title}. لا تفاوض نفسك كثيراً؛ ابدأ بخمس دقائق.';
    if(data.todayWin.isEmpty)return 'أغلقت مهامك. سجّل انتصار اليوم حتى يرى عقلك الدليل على تقدمك.';
    return 'أنت تبني نظاماً، لا تبحث عن دفعة مؤقتة. حضّر تركيز الغد قبل أن تنام.';
  }

  Widget card(Widget c)=>Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF151A22),Color(0xFF0B0F14)]),borderRadius:BorderRadius.circular(20),border:Border.all(color:border),boxShadow:const [BoxShadow(color:Color(0x33000000),blurRadius:16,offset:Offset(0,8))]),child:c);
  Widget titleBar(String title,{Widget? action})=>Row(children:[Container(width:48,height:48,alignment:Alignment.center,decoration:BoxDecoration(shape:BoxShape.circle,border:Border.all(color:gold),color:const Color(0xFF19150D)),child:const Text('نجم',style:TextStyle(color:gold,fontWeight:FontWeight.w900))),const SizedBox(width:12),Expanded(child:Text(title,style:const TextStyle(fontSize:24,fontWeight:FontWeight.w900))),if(saving)const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:gold)),if(action!=null)action]);

  @override Widget build(BuildContext context){
    if(loading)return const Directionality(textDirection:TextDirection.rtl,child:Scaffold(body:Center(child:CircularProgressIndicator(color:gold))));
    final pages=[home(),vision(),goals(),tasks(),habits(),coachPage()];
    return Directionality(textDirection:TextDirection.rtl,child:Scaffold(body:SafeArea(bottom:false,child:pages[tab]),bottomNavigationBar:SafeArea(top:false,child:NavigationBar(height:68,selectedIndex:tab,onDestinationSelected:(i)=>setState(()=>tab=i),backgroundColor:const Color(0xFF080B10),indicatorColor:const Color(0xFF332A15),destinations:const [NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home,color:gold),label:'اليوم'),NavigationDestination(icon:Icon(Icons.visibility_outlined),selectedIcon:Icon(Icons.visibility,color:gold),label:'رؤيتي'),NavigationDestination(icon:Icon(Icons.flag_outlined),selectedIcon:Icon(Icons.flag,color:gold),label:'أهدافي'),NavigationDestination(icon:Icon(Icons.checklist),selectedIcon:Icon(Icons.checklist,color:gold),label:'مهامي'),NavigationDestination(icon:Icon(Icons.loop),selectedIcon:Icon(Icons.loop,color:gold),label:'عاداتي'),NavigationDestination(icon:Icon(Icons.auto_awesome_outlined),selectedIcon:Icon(Icons.auto_awesome,color:gold),label:'مرشدي')]))));
  }

  Widget home()=>ListView(padding:const EdgeInsets.fromLTRB(18,16,18,24),children:[
    titleBar('مرحباً، ${data.displayName}',action:IconButton(onPressed:()=>sb.auth.signOut(),icon:const Icon(Icons.logout))),const SizedBox(height:16),
    card(Row(children:[SizedBox(width:82,height:82,child:Stack(alignment:Alignment.center,children:[CircularProgressIndicator(value:score/100,strokeWidth:8,backgroundColor:border,color:gold),Text('$score',style:const TextStyle(color:gold,fontSize:23,fontWeight:FontWeight.w900))])),const SizedBox(width:16),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('مؤشر التزام اليوم',style:TextStyle(color:gold,fontWeight:FontWeight.w900)),const SizedBox(height:7),Text(coach,style:const TextStyle(color:Colors.white70,height:1.55))]))])),const SizedBox(height:12),
    card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('تنفيذ اليوم',style:TextStyle(color:gold,fontWeight:FontWeight.w900)),const SizedBox(height:10),for(final t in data.tasks.where((e)=>!e.done).take(3))CheckboxListTile(contentPadding:EdgeInsets.zero,value:t.done,activeColor:gold,title:Text(t.title),subtitle:t.remindAt==null?null:Text('تذكير ${fmtTime(t.remindAt)}',style:const TextStyle(color:Colors.white54)),onChanged:(v){t.done=v??false;if(t.done)ExactReminderService.instance.cancel(ExactReminderService.instance.idFor(t.id));changed();}),if(data.tasks.where((e)=>!e.done).isEmpty)const Text('لا توجد مهام معلّقة. استغل الهدوء في خطوة نحو هدفك.',style:TextStyle(color:Colors.white60))])),const SizedBox(height:12),
    Row(children:[Expanded(child:_stat('الأحلام','$readDreams/${data.dreams.length}',Icons.visibility)),const SizedBox(width:8),Expanded(child:_stat('المهام','$doneTasks/${data.tasks.length}',Icons.check_circle_outline)),const SizedBox(width:8),Expanded(child:_stat('العادات','$checkedHabits/${data.habits.length}',Icons.local_fire_department_outlined))]),const SizedBox(height:12),
    FilledButton.icon(style:FilledButton.styleFrom(backgroundColor:gold,foregroundColor:Colors.black,padding:const EdgeInsets.all(15)),onPressed:()=>setState(()=>tab=3),icon:const Icon(Icons.play_arrow),label:const Text('ما الخطوة التالية؟ افتح مهامي',style:TextStyle(fontWeight:FontWeight.w900))),
  ]);
  Widget _stat(String a,String b,IconData i)=>card(Column(children:[Icon(i,color:gold),const SizedBox(height:7),Text(b,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:17)),Text(a,style:const TextStyle(color:Colors.white54,fontSize:11))]));

  Widget vision()=>ListView(padding:const EdgeInsets.fromLTRB(18,16,18,24),children:[titleBar('رؤيتي وأحلامي',action:IconButton(onPressed:addDream,icon:const Icon(Icons.add_circle,color:gold))),const SizedBox(height:10),const Text('اقرأ رؤيتك يومياً، تخيّل المشهد بوضوح، ثم اربطه بفعل واقعي اليوم.',style:TextStyle(color:Colors.white60,height:1.5)),const SizedBox(height:14),for(final d in data.dreams)Padding(padding:const EdgeInsets.only(bottom:10),child:card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text(d.title,style:const TextStyle(fontSize:19,fontWeight:FontWeight.w900))),IconButton(onPressed:(){data.dreams.remove(d);changed();},icon:const Icon(Icons.delete_outline,color:Colors.white38))]),if(d.scene.isNotEmpty)Text('مشهد مستقبلي: ${d.scene}',style:const TextStyle(color:Colors.white70,height:1.5)),if(d.identity.isNotEmpty)Padding(padding:const EdgeInsets.only(top:8),child:Text('هويتي: ${d.identity}',style:const TextStyle(color:gold,height:1.4,fontWeight:FontWeight.w700))),const SizedBox(height:10),FilledButton.tonalIcon(onPressed:(){d.readToday=!d.readToday;changed();},icon:Icon(d.readToday?Icons.check:Icons.menu_book),label:Text(d.readToday?'قرأتها اليوم ✓':'قرأت رؤيتي اليوم'))]))),if(data.dreams.isEmpty)card(const Text('أضف أول حلم. اكتب ما تريد أن تعيشه، لا ما تريد أن تملكه فقط.',style:TextStyle(color:Colors.white60,height:1.6)))]);

  Widget goals()=>ListView(padding:const EdgeInsets.fromLTRB(18,16,18,24),children:[titleBar('أهدافي',action:IconButton(onPressed:addGoal,icon:const Icon(Icons.add_circle,color:gold))),const SizedBox(height:14),for(final g in data.goals)Padding(padding:const EdgeInsets.only(bottom:10),child:card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text(g.title,style:const TextStyle(fontSize:19,fontWeight:FontWeight.w900))),Text('${(g.progress*100).round()}%',style:const TextStyle(color:gold,fontWeight:FontWeight.w900))]),if(g.why.isNotEmpty)Padding(padding:const EdgeInsets.only(top:5),child:Text('لماذا: ${g.why}',style:const TextStyle(color:Colors.white60))),const SizedBox(height:9),LinearProgressIndicator(value:g.progress,minHeight:7,backgroundColor:border,color:gold),const SizedBox(height:9),for(int i=0;i<g.steps.length;i++)CheckboxListTile(contentPadding:EdgeInsets.zero,dense:true,value:i<g.done.length&&g.done[i],title:Text(g.steps[i]),activeColor:gold,onChanged:(v){while(g.done.length<g.steps.length)g.done.add(false);g.done[i]=v??false;g.progress=g.steps.isEmpty?0:g.done.where((e)=>e).length/g.steps.length;changed();}),Row(children:[TextButton.icon(onPressed:()=>addStep(g),icon:const Icon(Icons.add),label:const Text('إضافة خطوة')),const Spacer(),IconButton(onPressed:(){data.goals.remove(g);changed();},icon:const Icon(Icons.delete_outline,color:Colors.white38))])]))),if(data.goals.isEmpty)card(const Text('الحلم بلا هدف يبقى أمنية. أضف هدفاً واضحاً وقسّمه إلى خطوات.',style:TextStyle(color:Colors.white60,height:1.6)))]);

  Widget tasks()=>ListView(padding:const EdgeInsets.fromLTRB(18,16,18,24),children:[titleBar('مدير المهام',action:IconButton(onPressed:addTask,icon:const Icon(Icons.add_circle,color:gold))),const SizedBox(height:8),const Text('للتنبيه الدقيق: اختر وقتاً قريباً، وسيطلب نجم صلاحية «المنبّهات والتذكيرات» من Android.',style:TextStyle(color:Colors.white60,height:1.45)),const SizedBox(height:12),for(final t in [...data.tasks]..sort((a,b)=>b.priority.compareTo(a.priority)))Padding(padding:const EdgeInsets.only(bottom:8),child:card(Row(children:[Checkbox(value:t.done,activeColor:gold,onChanged:(v){t.done=v??false;if(t.done)ExactReminderService.instance.cancel(ExactReminderService.instance.idFor(t.id));changed();}),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(t.title,style:TextStyle(fontWeight:FontWeight.w800,decoration:t.done?TextDecoration.lineThrough:null)),if(t.remindAt!=null)Text('${t.remindAt!.day}/${t.remindAt!.month} • ${fmtTime(t.remindAt)}',style:const TextStyle(color:gold,fontSize:12))])),Container(width:9,height:9,decoration:BoxDecoration(shape:BoxShape.circle,color:t.priority==3?danger:t.priority==2?gold:success)),IconButton(onPressed:(){ExactReminderService.instance.cancel(ExactReminderService.instance.idFor(t.id));data.tasks.remove(t);changed();},icon:const Icon(Icons.close,color:Colors.white38))]))),if(data.tasks.isEmpty)card(const Text('أضف مهمة وحدد «بعد 5 دقائق» لتجربة التنبيه الدقيق.',style:TextStyle(color:Colors.white60)))]);

  Widget habits()=>ListView(padding:const EdgeInsets.fromLTRB(18,16,18,24),children:[titleBar('عاداتي',action:IconButton(onPressed:addHabit,icon:const Icon(Icons.add_circle,color:gold))),const SizedBox(height:10),for(final h in data.habits)Padding(padding:const EdgeInsets.only(bottom:10),child:card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Icon(h.quit?Icons.shield_outlined:Icons.local_fire_department_outlined,color:gold),const SizedBox(width:8),Expanded(child:Text(h.name,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w900))),Text('${h.streak} يوم',style:const TextStyle(color:gold,fontWeight:FontWeight.w900))]),if(h.quit&&h.replacement.isNotEmpty)Padding(padding:const EdgeInsets.only(top:7),child:Text('البديل عند الرغبة: ${h.replacement}',style:const TextStyle(color:Colors.white60))),const SizedBox(height:10),Row(children:[Expanded(child:FilledButton.tonal(onPressed:h.checkedDay==dayKey()?null:(){h.checkedDay=dayKey();h.streak++;changed();},child:Text(h.checkedDay==dayKey()?'تم اليوم ✓':h.quit?'تجاوزتها اليوم':'أنجزتها اليوم'))),if(h.quit)...[const SizedBox(width:8),OutlinedButton(onPressed:()=>rescue(h),child:const Text('أحتاج إنقاذ'))],IconButton(onPressed:(){data.habits.remove(h);changed();},icon:const Icon(Icons.delete_outline,color:Colors.white38))])]))),if(data.habits.isEmpty)card(const Text('أضف عادة تريد بناءها أو عادة تريد تركها. نجم يتعامل مع الاثنين كنظام يومي.',style:TextStyle(color:Colors.white60,height:1.6)))]);

  Widget coachPage()=>ListView(padding:const EdgeInsets.fromLTRB(18,16,18,24),children:[titleBar('مرشد نجم'),const SizedBox(height:14),card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Row(children:[Icon(Icons.auto_awesome,color:gold),SizedBox(width:8),Text('توجيهك الآن',style:TextStyle(color:gold,fontWeight:FontWeight.w900))]),const SizedBox(height:10),Text(coach,style:const TextStyle(fontSize:17,height:1.65,fontWeight:FontWeight.w600))])),const SizedBox(height:12),card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('محاسبة اليوم',style:TextStyle(color:gold,fontWeight:FontWeight.w900)),const SizedBox(height:10),TextField(controller:TextEditingController(text:data.todayWin),onChanged:(v){data.todayWin=v;changed();},decoration:const InputDecoration(labelText:'ما أهم انتصار اليوم؟')),const SizedBox(height:8),TextField(controller:TextEditingController(text:data.todayLesson),onChanged:(v){data.todayLesson=v;changed();},decoration:const InputDecoration(labelText:'ماذا تعلمت من تعثرك؟')),const SizedBox(height:8),TextField(controller:TextEditingController(text:data.tomorrowFocus),onChanged:(v){data.tomorrowFocus=v;changed();},decoration:const InputDecoration(labelText:'ما تركيز الغد؟'))])),const SizedBox(height:12),card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('مركز الإشعارات',style:TextStyle(color:gold,fontWeight:FontWeight.w900)),const SizedBox(height:8),Text(notifEnabled?'الإشعارات مفعّلة على الجهاز':'الإشعارات غير مفعّلة أو تحتاج إذناً',style:TextStyle(color:notifEnabled?success:danger)),const SizedBox(height:10),Row(children:[Expanded(child:FilledButton.tonal(onPressed:()async{final r=await ExactReminderService.instance.requestPermissions();notifEnabled=r['notifications']==true;if(mounted)setState((){});},child:const Text('تفعيل التنبيهات الدقيقة'))),const SizedBox(width:8),Expanded(child:OutlinedButton(onPressed:()async{await ExactReminderService.instance.showNow('اختبار نجم ✦','إذا ظهر هذا فوراً فالإشعارات تعمل.');},child:const Text('اختبار الآن')))]),const SizedBox(height:8),OutlinedButton(onPressed:()async{final when=DateTime.now().add(const Duration(minutes:5));await ExactReminderService.instance.requestPermissions();try{await ExactReminderService.instance.schedule(id:998877,when:when,title:'اختبار 5 دقائق من نجم',body:'مرّت 5 دقائق. التنبيه الدقيق يعمل الآن.');if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم ضبط اختبار بعد 5 دقائق. اقفل التطبيق وانتظر.')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Android منع المنبه الدقيق: $e')));}},child:const Text('اختبار تنبيه بعد 5 دقائق'))]))]);

  Future<String?> textDialog(String title,String label,{String initial=''}) async{final c=TextEditingController(text:initial);return showDialog<String>(context:context,builder:(x)=>Directionality(textDirection:TextDirection.rtl,child:AlertDialog(backgroundColor:panel,title:Text(title),content:TextField(controller:c,autofocus:true,maxLines:label.contains('مشهد')?3:1,decoration:InputDecoration(labelText:label)),actions:[TextButton(onPressed:()=>Navigator.pop(x),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(x,c.text.trim()),child:const Text('حفظ'))])));}
  Future<void> addDream() async{final t=await textDialog('حلم جديد','ما حلمك؟');if(t==null||t.isEmpty)return;final s=await textDialog('صوّر مستقبلك','اكتب مشهد مستقبلك عندما يتحقق الحلم');final i=await textDialog('هوية المستقبل','من الشخص الذي تحتاج أن تصبحه؟');data.dreams.add(DreamItem(id:uid(),title:t,scene:s??'',identity:i??''));changed();}
  Future<void> addGoal() async{final t=await textDialog('هدف جديد','اكتب الهدف بوضوح');if(t==null||t.isEmpty)return;final w=await textDialog('لماذا هذا الهدف؟','سبب قوي يجعلك تستمر');data.goals.add(GoalItem(id:uid(),title:t,why:w??'',steps:[],done:[]));changed();}
  Future<void> addStep(GoalItem g) async{final t=await textDialog('خطوة تنفيذية','ما الخطوة الصغيرة التالية؟');if(t==null||t.isEmpty)return;g.steps.add(t);g.done.add(false);changed();}
  Future<void> addTask() async{
    final t=await textDialog('مهمة جديدة','ماذا تريد أن تنجز؟');if(t==null||t.isEmpty)return;
    if(!mounted)return; final choice=await showModalBottomSheet<int>(context:context,backgroundColor:panel,builder:(x)=>Directionality(textDirection:TextDirection.rtl,child:SafeArea(child:Padding(padding:const EdgeInsets.all(18),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[const Text('متى أذكّرك؟',style:TextStyle(fontSize:21,fontWeight:FontWeight.w900,color:gold)),ListTile(title:const Text('بعد 5 دقائق'),onTap:()=>Navigator.pop(x,5)),ListTile(title:const Text('بعد 15 دقيقة'),onTap:()=>Navigator.pop(x,15)),ListTile(title:const Text('بعد ساعة'),onTap:()=>Navigator.pop(x,60)),ListTile(title:const Text('بدون تذكير'),onTap:()=>Navigator.pop(x,0))]))));
    DateTime? at; if((choice??0)>0)at=DateTime.now().add(Duration(minutes:choice!)); final item=TaskItem(id:uid(),title:t,remindAt:at,priority:2);data.tasks.add(item);changed();
    if(at!=null){await ExactReminderService.instance.requestPermissions();try{await ExactReminderService.instance.schedule(id:ExactReminderService.instance.idFor(item.id),when:at,title:'نجم يذكّرك ✦',body:t);}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('اسمح لنجم من إعدادات Android باستخدام «المنبّهات والتذكيرات» حتى يعمل الوقت الدقيق.')));}}
  }
  Future<void> addHabit() async{final n=await textDialog('عادة جديدة','اسم العادة');if(n==null||n.isEmpty)return;if(!mounted)return;final q=await showDialog<bool>(context:context,builder:(x)=>Directionality(textDirection:TextDirection.rtl,child:AlertDialog(backgroundColor:panel,title:const Text('نوع العادة'),content:const Text('هل تريد ترك هذه العادة السيئة؟'),actions:[TextButton(onPressed:()=>Navigator.pop(x,false),child:const Text('أريد بناءها')),FilledButton(onPressed:()=>Navigator.pop(x,true),child:const Text('أريد تركها'))])));String r='';if(q==true)r=await textDialog('السلوك البديل','ماذا ستفعل بدلاً منها عند الرغبة؟')??'';data.habits.add(HabitItem(id:uid(),name:n,quit:q==true,replacement:r));changed();}
  void rescue(HabitItem h){showModalBottomSheet(context:context,backgroundColor:panel,builder:(x)=>Directionality(textDirection:TextDirection.rtl,child:SafeArea(child:Padding(padding:const EdgeInsets.all(22),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[const Text('موجة الرغبة ستمر',style:TextStyle(color:gold,fontSize:23,fontWeight:FontWeight.w900)),const SizedBox(height:12),const Text('1) غيّر مكانك فوراً.\n2) أبعد المحفّز.\n3) تنفّس ببطء لمدة دقيقة.\n4) لا تقل «للأبد»؛ قل «ليس في الدقائق العشر القادمة».',style:TextStyle(height:1.8,color:Colors.white70)),if(h.replacement.isNotEmpty)Padding(padding:const EdgeInsets.only(top:10),child:Text('نفّذ البديل الآن: ${h.replacement}',style:const TextStyle(color:gold,fontWeight:FontWeight.w900))),const SizedBox(height:12),FilledButton(style:FilledButton.styleFrom(backgroundColor:gold,foregroundColor:Colors.black),onPressed:()=>Navigator.pop(x),child:const Text('سأتجاوزها الآن'))]))))));}
}
