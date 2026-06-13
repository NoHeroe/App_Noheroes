import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Efeitos visuais de combate construídos sobre as texturas de partícula do
/// **Kenney Particle Pack (CC0)** — `assets/vfx/particles/`. São glows suaves
/// brancos, então tingimos por elemento via `BlendMode.modulate` e animamos
/// posição/escala/opacidade com flutter_animate.
///
/// Substitui os efeitos antigos desenhados na mão (CustomPaint de corte +
/// quadradinhos de morte + ícones do Material pra magia/flecha), que tinham
/// teto de qualidade baixo. Aqui o teto é a arte pré-renderizada do Kenney.
///
/// Slash de LÂMINA hand-painted (estilo Card Monsters) é um upgrade futuro com
/// sprite-sheet frame-a-frame (CraftPix/CartoonCoffee); este corte é um "arco
/// de energia" — já muito acima do risco anterior, mas honestamente não é uma
/// espada de aço desenhada quadro a quadro.
class CombatVfx {
  CombatVfx._();

  static const String _base = 'assets/vfx/particles';
  static const String slash = '$_base/slash_01.png';
  static const String magic = '$_base/magic_05.png';
  static const String light = '$_base/light_01.png';
  static const String flare = '$_base/flare_01.png';
  static const String spark = '$_base/spark_07.png';
  static const String star = '$_base/star_05.png';
  static const String smoke = '$_base/smoke_04.png';
  static const String scorch = '$_base/scorch_01.png';
  static const String trace = '$_base/trace_01.png';
  static const String circle = '$_base/circle_05.png';

  /// Espada (PNG tier 3, pasta weapons) usada no GOLPE melee — arte completa
  /// (não é glow tingível). Aponta pra NE (cabo embaixo-esq, ponta em cima-dir).
  static const String sword = 'assets/vfx/weapons/sword_tier3.png';

  /// Todas as texturas — usar pra `precacheImage` no início da partida e evitar
  /// engasgo no 1º efeito.
  static const List<String> all = <String>[
    slash, magic, light, flare, spark, star, smoke, scorch, trace, circle,
    sword,
  ];

  /// Uma textura tingida (glow branco → cor do elemento via modulate).
  static Widget tex(
    String path, {
    required double size,
    required Color color,
    BoxFit fit = BoxFit.contain,
  }) {
    return Image.asset(
      path,
      width: size,
      height: size,
      fit: fit,
      color: color,
      colorBlendMode: BlendMode.modulate,
      filterQuality: FilterQuality.medium,
    );
  }

  // ----------------------------------------------------------------- MORTE ---

  /// Morte da carta (CEO 2026-06-13): a carta vira P&B (grayscale, aplicado no
  /// tile) + trincas de VIDRO (ver [glassCrack]) e então ESTILHAÇA em cacos
  /// cinzas de formas IRREGULARES que voam radialmente e CAEM (gravidade),
  /// somindo — mesma técnica barata das partículas de missão (XP/ouro), porém em
  /// tons de cinza e em cacos. Tudo num único CustomPaint (pool reutilizado,
  /// RepaintBoundary). `delayMs` sincroniza com a chegada do golpe.
  static Widget deathShatter({double size = 96, int delayMs = 0}) {
    final d = Duration(milliseconds: delayMs);
    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Flash branco do vidro estourando.
            tex(flare, size: size * 0.9, color: Colors.white)
                .animate()
                .scaleXY(begin: 0.4, end: 1.25, delay: d, duration: 200.ms, curve: Curves.easeOut)
                .fadeIn(delay: d, duration: 40.ms)
                .fadeOut(delay: d + 120.ms, duration: 220.ms),
            // Estilhaços de vidro CINZA (formas irregulares) via pool.
            _DeathShatter(size: size, delayMs: delayMs),
          ],
        ),
      ),
    );
  }

  /// Trincas de vidro estáticas irradiando do centro — sobreposta na carta P&B no
  /// instante da morte (desenho único, `shouldRepaint=false`).
  static Widget glassCrack({double size = 96}) {
    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          size: Size(size, size),
          painter: _GlassCrackPainter(),
        ),
      ),
    );
  }

  // --------------------------------------------------------------- IMPACTO ---

  /// Impacto de um golpe no alvo: flash colorido + estrela + faíscas radiais.
  /// `delayMs` atrasa o burst até a chegada do projétil (mágico/à distância).
  static Widget impactBurst({
    double size = 78,
    required Color color,
    int delayMs = 0,
  }) {
    final d = Duration(milliseconds: delayMs);
    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            tex(flare, size: size, color: color)
                .animate()
                .scaleXY(begin: 0.3, end: 1.2, delay: d, duration: 170.ms, curve: Curves.easeOut)
                .fadeIn(delay: d, duration: 40.ms)
                .fadeOut(delay: d + 110.ms, duration: 190.ms),
            tex(star, size: size * 0.66, color: Colors.white)
                .animate()
                .scaleXY(begin: 0.2, end: 1.0, delay: d, duration: 200.ms, curve: Curves.easeOut)
                .fadeIn(delay: d, duration: 40.ms)
                .fadeOut(delay: d + 120.ms, duration: 200.ms),
            for (var i = 0; i < 5; i++)
              _spark(i, size, color, delay: d, count: 5),
          ],
        ),
      ),
    );
  }

  static Widget _spark(int i, double size, Color color,
      {Duration delay = Duration.zero, int count = 7}) {
    final ang = (i / count) * 2 * math.pi + 0.4;
    final dist = size * 0.52;
    return tex(spark, size: size * 0.18, color: color)
        .animate()
        .move(
            begin: Offset.zero,
            end: Offset(math.cos(ang) * dist, math.sin(ang) * dist),
            delay: delay,
            duration: 300.ms,
            curve: Curves.easeOut)
        .fadeIn(delay: delay, duration: 40.ms)
        .fadeOut(delay: delay + 120.ms, duration: 180.ms);
  }

  // ----------------------------------------------------------------- CORTE ---

  /// Arco de corte (melee): swoosh em crescente que entra rápido + faíscas no
  /// ponto de contato. `delayMs` sincroniza com o pico da investida do
  /// atacante (quando "encosta" no alvo). `flip` espelha pro lado do bot.
  static Widget slashArc({
    double size = 92,
    Color color = const Color(0xFFEDE7FF),
    int delayMs = 230,
    bool flip = false,
  }) {
    final d = Duration(milliseconds: delayMs);
    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Transform.rotate(
              angle: flip ? math.pi : 0,
              child: tex(slash, size: size, color: color),
            )
                .animate()
                .rotate(begin: -0.55, end: 0.2, delay: d, duration: 230.ms, curve: Curves.easeOut)
                .scaleXY(begin: 0.5, end: 1.3, delay: d, duration: 220.ms, curve: Curves.easeOut)
                .fadeIn(delay: d, duration: 60.ms)
                .fadeOut(delay: d + 170.ms, duration: 160.ms),
            for (var i = 0; i < 3; i++)
              _spark(i, size * 0.8, color, delay: d, count: 3),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------- ESPADA --

  /// GOLPE de ESPADA melee (CEO 2026-06-13): a espada (PNG tier 3) entra
  /// "armada" (recuada), desce num ARCO rápido cortando o alvo e some; faíscas
  /// no impacto. A carta atacante já AVANÇA (lunge) — isto é o golpe em si.
  /// `delayMs` casa com o pico da investida (quando "encosta"). `flip`=lado do
  /// BOT: espelha no eixo Y (golpe pra BAIXO, rumo ao jogador) em vez de pra cima.
  /// Ângulos/tamanho são tunáveis (1ª passada — CEO afina no flutter run).
  static Widget swordStrike({
    double size = 88,
    int delayMs = 240,
    bool flip = false,
  }) {
    final d = Duration(milliseconds: delayMs);
    const pivot = Alignment(-0.5, 0.55);
    // GIRO no CABO (só a ponta arca): arma (+0.20) e varre a meia-lua terminando
    // PRA FRENTE (rotações somam: 0.20 → -0.12). É SÓ rotação aqui — a VIAGEM é
    // aplicada POR FORA (no Stack abaixo). Crítico (CEO 2026-06-13): se a
    // translação ficasse DENTRO do giro, o avanço saía inclinado e a espada ia
    // "pro lado" em vez de pra frente.
    final blade = Image.asset(sword, width: size, height: size, fit: BoxFit.contain)
        .animate()
        .fadeIn(delay: d, duration: 60.ms)
        .rotate(
            begin: 0.0,
            end: 0.20,
            delay: d,
            duration: 300.ms,
            curve: Curves.easeOut,
            alignment: pivot)
        .rotate(
            begin: 0.0,
            end: -0.32,
            delay: d + 300.ms,
            duration: 200.ms,
            curve: Curves.easeInCubic,
            alignment: pivot)
        .scaleXY(
            begin: 1.0,
            end: 1.15,
            delay: d + 300.ms,
            duration: 200.ms,
            curve: Curves.easeIn)
        .fadeOut(delay: d + 540.ms, duration: 130.ms, curve: Curves.easeOut);
    // VIAGEM alinhada à TELA (por fora do giro): recuo curto pra trás (+y) e
    // ESTOCADA longa PRA FRENTE/cima (-y) rumo ao alvo. moves somam (2º começa em
    // 0): 0 → +56 (arma) → -174 (viaja). flipY espelha pro bot (golpe desce).
    final traveling = Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        blade,
        for (var i = 0; i < 4; i++)
          _spark(i, size * 0.85, const Color(0xFFFFF2CC),
              delay: d + 470.ms, count: 4),
      ],
    )
        .animate()
        .moveY(begin: 0, end: 56, delay: d, duration: 300.ms, curve: Curves.easeOut)
        .moveY(
            begin: 0,
            end: -230,
            delay: d + 300.ms,
            duration: 200.ms,
            curve: Curves.easeInCubic);
    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: Transform.flip(flipY: flip, child: traveling),
      ),
    );
  }

  // ------------------------------------------------------------ CORTE/IMPACTO -

  /// CORTE de impacto (CEO 2026-06-13): uma lâmina VERMELHA atravessa a carta na
  /// diagonal — de baixo-direita pra cima-esquerda, inclinada mais pro MEIO (mais
  /// vertical que 45°). Aparece num estalo no momento do impacto (junto do tremor)
  /// e some. Preenche o tile do alvo (usar em `Positioned.fill`).
  static Widget slashCut({int delayMs = 0}) {
    final d = Duration(milliseconds: delayMs);
    return IgnorePointer(
      child: CustomPaint(
        painter: _SlashCutPainter(),
        child: const SizedBox.expand(),
      )
          .animate()
          .fadeIn(delay: d, duration: 50.ms)
          .scaleXY(
              begin: 0.55,
              end: 1.0,
              delay: d,
              duration: 130.ms,
              curve: Curves.easeOutBack)
          .then(delay: 70.ms)
          .fadeOut(duration: 200.ms, curve: Curves.easeIn),
    );
  }

  // ------------------------------------------------------------- PROJÉTIL ----

  /// Orbe/streak que VIAJA do atacante ao alvo (mágico = orbe arcano; à
  /// distância = bolt/streak). `travel` é o vetor início→fim em px. A cauda
  /// (trace) segue atrás. Use dentro de um Stack ancorado no alvo.
  static Widget projectile({
    required Offset travel,
    required Color color,
    bool arrow = false,
    double size = 30,
    int durationMs = 260,
    int delayMs = 0,
  }) {
    final dur = Duration(milliseconds: durationMs);
    final d = Duration(milliseconds: delayMs);
    final angle = math.atan2(travel.dy, travel.dx) + math.pi / 2;
    final core = arrow ? trace : magic;
    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Cauda/rastro: streak alongado, orientado no sentido do voo.
          Transform.rotate(
            angle: angle,
            child: tex(trace, size: size * 1.5, color: color),
          )
              .animate()
              .move(begin: travel, end: Offset.zero, delay: d, duration: dur, curve: Curves.easeIn)
              .fadeIn(delay: d, duration: 50.ms)
              .fadeOut(delay: d + (durationMs - 40).ms, duration: 60.ms),
          // Núcleo do projétil.
          Transform.rotate(
            angle: arrow ? angle : 0,
            child: tex(core, size: arrow ? size * 0.9 : size, color: color),
          )
              .animate()
              .move(begin: travel, end: Offset.zero, delay: d, duration: dur, curve: Curves.easeIn)
              .fadeIn(delay: d, duration: 40.ms)
              .scaleXY(begin: 0.7, end: 1.05, delay: d, duration: dur),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- MAGIA --------

  /// CANALIZAÇÃO de magia no ATACANTE (CEO 2026-06-13 — teatral): um orbe
  /// arcano SURGE pequeno e CRESCE girando enquanto fica PARADO (carregando),
  /// com halo pulsando e faíscas orbitando, e então COLAPSA (libera) — o
  /// projétil sai logo depois. ~840ms.
  static Widget magicChannel({double size = 70, required Color color}) {
    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Halo de carga: cresce devagar e, no fim, estoura (libera).
            tex(light, size: size, color: color)
                .animate()
                .fadeIn(duration: 160.ms)
                .scaleXY(begin: 0.25, end: 1.15, duration: 640.ms, curve: Curves.easeOutCubic)
                .then()
                .scaleXY(begin: 1, end: 1.6, duration: 220.ms, curve: Curves.easeIn)
                .fadeOut(duration: 220.ms),
            // Núcleo arcano: gira e cresce (canalização), depois colapsa.
            tex(magic, size: size * 0.8, color: color)
                .animate()
                .fadeIn(duration: 120.ms)
                .scaleXY(begin: 0.3, end: 1.0, duration: 640.ms, curve: Curves.easeOutBack)
                .rotate(begin: 0, end: 0.7, duration: 640.ms)
                .then()
                .scaleXY(begin: 1, end: 1.7, duration: 200.ms, curve: Curves.easeIn)
                .fadeOut(duration: 200.ms),
            for (var i = 0; i < 3; i++) _channelSpark(i, size, color),
          ],
        ),
      ),
    );
  }

  static Widget _channelSpark(int i, double size, Color color) {
    final ang = (i / 3) * 2 * math.pi;
    final dist = size * 0.46;
    // Faíscas que vêm DE FORA pra dentro (sendo sugadas pra canalização) —
    // uma leva durante a carga (sem loop, pra não "entrar" depois do disparo).
    final stagger = (i * 70).ms;
    return tex(spark, size: size * 0.16, color: color)
        .animate()
        .move(
            begin: Offset(math.cos(ang) * dist, math.sin(ang) * dist),
            end: Offset.zero,
            delay: stagger,
            duration: 540.ms,
            curve: Curves.easeIn)
        .fadeIn(delay: stagger, duration: 100.ms)
        .fadeOut(delay: stagger + 380.ms, duration: 160.ms);
  }

  /// IMPACTO de magia no ALVO (exagerado): flash grande + ONDA DE CHOQUE
  /// (anel que expande) + estrela + muitas faíscas. `delayMs` = momento em que
  /// o projétil chega.
  static Widget magicImpact({
    double size = 104,
    required Color color,
    int delayMs = 0,
  }) {
    final d = Duration(milliseconds: delayMs);
    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Onda de choque: anel que estoura pra fora.
            tex(light, size: size, color: color)
                .animate()
                .scaleXY(begin: 0.2, end: 1.5, delay: d, duration: 360.ms, curve: Curves.easeOut)
                .fadeIn(delay: d, duration: 50.ms)
                .fadeOut(delay: d + 150.ms, duration: 280.ms),
            // Flash central forte.
            tex(flare, size: size * 0.95, color: Colors.white)
                .animate()
                .scaleXY(begin: 0.3, end: 1.3, delay: d, duration: 200.ms, curve: Curves.easeOut)
                .fadeIn(delay: d, duration: 40.ms)
                .fadeOut(delay: d + 140.ms, duration: 220.ms),
            tex(star, size: size * 0.7, color: color)
                .animate()
                .scaleXY(begin: 0.2, end: 1.1, delay: d, duration: 240.ms, curve: Curves.easeOut)
                .fadeIn(delay: d, duration: 40.ms)
                .fadeOut(delay: d + 150.ms, duration: 220.ms),
            for (var i = 0; i < 7; i++) _impactShard(i, size, color, d),
          ],
        ),
      ),
    );
  }

  static Widget _impactShard(int i, double size, Color color, Duration delay) {
    final ang = (i / 7) * 2 * math.pi + 0.2;
    final dist = size * 0.56;
    return tex(spark, size: size * 0.16, color: color)
        .animate()
        .move(
            begin: Offset.zero,
            end: Offset(math.cos(ang) * dist, math.sin(ang) * dist),
            delay: delay,
            duration: 380.ms,
            curve: Curves.easeOut)
        .fadeIn(delay: delay, duration: 40.ms)
        .fadeOut(delay: delay + 180.ms, duration: 200.ms);
  }
}

/// Pool de estilhaços de vidro (cinza) da morte de carta. Mesma técnica leve das
/// partículas de missão (XP/ouro): pool fixo, um único CustomPaint, controller que
/// roda UMA vez e some. Cacos de formas irregulares (não círculos), com gravidade.
class _DeathShatter extends StatefulWidget {
  const _DeathShatter({required this.size, this.delayMs = 0});
  final double size;
  final int delayMs;
  @override
  State<_DeathShatter> createState() => _DeathShatterState();
}

class _DeathShatterState extends State<_DeathShatter>
    with SingleTickerProviderStateMixin {
  static const int _count = 16;
  late final AnimationController _c;
  final math.Random _rand = math.Random();
  final List<_GlassShard> _shards = <_GlassShard>[];
  Duration _last = Duration.zero;
  bool _started = false; // cacos só aparecem no ESTOURO (após delayMs)

  @override
  void initState() {
    super.initState();
    _spawn();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..addListener(_tick);
    if (widget.delayMs > 0) {
      Future<void>.delayed(Duration(milliseconds: widget.delayMs), () {
        if (!mounted) return;
        setState(() => _started = true); // revela e dispara o estouro
        _c.forward();
      });
    } else {
      _started = true;
      _c.forward();
    }
  }

  void _spawn() {
    final s = widget.size;
    for (var i = 0; i < _count; i++) {
      final ang = (i / _count) * 2 * math.pi + (_rand.nextDouble() - 0.5) * 0.7;
      // Voam LONGE (CEO 2026-06-13): velocidade inicial bem maior + impulso pra
      // cima mais forte (espalha melhor); a gravidade puxa de volta como vidro.
      final speed = s * (1.7 + _rand.nextDouble() * 2.1); // 1.7..3.8
      final gray = 150 + _rand.nextInt(95); // 150..244
      _shards.add(_GlassShard(
        vx: math.cos(ang) * speed,
        vy: math.sin(ang) * speed - s * 0.7, // impulso pra cima
        rot: _rand.nextDouble() * math.pi,
        rotVel: (_rand.nextDouble() - 0.5) * 11,
        radius: s * (0.05 + _rand.nextDouble() * 0.07),
        sides: 3 + _rand.nextInt(3), // 3..5 lados
        seed: _rand.nextInt(1 << 20),
        color: Color.fromARGB(255, gray, gray, gray),
      ));
    }
  }

  void _tick() {
    if (!mounted) return; // não chama setState depois de desmontar
    final now = _c.lastElapsedDuration ?? Duration.zero;
    final dt = ((now - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = now;
    final gravity = widget.size * 1.9; // menos puxão = carrega mais longe
    for (final sh in _shards) {
      sh.x += sh.vx * dt;
      sh.y += sh.vy * dt;
      sh.vy += gravity * dt; // cai como caco de vidro
      sh.rot += sh.rotVel * dt;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _c.removeListener(_tick);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Antes do estouro (durante o "hold" da carta trincada) NÃO desenha nada —
    // evita um amontoado de cacos parados no centro do tile (CEO 2026-06-13).
    if (!_started) return const SizedBox.shrink();
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _GlassShardPainter(_shards, _c.value),
        ),
      ),
    );
  }
}

class _GlassShard {
  _GlassShard({
    required this.vx,
    required this.vy,
    required this.rot,
    required this.rotVel,
    required double radius,
    required int sides,
    required int seed,
    required this.color,
  }) : path = _buildPath(sides, radius, seed);

  double x = 0;
  double y = 0;
  double vx;
  double vy;
  double rot;
  final double rotVel;
  final Color color;
  // Forma irregular pré-computada UMA vez (determinística por seed) — não é
  // reconstruída a cada frame (perf, CEO 2026-06-13).
  final Path path;

  static Path _buildPath(int sides, double radius, int seed) {
    final rnd = math.Random(seed);
    final path = Path();
    for (var i = 0; i < sides; i++) {
      final a = (i / sides) * 2 * math.pi;
      final r = radius * (0.55 + rnd.nextDouble() * 0.8); // raio irregular
      final x = math.cos(a) * r;
      final y = math.sin(a) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }
}

class _GlassShardPainter extends CustomPainter {
  _GlassShardPainter(this.shards, this.t);
  final List<_GlassShard> shards;
  final double t; // 0..1 progresso (some no fim)

  @override
  void paint(Canvas canvas, Size size) {
    final alpha = (1.0 - t * t).clamp(0.0, 1.0);
    if (alpha <= 0.01) return;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final fill = Paint()..style = PaintingStyle.fill;
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Colors.white.withValues(alpha: alpha * 0.45);
    for (final sh in shards) {
      canvas
        ..save()
        ..translate(cx + sh.x, cy + sh.y)
        ..rotate(sh.rot);
      fill.color = sh.color.withValues(alpha: alpha * 0.9);
      canvas
        ..drawPath(sh.path, fill)
        ..drawPath(sh.path, edge)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_GlassShardPainter old) =>
      old.t != t || !identical(old.shards, shards);
}

/// Trincas de vidro: linhas brancas irradiando do centro + ramos. Desenho único.
class _GlassCrackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = math.min(size.width, size.height) / 2 * 0.95;
    final rand = math.Random(42); // padrão fixo de trincas
    for (var i = 0; i < 7; i++) {
      final ang = (i / 7) * 2 * math.pi + rand.nextDouble() * 0.3;
      final innerR = radius * 0.18;
      final x1 = cx + math.cos(ang) * innerR;
      final y1 = cy + math.sin(ang) * innerR;
      final x2 = cx + math.cos(ang) * radius;
      final y2 = cy + math.sin(ang) * radius;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
      final branches = 1 + rand.nextInt(2);
      for (var j = 0; j < branches; j++) {
        final mid = 0.4 + rand.nextDouble() * 0.4;
        final mx = cx + math.cos(ang) * radius * mid;
        final my = cy + math.sin(ang) * radius * mid;
        final bAng = ang + (rand.nextDouble() - 0.5) * 1.1;
        final bLen = radius * (0.2 + rand.nextDouble() * 0.25);
        canvas.drawLine(
          Offset(mx, my),
          Offset(mx + math.cos(bAng) * bLen, my + math.sin(bAng) * bLen),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_GlassCrackPainter old) => false;
}

/// Lâmina VERMELHA do CORTE de impacto: 3 traços (glow + núcleo + núcleo quente)
/// na diagonal baixo-direita → cima-esquerda, inclinada mais pro MEIO da carta
/// (mais vertical que 45°). Desenho único (`shouldRepaint=false`); o fade/escala
/// ficam no widget.
class _SlashCutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    // Direção do corte (aponta pra cima-esquerda): |y| > |x| ⇒ mais vertical que
    // 45°, virado pro meio da carta.
    const dir = Offset(-0.5, -1.0);
    final dn = dir / dir.distance;
    final half = size.height * 0.55; // atravessa a carta (vertical)
    final p1 = c + dn * half; // ponta cima-esquerda
    final p2 = c - dn * half; // ponta baixo-direita
    final w = size.shortestSide;
    void stroke(Color color, double width, [double blur = 0]) {
      final p = Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round;
      if (blur > 0) p.maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
      canvas.drawLine(p1, p2, p);
    }

    stroke(const Color(0x88FF1E12), w * 0.16, 7); // glow vermelho
    stroke(const Color(0xFFFF2D1F), w * 0.06); // núcleo vermelho
    stroke(const Color(0xFFFFE2DC), w * 0.02); // núcleo quente
  }

  @override
  bool shouldRepaint(_SlashCutPainter old) => false;
}
