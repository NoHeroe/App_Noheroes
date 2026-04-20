import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/datasources/local/tutorial_service.dart';
import 'widgets/npc_dialog_overlay.dart';
import 'widgets/milestone_popup.dart';

/// Sistema unificado de tutorial.
/// Cada fase: NPC(s) + popup de ação (se aplicável) + markDone.
/// Popup de ação pode navegar para /class-selection, /faction-selection, /playstyle.
class TutorialManager {

  // ── FASE 1 — Santuário (nível 1) ──────────────────────────────────────────
  static Future<void> phase1Sanctuary(BuildContext ctx) async {
    if (!await TutorialService.shouldShow(TutorialPhase.phase1_sanctuary)) return;
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'O Vazio',
      npcTitle: 'Presenca silenciosa',
      message: 'Este é o Santuário. Aqui você acompanha sua jornada, completa missões e acessa tudo que Caelum oferece.',
    );
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'O Vazio',
      npcTitle: 'Presenca silenciosa',
      message: 'Vá até MISSÕES e complete seu primeiro hábito diário. Cada missão fortalece sua forma aqui.',
    );
    await TutorialService.markDone(TutorialPhase.phase1_sanctuary);
  }

  // ── FASE 2 — Biblioteca + Atributos (nível 2) ────────────────────────────
  static Future<void> phase2Library(BuildContext ctx) async {
    if (!await TutorialService.shouldShow(TutorialPhase.phase2_library)) return;
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'O Vazio',
      npcTitle: 'Presenca silenciosa',
      message: 'A Biblioteca está desbloqueada. Registre seu Diário — cada palavra alimenta sua forma.',
    );
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'O Vazio',
      npcTitle: 'Presenca silenciosa',
      message: 'Você subiu de nível. No Personagem há pontos de atributo disponíveis — cada ponto melhora suas estatísticas permanentemente.',
    );
    await TutorialService.markDone(TutorialPhase.phase2_library);
  }

  // ── FASE 3 — Loja + Itens (nível 3) ─────────────────────────────────────
  static Future<void> phase3Shop(BuildContext ctx) async {
    if (!await TutorialService.shouldShow(TutorialPhase.phase3_shop)) return;
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'O Vazio',
      npcTitle: 'Presenca silenciosa',
      message: 'A Loja está disponível. Com ouro de missões você compra equipamentos, consumíveis e materiais.',
    );
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'O Vazio',
      npcTitle: 'Presenca silenciosa',
      message: 'Itens equipados aparecem no Personagem. Eles adicionam bônus reais aos seus atributos.',
    );
    await TutorialService.markDone(TutorialPhase.phase3_shop);
  }

  // ── FASE 4 — Regiões (nível 4) ────────────────────────────────────────────
  static Future<void> phase4Regions(BuildContext ctx) async {
    if (!await TutorialService.shouldShow(TutorialPhase.phase4_regions)) return;
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'O Vazio',
      npcTitle: 'Presenca silenciosa',
      message: 'As Regiões de Caelum abriram. Áreas de exploração onde você descobre NPCs, tesouros e missões extras.',
    );
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'O Vazio',
      npcTitle: 'Presenca silenciosa',
      message: 'Explorar regiões aumenta reputação com NPCs e facções — e desbloqueia partes da história.',
    );
    await TutorialService.markDone(TutorialPhase.phase4_regions);
  }

  // ── FASE 5 — Classe (nível 5) ─────────────────────────────────────────────
  static Future<void> phase5Class(BuildContext ctx, {required bool hasClass}) async {
    if (!await TutorialService.shouldShow(TutorialPhase.phase5_class)) return;
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'O Vazio',
      npcTitle: 'Presenca silenciosa',
      message: 'Sua forma está pronta para assumir um caminho. A classe define seus atributos, missões diárias e como Caelum te enxerga.',
    );
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'O Vazio',
      npcTitle: 'Presenca silenciosa',
      message: 'Classes de Mana dominam magia arcana. Classes de Vitalismo vão além — causam dano vitalista. A escolha muda seu estilo para sempre.',
    );
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'O Vazio',
      npcTitle: 'Presenca silenciosa',
      message: 'Após escolher sua classe, 3 Missões de Classe aparecerão todos os dias — completadas automaticamente conforme você age.',
    );
    await TutorialService.markDone(TutorialPhase.phase5_class);

    // Popup de ação: só se ainda não tem classe
    if (hasClass || !ctx.mounted) return;
    await MilestonePopup.show(ctx,
      title: 'Escolha sua Classe',
      subtitle: 'Nível 5 atingido',
      message: 'A hora chegou. Cada classe define seus atributos, missões e destino em Caelum.',
      icon: Icons.auto_fix_high_outlined,
      color: AppColors.purple,
      onDismiss: () => ctx.go('/class-selection'),
    );
  }

  // ── FASE 6 — Guilda (nível 6) ─────────────────────────────────────────────
  static Future<void> phase6Guild(BuildContext ctx) async {
    if (!await TutorialService.shouldShow(TutorialPhase.phase6_guild)) return;
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'Noryan Gray',
      npcTitle: 'Mestre da Guilda',
      message: 'Aventureiro. A Guilda de Aventureiros agora está acessível. O Colar te aguarda.',
    );
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'Noryan Gray',
      npcTitle: 'Mestre da Guilda',
      message: 'Aqui você sobe de Rank completando o Teste de Ascensão — missões encadeadas de alta dificuldade.',
    );
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'Noryan Gray',
      npcTitle: 'Mestre da Guilda',
      message: 'As Missões de Guilda ainda estão bloqueadas — chegam com o sistema de batalha. Por enquanto, foque no Teste de Ascensão.',
    );
    await TutorialService.markDone(TutorialPhase.phase6_guild);
  }

  // ── FASE 7 — Facções (nível 7) ────────────────────────────────────────────
  static Future<void> phase7Factions(BuildContext ctx, {required bool hasFaction}) async {
    if (!await TutorialService.shouldShow(TutorialPhase.phase7_faction)) return;
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'O Vazio',
      npcTitle: 'Presenca silenciosa',
      message: 'As 8 Facções de Caelum abriram suas portas. Cada uma tem filosofia, bônus, missões exclusivas e NPCs próprios.',
    );
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'O Vazio',
      npcTitle: 'Presenca silenciosa',
      message: 'Não é obrigatório escolher. O Caminho do Lobo Solitário existe para quem prefere caminhar sem alianças — por ora.',
    );
    await TutorialService.markDone(TutorialPhase.phase7_faction);

    // Popup de ação: só se ainda não tem facção
    if (hasFaction || !ctx.mounted) return;
    await MilestonePopup.show(ctx,
      title: 'Facções Desbloqueadas',
      subtitle: 'Nível 7 atingido',
      message: 'As 8 facções aceitam sua candidatura. Cada uma tem seu preço, recompensas e segredos. Escolha com cuidado.',
      icon: Icons.shield_outlined,
      color: AppColors.gold,
      onDismiss: () => ctx.go('/faction-selection'),
    );
  }

  // ── FASE 8 — Shadow Boss (nível 10) ───────────────────────────────────────
  static Future<void> phase8Shadow(BuildContext ctx) async {
    if (!await TutorialService.shouldShow(TutorialPhase.phase8_shadow)) return;
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'O Vazio',
      npcTitle: 'Presenca silenciosa',
      message: 'Algo surgiu das suas falhas e excessos. É um Shadow Boss — a forma mais verdadeira do seu erro em Caelum.',
    );
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'O Vazio',
      npcTitle: 'Presenca silenciosa',
      message: 'A Câmara das Sombras contém sua Sombra. Acesse para entender seu estado de estabilidade.',
    );
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'O Vazio',
      npcTitle: 'Presenca silenciosa',
      message: 'Estabilidade vai de 0 a 100. Missões aumentam, falhas diminuem. Em 0 acontece o Colapso e você perde XP.',
    );
    await TutorialService.markDone(TutorialPhase.phase8_shadow);
  }

  // ── FASE 9 — Estilo de Jogo (nível 15) ────────────────────────────────────
  static Future<void> phase9Playstyle(BuildContext ctx, {required bool hasPlaystyle}) async {
    if (!await TutorialService.shouldShow(TutorialPhase.phase9_playstyle)) return;
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'O Vazio',
      npcTitle: 'Presenca silenciosa',
      message: 'Você amadureceu. Hora de definir como joga: Solo — mais XP individual. Duo — bônus em dupla. Team — party com bônus progressivo.',
    );
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'O Vazio',
      npcTitle: 'Presenca silenciosa',
      message: 'O estilo de jogo desbloqueia missões e conteúdos específicos. Pode mudar depois, mas tem custo.',
    );
    await TutorialService.markDone(TutorialPhase.phase9_playstyle);

    if (hasPlaystyle || !ctx.mounted) return;
    await MilestonePopup.show(ctx,
      title: 'Estilo de Jogo',
      subtitle: 'Nível 15 atingido',
      message: 'Defina como você joga em Caelum: Solo, Duo ou Team. Afeta missões, bônus e acesso a conteúdos.',
      icon: Icons.sports_martial_arts,
      color: AppColors.gold,
      onDismiss: () => ctx.go('/playstyle'),
    );
  }

  // ── FASE 10 — Vitalismo (nível 25) ────────────────────────────────────────
  // Refatorada no Sprint 1.2: despertar deixou de ser afirmação genérica e virou
  // evento interativo (cerimônia do Cristal). Ver vitalismos_unicos.md.
  //
  // - Vitalista sem afinidade: dois diálogos do Vazio + redirect pra /vitalism/crystal-ceremony.
  // - Mana-user (ou vitalista que por algum caminho já tem afinidade): marca
  //   feito silenciosamente — a fase não se aplica ao caminho dele.
  static Future<void> phase10Vitalism(
    BuildContext ctx, {
    required bool isVitalistWithoutAffinity,
  }) async {
    if (!await TutorialService.shouldShow(TutorialPhase.phase10_vitalism)) return;
    if (!isVitalistWithoutAffinity) {
      await TutorialService.markDone(TutorialPhase.phase10_vitalism);
      return;
    }
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'O Vazio',
      npcTitle: 'Presenca silenciosa',
      message: 'Algo despertou em você. Uma afinidade que ainda não tem nome.',
    );
    if (!ctx.mounted) return;
    await NpcDialogOverlay.show(ctx,
      npcName: 'O Vazio',
      npcTitle: 'Presenca silenciosa',
      message: 'O Cristal de Obsidiana do Dragão a revelará. Venha.',
    );
    await TutorialService.markDone(TutorialPhase.phase10_vitalism);
    if (!ctx.mounted) return;
    ctx.go('/vitalism/crystal-ceremony');
  }

  // ── FASE 11 — Nível Caveira (nível 99) ────────────────────────────────────
  static Future<void> phase11Skull(BuildContext ctx) async {
    if (!await TutorialService.shouldShow(TutorialPhase.phase11_skull)) return;
    if (!ctx.mounted) return;
    await MilestonePopup.show(ctx,
      title: 'Nível 99 — Pináculo',
      subtitle: 'O topo de Caelum',
      message: 'Você está a um passo do impossível. O Nível Caveira é um estado. A cada 1000 XP acumulados você recebe recompensas de prestígio.',
      icon: Icons.whatshot,
      color: const Color(0xFFFF2D55),
    );
    await TutorialService.markDone(TutorialPhase.phase11_skull);
  }

  /// Roda todas as fases aplicáveis ao nível do player, em ordem.
  /// Recebe o player para decidir hasClass/hasFaction/hasPlaystyle.
  static Future<void> runAll(
    BuildContext ctx, {
    required int level,
    required bool hasClass,
    required bool hasFaction,
    required bool hasPlaystyle,
    required bool isVitalistWithoutAffinity,
  }) async {
    if (level >= 1 && ctx.mounted) await phase1Sanctuary(ctx);
    if (level >= 2 && ctx.mounted) await phase2Library(ctx);
    if (level >= 3 && ctx.mounted) await phase3Shop(ctx);
    if (level >= 4 && ctx.mounted) await phase4Regions(ctx);
    if (level >= 5 && ctx.mounted) await phase5Class(ctx, hasClass: hasClass);
    if (level >= 6 && ctx.mounted) await phase6Guild(ctx);
    if (level >= 7 && ctx.mounted) await phase7Factions(ctx, hasFaction: hasFaction);
    if (level >= 10 && ctx.mounted) await phase8Shadow(ctx);
    if (level >= 15 && ctx.mounted) await phase9Playstyle(ctx, hasPlaystyle: hasPlaystyle);
    if (level >= 25 && ctx.mounted) {
      await phase10Vitalism(ctx,
          isVitalistWithoutAffinity: isVitalistWithoutAffinity);
    }
    if (level >= 99 && ctx.mounted) await phase11Skull(ctx);
  }
}
