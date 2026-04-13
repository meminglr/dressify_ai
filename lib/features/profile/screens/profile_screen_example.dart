import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/profile_view_model.dart';
import 'profile_screen.dart';

/// Example usage of ProfileScreen
///
/// This file demonstrates how to properly use ProfileScreen with ChangeNotifierProvider.
/// 
/// ## Usage in your app:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (_) => ChangeNotifierProvider(
///       create: (_) => ProfileViewModel(),
///       child: ProfileScreen(userId: null), // null = current user
///     ),
///   ),
/// );
/// ```
class ProfileScreenExample extends StatelessWidget {
  const ProfileScreenExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Profile Screen Example',
      theme: ThemeData(
        primaryColor: const Color(0xFF742FE5),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      home: ChangeNotifierProvider(
        create: (_) => ProfileViewModel(),
        child: const ProfileScreen(userId: null),
      ),
    );
  }
}

/// Example: Navigate to profile screen from another screen
void navigateToProfile(BuildContext context, {String? userId}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider(
        create: (_) => ProfileViewModel(),
        child: ProfileScreen(userId: userId),
      ),
    ),
  );
}
