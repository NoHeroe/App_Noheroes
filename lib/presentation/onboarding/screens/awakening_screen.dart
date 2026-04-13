import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';

class AwakeningScreen extends ConsumerStatefulWidget {
  const AwakeningScreen({super.key});

  @override
  ConsumerState<AwakeningScreen> createState() => _AwakeningScreenState();
}

class _AwakeningScreenState extends ConsumerState<AwakeningScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bgCtrl;
  late final AnimationController _textCtrl;
  late final Animation<double> _bgFade;
  late final Animation<double> _textFade;

  int _currentPage = 0;
  final _nameCtrl = TextEditingController();
  String _narrativeMode = 'longa';
  String? _selectedHabit;
  bool _canAdvance = false;

  // Hábitos disponíveis: (label, emoji, categoria)
  final _habits = [
    ('Hidratação', '💧', 'spiritual'),
    ('Treino',     '⚔️', 'physical'),
    ('Leitura',    '📖', 'mental'),
    ('Meditação',  '🌑', 'spiritual'),
    ('Escrita',    '✍️', 'mental'),
    ('Sono',       '🌙', 'spiritual'),
  ];

  final List<_Scene> _scenes = [
    _Scene(npc: null,
        text: 'Você desperta entre ruínas antigas…\n\nA luz do céu parece quebrada.\n\nHá algo errado com seu corpo.',
        mood: _Mood.ruins),
    _Scene(npc: 'Figura Desconhecida',
        text: '"Venha.\n\nSe ficar aí, o Vazio coleta você."',
        mood: _Mood.npc),
    _Scene(npc: 'Figura Desconhecida',
        text: '"Você não é de Caelum."\n\n"Sua forma aqui é uma Sombra."\n\n"Ainda está instável."\n\n"Se quiser sobreviver, vai precisar aprender rápido."',
        mood: _Mood.npc),
    _Scene(npc: 'O Vazio',
        text: '"Caelum só reage à disciplina.\n\nE sua forma sombra é moldada pelo que você faz no outro mundo."',
        mood: _Mood.identity),
    _Scene(npc: 'O Vazio',
        text: 'Como deseja ser chamado?\n\nEsse nome dará forma à sua Sombra em Caelum.',
        mood: _Mood.identity,
        isNameInput: true),
    _Scene(npc: null,
        text: 'Como prefere receber as mensagens de Caelum?',
        mood: _Mood.identity,
        isNarrativeChoice: true),
    _Scene(npc: 'Figura Desconhecida',
        text: '"Todo ser em Caelum tem um ritual.\n\nNão é uma tarefa — é um pacto.\n\nEscolha o que você se compromete a honrar."',
        mood: _Mood.ritual,
        isHabitChoice: true),
  ];

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _bgFade = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeIn);
    _textFade = CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn);
    _bgCtrl.forward().then((_) {
      _textCtrl.forward().then((_) => setState(() => _canAdvance = true));
    });
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _textCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _advance() async {
    if (!_canAdvance) return;

    final scene = _scenes[_currentPage];

    if (scene.isNameInput && _nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Dê um nome à sua Sombra.'),
        backgroundColor: AppColors.shadowChaotic,
      ));
      return;
    }

    if (scene.isHabitChoice && _selectedHabit == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Escolha seu primeiro ritual.'),
        backgroundColor: AppColors.shadowChaotic,
      ));
      return;
    }

    if (_currentPage >= _scenes.length - 1) {
      await _finishOnboarding();
      return;
    }

    setState(() => _canAdvance = false);
    await _textCtrl.reverse();
    setState(() => _currentPage++);
    await _textCtrl.forward();
    setState(() => _canAdvance = true);
  }

  Future<void> _finishOnboarding() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) {
      if (mounted) context.go('/sanctuary');
      return;
    }

    final ds = ref.read(authDsProvider);

    // Salva onboarding
    await ds.completeOnboarding(
      player.id,
      _nameCtrl.text.trim().isEmpty ? 'Sombra' : _nameCtrl.text.trim(),
      _narrativeMode,
    );

    // Salva o hábito escolhido como ritual diário
    if (_selectedHabit != null) {
      final habitData = _habits.firstWhere((h) => h.$1 == _selectedHabit);
      await ds.createInitialHabit(
        player.id,
        habitData.$1,
        habitData.$3,
      );
    }

    // Atualiza provider
    final updated = await ds.currentSession();
    if (mounted) {
      ref.read(currentPlayerProvider.notifier).state = updated;
      context.go('/sanctuary');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scene = _scenes[_currentPage];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          FadeTransition(opacity: _bgFade, child: _SceneBg(mood: scene.mood)),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.92),
                ],
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _textFade,
              child: Column(
                children: [
                  // Progress bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: Row(
                      children: List.generate(_scenes.length, (i) => Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          color: i <= _currentPage
                              ? AppColors.purple
                              : AppColors.border,
                        ),
                      )),
                    ),
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (scene.npc != null) ...[
                            Text(scene.npc!.toUpperCase(),
                                style: GoogleFonts.cinzelDecorative(
                                    fontSize: 11,
                                    color: AppColors.gold,
                                    letterSpacing: 2)),
                            const SizedBox(height: 12),
                          ],
                          Text(scene.text,
                              style: GoogleFonts.roboto(
                                  fontSize: 18,
                                  color: AppColors.textPrimary,
                                  height: 1.8,
                                  fontStyle: scene.npc != null
                                      ? FontStyle.italic
                                      : FontStyle.normal)),
                          const SizedBox(height: 32),
                          if (scene.isNameInput) _buildNameInput(),
                          if (scene.isNarrativeChoice) _buildNarrativeChoice(),
                          if (scene.isHabitChoice) _buildHabitChoice(),
                        ],
                      ),
                    ),
                  ),

                  // Botão avançar (não aparece na cena de hábito — o tap no hábito avança)
                  if (!scene.isHabitChoice)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
                      child: GestureDetector(
                        onTap: _advance,
                        child: Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _canAdvance
                                  ? AppColors.purple
                                  : AppColors.border,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: _canAdvance
                                ? AppColors.purple.withOpacity(0.15)
                                : Colors.transparent,
                          ),
                          child: Center(
                            child: Text('Continuar',
                                style: GoogleFonts.cinzelDecorative(
                                    fontSize: 14,
                                    color: _canAdvance
                                        ? AppColors.textPrimary
                                        : AppColors.textMuted,
                                    letterSpacing: 1.5)),
                          ),
                        ),
                      ),
                    ),

                  // Na cena de hábito, mostra botão Despertar após seleção
                  if (scene.isHabitChoice && _selectedHabit != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
                      child: GestureDetector(
                        onTap: _advance,
                        child: Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.purple),
                            borderRadius: BorderRadius.circular(12),
                            color: AppColors.purple.withOpacity(0.15),
                          ),
                          child: Center(
                            child: Text('Despertar',
                                style: GoogleFonts.cinzelDecorative(
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                    letterSpacing: 1.5)),
                          ),
                        ),
                      ),
                    ),

                  if (scene.isHabitChoice && _selectedHabit == null)
                    const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameInput() {
    return TextField(
      controller: _nameCtrl,
      style: GoogleFonts.cinzelDecorative(
          color: AppColors.textPrimary, fontSize: 16),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: 'Nome da sua Sombra',
        hintStyle: GoogleFonts.roboto(color: AppColors.textMuted),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.purple)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.purple, width: 1.5)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border)),
      ),
    );
  }

  Widget _buildNarrativeChoice() {
    return Column(
      children: ['longa', 'curta'].map((mode) {
        final selected = _narrativeMode == mode;
        return GestureDetector(
          onTap: () => setState(() => _narrativeMode = mode),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                  color: selected ? AppColors.purple : AppColors.border,
                  width: selected ? 1.5 : 1),
              borderRadius: BorderRadius.circular(12),
              color: selected
                  ? AppColors.purple.withOpacity(0.1)
                  : Colors.transparent,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    mode == 'longa'
                        ? 'Narrativa Completa'
                        : 'Narrativa Direta',
                    style: GoogleFonts.cinzelDecorative(
                        fontSize: 13,
                        color: selected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                    mode == 'longa'
                        ? 'Imersão total. Caelum fala com profundidade.'
                        : 'Objetivo e direto. Menos texto, mais ação.',
                    style: GoogleFonts.roboto(
                        fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHabitChoice() {
    return Column(
      children: _habits.map((h) {
        final selected = _selectedHabit == h.$1;
        return GestureDetector(
          onTap: () => setState(() => _selectedHabit = h.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(
                  color: selected
                      ? AppColors.gold
                      : AppColors.border,
                  width: selected ? 1.5 : 1),
              borderRadius: BorderRadius.circular(12),
              color: selected
                  ? AppColors.gold.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.03),
            ),
            child: Row(
              children: [
                Text(h.$2, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(h.$1,
                          style: GoogleFonts.cinzelDecorative(
                              fontSize: 13,
                              color: selected
                                  ? AppColors.gold
                                  : AppColors.textPrimary)),
                      Text(_habitDesc(h.$1),
                          style: GoogleFonts.roboto(
                              fontSize: 11,
                              color: AppColors.textMuted)),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle,
                      color: AppColors.gold, size: 20),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _habitDesc(String habit) => switch (habit) {
    'Hidratação' => 'Beber água conscientemente todos os dias',
    'Treino'     => 'Mover o corpo com intenção e disciplina',
    'Leitura'    => 'Expandir a mente através do conhecimento',
    'Meditação'  => 'Silenciar o ruído interno diariamente',
    'Escrita'    => 'Registrar pensamentos e experiências',
    'Sono'       => 'Honrar o descanso como parte da jornada',
    _            => '',
  };
}

class _Scene {
  final String? npc;
  final String text;
  final _Mood mood;
  final bool isNameInput;
  final bool isNarrativeChoice;
  final bool isHabitChoice;

  const _Scene({
    required this.npc,
    required this.text,
    required this.mood,
    this.isNameInput = false,
    this.isNarrativeChoice = false,
    this.isHabitChoice = false,
  });
}

enum _Mood { ruins, npc, identity, ritual }

class _SceneBg extends StatefulWidget {
  final _Mood mood;
  const _SceneBg({super.key, required this.mood});

  @override
  State<_SceneBg> createState() => _SceneBgState();
}

class _SceneBgState extends State<_SceneBg>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _BgPainter(mood: widget.mood, t: _ctrl.value),
        child: Container(),
      ),
    );
  }
}

class _BgPainter extends CustomPainter {
  final _Mood mood;
  final double t;
  _BgPainter({required this.mood, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    switch (mood) {
      case _Mood.ruins:
        _bg(canvas, size, paint,
            const Color(0xFF0A0015), const Color(0xFF1A0A2E));
        _fragments(canvas, size, paint);
        break;
      case _Mood.npc:
        _bg(canvas, size, paint,
            const Color(0xFF0D0010), const Color(0xFF120820));
        _glow(canvas, size, paint, const Color(0xFF4A1080));
        break;
      case _Mood.identity:
        _bg(canvas, size, paint,
            const Color(0xFF080010), const Color(0xFF0F0520));
        _glow(canvas, size, paint, const Color(0xFF7C3AED));
        _gold(canvas, size, paint);
        break;
      case _Mood.ritual:
        _bg(canvas, size, paint,
            const Color(0xFF0A0005), const Color(0xFF1A0530));
        _glow(canvas, size, paint, const Color(0xFF8B3DFF));
        _gold(canvas, size, paint);
        break;
    }
  }

  void _bg(Canvas c, Size s, Paint p, Color top, Color bot) {
    p.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [top, bot],
    ).createShader(Offset.zero & s);
    c.drawRect(Offset.zero & s, p);
    p.shader = null;
  }

  void _fragments(Canvas c, Size s, Paint p) {
    p.color = const Color(0xFF3D1F6E).withOpacity(0.4 + t * 0.2);
    p.strokeWidth = 1.5;
    p.style = PaintingStyle.stroke;
    final lines = [
      [Offset(0, s.height * 0.15), Offset(s.width * 0.4, s.height * 0.12)],
      [Offset(s.width * 0.4, s.height * 0.12), Offset(s.width * 0.7, s.height * 0.18)],
      [Offset(s.width * 0.7, s.height * 0.18), Offset(s.width, s.height * 0.14)],
    ];
    for (final l in lines) c.drawLine(l[0], l[1], p);
    p.style = PaintingStyle.fill;
    p.color = const Color(0xFF8B3DFF).withOpacity(0.3 + t * 0.3);
    for (final l in lines) c.drawCircle(l[0], 2 + t * 1.5, p);
  }

  void _glow(Canvas c, Size s, Paint p, Color color) {
    p.maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
    p.color = color.withOpacity(0.15 + t * 0.08);
    c.drawCircle(Offset(s.width * .5, s.height * .35), s.width * .6, p);
    p.maskFilter = null;
  }

  void _gold(Canvas c, Size s, Paint p) {
    p.maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    p.color = const Color(0xFFC2A05A).withOpacity(0.06 + t * 0.04);
    c.drawCircle(Offset(s.width * .8, s.height * .7), s.width * .4, p);
    p.maskFilter = null;
  }

  @override
  bool shouldRepaint(covariant _BgPainter o) =>
      o.t != t || o.mood != mood;
}
