// Example usage of FlexibleSpaceBarWidget
// This file demonstrates how to use the FlexibleSpaceBarWidget in a SliverAppBar

import 'package:flutter/material.dart';
import '../models/profile.dart';
import '../models/user_stats.dart';
import 'flexible_space_bar_widget.dart';

/// Example screen showing how to use FlexibleSpaceBarWidget
class FlexibleSpaceBarExample extends StatelessWidget {
  const FlexibleSpaceBarExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Example profile data
    final profile = Profile(
      id: 'user_001',
      fullName: 'Alex Rivera',
      username: '@alexrivera',
      bio: 'Digital Fashion Curator',
      avatarUrl: 'https://example.com/avatar.jpg',
      coverImageUrl: 'https://example.com/cover.jpg',
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      updatedAt: DateTime.now(),
    );

    // Example stats data
    final stats = UserStats(
      aiLooksCount: 24,
      uploadsCount: 12,
      modelsCount: 8,
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // SliverAppBar with FlexibleSpaceBarWidget
          SliverAppBar(
            expandedHeight: FlexibleSpaceBarWidget.expandedHeight,
            collapsedHeight: FlexibleSpaceBarWidget.collapsedHeight,
            pinned: false,
            floating: false,
            flexibleSpace: FlexibleSpaceBarWidget(
              profile: profile,
              stats: stats,
            ),
            actions: [
              // Settings button
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  // Navigate to settings
                },
              ),
            ],
          ),
          
          // Additional content below the header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: const Text('Content below the flexible header'),
            ),
          ),
        ],
      ),
    );
  }
}
