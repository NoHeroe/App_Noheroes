import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/widgets/animated_bg.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/mystic_title.dart';
import '../../../core/widgets/caelum_button.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _acceptedTerms = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      setState(() => _error = 'Aceite os termos para continuar.');
      return;
    }
    setState(() => _error = null);
    ref.read(authLoadingProvider.notifier).state = true;

    final player = await ref.read(authDsProvider).register(
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
    );

    ref.read(authLoadingProvider.notifier).state = false;

    if (!mounted) return;

    if (player != null) {
      ref.read(currentPlayerProvider.notifier).state = player;
      context.go('/awakening');
    } else {
      setState(() => _error = 'Este email já está em uso.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authLoadingProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AnimatedBg(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const MysticTitle(text: 'NoHeroes', fontSize: 32),
                    const SizedBox(height: 40),
                    GlassContainer(
                      borderRadius: BorderRadius.circular(24),
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Criar Conta', style: AppTypography.titleLarge),
                            const SizedBox(height: 6),
                            Text('Sua sombra aguarda em Caelum.',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textMuted)),
                            const SizedBox(height: 24),
                            _buildField(
                              label: 'Email',
                              controller: _emailCtrl,
                              icon: Icons.mail_outline,
                              validator: (v) => v == null || !v.contains('@')
                                  ? 'Email inválido' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildField(
                              label: 'Senha',
                              controller: _passwordCtrl,
                              icon: Icons.lock_outline,
                              obscure: _obscure,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure ? Icons.visibility_off : Icons.visibility,
                                  color: AppColors.textMuted, size: 18,
                                ),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                              validator: (v) => v == null || v.length < 6
                                  ? 'Mínimo 6 caracteres' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildField(
                              label: 'Confirmar Senha',
                              controller: _confirmCtrl,
                              icon: Icons.lock_outline,
                              obscure: true,
                              validator: (v) => v != _passwordCtrl.text
                                  ? 'Senhas não conferem' : null,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Checkbox(
                                  value: _acceptedTerms,
                                  onChanged: (v) =>
                                      setState(() => _acceptedTerms = v!),
                                  activeColor: AppColors.purple,
                                  side: const BorderSide(color: AppColors.textMuted),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(
                                        () => _acceptedTerms = !_acceptedTerms),
                                    child: Text(
                                      'Aceito os Termos de Uso e Política de Privacidade',
                                      style: AppTypography.bodySmall,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 8),
                              Text(_error!,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.hp)),
                            ],
                            const SizedBox(height: 24),
                            CaelumButton(
                              label: 'Despertar',
                              loading: loading,
                              onPressed: _handleRegister,
                            ),
                            const SizedBox(height: 12),
                            CaelumButton(
                              label: 'Já tenho conta',
                              outline: true,
                              onPressed: () => context.go('/login'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: AppTypography.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.purple, size: 18),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.purple, width: 1.5)),
      ),
      validator: validator,
    );
  }
}
