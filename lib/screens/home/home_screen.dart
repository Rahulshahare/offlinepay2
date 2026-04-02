import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app_theme.dart';
import '../../app_router.dart';
import '../../ussd_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  bool _refreshing = false;

  // ── Refresh My Details in background ─────────────────────────────────────

  Future<void> _refreshDetails() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);

    try {
      await UssdService.setCurrentStep('fetch_my_details');
      await UssdService.dialUssd(
        '*99#',
        subscriptionId: AppState.preferredSim?.subscriptionId,
      );

      final sub = UssdService.sessionStream.listen(null);
      sub.onData((event) async {
        if (event.type == SessionEventType.myDetails) {
          AppState.myDetails = event.myDetails;
          await sub.cancel();
          if (mounted) setState(() => _refreshing = false);
        } else if (event.type == SessionEventType.sessionError ||
                   event.type == SessionEventType.sessionEnd) {
          await sub.cancel();
          if (mounted) setState(() => _refreshing = false);
        }
      });
    } catch (_) {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [

          // ── App Bar ───────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned:         true,
            elevation:      0,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(),
            ),
            actions: [
              // Refresh button
              IconButton(
                onPressed: _refreshDetails,
                icon: _refreshing
                    ? const SizedBox(
                        width:  20,
                        height: 20,
                        child:  CircularProgressIndicator(
                          strokeWidth: 2,
                          color:       Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                      ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
          ),

          // ── Quick actions ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.lg,
                AppSpacing.md, 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What would you like to do?',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),

          // ── Menu grid ─────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
            ),
            sliver: SliverGrid(
              delegate: SliverChildListDelegate(
                _menuItems.map((item) => _MenuCard(
                  item:  item,
                  onTap: () => Navigator.of(context)
                      .pushNamed(item.route),
                )).toList(),
              ),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:   2,
                mainAxisSpacing:  AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.1,
              ),
            ),
          ),

          // ── UPI ID card ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: _buildUpiIdCard(),
            ),
          ),

          // ── Bottom padding ────────────────────────────────────────────────
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.xl),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final details = AppState.myDetails;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.xl,
            AppSpacing.lg, AppSpacing.md,
          ),
          child: Row(
            children: [

              // Avatar
              Container(
                width:  56,
                height: 56,
                decoration: BoxDecoration(
                  color:  Colors.white.withOpacity(0.2),
                  shape:  BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    details?.fullName.isNotEmpty == true
                        ? details!.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize:   24,
                      fontWeight: FontWeight.w700,
                      color:      Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              // Name + bank
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize:       MainAxisSize.min,
                  children: [
                    Text(
                      details != null
                          ? 'Hello, ${details.fullName.split(' ').first}'
                          : 'Hello',
                      style: const TextStyle(
                        fontSize:   22,
                        fontWeight: FontWeight.w700,
                        color:      Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (details != null)
                      Text(
                        '${details.bankName} ••••${details.accountLast4}',
                        style: TextStyle(
                          fontSize: 13,
                          color:    Colors.white.withOpacity(0.8),
                        ),
                      ),
                  ],
                ),
              ),

              // OfflinePay logo
              const Text(
                '₹',
                style: TextStyle(
                  fontSize:   28,
                  fontWeight: FontWeight.w700,
                  color:      Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── UPI ID card ───────────────────────────────────────────────────────────

  Widget _buildUpiIdCard() {
    final upiId = AppState.myDetails?.upiId ?? '';
    if (upiId.isEmpty) return const SizedBox();

    return Container(
      padding:    const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.card(),
      child: Row(
        children: [
          Container(
            width:  40,
            height: 40,
            decoration: BoxDecoration(
              color:        AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              Icons.account_circle_outlined,
              color: AppColors.primary,
              size:  22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your UPI ID', style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                )),
                const SizedBox(height: 2),
                Text(upiId, style: AppTextStyles.upiId),
              ],
            ),
          ),
          // Copy button
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: upiId));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:  Text('UPI ID copied'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(
              Icons.copy_rounded,
              size:  18,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Menu items ────────────────────────────────────────────────────────────

  static final _menuItems = [
    _MenuItem(
      icon:        Icons.send_rounded,
      label:       'Send Money',
      description: 'Pay anyone instantly',
      color:       AppColors.primary,
      route:       AppRouter.sendMoney,
    ),
    _MenuItem(
      icon:        Icons.request_page_rounded,
      label:       'Request Money',
      description: 'Collect from anyone',
      color:       AppColors.accentDark,
      route:       AppRouter.requestMoney,
    ),
    _MenuItem(
      icon:        Icons.account_balance_wallet_rounded,
      label:       'Check Balance',
      description: 'View account balance',
      color:       AppColors.success,
      route:       AppRouter.checkBalance,
    ),
    _MenuItem(
      icon:        Icons.receipt_long_rounded,
      label:       'Transactions',
      description: 'History & rewards',
      color:       AppColors.warning,
      route:       AppRouter.transactions,
    ),
    _MenuItem(
      icon:        Icons.pending_actions_rounded,
      label:       'Pending',
      description: 'Pending requests',
      color:       AppColors.error,
      route:       AppRouter.pendingRequests,
    ),
    _MenuItem(
      icon:        Icons.person_rounded,
      label:       'My Profile',
      description: 'Account & settings',
      color:       AppColors.primaryLight,
      route:       AppRouter.myProfile,
    ),
  ];
}

// ── Menu item model ───────────────────────────────────────────────────────────

class _MenuItem {
  final IconData icon;
  final String   label;
  final String   description;
  final Color    color;
  final String   route;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.route,
  });
}

// ── Menu card widget ──────────────────────────────────────────────────────────

class _MenuCard extends StatefulWidget {
  final _MenuItem   item;
  final VoidCallback onTap;

  const _MenuCard({required this.item, required this.onTap});

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.identity()
          ..scale(_pressed ? 0.96 : 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color:        AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow:    _pressed ? [] : AppShadows.card,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Icon
            Container(
              width:  48,
              height: 48,
              decoration: BoxDecoration(
                color:        widget.item.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                widget.item.icon,
                color: widget.item.color,
                size:  24,
              ),
            ),

            const Spacer(),

            // Label
            Text(
              widget.item.label,
              style: AppTextStyles.labelLarge,
            ),
            const SizedBox(height: 2),

            // Description
            Text(
              widget.item.description,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}