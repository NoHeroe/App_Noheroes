import 'package:drift/native.dart';

import 'package:noheroes_app/data/database/app_database.dart';

/// Sprint 3.1 Bloco 4 — helper comum dos testes de Repository.
///
/// Abre AppDatabase in-memory; cada teste recebe instância isolada via
/// `setUp`/`tearDown` (ver cada `*_repository_drift_test.dart`). Usa o
/// construtor `AppDatabase.forTesting` adicionado no Bloco 1.
AppDatabase newTestDb() => AppDatabase.forTesting(NativeDatabase.memory());
