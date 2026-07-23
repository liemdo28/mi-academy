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
    final locale =
        ref.watch(parentSettingsProvider).valueOrNull?.language ?? 'vi';
    final copy = _LoginCopy(locale);

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
                  copy.subtitle,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: MiTokens.space12),

                // Toggle login/register
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(value: true, label: Text(copy.login)),
                    ButtonSegment(value: false, label: Text(copy.register)),
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
                    decoration: InputDecoration(
                      labelText: copy.displayName,
                      prefixIcon: const Icon(Icons.person),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? copy.enterDisplayName
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
                      ? copy.enterValidEmail
                      : null,
                ),
                const SizedBox(height: MiTokens.space4),

                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: copy.password,
                    prefixIcon: const Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (v) =>
                      v == null || v.length < 8 ? copy.minimumPassword : null,
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
                  label: _isLogin ? copy.login : copy.register,
                  isLoading: authState.isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: MiTokens.space6),

                // Offline mode button
                MiOutlinedButton(
                  label: copy.offlineMode,
                  icon: Icons.offline_bolt,
                  onPressed: () async {
                    await ref
                        .read(activeChildProvider.notifier)
                        .selectOfflineChild();
                    if (context.mounted) context.go('/home');
                  },
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

class _LoginCopy {
  const _LoginCopy(this.locale);

  final String locale;

  bool get _en => locale == 'en';

  String get subtitle => _en ? 'Learn through play' : 'Học tập qua trò chơi';
  String get login => _en ? 'Log in' : 'Đăng nhập';
  String get register => _en ? 'Register' : 'Đăng ký';
  String get displayName => _en ? 'Display name' : 'Tên hiển thị';
  String get enterDisplayName =>
      _en ? 'Enter a display name' : 'Nhập tên hiển thị';
  String get enterValidEmail =>
      _en ? 'Enter a valid email' : 'Nhập email hợp lệ';
  String get password => _en ? 'Password' : 'Mật khẩu';
  String get minimumPassword =>
      _en ? 'At least 8 characters' : 'Tối thiểu 8 ký tự';
  String get offlineMode => _en ? 'Offline mode' : 'Chế độ offline';
}
