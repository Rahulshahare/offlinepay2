import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app_theme.dart';
import '../../app_router.dart';
import '../../ussd_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // ── Step states ───────────────────────────────────────────────────────────
  bool _phoneGranted = false;
  bool _dialerGranted = false;
  bool _simSelected = false;
  bool _detailsFetched = false;
  bool _fetchingDetails = false;
  String _fetchError = '';

  SimSlot? _selectedSim;
  List<SimSlot> _simSlots = [];

  // ── Pages ─────────────────────────────────────────────────────────────────
  // 0: Welcome
  // 1: Prerequisite info
  // 2: Phone permission
  // 3: Default dialer
  // 4: SIM selection
  // 5: Fetch My Details
  // 6: App PIN setup

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
    setState(() => _currentPage++);
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
    setState(() => _currentPage = page);
  }

  // ── Permission handlers ───────────────────────────────────────────────────

  Future<void> _requestPhonePermission() async {
    final status = await Permission.phone.request();
    if (status.isGranted) {
      setState(() => _phoneGranted = true);
      await Future.delayed(const Duration(milliseconds: 500));
      _nextPage();
    } else {
      _showPermissionDeniedSnack('Phone permission is required');
    }
  }

  Future<void> _requestDefaultDialer() async {
    final granted = await UssdService.requestDefaultDialer();
    if (granted) {
      setState(() => _dialerGranted = true);
      await Future.delayed(const Duration(milliseconds: 500));
      _loadSimSlots();
      _nextPage();
    } else {
      _showPermissionDeniedSnack(
        'Default dialer permission is required for offline payments',
      );
    }
  }

  Future<void> _loadSimSlots() async {
    try {
      final slots = await UssdService.getSimSlots();
      setState(() => _simSlots = slots);
    } catch (e) {
      setState(() => _simSlots = []);
    }
  }

  void _selectSim(SimSlot sim) async {
    setState(() {
      _selectedSim = sim;
      _simSelected = true;
    });

    // Save preferred SIM
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('preferred_sub_id', sim.subscriptionId);
    AppState.preferredSim = sim;

    await Future.delayed(const Duration(milliseconds: 600));
    _nextPage();
  }

  Future<void> _fetchMyDetails() async {
    setState(() {
      _fetchingDetails = true;
      _fetchError = '';
    });

    try {
      // Dial *99# and navigate to My Profile → My Details
      await UssdService.setCurrentStep('fetch_my_details');
      await UssdService.dialUssd(
        '*99#',
        subscriptionId: _selectedSim?.subscriptionId,
      );

      // Listen for My Details response
      final sub = UssdService.sessionStream.listen(null);
      sub.onData((event) async {
        if (event.type == SessionEventType.myDetails &&
            event.myDetails != null) {
          AppState.myDetails = event.myDetails;
          await sub.cancel();

          if (!mounted) return;
          setState(() {
            _fetchingDetails = false;
            _detailsFetched = true;
          });

          await Future.delayed(const Duration(milliseconds: 800));
          if (!mounted) return;
          _nextPage();
        } else if (event.type == SessionEventType.sessionError) {
          await sub.cancel();
          if (!mounted) return;
          setState(() {
            _fetchingDetails = false;
            _fetchError = 'Could not fetch details. Please try again.';
          });
        }
      });
    } catch (e) {
      setState(() {
        _fetchingDetails = false;
        _fetchError = 'Error: $e';
      });
    }
  }

  // ── Complete onboarding ───────────────────────────────────────────────────

  Future<void> _completeOnboarding({bool setPinLater = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_onboarded', true);

    if (!mounted) return;

    if (setPinLater) {
      Navigator.of(context).pushReplacementNamed(AppRouter.home);
    } else {
      Navigator.of(context).pushReplacementNamed(AppRouter.appPin);
    }
  }

  void _showPermissionDeniedSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Progress indicator ────────────────────────────────────────
            _buildProgress(),

            // ── Pages ─────────────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildWelcomePage(),
                  _buildPrerequisitePage(),
                  _buildPhonePermissionPage(),
                  _buildDefaultDialerPage(),
                  _buildSimSelectionPage(),
                  _buildFetchDetailsPage(),
                  _buildAppPinPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Progress bar ──────────────────────────────────────────────────────────

  Widget _buildProgress() {
    const total = 7;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      child: Row(
        children: List.generate(total, (i) {
          final done = i <= _currentPage;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
              decoration: BoxDecoration(
                color: done ? AppColors.primary : AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Page 0: Welcome ───────────────────────────────────────────────────────

  Widget _buildWelcomePage() {
    return _OnboardingPage(
      icon: '₹',
      iconBg: AppColors.primary,
      title: 'Welcome to\nOfflinePay',
      description:
          'The first UPI payment app that works\nwithout internet. Send money, check\nbalance and more — anywhere.',
      buttonLabel: 'Get Started',
      onTap: _nextPage,
    );
  }

  // ── Page 1: Prerequisite ──────────────────────────────────────────────────

  Widget _buildPrerequisitePage() {
    return _OnboardingPage(
      icon: '🏦',
      iconBg: AppColors.accentDark,
      title: 'Before you begin',
      description:
          'OfflinePay works with your existing bank account linked to this mobile number.\n\nMake sure you have already registered for UPI with your bank or via BHIM before continuing.',
      buttonLabel: 'I understand',
      onTap: _nextPage,
      showNote: true,
      note:
          'No new bank account needed — we use your existing UPI registration.',
    );
  }

  // ── Page 2: Phone permission ──────────────────────────────────────────────

  Widget _buildPhonePermissionPage() {
    return _OnboardingPage(
      icon: '📞',
      iconBg: AppColors.primaryLight,
      title: 'Phone Access',
      description:
          'OfflinePay needs permission to make USSD calls to your bank.\n\nThis is used only for processing your payments — no calls are made without your action.',
      buttonLabel: _phoneGranted ? '✓ Permission Granted' : 'Grant Permission',
      buttonColor: _phoneGranted ? AppColors.success : AppColors.primary,
      onTap: _phoneGranted ? _nextPage : _requestPhonePermission,
    );
  }

  // ── Page 3: Default dialer ────────────────────────────────────────────────

  Widget _buildDefaultDialerPage() {
    return _OnboardingPage(
      icon: '🔒',
      iconBg: AppColors.warning,
      title: 'Enable Offline\nPayments',
      description:
          'To process payments without internet, OfflinePay needs to manage phone calls temporarily during each transaction.\n\nYour current dialer app is not affected.',
      buttonLabel: _dialerGranted ? '✓ Enabled' : 'Enable Now',
      buttonColor: _dialerGranted ? AppColors.success : AppColors.primary,
      onTap: _dialerGranted ? _nextPage : _requestDefaultDialer,
    );
  }

  // ── Page 4: SIM selection ─────────────────────────────────────────────────

  Widget _buildSimSelectionPage() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xl),

          // Icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Center(
              child: Text('📱', style: TextStyle(fontSize: 36)),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          Text('Select your SIM', style: AppTextStyles.headingLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Choose the SIM card linked to your bank account for *99# payments.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // SIM cards
          if (_simSlots.isEmpty)
            const Center(child: CircularProgressIndicator())
          else
            ..._simSlots.map((sim) => _SimCard(
                  sim: sim,
                  isSelected:
                      _selectedSim?.subscriptionId == sim.subscriptionId,
                  onTap: () => _selectSim(sim),
                )),
        ],
      ),
    );
  }

  // ── Page 5: Fetch My Details ──────────────────────────────────────────────

  Widget _buildFetchDetailsPage() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_fetchingDetails) ...[
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Fetching your account details\nvia *99#...',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ] else if (_detailsFetched && AppState.myDetails != null) ...[
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 72,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Welcome,\n${AppState.myDetails!.fullName}',
              textAlign: TextAlign.center,
              style: AppTextStyles.headingLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${AppState.myDetails!.bankName} ••••${AppState.myDetails!.accountLast4}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ] else ...[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: const Center(
                child: Text('🔗', style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Link your account',
              style: AppTextStyles.headingLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'We will connect to your bank via *99# to fetch your account details. No internet required.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (_fetchError.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _fetchError,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: _fetchMyDetails,
              child: const Text('Connect Now'),
            ),
          ],
        ],
      ),
    );
  }

  // ── Page 6: App PIN setup ─────────────────────────────────────────────────

  Widget _buildAppPinPage() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xl),

          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Center(
              child: Text('🔐', style: TextStyle(fontSize: 36)),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          Text('Secure your app', style: AppTextStyles.headingLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Set a 4-digit PIN to protect OfflinePay. You can also set this later in Settings.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          const Spacer(),

          // Set PIN button
          FilledButton(
            onPressed: () => _completeOnboarding(setPinLater: false),
            child: const Text('Set App PIN'),
          ),

          const SizedBox(height: AppSpacing.md),

          // Skip button
          OutlinedButton(
            onPressed: () => _completeOnboarding(setPinLater: true),
            child: const Text('Skip for now'),
          ),

          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

// ── Reusable onboarding page widget ──────────────────────────────────────────
class _OnboardingPage extends StatelessWidget {
  final String icon;
  final Color iconBg;
  final String title;
  final String description;
  final String buttonLabel;
  final Color? buttonColor;
  final VoidCallback onTap;
  final bool showNote;
  final String? note;

  const _OnboardingPage({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onTap,
    this.buttonColor,
    this.showNote = false,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xl),

          // Icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: iconBg.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 36)),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Title
          Text(title, style: AppTextStyles.headingLarge),

          const SizedBox(height: AppSpacing.md),

          // Description
          Text(
            description,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          // Note
          if (showNote && note != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.accentLight.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppColors.accent.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.accentDark,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      note!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.accentDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Spacer(),

          // Button
          FilledButton(
            onPressed: onTap,
            style: buttonColor != null
                ? FilledButton.styleFrom(backgroundColor: buttonColor)
                : null,
            child: Text(buttonLabel),
          ),

          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

// ── SIM card tile ─────────────────────────────────────────────────────────────
class _SimCard extends StatelessWidget {
  final SimSlot sim;
  final bool isSelected;
  final VoidCallback onTap;

  const _SimCard({
    required this.sim,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected ? AppShadows.card : [],
        ),
        child: Row(
          children: [
            // SIM icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.1)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Center(
                child: Text(
                  'SIM ${sim.simSlotIndex + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // SIM details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sim.displayName,
                    style: AppTextStyles.labelLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sim.carrierName,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (sim.number.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      sim.number,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Selected indicator
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 24,
              )
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.divider,
                    width: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
