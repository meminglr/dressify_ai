import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../auth/login_screen.dart';
import '../virtual_tryon/virtual_tryon_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    final userName =
        user?.userMetadata?['full_name'] ??
        user?.email?.split('@').first ??
        'User';

    return Scaffold(
      appBar: AppBar(toolbarHeight: 0,),
      body: CustomScrollView(
        controller: controller,
        slivers: [
          _buildAppbar(userName, context),
          _buildHeader(context),
          _buildList(),
        ],
      ),
    );
  }

  SliverPadding _buildList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.onSurface.withAlpha(5),
                    blurRadius: 40,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  SliverPadding _buildHeader(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      sliver: SliverToBoxAdapter(
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const VirtualTryOnScreen()),
            );
          },
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: AppColors.onSurface.withAlpha(5),
                  blurRadius: 40,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'YENİ ÖZELLİK',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Yapay Zeka Deneme Odası',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Satın almadan önce nasıl göründüğüne bakın.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.outlineVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  SliverPadding _buildAppbar(userName, BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
      sliver: SliverAppBar(
        pinned: false,
        floating: true,

        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Merhaba, $userName',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.outlineVariant,
                  ),
                ),
                Text(
                  'Tarzınızı Keşfedin',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
            GestureDetector(
              onTap: () async {
                await context.read<AuthViewModel>().logout();

                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: CircleAvatar(
                backgroundColor: AppColors.primary.withAlpha(20),
                radius: 24,
                child: const Icon(
                  Iconsax.logout,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
