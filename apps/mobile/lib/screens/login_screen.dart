import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import '../providers/providers.dart';

/// Login screen for parents.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true; // Toggle login/register

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MiTokens.space6),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: MiTokens.space12),
                // Logo and title
                Text(
                  'MI Academy',
                  style: Theme.of(context).textTheme.displayLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: MiTokens.space2),
                Text(
                  'Học tập qua trò chơi',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: MiTokens.space12),

                // Toggle login/register
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Đăng nhập')),
                    ButtonSegment(value: false, label: Text('Đăng ký')),
                  ],
                  selected: {_isLogin},
                  onSelectionChanged: (value) {
                    setState(() => _isLogin = value.first);
                  },
                ),
                const SizedBox(height: MiTokens.space6),

                if (!_isLogin)
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Tên hiển thị',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Nhập tên hiển thị'
                        : null,
                  ),
                if (!_isLogin) const SizedBox(height: MiTokens.space4),

                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || !v.contains('@')
                      ? 'Nhập email hợp lệ'
                      : null,
                ),
                const SizedBox(height: MiTokens.space4),

                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (v) =>
                      v == null || v.length < 8 ? 'Tối thiểu 8 ký tự' : null,
                ),
                const SizedBox(height: MiTokens.space6),

                // Error message
                if (authState.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(MiTokens.space3),
                    decoration: BoxDecoration(
                      color: MiColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(MiTokens.radiusSm),
                    ),
                    child: Text(
                      authState.error!,
                      style: const TextStyle(color: MiColors.error),
                    ),
                  ),
                  const SizedBox(height: MiTokens.space4),
                ],

                // Submit button
                MiButton(
                  label: _isLogin ? 'Đăng nhập' : 'Đăng ký',
                  isLoading: authState.isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: MiTokens.space6),

                // Offline mode button
                MiOutlinedButton(
                  label: 'Chế độ offline',
                  icon: Icons.offline_bolt,
                  onPressed: () => context.go('/select-child'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authNotifier = ref.read(authProvider.notifier);

    bool success;
    if (_isLogin) {
      success = await authNotifier.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      success = await authNotifier.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _emailController.text.trim().split('@').first,
      );
    }

    if (success && mounted) {
      context.go('/select-child');
    }
  }
}
