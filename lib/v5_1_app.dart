import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'v5_app.dart';

const _bg = Color(0xFF05070A);
const _panel = Color(0xFF11151B);
const _panel2 = Color(0xFF171C24);
const _gold = Color(0xFFE8B84E);
const _gold2 = Color(0xFFFFD978);
const _border = Color(0xFF2A303A);

class NajmV51App extends StatelessWidget {
  const NajmV51App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'نجم',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _gold,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const _NajmV51Root(),
    );
  }
}

class _NajmV51Root extends StatefulWidget {
  const _NajmV51Root();

  @override
  State<_NajmV51Root> createState() => _NajmV51RootState();
}

class _NajmV51RootState extends State<_NajmV51Root> {
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = Supabase.instance.client.auth.currentSession != null;
    return Stack(
      children: [
        const V5Gate(),
        if (loggedIn)
          PositionedDirectional(
            end: 14,
            top: MediaQuery.of(context).padding.top + 62,
            child: SafeArea(
              child: Material(
                color: Colors.transparent,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: Colors.black,
                    elevation: 6,
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NajmAiSetupPage()),
                    );
                  },
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text(
                    'AI حقيقي',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class NajmAiSetupPage extends StatefulWidget {
  const NajmAiSetupPage({super.key});

  @override
  State<NajmAiSetupPage> createState() => _NajmAiSetupPageState();
}

class _NajmAiSetupPageState extends State<NajmAiSetupPage> {
  final _controller = TextEditingController();
  final _sb = Supabase.instance.client;
  bool _loading = true;
  bool _saving = false;
  bool _enabled = false;
  bool _hideKey = true;
  String? _message;

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    try {
      final res = await _sb.functions.invoke(
        'najm-coach',
        body: const {'action': 'status'},
      );
      final map = Map<String, dynamic>.from(res.data as Map);
      _enabled = map['ai_enabled'] == true;
    } catch (_) {
      _message = 'تعذر فحص حالة AI الآن. تأكد من الإنترنت وحاول مرة ثانية.';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _activate() async {
    final key = _controller.text.trim();
    if (key.isEmpty) {
      setState(() => _message = 'الصق مفتاح OpenAI أولاً.');
      return;
    }
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final res = await _sb.functions.invoke(
        'najm-coach',
        body: {'action': 'set_key', 'key': key},
      );
      final map = Map<String, dynamic>.from(res.data as Map);
      if (map['ok'] == true) {
        _controller.clear();
        _enabled = true;
        _message = 'تم تفعيل OpenAI الحقيقي ✅ مرشد نجم الآن يستخدم AI الفعلي.';
      } else {
        _message = 'المفتاح غير صالح. تأكد أنك نسخته كاملًا.';
      }
    } catch (_) {
      _message = 'لم يتم قبول المفتاح. تأكد أنه مفتاح OpenAI صالح وأن حساب API مفعّل.';
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _remove() async {
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      await _sb.functions.invoke(
        'najm-coach',
        body: const {'action': 'remove_key'},
      );
      _enabled = false;
      _message = 'تم إيقاف AI الحقيقي لهذا الحساب.';
    } catch (_) {
      _message = 'تعذر إيقاف AI الآن.';
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          title: const Text(
            'نجم AI',
            style: TextStyle(color: _gold2, fontWeight: FontWeight.w900),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _panel,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _enabled ? _gold : _border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _panel2,
                            shape: BoxShape.circle,
                            border: Border.all(color: _gold),
                          ),
                          child: const Icon(Icons.psychology, color: _gold2),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'مرشد OpenAI الحقيقي',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _loading
                                    ? 'أفحص الحالة...'
                                    : _enabled
                                        ? 'مفعّل لهذا الحساب ✅'
                                        : 'غير مفعّل بعد',
                                style: TextStyle(
                                  color: _enabled ? _gold2 : Colors.white60,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'بعد التفعيل، نجم يرسل للـAI أهدافك ومهامك وعاداتك وتقدمك الحالي حتى يعطيك توجيهًا مرتبطًا بحياتك الفعلية، وليس رسائل محفوظة.',
                      style: TextStyle(color: Colors.white70, height: 1.6),
                    ),
                    if (!_enabled) ...[
                      const SizedBox(height: 18),
                      TextField(
                        controller: _controller,
                        obscureText: _hideKey,
                        enableSuggestions: false,
                        autocorrect: false,
                        decoration: InputDecoration(
                          labelText: 'مفتاح OpenAI API',
                          hintText: 'sk-...',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _hideKey = !_hideKey),
                            icon: Icon(_hideKey ? Icons.visibility : Icons.visibility_off),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'المفتاح لا يُحفظ داخل التطبيق. يُرسل مرة واحدة إلى خادم نجم ويُستخدم من هناك.',
                        style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.5),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: _gold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _saving ? null : _activate,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.lock),
                        label: const Text(
                          'تفعيل AI الحقيقي',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: const Color(0x2217C964),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'جاهز ✦ ارجع إلى تبويب «مرشدي» واكتب أي شيء مثل: رتب يومي، حاسبني، أو أنا ضايع. الرد سيأتي من OpenAI.',
                          style: TextStyle(height: 1.55),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _saving ? null : _remove,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('إزالة مفتاح AI من الحساب'),
                      ),
                    ],
                    if (_message != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _message!,
                        style: const TextStyle(color: _gold2, height: 1.5),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _panel,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _border),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ماذا يستطيع نجم AI أن يفعل؟', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    SizedBox(height: 10),
                    Text('• يختار لك أهم خطوة الآن من أهدافك ومهامك.\n• يحاسبك على يومك بدون جلد ذات.\n• يحلل التعثر ويقترح تعديلًا عمليًا.\n• يساعدك عند الرغبة بالعودة لعادات سيئة.\n• يحول رؤيتك إلى تصرف صغير قابل للتنفيذ اليوم.', style: TextStyle(color: Colors.white70, height: 1.7)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
