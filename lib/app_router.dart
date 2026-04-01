import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/send_money/send_money_screen.dart';
import 'screens/request_money/request_money_screen.dart';
import 'screens/check_balance/check_balance_screen.dart';
import 'screens/my_profile/my_profile_screen.dart';
import 'screens/pending_requests/pending_requests_screen.dart';
import 'screens/transactions/transactions_screen.dart';
import 'screens/upi_pin/upi_pin_screen.dart';

class AppRouter {
  // ── Route names ───────────────────────────────────────────────────────────
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const sendMoney = '/send-money';
  static const requestMoney = '/request-money';
  static const checkBalance = '/check-balance';
  static const myProfile = '/my-profile';
  static const pendingRequests = '/pending-requests';
  static const transactions = '/transactions';
  static const upiPin = '/upi-pin';

  // ── Route generator ───────────────────────────────────────────────────────
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _fade(const SplashScreen());

      case onboarding:
        return _fade(const OnboardingScreen());

      case home:
        return _fade(const HomeScreen());

      case sendMoney:
        return _slide(const SendMoneyScreen());

      case requestMoney:
        return _slide(const RequestMoneyScreen());

      case checkBalance:
        return _slide(const CheckBalanceScreen());

      case myProfile:
        return _slide(const MyProfileScreen());

      case pendingRequests:
        return _slide(const PendingRequestsScreen());

      case transactions:
        return _slide(const TransactionsScreen());

      case upiPin:
        return _slide(const UpiPinScreen());

      default:
        return _fade(const SplashScreen());
    }
  }

  // ── Transition helpers ────────────────────────────────────────────────────
  static PageRouteBuilder _fade(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
      );

  static PageRouteBuilder _slide(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) {
          final tween = Tween(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      );
}
