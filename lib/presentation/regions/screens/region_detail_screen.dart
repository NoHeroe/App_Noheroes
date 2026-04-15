import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/widgets/npc_dialog_overlay.dart';

class RegionDetailScreen extends ConsumerWidget {
  final Map<String, dynamic> region;
  const RegionDetailScreen({super.key, required this.region});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(region['color'] as int);
    final npcs = (region['npcs'] as List).cast<String>();
    final hasQuests = region['quests_available'] as bool? ?? false;
    final player = ref.watch(currentPlayerProvider);

    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header com gradiente
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.25),
                    AppColors.black,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: const Border(
                    bottom: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.go('/regions'),
                        child: const Icon(Icons.arrow_back_ios,
                            color: AppColors.textSecondary, size: 20),
                      ),
                      const Spacer(),
                      Icon(Icons.explore_outlined, color: color, size: 20),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(region['name'] as String,
                      style: GoogleFonts.cinzelDecorative(
                          fontSize: 20, color: color)),
                  const SizedBox(height: 4),
                  Text(region['subtitle'] as String,
                      style: GoogleFonts.roboto(
                          fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Descrição
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: color.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      region['description'] as String,
                      style: GoogleFonts.roboto(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.6,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // NPCs da região
                  _SectionTitle('NPCs PRESENTES', color),
                  const SizedBox(height: 8),
                  ...npcs.map((npc) => GestureDetector(
                        onTap: () => NpcDialogOverlay.show(
                          context,
                          npcName: npc,
                          npcTitle: 'Habitante de ${region['name']}',
                          message:
                              '"${_npcDialogue(npc, region['id'] as String)}"',
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: color.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: color.withValues(alpha: 0.1),
                                  border: Border.all(
                                      color:
                                          color.withValues(alpha: 0.4)),
                                ),
                                child: Icon(Icons.person_outline,
                                    color: color, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(npc,
                                    style: GoogleFonts.roboto(
                                        fontSize: 13,
                                        color: AppColors.textPrimary)),
                              ),
                              Icon(Icons.chat_bubble_outline,
                                  color: color.withValues(alpha: 0.6),
                                  size: 16),
                            ],
                          ),
                        ),
                      )),
                  const SizedBox(height: 16),

                  // Missões
                  _SectionTitle('MISSÕES', color),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          hasQuests
                              ? Icons.map_outlined
                              : Icons.hourglass_empty,
                          color: hasQuests ? color : AppColors.textMuted,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          hasQuests
                              ? 'Missões disponíveis nesta região.'
                              : 'Missões regionais chegam em breve.',
                          style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: hasQuests
                                  ? AppColors.textSecondary
                                  : AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Lore da região
                  _SectionTitle('LORE', color),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: color.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      _regionLore(region['id'] as String),
                      style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _SectionTitle(String title, Color color) => Row(
        children: [
          Container(width: 3, height: 14,
              decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title,
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 10, color: color, letterSpacing: 2)),
        ],
      );

  String _npcDialogue(String npc, String regionId) {
    const dialogues = {
      'Figura Desconhecida': 'Você chegou a Aureum. Isso é apenas o começo do que Caelum tem para mostrar.',
      'Noryan Gray': 'Aureum tem missões para aventureiros de todos os ranks. A Guilda opera aqui.',
      'Guardião das Ruínas': 'Essas ruínas guardam segredos que a maioria prefere ignorar. Você não é a maioria.',
      'Espírito da Floresta': 'A Floresta Branca não é hostil. Mas tampouco é amigável. Respeite-a.',
      'Andarilho do Vale': 'O Vale Estilhaçado não foi sempre assim. Algo o quebrou. Ninguém sabe o quê.',
    };
    return dialogues[npc] ?? 'Bem-vindo a esta região.';
  }

  String _regionLore(String id) {
    const lore = {
      'aureum': 'Os Campos de Aureum existem desde antes da Terceira Era. Dizem que foi aqui que o primeiro convocado despertou. O céu entre o dia e o crepúsculo não é natural — é um efeito residual de algo que aconteceu aqui há muito tempo.',
      'ruins': 'As Ruínas Exteriores são os únicos resquícios visíveis da civilização que existia em Caelum antes dos convocados chegarem. Arqueólogos da Nova Ordem estão constantemente catalogando o local. Ninguém sabe o que realmente encontraram.',
      'white_forest': 'A Floresta Branca recebe esse nome porque as árvores não produzem sombra. A luz entra, mas não atravessa o solo. Entidades que habitam a floresta não são classificadas em nenhum bestário conhecido.',
      'shattered_valley': 'O Vale Estilhaçado parece ter sido partido por uma força dimensional. Fragmentos de terra flutuam sem lógica gravitacional. Alguns exploram que é o resultado de uma Fenda que não fechou completamente.',
      'vallarys': 'Vallarys foi construída pelos Operadores dos Portais há séculos. É o único lugar em Caelum onde múltiplos portais dimensionais coexistem de forma estável. O preço dessa estabilidade é desconhecido.',
      'nova_draconis': 'Nova Draconis foi fundada após a Queda dos Quatro Clãs pelos Draconianos que sobreviveram. É um território hostil para estranhos, mas repleto de recursos que não existem em nenhuma outra região de Caelum.',
    };
    return lore[id] ?? 'Informações sobre esta região ainda não foram catalogadas.';
  }
}
