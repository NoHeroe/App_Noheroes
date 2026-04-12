import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

    // Cinzel — títulos rituais
      static const TextStyle displayLarge = TextStyle(
          fontFamily: 'CinzelDecorative',
              fontSize: 28,
                  fontWeight: FontWeight.bold,
                      color: AppColors.gold,
                          letterSpacing: 2.0,
                            );

                              static const TextStyle displayMedium = TextStyle(
                                  fontFamily: 'CinzelDecorative',
                                      fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                                  letterSpacing: 1.5,
                                                    );

                                                      static const TextStyle titleLarge = TextStyle(
                                                          fontFamily: 'CinzelDecorative',
                                                              fontSize: 18,
                                                                  fontWeight: FontWeight.bold,
                                                                      color: AppColors.textPrimary,
                                                                          letterSpacing: 1.0,
                                                                            );

                                                                              // Roboto — corpo de texto
                                                                                static const TextStyle bodyLarge = TextStyle(
                                                                                    fontFamily: 'Roboto',
                                                                                        fontSize: 16,
                                                                                            fontWeight: FontWeight.normal,
                                                                                                color: AppColors.textPrimary,
                                                                                                  );

                                                                                                    static const TextStyle bodyMedium = TextStyle(
                                                                                                        fontFamily: 'Roboto',
                                                                                                            fontSize: 14,
                                                                                                                fontWeight: FontWeight.normal,
                                                                                                                    color: AppColors.textSecondary,
                                                                                                                      );

                                                                                                                        static const TextStyle bodySmall = TextStyle(
                                                                                                                            fontFamily: 'Roboto',
                                                                                                                                fontSize: 12,
                                                                                                                                    fontWeight: FontWeight.normal,
                                                                                                                                        color: AppColors.textMuted,
                                                                                                                                          );

                                                                                                                                            static const TextStyle labelMystic = TextStyle(
                                                                                                                                                fontFamily: 'CinzelDecorative',
                                                                                                                                                    fontSize: 11,
                                                                                                                                                        fontWeight: FontWeight.normal,
                                                                                                                                                            color: AppColors.purple,
                                                                                                                                                                letterSpacing: 1.5,
                                                                                                                                                                  );
                                                                                                                                                                  }