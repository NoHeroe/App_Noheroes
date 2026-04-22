import 'dart:async';

import 'app_event.dart';

/// Sprint 3.1 Bloco 2 — EventBus local do app.
///
/// Stream broadcast único que tramita instâncias de [AppEvent]. Consumidores
/// assinam com [on], filtrando pelo tipo concreto. Produtores emitem com
/// [publish].
///
/// ## Contratos
///
/// - **Broadcast**: múltiplos listeners no mesmo tipo recebem todos.
/// - **Sem replay**: um listener adicionado *depois* de uma emissão **não**
///   recebe eventos passados. O bus não mantém histórico.
/// - **Ordem**: eventos emitidos sequencialmente em síncrono chegam em
///   ordem de emissão — mas a entrega é via *microtask* do Dart, então
///   testes devem drenar o event loop antes de assertar ordem.
/// - **Pós-dispose**: ver [dispose] — publish vira noop silencioso.
///
/// Na Sprint 3.1 este bus é criado como singleton via `appEventBusProvider`
/// em `lib/app/providers.dart`. Testes criam instâncias próprias.
class AppEventBus {
  final StreamController<AppEvent> _controller =
      StreamController<AppEvent>.broadcast();
  bool _disposed = false;

  /// Emite [event] pra todos os listeners assinados em tipos compatíveis.
  ///
  /// Se o bus já foi descartado via [dispose], a chamada é **noop silencioso**
  /// (retorna sem emitir e sem lançar). Ver [dispose] pra contexto.
  void publish(AppEvent event) {
    if (_disposed) return;
    _controller.add(event);
  }

  /// Stream filtrado por tipo — só entrega instâncias de [T].
  ///
  /// Uso típico:
  /// ```dart
  /// final sub = bus.on<MissionCompleted>().listen((event) { ... });
  /// // ...
  /// await sub.cancel();
  /// ```
  ///
  /// Implementado com `.where` + `.cast` pra não depender de rxdart.
  Stream<T> on<T extends AppEvent>() =>
      _controller.stream.where((e) => e is T).cast<T>();

  /// Indica se [dispose] já foi chamado. Expor publicamente facilita testes
  /// e instrumentação; produção não precisa consultar.
  bool get isDisposed => _disposed;

  /// Fecha o controlador e marca o bus como descartado.
  ///
  /// **Idempotente**: chamadas subsequentes são noop.
  ///
  /// **Publish pós-dispose é noop silencioso, nunca lança.** Motivo: durante
  /// teardown de Riverpod (hot reload, logout, dispose em cascata de
  /// providers), outros services podem tentar emitir num bus já fechado.
  /// Lançar `StateError` ali faria o crash aparecer em contexto não-óbvio
  /// pra QA; preferimos silêncio + indicador via [isDisposed] pra quem
  /// quiser observar.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _controller.close();
  }
}
