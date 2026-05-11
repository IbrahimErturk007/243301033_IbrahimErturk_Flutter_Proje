import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/driver/attendance/screens/attendance_screen.dart';
import '../../features/driver/profile/screens/driver_profile_screen.dart';
import '../../features/driver/trips/screens/driver_home_screen.dart';
import '../../features/driver/trips/screens/trip_detail_screen.dart';
import '../../features/driver/trips/screens/trip_form_screen.dart';
import '../../features/parent/children/screens/child_form_screen.dart';
import '../../features/parent/children/screens/parent_home_screen.dart';
import '../../features/parent/profile/screens/parent_profile_screen.dart';
import '../../features/parent/tracking/screens/child_detail_screen.dart';
import '../../features/shared/screens/logs_screen.dart';
import '../../features/shared/screens/splash_screen.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/logs',
        builder: (_, __) => const LogsScreen(),
      ),

      // Driver
      GoRoute(
        path: '/driver',
        builder: (_, __) => const DriverHomeScreen(),
        routes: [
          GoRoute(
            path: 'profile',
            builder: (_, __) => const DriverProfileScreen(),
          ),
          GoRoute(
            path: 'trip/new',
            builder: (_, __) => const TripFormScreen(),
          ),
          GoRoute(
            path: 'trip/:id',
            builder: (_, st) =>
                TripDetailScreen(tripId: st.pathParameters['id']!),
          ),
          GoRoute(
            path: 'attendance/:id',
            builder: (_, st) =>
                AttendanceScreen(tripId: st.pathParameters['id']!),
          ),
        ],
      ),

      // Parent
      GoRoute(
        path: '/parent',
        builder: (_, __) => const ParentHomeScreen(),
        routes: [
          GoRoute(
            path: 'profile',
            builder: (_, __) => const ParentProfileScreen(),
          ),
          GoRoute(
            path: 'child/new',
            builder: (_, __) => const ChildFormScreen(),
          ),
          GoRoute(
            path: 'child/edit/:id',
            builder: (_, st) =>
                ChildFormScreen(childId: st.pathParameters['id']),
          ),
          GoRoute(
            path: 'child/:id',
            builder: (_, st) =>
                ChildDetailScreen(studentId: st.pathParameters['id']!),
          ),
        ],
      ),
    ],
    errorBuilder: (_, st) => Scaffold(
      appBar: AppBar(title: const Text('Hata')),
      body: Center(child: Text('Sayfa bulunamadı: ${st.uri}')),
    ),
  );
}
