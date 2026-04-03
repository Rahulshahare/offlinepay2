import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app_theme.dart';
import '../../ussd_service.dart';
import '../../widgets/upi_pin_pad.dart';

// ── Screen state ──────────────────────────────────────────────────────────────
enum _ScreenState { pinEntry, loading, result, error }

class CheckBalanceScreen extends StatefulWidget {
  const CheckBalanceScreen({super.key});
  @override
  State<CheckBalanceScreen> createState() => _CheckBalanceScreenState();
}

class _CheckBalanceScreenState extends State<CheckBalanceScreen> {
  _ScreenState _state = _ScreenState.pinEntry;
  String _balance = '';
  String _errorMsg = '';
  StreamSubscription? _sessionSub;

  // *99# navigation sequence for Check Balance:
  // Dial *99# → send '3' (Check Balance) → send UPI PIN → read result

  @override
  void dispose() {
    _sessionSub?.cancel();
    UssdService.endSession();
    super.dispose();
  }

  // ── Start check balance session ───────────────────────────────────────────

  Future<void> _startSession(String pin) async {
    setState(() => _state = _ScreenState.loading);

    try {
      await UssdService.setCurrentStep('check_balance');

      // Listen for session events
      _sessionSub = UssdService.sessionStream.listen((event) {
        _handleSessionEvent(event, pin);
      });

      // Dial *99#
      await UssdService.dialUssd(
        '*99#',
        subscriptionId: AppState.preferredSim?.subscriptionId,
      );
    } catch (e) {
      _showError('Failed to start session: $e');
    }
  }

  // ── Handle each session step ──────────────────────────────────────────────

  int _step = 0;

  void _handleSessionEvent(SessionEvent event, String pin) async {
    switch (event.type) {
      case SessionEventType.sessionResponse:
        await _handleStep(event.message ?? '', pin);

      case SessionEventType.sessionEnd:
        _parseBalanceResult(event.message ?? '');

      case SessionEventType.sessionTimeout:
        _showError('Session timed out. Please try again.');

      case SessionEventType.sessionError:
        _showError(event.errorReason ?? 'Something went wrong.');

      case SessionEventType.incomingCall:
        _showIncomingCallWarning(pin);

      default:
        break;
    }
  }

  Future<void> _handleStep(String message, String pin) async {
    _step++;

    // Step 1 — Main menu received → send '3' for Check Balance
    if (_step == 1) {
      await Future.delayed(const Duration(milliseconds: 300));
      await UssdService.sendReply('3');
      return;
    }

    // Step 2 — PIN prompt received → send UPI PIN
    if (_step == 2) {
      await Future.delayed(const Duration(milliseconds: 300));
      await UssdService.sendReply(pin);
      // Clear PIN from local variable
      pin = '';
      return;
    }

    // Step 3+ — Balance result
    _parseBalanceResult(message);
  }

  void _parseBalanceResult(String message) {
    _sessionSub?.cancel();

    if (!mounted) return;

    // Check for error patterns
    final lower = message.toLowerCase();
    if (lower.contains('invalid') ||
        lower.contains('wrong pin') ||
        lower.contains('incorrect') ||
        lower.contains('failed')) {
      _showError('Incorrect UPI PIN. Please try again.');
      return;
    }

    setState(() {
      _balance = message;
      _state = _ScreenState.result;
      _step = 0;
    });
  }

  void _showError(String msg) {
    if (!mounted) return;
    setState(() {
      _errorMsg = msg;
      _state = _ScreenState.error;
      _step = 0;
    });
  }

  void _reset() {
    _sessionSub?.cancel();
    UssdService.endSession();
    setState(() {
      _state = _ScreenState.pinEntry;
      _balance = '';
      _errorMsg = '';
      _step = 0;
    });
  }

  // ── Incoming call warning ─────────────────────────────────────────────────

  void _showIncomingCallWarning(String pin) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Incoming Call'),
        content: const Text(
          'You have an incoming call. Answering will end your current session.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Continue session — reject call implicitly
            },
            child: const Text('Ignore Call'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _reset();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Take Call'),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Check Balance'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: switch (_state) {
          _ScreenState.pinEntry => _buildPinEntry(),
          _ScreenState.loading => _buildLoading(),
          _ScreenState.result => _buildResult(),
          _ScreenState.error => _buildError(),
        },
      ),
    );
  }

  // ── PIN Entry ─────────────────────────────────────────────────────────────

  Widget _buildPinEntry() {
    return SingleChildScrollView(
      key: const ValueKey('pin'),
      child: Column(
        children: [
          // Bank context banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            color: AppColors.primary.withOpacity(0.05),
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'You are checking your account balance',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          UpiPinPad(
            pinLength: 6,
            title: 'Enter your UPI PIN',
            subtitle: 'Your 6-digit UPI PIN',
            actionLabel: 'Check Balance',
            showBankContext: true,
            bankName: AppState.myDetails?.bankName,
            accountLast4: AppState.myDetails?.accountLast4,
            onCompleted: _startSession,
            onCancel: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // ── Loading ───────────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return Center(
      key: const ValueKey('loading'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Checking your balance...',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Connecting to your bank via *99#',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  // ── Result ────────────────────────────────────────────────────────────────

  Widget _buildResult() {
    return Center(
      key: const ValueKey('result'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success icon
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 48,
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            Text(
              'Account Balance',
              style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Balance card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: AppDecorations.card(),
              child: Column(
                children: [
                  // Bank info
                  if (AppState.myDetails != null) ...[
                    Text(
                      AppState.myDetails!.bankName,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Savings ••••${AppState.myDetails!.accountLast4}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Divider(),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Balance text from *99# response
                  SelectableText(
                    _balance,
                    style: AppTextStyles.bodyLarge.copyWith(
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Copy button
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _balance));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Balance details copied'),
                          duration: Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Check again button
            FilledButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Check Again'),
            ),

            const SizedBox(height: AppSpacing.md),

            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error ─────────────────────────────────────────────────────────────────

  Widget _buildError() {
    return Center(
      key: const ValueKey('error'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 48,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Something went wrong',
              style: AppTextStyles.headingSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _errorMsg,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
