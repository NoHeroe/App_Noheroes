import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Avatar do jogador — presets placeholder até o Editor de Personagem 3D
/// (premium, ver vault ADR-0026 / editor_de_personagem). Persistido
/// LOCALMENTE via SharedPreferences. ⚠️ ainda NÃO sincroniza entre dispositivos
/// (não há campo no schema). Exibido em TODOS os mini-perfis (Santuário,
/// Missões, Perfil).
class AvatarPreset {
  final IconData icon;
  final Color color;
  const AvatarPreset(this.icon, this.color);
}

const List<AvatarPreset> kAvatarPresets = [
  AvatarPreset(Icons.person, Color(0xFFC9A227)),
  AvatarPreset(Icons.face, Color(0xFF8B3DFF)),
  AvatarPreset(Icons.shield, Color(0xFF3070B3)),
  AvatarPreset(Icons.bolt, Color(0xFFFF8A3D)),
  AvatarPreset(Icons.auto_awesome, Color(0xFF4FA06B)),
  AvatarPreset(Icons.local_fire_department, Color(0xFFE0533D)),
  AvatarPreset(Icons.nightlight_round, Color(0xFF6A6AE0)),
  AvatarPreset(Icons.pets, Color(0xFFC2A05A)),
];

const String _prefsKey = 'profile_avatar_index';

class AvatarNotifier extends StateNotifier<int> {
  AvatarNotifier() : super(0) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final i = prefs.getInt(_prefsKey) ?? 0;
    if (i >= 0 && i < kAvatarPresets.length) state = i;
  }

  Future<void> select(int i) async {
    if (i < 0 || i >= kAvatarPresets.length) return;
    state = i;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, i);
  }
}

final selectedAvatarProvider =
    StateNotifierProvider<AvatarNotifier, int>((ref) => AvatarNotifier());
