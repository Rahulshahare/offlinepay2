
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_theme.dart';

// ── PIN Pad Widget ────────────────────────────────────────────────────────────
// Reusable across:
// - Check Balance (6-digit UPI PIN)
// - Send Money confirmation (6-digit UPI PIN)
// - App lock (4-digit App PIN)
// - Set/Change UPI PIN

class UpiPinPad extends StatefulWidget {
  final int          pinLength;
  final String       title;
  final String       subtitle;
  final String       actionLabel;
  final bool         showBankContext;
  final String?      bankName;
  final String?      accountLast4;
  final bool         randomizeKeys;
  final void Function(String pin) onCompleted;
  final VoidCallback? onCancel;

  const UpiPinPad({
    super.key,
    required this.pinLength,
    required this.title,
    required this.actionLabel,
    required this.onCompleted,
    this.subtitle        = '',
    this.showBankContext = false,
    this.bankName,
    this.accountLast4,
    this.randomizeKeys   = false,
    this.onCancel,
  });

  @override
  State<UpiPinPad> createState() => _UpiPinPadState();
}

class _UpiPinPadState extends State<UpiPinPad>
    with SingleTickerProviderStateMixin {

  final List<int> _pin       = [];
  late List<int>  _keyLayout;
  bool            _submitted = false;

  late AnimationController _shakeController;
  late Animation<double>   _shakeAnim;

  @override
  void initState() {
    super.initState();
    _buildKeyLayout();
    _setupShakeAnimation();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  // ── Key layout ────────────────────────────────────────────────────────────

  void _buildKeyLayout() {
    final keys = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0];
    if (widget.randomizeKeys) keys.shuffle();
    _keyLayout = keys;
  }

  // ── Shake animation for wrong PIN ─────────────────────────────────────────

  void _setupShakeAnimation() {
    _shakeController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 500),
    );

    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  void shake() {
    _shakeController.forward(from: 0);
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _pin.clear());
    });
  }

  // ── PIN input handlers ────────────────────────────────────────────────────

  void _onKeyTap(int digit) {
    if (_pin.length >= widget.pinLength || _submitted) return;

    HapticFeedback.lightImpact();
    setState(() => _pin.add(digit));

    if (_pin.length == widget.pinLength) {
      _onPinComplete();
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _pin.removeLast());
  }

  void _onPinComplete() {
    setState(() => _submitted = true);
    final pin = _pin.join();

    // Small delay for last dot to animate
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      widget.onCompleted(pin);

      // Clear PIN from memory immediately after callback
      setState(() {
        _pin.clear();
        _submitted = false;
      });
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        // ── Bank context header ───────────────────────────────────────────
        if (widget.showBankContext &&
            widget.bankName != null &&
            widget.accountLast4 != null)
          _buildBankContext(),

        const SizedBox(height: AppSpacing.xl),

        // ── Title ─────────────────────────────────────────────────────────
        Text(
          widget.title,
          style: AppTextStyles.headingMedium,
          textAlign: TextAlign.center,
        ),

        if (widget.subtitle.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            widget.subtitle,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],

        const SizedBox(height: AppSpacing.xl),

        // ── PIN dots ──────────────────────────────────────────────────────
        AnimatedBuilder(
          animation: _shakeAnim,
          builder: (_, child) {
            final offset = _shakeAnim.value == 0
                ? 0.0
                : ((_shakeAnim.value * 4).round() % 2 == 0 ? 8.0 : -8.0);
            return Transform.translate(
              offset: Offset(offset, 0),
              child:  child,
            );
          },
          child: _buildPinDots(),
        ),

        const SizedBox(height: AppSpacing.xl),

        // ── Security tip ──────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.shield_outlined,
              size:  14,
              color: AppColors.textHint,
            ),
            const SizedBox(width: 4),
            Text(
              'Never share your PIN with anyone',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.xl),

        // ── Keypad ────────────────────────────────────────────────────────
        _buildKeypad(),

      ],
    );
  }

  // ── Bank context ──────────────────────────────────────────────────────────

  Widget _buildBankContext() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical:   AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color:        AppColors.primary.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color:        AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              Icons.account_balance_rounded,
              color: AppColors.primary,
              size:  20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.bankName!,
                  style: AppTextStyles.labelMedium,
                ),
                Text(
                  'Savings ••••${widget.accountLast4}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── PIN dots ──────────────────────────────────────────────────────────────

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.pinLength, (i) {
        final filled = i < _pin.length;
        return AnimatedContainer(
          duration:     const Duration(milliseconds: 200),
          curve:        Curves.easeOutBack,
          margin:       const EdgeInsets.symmetric(horizontal: 10),
          width:        filled ? 18 : 16,
          height:       filled ? 18 : 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled
                ? AppColors.primary
                : Colors.transparent,
            border: Border.all(
              color: filled
                  ? AppColors.primary
                  : AppColors.textHint,
              width: 2,
            ),
          ),
        );
      }),
    );
  }

  // ── Keypad ────────────────────────────────────────────────────────────────

  Widget _buildKeypad() {
    // Build 4 rows: [1,2,3], [4,5,6], [7,8,9], [cancel,0,backspace]
    final rows = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [

          // Number rows
          ...rows.map((row) => Row(
            children: row.map((keyIndex) {
              final digit = _keyLayout[keyIndex];
              return Expanded(
                child: _KeyButton(
                  label:   '$digit',
                  onTap:   () => _onKeyTap(digit),
                ),
              );
            }).toList(),
          )),

          // Bottom row: Cancel | 0 | Backspace
          Row(
            children: [

              // Cancel
              Expanded(
                child: widget.onCancel != null
                    ? _KeyButton(
                        label:       'Cancel',
                        isText:      true,
                        onTap:       widget.onCancel!,
                      )
                    : const SizedBox(),
              ),

              // 0
              Expanded(
                child: _KeyButton(
                  label: '${_keyLayout[9]}',
                  onTap: () => _onKeyTap(_keyLayout[9]),
                ),
              ),

              // Backspace
              Expanded(
                child: _KeyButton(
                  isBackspace: true,
                  onTap:       _onBackspace,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Key Button ────────────────────────────────────────────────────────────────

class _KeyButton extends StatefulWidget {
  final String?      label;
  final bool         isBackspace;
  final bool         isText;
  final VoidCallback onTap;

  const _KeyButton({
    required this.onTap,
    this.label,
    this.isBackspace = false,
    this.isText      = false,
  });

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:  (_) => setState(() => _pressed = true),
      onTapUp:    (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin:   const EdgeInsets.all(6),
        height:   64,
        decoration: BoxDecoration(
          color: widget.isText
              ? Colors.transparent
              : _pressed
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: widget.isText || _pressed
              ? []
              : AppShadows.subtle,
        ),
        child: Center(
          child: widget.isBackspace
              ? Icon(
                  Icons.backspace_outlined,
                  color: AppColors.textSecondary,
                  size:  24,
                )
              : Text(
                  widget.label ?? '',
                  style: widget.isText
                      ? AppTextStyles.labelMedium.copyWith(
                          color: AppColors.primary,
                        )
                      : AppTextStyles.headingMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                ),
        ),
      ),
    );
  }
}