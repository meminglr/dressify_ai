import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/theme/app_colors.dart';

class VirtualTryOnScreen extends StatelessWidget {
  const VirtualTryOnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Iconsax.arrow_left_2),
              onPressed: () => Navigator.of(context).pop(),
              color: AppColors.onSurface,
            ),
          ),
        ),

        title: const Text('Virtual Try On'),
      ),
    );
  }
}
