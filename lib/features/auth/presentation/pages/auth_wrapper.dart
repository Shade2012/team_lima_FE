import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:team_five_fe/features/auth/presentation/providers/auth_provider.dart';
import 'package:team_five_fe/features/auth/presentation/pages/login_page.dart';
import 'package:team_five_fe/features/event/presentation/pages/organizer/my_events_page.dart';
import 'package:team_five_fe/features/customer/presentation/pages/customer_main_screen.dart';
import 'package:team_five_fe/features/gate/presentation/pages/gate_operator/gate_operator_dashboard_page.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!authState.isAuthenticated) {
      return const LoginPage();
    }

    final user = authState.currentUser;
    if (user?.role == 'ORGANIZER' || user?.role == 'EVENT_ORGANIZER') {
      return const MyEventsPage();
    }

    if (user?.role == 'GATE_OPERATOR') {
      return const GateOperatorDashboardPage();
    }

    return const CustomerMainScreen();
  }
}
