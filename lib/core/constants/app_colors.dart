import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

    // Base
      static const black      = Color(0xFF000000);
        static const surface    = Color(0xFF0D0D0D);
          static const surfaceAlt = Color(0xFF141414);
            static const border     = Color(0xFF1E1E1E);

              // Roxo — energia vital e sombra
                static const purple      = Color(0xFF8B3DFF);
                  static const purpleLight = Color(0xFF9B5CF6);
                    static const purpleDark  = Color(0xFF5B1FBF);
                      static const purpleGlow  = Color(0x338B3DFF);

                        // Dourado — sagrado e ritualístico
                          static const gold    = Color(0xFFC2A05A);
                            static const goldDim = Color(0xFF8A6E3A);

                              // Status
                                static const hp = Color(0xFFB33030);
                                  static const mp = Color(0xFF3070B3);
                                    static const xp = Color(0xFF7C3AED);

                                      // Estados da Sombra
                                        static const shadowStable    = Color(0xFF6B4FA0);
                                          static const shadowChaotic   = Color(0xFF8B2020);
                                            static const shadowAscending = Color(0xFF4FA06B);
                                              static const shadowVoid      = Color(0xFF1A1A2E);
                                                static const shadowObsessive = Color(0xFFB36B00);

                                                  // Texto
                                                    static const textPrimary   = Color(0xFFEEEEEE);
                                                      static const textSecondary = Color(0xFF999999);
                                                        static const textMuted     = Color(0xFF555555);

                                                          // Raridades
                                                            static const rarityCommon    = Color(0xFF888888);
                                                              static const rarityUncommon  = Color(0xFF4CAF50);
                                                                static const rarityRare      = Color(0xFF2196F3);
                                                                  static const rarityEpic      = Color(0xFF9C27B0);
                                                                    static const rarityLegendary = Color(0xFFFF9800);
                                                                      static const rarityMythic    = Color(0xFFFF1744);

  // ── Tokens do restyle do Santuário (mockup v3) ──────────────────────
  // Aditivos — NÃO substituem os base globais (black/surface/purple/gold).
  static const blackVeil    = Color(0xFF070509); // fundo profundo da atmosfera
  static const surfaceVeil  = Color(0xFF0D0B11);
  static const surfaceVeil2 = Color(0xFF141019);
  static const borderViolet = Color(0xFF241C30);

  static const purpleLt   = Color(0xFF9B5CF6);
  static const purpleDk   = Color(0xFF5B1FBF);
  static const purpleGlow45 = Color(0x738B3DFF); // rgba(139,61,255,.45)

  static const goldLt = Color(0xFFE4CB8A);
  static const goldDk = Color(0xFF7A6233);

  static const txt    = Color(0xFFECE6F2);
  static const txt2   = Color(0xFF9B93A8);
  static const txtMut = Color(0xFF5B5468);

  // ── Conceitos de carta (Fatia 2 — Coleção) ──────────────────────────
  static const conceptVita       = Color(0xFF8B3DFF); // == purple
  static const conceptNeutro     = Color(0xFFB8B2C4);
  static const conceptChrysalis  = Color(0xFF3FAE7A);
  static const conceptCelestial  = Color(0xFF4A90D9);
  static const conceptMagico     = Color(0xFFE0B341);
  static const conceptCorrompido = Color(0xFFD8323F);

  // ── Raridade de carta (gema) ────────────────────────────────────────
  static const cardComum     = Color(0xFF8C8594);
  static const cardRara      = Color(0xFF5AA8FF);
  static const cardEpica     = Color(0xFFB06CFF);
  static const cardLendaria  = Color(0xFFF0C850);
  static const cardElite     = Color(0xFFFF5B6E);
  static const cardExclusiva = Color(0xFF7FFFD4);
}