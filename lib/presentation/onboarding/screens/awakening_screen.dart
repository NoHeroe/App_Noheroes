import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/datasources/local/tutorial_service.dart';

class AwakeningScreen extends ConsumerStatefulWidget {
  const AwakeningScreen({super.key});
  @override
  ConsumerState<AwakeningScreen> createState() => _AwakeningScreenState();
}

class _AwakeningScreenState extends ConsumerState<AwakeningScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bgCtrl;
  late final AnimationController _dialogCtrl;
  late final Animation<double> _bgFade;
  late final Animation<Offset> _dialogSlide;
  late final Animation<double> _dialogFade;

  int _step = 0;
  final _nameCtrl = TextEditingController();
  String _narrativeMode = 'longa';
  String? _selectedHabit;
  bool _ready = false;

  final _habits = [
    ('Hidratação', '💧', 'spiritual',  'Beber água conscientemente todos os dias'),
    ('Treino',     '⚔️', 'physical',   'Mover o corpo com intenção e disciplina'),
    ('Leitura',    '📖', 'mental',     'Expandir a mente através do conhecimento'),
    ('Meditação',  '🌑', 'spiritual',  'Silenciar o ruído interno diariamente'),
    ('Escrita',    '✍️', 'mental',     'Registrar pensamentos e experiências'),
    ('Sono',       '🌙', 'spiritual',  'Honrar o descanso como parte da jornada'),
  ];

  List<_Scene> get _scenes => [
    _Scene(npc: null, text: 'Você desperta entre ruínas antigas…\n\nA luz do céu parece quebrada.\n\nHá algo errado com seu corpo.', mood: _Mood.ruins),
    _Scene(npc: 'O Vazio', text: '"Você não é de Caelum.\n\nSua forma aqui é uma Sombra — ainda instável.\n\nSe quiser sobreviver, vai precisar aprender rápido."', mood: _Mood.npc, isVoid: true),
    _Scene(npc: 'O Vazio', text: 'Como devemos lhe chamar?', mood: _Mood.identity, isNameInput: true, isVoid: true),
    _Scene(npc: 'O Vazio', text: '"Todo ser em Caelum tem um ritual.\n\nNão é uma tarefa — é um pacto.\n\nEscolha o que você se compromete a honrar."', mood: _Mood.ritual, isHabitChoice: true, isVoid: true),
  ];

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _dialogCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _bgFade = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeIn);
    _dialogSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _dialogCtrl, curve: Curves.easeOut));
    _dialogFade = CurvedAnimation(parent: _dialogCtrl, curve: Curves.easeIn);

    _bgCtrl.forward().then((_) {
      _dialogCtrl.forward().then((_) => setState(() => _ready = true));
    });
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _dialogCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _advance() async {
    if (!_ready) return;
    final scene = _scenes[_step];

    if (scene.isNameInput && _nameCtrl.text.trim().isEmpty) return;
    if (scene.isHabitChoice && _selectedHabit == null) return;

    if (_step >= _scenes.length - 1) {
      await _finish();
      return;
    }

    setState(() => _ready = false);
    await _dialogCtrl.reverse();
    setState(() => _step++);
    await _dialogCtrl.forward();
    setState(() => _ready = true);
  }

  Future<void> _finish() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) { if (mounted) context.go('/sanctuary'); return; }
    final ds = ref.read(authDsProvider);
    await ds.completeOnboarding(
      player.id,
      _nameCtrl.text.trim().isEmpty ? 'Sombra' : _nameCtrl.text.trim(),
      _narrativeMode,
    );
    if (_selectedHabit != null) {
      final h = _habits.firstWhere((h) => h.$1 == _selectedHabit);
      await ds.createInitialHabit(player.id, h.$1, h.$3);
    }
    await TutorialService.markDone(TutorialPhase.phase0_onboarding);
    final updated = await ds.currentSession();
    if (mounted) {
      ref.read(currentPlayerProvider.notifier).state = updated;
      context.go('/sanctuary');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scene = _scenes[_step];
    return GestureDetector(
      onTap: (!scene.isNameInput && !scene.isHabitChoice)
          ? _advance
          : null,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Background
            FadeTransition(opacity: _bgFade, child: _SceneBg(mood: scene.mood)),
            // Gradient de baixo para cima
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                    Colors.black.withValues(alpha: 0.92),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            // Conteúdo central (para cenas sem NPC)
            if (scene.npc == null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: FadeTransition(
                    opacity: _dialogFade,
                    child: Text(
                      scene.text,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        color: AppColors.textPrimary,
                        height: 1.8,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ),
            // NPC Dialog — embaixo
            if (scene.npc != null || scene.isHabitChoice || scene.isNameInput)
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: SlideTransition(
                  position: _dialogSlide,
                  child: FadeTransition(
                    opacity: _dialogFade,
                    child: _buildBottomDialog(scene),
                  ),
                ),
              ),
            // Hint toque — indicador visual pulsante (so em cenas sem input)
            if (!scene.isNameInput && !scene.isHabitChoice)
              Align(
                alignment: const Alignment(0, -0.3),
                child: FadeTransition(
                  opacity: _dialogFade,
                  child: _PulsingTapHint(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomDialog(_Scene scene) {
    final isVoid = scene.isVoid;
    final color = isVoid ? AppColors.purple : AppColors.gold;
    final hasNpc = scene.npc != null;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0010).withValues(alpha: 0.97),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: color.withValues(alpha: 0.3))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasNpc) Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Avatar NPC
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.shadowVoid,
                      border: Border.all(color: color.withValues(alpha: 0.7), width: 2),
                      boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12)],
                    ),
                    child: Icon(isVoid ? Icons.blur_on : Icons.person_outline, color: color, size: 26),
                  ),
                  const SizedBox(height: 4),
                  Text(scene.npc!, style: GoogleFonts.roboto(fontSize: 8, color: color, letterSpacing: 1), textAlign: TextAlign.center),
                ],
              ),
              const SizedBox(width: 12),
              // Balão de fala
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.05),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                    border: Border.all(color: color.withValues(alpha: 0.25)),
                  ),
                  child: Text(scene.text,
                      style: GoogleFonts.roboto(
                          fontSize: 14, color: AppColors.textPrimary,
                          height: 1.6, fontStyle: FontStyle.italic)),
                ),
              ),
            ],
          ),
          // Inputs
          if (scene.isNameInput) ...[
            const SizedBox(height: 16),
            _buildNameInput(),
            const SizedBox(height: 12),
            _buildBtn('Confirmar', _advance),
          ],
          if (scene.isNarrativeChoice) ...[
            _buildNarrativeChoice(),
          ],
          if (scene.isHabitChoice) ...[
            const SizedBox(height: 16),
            _buildHabitChoice(),
            if (_selectedHabit != null) ...[
              const SizedBox(height: 12),
              _buildBtn('Despertar', _advance),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildNameInput() => TextField(
    controller: _nameCtrl,
    style: GoogleFonts.cinzelDecorative(color: AppColors.textPrimary, fontSize: 16),
    textAlign: TextAlign.center,
    autofocus: false,
    decoration: InputDecoration(
      hintText: 'Nome da sua Sombra',
      hintStyle: GoogleFonts.roboto(color: AppColors.textMuted),
      filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.purple)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.purple, width: 1.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
    ),
  );

  Widget _buildNarrativeChoice() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 4),
        child: Text('Como prefere receber as mensagens de Caelum?',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(fontSize: 13, color: AppColors.textSecondary)),
      ),
      ...['longa', 'curta'].map((mode) {
        final selected = _narrativeMode == mode;
        return GestureDetector(
          onTap: () async {
            setState(() => _narrativeMode = mode);
            await Future.delayed(const Duration(milliseconds: 300));
            _advance();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: selected ? AppColors.purple : AppColors.border, width: selected ? 1.5 : 1),
              borderRadius: BorderRadius.circular(12),
              color: selected ? AppColors.purple.withValues(alpha: 0.1) : Colors.transparent,
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(mode == 'longa' ? 'Narrativa Completa' : 'Narrativa Direta',
                  style: GoogleFonts.cinzelDecorative(fontSize: 12, color: selected ? AppColors.textPrimary : AppColors.textSecondary)),
              const SizedBox(height: 3),
              Text(mode == 'longa' ? 'Imersão total. Caelum fala com profundidade.' : 'Objetivo e direto. Menos texto, mais ação.',
                  style: GoogleFonts.roboto(fontSize: 11, color: AppColors.textMuted)),
            ]),
          ),
        );
      }),
    ],
  );

  Widget _buildHabitChoice() => Column(
    children: _habits.map((h) {
      final selected = _selectedHabit == h.$1;
      return GestureDetector(
        onTap: () => setState(() => _selectedHabit = h.$1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: selected ? AppColors.gold : AppColors.border, width: selected ? 1.5 : 1),
            borderRadius: BorderRadius.circular(12),
            color: selected ? AppColors.gold.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.03),
          ),
          child: Row(children: [
            Text(h.$2, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(h.$1, style: GoogleFonts.cinzelDecorative(fontSize: 12, color: selected ? AppColors.gold : AppColors.textPrimary)),
              Text(h.$4, style: GoogleFonts.roboto(fontSize: 10, color: AppColors.textMuted)),
            ])),
            if (selected) const Icon(Icons.check_circle, color: AppColors.gold, size: 18),
          ]),
        ),
      );
    }).toList(),
  );

  Widget _buildBtn(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity, height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.purple, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.purple.withValues(alpha: 0.15),
      ),
      child: Center(child: Text(label, style: GoogleFonts.cinzelDecorative(fontSize: 13, color: AppColors.textPrimary, letterSpacing: 1.5))),
    ),
  );
}

class _Scene {
  final String? npc;
  final String text;
  final _Mood mood;
  final bool isNameInput;
  final bool isNarrativeChoice;
  final bool isHabitChoice;
  final bool isVoid;
  const _Scene({required this.npc, required this.text, required this.mood,
    this.isNameInput = false, this.isNarrativeChoice = false,
    this.isHabitChoice = false, this.isVoid = false});
}

enum _Mood { ruins, npc, identity, ritual }

class _SceneBg extends StatefulWidget {
  final _Mood mood;
  const _SceneBg({super.key, required this.mood});
  @override State<_SceneBg> createState() => _SceneBgState();
}

class _SceneBgState extends State<_SceneBg> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) => CustomPaint(painter: _BgPainter(mood: widget.mood, t: _ctrl.value), child: Container()),
  );
}

class _BgPainter extends CustomPainter {
  final _Mood mood;
  final double t;
  _BgPainter({required this.mood, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    switch (mood) {
      case _Mood.ruins:
        _bg(canvas, size, p, const Color(0xFF0A0015), const Color(0xFF1A0A2E));
        _drawRuins(canvas, size, p);
        break;
      case _Mood.npc:
        _bg(canvas, size, p, const Color(0xFF0D0010), const Color(0xFF120820));
        _glow(canvas, size, p, const Color(0xFF4A1080));
        break;
      case _Mood.identity:
        _bg(canvas, size, p, const Color(0xFF080010), const Color(0xFF0F0520));
        _glow(canvas, size, p, const Color(0xFF7C3AED));
        _goldGlow(canvas, size, p);
        break;
      case _Mood.ritual:
        _bg(canvas, size, p, const Color(0xFF0A0005), const Color(0xFF1A0530));
        _glow(canvas, size, p, const Color(0xFF8B3DFF));
        _goldGlow(canvas, size, p);
        break;
    }
  }

  void _bg(Canvas c, Size s, Paint p, Color top, Color bot) {
    p.shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, bot]).createShader(Offset.zero & s);
    c.drawRect(Offset.zero & s, p);
    p.shader = null;
  }

  void _drawRuins(Canvas c, Size s, Paint p) {
    // Fragmentos de ruínas
    p.color = const Color(0xFF3D1F6E).withValues(alpha: 0.4 + t * 0.2);
    p.strokeWidth = 1.5;
    p.style = PaintingStyle.stroke;
    final lines = [
      [Offset(0, s.height * 0.15), Offset(s.width * 0.4, s.height * 0.12)],
      [Offset(s.width * 0.4, s.height * 0.12), Offset(s.width * 0.7, s.height * 0.18)],
      [Offset(s.width * 0.7, s.height * 0.18), Offset(s.width, s.height * 0.14)],
      // Pilares
      [Offset(s.width * 0.1, s.height * 0.12), Offset(s.width * 0.1, s.height * 0.45)],
      [Offset(s.width * 0.9, s.height * 0.14), Offset(s.width * 0.9, s.height * 0.42)],
      [Offset(s.width * 0.4, s.height * 0.08), Offset(s.width * 0.4, s.height * 0.35)],
    ];
    for (final l in lines) c.drawLine(l[0], l[1], p);
    p.style = PaintingStyle.fill;
    p.color = const Color(0xFF8B3DFF).withValues(alpha: 0.3 + t * 0.3);
    for (final l in lines) c.drawCircle(l[0], 2 + t * 1.5, p);
    // Partículas
    p.maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    for (var i = 0; i < 8; i++) {
      final x = s.width * (0.1 + i * 0.1 + t * 0.02);
      final y = s.height * (0.1 + (i % 3) * 0.08 + t * 0.015);
      p.color = const Color(0xFF8B3DFF).withValues(alpha: 0.2 + t * 0.15);
      c.drawCircle(Offset(x, y), 1.5 + t, p);
    }
    p.maskFilter = null;
  }

  void _glow(Canvas c, Size s, Paint p, Color color) {
    p.maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
    p.color = color.withValues(alpha: 0.15 + t * 0.08);
    c.drawCircle(Offset(s.width * .5, s.height * .3), s.width * .6, p);
    p.maskFilter = null;
  }

  void _goldGlow(Canvas c, Size s, Paint p) {
    p.maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    p.color = const Color(0xFFC2A05A).withValues(alpha: 0.06 + t * 0.04);
    c.drawCircle(Offset(s.width * .8, s.height * .7), s.width * .4, p);
    p.maskFilter = null;
  }

  @override
  bool shouldRepaint(covariant _BgPainter o) => o.t != t || o.mood != mood;
}

// Indicador visual pulsante que sinaliza "toque para continuar"
class _PulsingTapHint extends StatefulWidget {
  @override
  State<_PulsingTapHint> createState() => _PulsingTapHintState();
}

class _PulsingTapHintState extends State<_PulsingTapHint>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _pulse,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.textMuted, width: 1),
            ),
            child: const Icon(Icons.touch_app_outlined,
                color: AppColors.textMuted, size: 16),
          ),
        ],
      ),
    );
  }
}

