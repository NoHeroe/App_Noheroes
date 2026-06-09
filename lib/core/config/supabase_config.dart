/// Configuração pública do Supabase (Época 2 — full-online, [[ADR-0024]]).
///
/// Estes valores são de **cliente** e seguros pra embutir no app:
/// - [url] é o endpoint público do projeto.
/// - [publishableKey] é a chave pública (novo formato `sb_publishable_...`,
///   equivalente à anon key). NÃO é segredo — o acesso real é controlado por
///   RLS no servidor. A `service_role`/secret key NUNCA entra no cliente.
///
/// Projeto: `ljqzwfuirydhbtzvagmu` (Supabase Cloud free, dev).
class SupabaseConfig {
  const SupabaseConfig._();

  static const String url = 'https://ljqzwfuirydhbtzvagmu.supabase.co';

  static const String publishableKey =
      'sb_publishable_cbfU2VeVjWlvZahnryBWsQ_T14SybZG';
}
