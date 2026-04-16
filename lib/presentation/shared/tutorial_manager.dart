import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/datasources/local/tutorial_service.dart';
import 'widgets/npc_dialog_overlay.dart';
import 'widgets/milestone_popup.dart';

/// Dispara diálogos de tutorial em sequência.
/// Cada fase é mostrada uma única vez (flag no SharedPreferences).
class TutorialManager {

  // ── FASE 1 — Santuário (nível 1) ──────────────────────────────────────────
  static Future<void> phase1Sanctuary(BuildContext ctx) async {
    if (!await TutorialService.shouldShow(TutorialPhase.phase1_sanctuary)) return;
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'Figura Desconhecida',
      npcTitle: 'Seu guia em Caelum',
      message: 'Este é o Santuário. Aqui você acompanha sua jornada, completa missões e acessa tudo que Caelum oferece.',
    );
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'Figura Desconhecida',
      npcTitle: 'Seu guia em Caelum',
      message: 'Vá até MISSÕES e complete seu primeiro hábito diário. Cada missão completada fortalece sua forma aqui.',
    );
    await TutorialService.markDone(TutorialPhase.phase1_sanctuary);
  }

  // ── FASE 2 — Biblioteca + Atributos (nível 2) ────────────────────────────
  static Future<void> phase2Library(BuildContext ctx) async {
    if (!await TutorialService.shouldShow(TutorialPhase.phase2_library)) return;
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'Figura Desconhecida',
      npcTitle: 'Seu guia em Caelum',
      message: 'A Biblioteca de Caelum está desbloqueada. Ali você pode registrar seu Diário — cada palavra escrita alimenta sua forma.',
    );
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'Figura Desconhecida',
      npcTitle: 'Seu guia em Caelum',
      message: 'Você subiu de nível. Acesse o Personagem — há pontos de atributo disponíveis. Cada ponto melhora suas estatísticas permanentemente.',
    );
    await TutorialService.markDone(TutorialPhase.phase2_library);
  }

  // ── FASE 3 — Loja + Itens (nível 3) ─────────────────────────────────────
  static Future<void> phase3Shop(BuildContext ctx) async {
    if (!await TutorialService.shouldShow(TutorialPhase.phase3_shop)) return;
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'Figura Desconhecida',
      npcTitle: 'Seu guia em Caelum',
      message: 'A Loja está disponível. Com ouro acumulado em missões você pode comprar equipamentos, consumíveis e materiais.',
    );
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'Figura Desconhecida',
      npcTitle: 'Seu guia em Caelum',
      message: 'Itens equipados aparecem nos slots do seu Personagem. Eles adicionam bônus reais aos seus atributos e estatísticas.',
    );
    await TutorialService.markDone(TutorialPhase.phase3_shop);
  }

  // ── FASE 4 — Regiões (nível 4) ────────────────────────────────────────────
  static Future<void> phase4Regions(BuildContext ctx) async {
    if (!await TutorialService.shouldShow(TutorialPhase.phase4_regions)) return;
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'Figura Desconhecida',
      npcTitle: 'Seu guia em Caelum',
      message: 'As Regiões de Caelum estão abertas. São áreas de exploração onde você descobre NPCs, tesouros e missões extras.',
    );
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'Figura Desconhecida',
      npcTitle: 'Seu guia em Caelum',
      message: 'Explorar regiões também aumenta reputação com NPCs e facções — e desbloqueia partes da história de Caelum.',
    );
    await TutorialService.markDone(TutorialPhase.phase4_regions);
  }

  // ── FASE 5 — Classe + Missões de Classe (nível 5) ─────────────────────────
  static Future<void> phase5Class(BuildContext ctx) async {
    if (!await TutorialService.shouldShow(TutorialPhase.phase5_class)) return;
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'Figura Desconhecida',
      npcTitle: 'Seu guia em Caelum',
      message: 'Sua forma está pronta para assumir um caminho. A classe define seus atributos, missões diárias e como Caelum te enxerga.',
    );
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'Figura Desconhecida',
      npcTitle: 'Seu guia em Caelum',
      message: 'Classes que usam Mana dominam magia arcana. Classes com Vitalismo vão além — causam dano vitalista além do mágico. A escolha muda seu estilo para sempre.',
    );
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'Figura Desconhecida',
      npcTitle: 'Seu guia em Caelum',
      message: 'Após escolher sua classe, 3 Missões de Classe aparecerão todos os dias automaticamente. Elas se completam sozinhas conforme você age.',
    );
    await TutorialService.markDone(TutorialPhase.phase5_class);
  }

  // ── FASE 6 — Guilda (nível 6) ─────────────────────────────────────────────
  static Future<void> phase6Guild(BuildContext ctx) async {
    if (!await TutorialService.shouldShow(TutorialPhase.phase6_guild)) return;
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'Noryan Gray',
      npcTitle: 'Mestre da Guilda',
      message: 'A Guilda de Aventureiros está aberta para você. Aqui você sobe de Rank completando o Teste de Ascensão — missões encadeadas de alta dificuldade.',
    );
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'Noryan Gray',
      npcTitle: 'Mestre da Guilda',
      message: 'As Missões da Guilda ainda estão bloqueadas — chegam em uma atualização futura com o sistema de batalha. Por enquanto, foque no Teste de Ascensão.',
    );
    await TutorialService.markDone(TutorialPhase.phase6_guild);
  }

  // ── FASE 7 — Facções (nível 7) ────────────────────────────────────────────
  static Future<void> phase7Factions(BuildContext ctx) async {
    if (!await TutorialService.shouldShow(TutorialPhase.phase7_faction)) return;
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'Figura Desconhecida',
      npcTitle: 'Seu guia em Caelum',
      message: 'As 8 Facções de Caelum abriram suas portas. Cada uma tem sua filosofia, bônus, missões exclusivas e NPCs próprios.',
    );
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'Figura Desconhecida',
      npcTitle: 'Seu guia em Caelum',
      message: 'Não é obrigatório escolher uma facção. O Caminho do Lobo Solitário existe para quem prefere caminhar sem alianças — por ora.',
    );
    await TutorialService.markDone(TutorialPhase.phase7_faction);
  }

  // ── FASE 8 — Shadow Boss (nível 10) ───────────────────────────────────────
  static Future<void> phase8Shadow(BuildContext ctx) async {
    if (!await TutorialService.shouldShow(TutorialPhase.phase8_shadow)) return;
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'Figura Desconhecida',
      npcTitle: 'Seu guia em Caelum',
      message: 'Algo surgiu das suas próprias falhas e excessos. Isso é um Shadow Boss — a forma mais verdadeira do seu erro em Caelum.',
    );
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'Figura Desconhecida',
      npcTitle: 'Seu guia em Caelum',
      message: 'Você não pode vencer agora. A Câmara das Sombras é onde sua Sombra é contida. Acesse-a para entender seu estado de estabilidade.',
    );
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'Figura Desconhecida',
      npcTitle: 'Seu guia em Caelum',
      message: 'A Estabilidade da Sombra vai de 0 a 100. Missões completadas aumentam. Falhas diminuem. Se chegar a 0, o Colapso acontece e você perde XP.',
    );
    await TutorialService.markDone(TutorialPhase.phase8_shadow);
  }

  // ── FASE 9 — Estilo de Jogo (nível 15) ────────────────────────────────────
  static Future<void> phase9Playstyle(BuildContext ctx) async {
    if (!await TutorialService.shouldShow(TutorialPhase.phase9_playstyle)) return;
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'Figura Desconhecida',
      npcTitle: 'Seu guia em Caelum',
      message: 'Você amadureceu o suficiente para definir como joga. Solo — mais XP individual. Duo — bônus em dupla. Team — party com bônus progressivo.',
    );
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'Figura Desconhecida',
      npcTitle: 'Seu guia em Caelum',
      message: 'O estilo de jogo desbloqueia missões e conteúdos específicos. Pode ser mudado depois, mas com custo.',
    );
    await TutorialService.markDone(TutorialPhase.phase9_playstyle);
  }

  // ── FASE 10 — Vitalismo (nível 25) ────────────────────────────────────────
  static Future<void> phase10Vitalism(BuildContext ctx) async {
    if (!await TutorialService.shouldShow(TutorialPhase.phase10_vitalism)) return;
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'Figura Desconhecida',
      npcTitle: 'Seu guia em Caelum',
      message: 'O Vitalismo acordou em você. É uma energia mais pura que a Mana — rara, poderosa e exclusiva para certos caminhos.',
    );
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'Figura Desconhecida',
      npcTitle: 'Seu guia em Caelum',
      message: 'Classes vitalistas causam dano vitalista além do mágico. A barra de Vitalismo é separada da Mana e reage de forma diferente ao seu estado.',
    );
    await TutorialService.markDone(TutorialPhase.phase10_vitalism);
  }

  // ── FASE 11 — Nível Caveira (nível 99) ────────────────────────────────────
  static Future<void> phase11Skull(BuildContext ctx) async {
    if (!await TutorialService.shouldShow(TutorialPhase.phase11_skull)) return;
    if (!ctx.mounted) return;
    await MilestonePopup.show(ctx,
      title: 'Nível 99 — Pináculo',
      subtitle: 'O topo de Caelum',
      message: 'Você está a um passo do impossível. O Nível Caveira não é um destino — é um estado. A cada 1000 XP acumulados você recebe recompensas de prestígio.',
      icon: Icons.whatshot,
      color: const Color(0xFFFF2D55),
    );
    await TutorialService.markDone(TutorialPhase.phase11_skull);
  }
}
