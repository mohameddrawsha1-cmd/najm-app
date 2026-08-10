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
const _green = Color(0xFF57D98C);

class NajmV52App extends StatelessWidget {
  const NajmV52App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'نجم',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _bg,
        colorScheme: ColorScheme.fromSeed(seedColor: _gold, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const _NajmV52Root(),
    );
  }
}

class _NajmV52Root extends StatefulWidget {
  const _NajmV52Root();
  @override
  State<_NajmV52Root> createState() => _NajmV52RootState();
}

class _NajmV52RootState extends State<_NajmV52Root> {
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
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NajmFreeAiSetupPage()),
                  ),
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('AI مجاني', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class NajmFreeAiSetupPage extends StatefulWidget {
  const NajmFreeAiSetupPage({super.key});
  @override
  State<NajmFreeAiSetupPage> createState() => _NajmFreeAiSetupPageState();
}

class _NajmFreeAiSetupPageState extends State<NajmFreeAiSetupPage> {
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
      final res = await _sb.functions.invoke('najm-coach', body: const {'action': 'status'});
      final map = Map<String, dynamic>.from(res.data as Map);
      _enabled = map['ai_enabled'] == true;
    } catch (_) {
      _message = 'تعذر فحص AI الآن، لكن محرك نجم المحلي يبقى متاحًا.';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _activate() async {
    final key = _controller.text.trim();
    if (key.isEmpty) {
      setState(() => _message = 'الصق مفتاح OpenRouter المجاني أولاً.');
      return;
    }
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final res = await _sb.functions.invoke('najm-coach', body: {'action': 'set_key', 'key': key});
      final map = Map<String, dynamic>.from(res.data as Map);
      if (map['ok'] == true) {
        _controller.clear();
        _enabled = true;
        _message = 'تم ✅ AI المجاني مفعّل. وإذا تعطل يرجع نجم تلقائيًا للمحرك المحلي.';
      } else {
        _message = 'المفتاح غير صالح. استخدم مفتاح OpenRouter يبدأ بـ sk-or-.';
      }
    } catch (_) {
      _message = 'لم يتم قبول المفتاح. تأكد أنه مفتاح OpenRouter صحيح واتصال الإنترنت شغال.';
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _remove() async {
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      await _sb.functions.invoke('najm-coach', body: const {'action': 'remove_key'});
      _enabled = false;
      _message = 'تم إيقاف AI المجاني. نجم سيستمر بمحركه المحلي.';
    } catch (_) {
      _message = 'تعذر إزالة المفتاح الآن.';
    }
    if (mounted) setState(() => _saving = false);
  }

  Widget _card(Widget child, {Color? border}) => Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border ?? _border),
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          title: const Text('نجم AI المجاني', style: TextStyle(color: _gold2, fontWeight: FontWeight.w900)),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _card(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(color: _panel2, shape: BoxShape.circle, border: Border.all(color: _gold)),
                          child: const Icon(Icons.psychology_alt, color: _gold2),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Free AI → نجم المحلي', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 4),
                              Text(
                                _loading ? 'أفحص الحالة...' : _enabled ? 'AI المجاني مفعّل ✅' : 'المحرك المحلي جاهز الآن',
                                style: TextStyle(color: _enabled ? _green : Colors.white60, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'نجم يحاول أولاً استخدام نموذج مجاني عبر OpenRouter. إذا كان المجاني مزدحمًا، وصل للحد، أو فشل الطلب، يرجع تلقائيًا لمحرك نجم المحلي بدل ما تتوقف المحادثة.',
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
                          labelText: 'مفتاح OpenRouter المجاني',
                          hintText: 'sk-or-v1-...',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _hideKey = !_hideKey),
                            icon: Icon(_hideKey ? Icons.visibility : Icons.visibility_off),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'المفتاح يُرسل إلى خادم نجم ولا يوضع داخل ملف APK. تحتاجه مرة واحدة فقط لهذا الحساب.',
                        style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.5),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: _saving ? null : _activate,
                        icon: _saving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.bolt),
                        label: const Text('فعّل AI المجاني', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ] else ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(color: const Color(0x2257D98C), borderRadius: BorderRadius.circular(16)),
                        child: const Text(
                          'جاهز ✦ استخدم تبويب «مرشدي» عادي. نجم يختار AI المجاني تلقائيًا، وإذا تعطل يتحول للمحرك المحلي بدون أي زر منك.',
                          style: TextStyle(height: 1.55),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(onPressed: _saving ? null : _remove, icon: const Icon(Icons.delete_outline), label: const Text('إزالة مفتاح AI المجاني')),
                    ],
                    if (_message != null) ...[
                      const SizedBox(height: 14),
                      Text(_message!, style: const TextStyle(color: _gold2, height: 1.5)),
                    ],
                  ],
                ),
                border: _enabled ? _gold : _border,
              ),
              const SizedBox(height: 14),
              _card(
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('كيف يعمل بدون توقف؟', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    SizedBox(height: 10),
                    Text(
                      '1. نموذج AI مجاني متاح الآن.\n2. إذا فشل، نجم يحاول المجاني مرة ثانية.\n3. إذا بقي غير متاح، يستخدم محرك نجم المبني على أهدافك ومهامك وعاداتك.\n4. إذا انقطع الإنترنت، التطبيق يعطيك توجيهًا محليًا بسيطًا بدل شاشة خطأ.',
                      style: TextStyle(color: Colors.white70, height: 1.75),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _card(
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('جرّبه بعد التفعيل', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    SizedBox(height: 10),
                    Text('• رتب يومي حسب أهدافي.\n• حاسبني على اللي عملته اليوم.\n• أنا مشتت، شو أعمل الآن؟\n• ساعدني ما أرجع لعادتي السيئة.\n• حوّل حلمي لأصغر خطوة أعملها اليوم.', style: TextStyle(color: Colors.white70, height: 1.75)),
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
