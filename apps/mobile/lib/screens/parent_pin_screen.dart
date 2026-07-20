import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import 'package:local_auth/local_auth.dart';
import 'package:localization/localization.dart';
import '../providers/providers.dart';

/// Parent PIN screen — unlocks the parent dashboard.
///
/// Supports PIN entry and biometric authentication.
class ParentPinScreen extends ConsumerStatefulWidget {
  const ParentPinScreen({
    super.key,
    this.enableBiometricPrompt = true,
    this.lockoutDuration = const Duration(seconds: 30),
    this.onUnlocked,
    this.onClose,
  });

  final bool enableBiometricPrompt;
  final Duration lockoutDuration;
  final VoidCallback? onUnlocked;
  final VoidCallback? onClose;

  @override
  ConsumerState<ParentPinScreen> createState() => _ParentPinScreenState();
}

class _ParentPinScreenState extends ConsumerState<ParentPinScreen> {
  String _pin = '';
  String? _error;
  int _failedAttempts = 0;
  DateTime? _lockedUntil;
  bool _showAdultChallenge = false;
  String _adultAnswer = '';
  final _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    if (!widget.enableBiometricPrompt) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryBiometric();
    });
  }

  bool get _isLocked =>
      _lockedUntil != null && DateTime.now().isBefore(_lockedUntil!);

  void _unlock() {
    ref.read(parentGateProvider.notifier).state = true;
    if (widget.onUnlocked != null) {
      widget.onUnlocked!();
      return;
    }
    context.go('/parent');
  }

  Future<void> _tryBiometric() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) return;
      final available = await _localAuth.isDeviceSupported();
      if (!available) return;

      final authenticated = await _localAuth.authenticate(
        localizedReason: MiMobileStrings.m101,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (authenticated && mounted) {
        _unlock();
      }
    } catch (e) {
      // Biometric not available, fall back to PIN
    }
  }

  void _onNumberPressed(String number) {
    if (_isLocked || _pin.length >= 4) return;
    setState(() {
      _pin += number;
      _error = null;
    });
    if (_pin.length >= 4) {
      _verifyPin();
    }
  }

  void _onDeletePressed() {
    if (_isLocked || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _verifyPin() async {
    if (_isLocked || _pin.length < 4) return;
    try {
      final verifyPin = ref.read(parentPinVerifierProvider);
      final verified = await verifyPin(_pin);
      if (!verified) throw StateError('PIN rejected');
      if (mounted) {
        _unlock();
      }
    } catch (e) {
      final nextAttempts = _failedAttempts + 1;
      setState(() {
        _failedAttempts = nextAttempts;
        if (nextAttempts >= 3) {
          _lockedUntil = DateTime.now().add(widget.lockoutDuration);
          _error = MiMobileStrings.text(
              'm102', {'p0': widget.lockoutDuration.inSeconds});
        } else {
          _error = MiMobileStrings.m103;
        }
        _pin = '';
      });
    }
  }

  void _openAdultChallenge() {
    setState(() {
      _showAdultChallenge = true;
      _adultAnswer = '';
      _error = null;
    });
  }

  void _submitAdultChallenge() {
    if (_adultAnswer.trim() == '13') {
      _unlock();
      return;
    }
    setState(() {
      _error = MiMobileStrings.m104;
      _adultAnswer = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiColors.background,
      appBar: AppBar(
        title: const Text(MiMobileStrings.m105),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onClose ?? () => context.go('/home'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MiTokens.space6),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 64,
                    color: MiColors.primary,
                  ),
                  const SizedBox(height: MiTokens.space4),
                  Text(
                    _showAdultChallenge
                        ? MiMobileStrings.m106
                        : MiMobileStrings.m107,
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: MiTokens.space2),
                  Text(
                    _showAdultChallenge
                        ? MiMobileStrings.m108
                        : MiMobileStrings.m109,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: MiTokens.space8),
                  if (_showAdultChallenge)
                    _buildAdultChallenge(context)
                  else
                    _buildPinEntry(),
                  if (_error != null) ...[
                    const SizedBox(height: MiTokens.space4),
                    Text(
                      _error!,
                      style: const TextStyle(color: MiColors.error),
                    ),
                  ],
                  const SizedBox(height: MiTokens.space8),
                  if (!_showAdultChallenge) ...[
                    _buildNumberPad(),
                    const SizedBox(height: MiTokens.space4),
                    TextButton(
                      onPressed: _openAdultChallenge,
                      child: const Text(MiMobileStrings.m110),
                    ),
                    const SizedBox(height: MiTokens.space2),
                    MiOutlinedButton(
                      label: MiMobileStrings.m111,
                      icon: Icons.fingerprint,
                      onPressed: _tryBiometric,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinEntry() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isFilled = index < _pin.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? MiColors.primary : Colors.transparent,
            border: Border.all(color: MiColors.primary, width: 2),
          ),
        );
      }),
    );
  }

  Widget _buildAdultChallenge(BuildContext context) {
    return Column(
      children: [
        Text(
          '8 + 5 = ?',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: MiTokens.space4),
        TextField(
          key: const ValueKey('adult-challenge-answer'),
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            labelText: MiMobileStrings.m112,
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _adultAnswer = value,
          onSubmitted: (_) => _submitAdultChallenge(),
        ),
        const SizedBox(height: MiTokens.space4),
        MiButton(
          label: MiMobileStrings.m113,
          icon: Icons.lock_open,
          onPressed: _submitAdultChallenge,
        ),
        TextButton(
          onPressed: () => setState(() {
            _showAdultChallenge = false;
            _adultAnswer = '';
            _error = null;
          }),
          child: const Text(MiMobileStrings.m114),
        ),
      ],
    );
  }

  Widget _buildNumberPad() {
    final buttons = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '⌫'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      mainAxisSpacing: MiTokens.space2,
      crossAxisSpacing: MiTokens.space2,
      children: buttons.map((b) {
        if (b.isEmpty) return const SizedBox();
        if (b == '⌫') {
          return MiIconButton(
            icon: Icons.backspace,
            backgroundColor: MiColors.border,
            iconColor: MiColors.textPrimary,
            onPressed: _isLocked ? null : _onDeletePressed,
          );
        }
        return SizedBox(
          width: 64,
          height: 64,
          child: OutlinedButton(
            onPressed: _isLocked ? null : () => _onNumberPressed(b),
            style: OutlinedButton.styleFrom(
              backgroundColor: MiColors.surface,
              foregroundColor: MiColors.textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(MiTokens.radiusMd),
              ),
            ),
            child: Text(
              b,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
          ),
        );
      }).toList(),
    );
  }
}
