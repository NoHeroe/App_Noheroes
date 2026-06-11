import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Configurações locais do app (SharedPreferences). Som/música/animações de
/// fundo. O toggle de **animações de fundo** desliga os controllers das
/// atmosferas (`NhAtmosphere`) — alívio de performance em telas pesadas.
class AppSettings {
  final bool soundEnabled;
  final bool musicEnabled;
  final bool backgroundAnimations;

  const AppSettings({
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.backgroundAnimations = true,
  });

  AppSettings copyWith({
    bool? soundEnabled,
    bool? musicEnabled,
    bool? backgroundAnimations,
  }) =>
      AppSettings(
        soundEnabled: soundEnabled ?? this.soundEnabled,
        musicEnabled: musicEnabled ?? this.musicEnabled,
        backgroundAnimations: backgroundAnimations ?? this.backgroundAnimations,
      );
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _load();
  }

  static const _kSound = 'set_sound_enabled';
  static const _kMusic = 'set_music_enabled';
  static const _kBgAnim = 'set_bg_animations';

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = AppSettings(
      soundEnabled: p.getBool(_kSound) ?? true,
      musicEnabled: p.getBool(_kMusic) ?? true,
      backgroundAnimations: p.getBool(_kBgAnim) ?? true,
    );
  }

  Future<void> setSound(bool v) async {
    state = state.copyWith(soundEnabled: v);
    (await SharedPreferences.getInstance()).setBool(_kSound, v);
  }

  Future<void> setMusic(bool v) async {
    state = state.copyWith(musicEnabled: v);
    (await SharedPreferences.getInstance()).setBool(_kMusic, v);
  }

  Future<void> setBackgroundAnimations(bool v) async {
    state = state.copyWith(backgroundAnimations: v);
    (await SharedPreferences.getInstance()).setBool(_kBgAnim, v);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>(
        (ref) => SettingsNotifier());

/// Atalho lido pelas atmosferas pra decidir se animam.
final backgroundAnimationsProvider =
    Provider<bool>((ref) => ref.watch(settingsProvider).backgroundAnimations);
