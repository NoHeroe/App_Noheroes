import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/item_equip_policy.dart';
import '../../../domain/models/player_snapshot.dart';
import '../../../domain/models/shop_spec.dart';
import '../../shared/widgets/nh_medallion.dart';
import '../../shared/widgets/app_snack.dart';
import '../widgets/market_atmosphere.dart';

// Tela /shops — o MERCADO. Sem header/recursos: só um botão de voltar e os
// medalhões redondos (padrão da Biblioteca). Lojas inacessíveis aparecem
// bloqueadas com cadeado (sem texto de requisito — aviso vem no toque).
//
// Carrega via FutureProvider reativo (ref.watch) em vez de FutureBuilder
// manual: sobrevive a rebuilds da transição do GoRouter e re-roda quando o
// player carrega/muda.
class ShopsListScreen extends ConsumerWidget {
  const ShopsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medsAsync = ref.watch(_marketMedallionsProvider);
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          const MarketAtmosphere(),
          SafeArea(
            child: Column(
              children: [
                _backButton(context),
                Expanded(
                  child: medsAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.gold),
                    ),
                    error: (e, _) => _error(context, '$e'),
                    data: (meds) =>
                        meds.isEmpty ? _empty() : _grid(context, meds),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Header mínimo: só o botão de voltar (sem título, sem recursos).
  Widget _backButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/sanctuary'),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2A1B12), Color(0xFF0B0705)],
                ),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: AppColors.goldLt, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  // Medalhões redondos dispersos (padrão da Biblioteca), em fileiras de 2 com
  // leve escalonamento vertical pra dar organicidade.
  Widget _grid(BuildContext context, List<_ShopMed> meds) {
    final rows = <Widget>[];
    for (var i = 0; i < meds.length; i += 2) {
      final left = meds[i];
      final right = (i + 1 < meds.length) ? meds[i + 1] : null;
      rows.add(Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 0),
            child: _medallion(context, left),
          ),
          if (right != null)
            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: _medallion(context, right),
            )
          else
            const SizedBox(width: 92),
        ],
      ));
      if (i + 2 < meds.length) rows.add(const SizedBox(height: 30));
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: rows),
      ),
    );
  }

  Widget _medallion(BuildContext context, _ShopMed med) {
    return NhMedallion(
      label: med.label,
      icon: med.icon,
      size: 84,
      locked: med.locked,
      badge: med.badge,
      onTap: () {
        if (med.locked) {
          AppSnack.warning(
              context, med.lockMsg ?? 'Esta loja ainda não está disponível.');
        } else if (med.key != null) {
          context.go('/shop/${med.key}');
        }
      },
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_outlined,
                color: AppColors.gold.withValues(alpha: 0.4), size: 44),
            const SizedBox(height: 16),
            Text('Nenhuma loja por aqui.',
                textAlign: TextAlign.center,
                style: GoogleFonts.cinzelDecorative(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    letterSpacing: 2)),
          ],
        ),
      ),
    );
  }

  Widget _error(BuildContext context, String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.hp, size: 40),
            const SizedBox(height: 12),
            Text('Não foi possível carregar o mercado.',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                    fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text(msg,
                textAlign: TextAlign.center,
                style: GoogleFonts.robotoMono(
                    fontSize: 9, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

/// Constrói os medalhões do mercado de forma reativa. Re-roda quando o player
/// carrega/muda (StateProvider). Lojas gerais → Guilda → Facção (só a do
/// jogador; genérica bloqueada se sem facção).
final _marketMedallionsProvider =
    FutureProvider.autoDispose<List<_ShopMed>>((ref) async {
  final player = ref.watch(currentPlayerProvider);
  final service = ref.read(shopsServiceProvider);
  final all = await service.listShops();

  Set<String> availableKeys = const {};
  if (player != null) {
    final snapshot = PlayerSnapshot(
      level: player.level,
      rank: ItemEquipPolicy.parseRank(player.guildRank),
      classKey: player.classType,
      factionKey: player.factionType,
    );
    final available = await service.listShopsAvailableTo(snapshot);
    availableKeys = available.map((s) => s.key).toSet();
  }

  final level = player?.level ?? 0;
  final faction = player?.factionType;
  final hasFaction = faction != null && faction.isNotEmpty && faction != 'none';

  ShopSpec? firstWhere(bool Function(ShopSpec) test) {
    for (final s in all) {
      if (test(s)) return s;
    }
    return null;
  }

  final meds = <_ShopMed>[];

  // Lojas gerais (na ordem do JSON). Algumas têm gate de NÍVEL (espelha o
  // LevelLockedView da própria tela da loja) — aí o cadeado mostra o nível.
  for (final s in all.where((s) => s.type == 'general')) {
    final reqLvl = _shopLevelGate[s.key] ?? 0;
    final levelLocked = level < reqLvl;
    meds.add(_ShopMed(
      key: s.key,
      label: _labelFor(s.key, s.name),
      icon: _iconFor(s.key),
      locked: levelLocked || !availableKeys.contains(s.key),
      badge: levelLocked ? 'NÍVEL $reqLvl' : null,
      lockMsg: levelLocked ? 'O ${s.name} abre no Nível $reqLvl.' : null,
    ));
  }

  // Loja da Guilda.
  final guild = firstWhere((s) => s.type == 'guild');
  if (guild != null) {
    meds.add(_ShopMed(
      key: guild.key,
      label: 'Guilda',
      icon: Icons.shield_outlined,
      locked: !availableKeys.contains(guild.key),
      lockMsg: 'A Loja da Guilda abre quando você entra na Guilda.',
    ));
  }

  // Loja de Facção — só a do jogador; genérica bloqueada se sem facção.
  if (hasFaction) {
    final fs = firstWhere(
        (s) => s.type == 'faction' && s.acceptedFactions.contains(faction));
    if (fs != null) {
      meds.add(_ShopMed(
        key: fs.key,
        label: 'Facção',
        icon: Icons.flag_outlined,
        locked: !availableKeys.contains(fs.key),
      ));
    }
  } else {
    meds.add(const _ShopMed(
      key: null,
      label: 'Facção',
      icon: Icons.flag_outlined,
      locked: true,
      lockMsg: 'Entre numa facção para acessar a loja de facção.',
    ));
  }

  return meds;
});

/// Gates de NÍVEL por loja (espelha os checks hardcoded nas telas das lojas —
/// ver LevelLockedView em shop_screen.dart). Loja sem entrada aqui = nível 0.
const Map<String, int> _shopLevelGate = {
  'blacksmith_aureum': 6, // Ferreiro de Aureum — Sprint 2.3 Bloco 0.B.
};

String _labelFor(String key, String fallback) {
  if (key.startsWith('blacksmith')) return 'Ferreiro';
  if (key.startsWith('general_store')) return 'Mercearia';
  return fallback;
}

IconData _iconFor(String key) {
  if (key.startsWith('blacksmith')) return Icons.hardware;
  if (key.startsWith('general_store')) return Icons.storefront_outlined;
  return Icons.store_outlined;
}

/// Spec de um medalhão de loja no mercado.
class _ShopMed {
  final String? key; // null = placeholder (loja de facção sem facção)
  final String label;
  final IconData icon;
  final bool locked;
  final String? lockMsg;
  final String? badge; // selo (ex.: 'NÍVEL 6') quando travado por nível.

  const _ShopMed({
    required this.key,
    required this.label,
    required this.icon,
    required this.locked,
    this.lockMsg,
    this.badge,
  });
}
