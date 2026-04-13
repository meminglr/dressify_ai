import 'package:flutter/material.dart';

/// AI Generation screen placeholder
/// TODO: Implement full AI generation functionality
class AIGenerationScreen extends StatelessWidget {
  const AIGenerationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Üret'),
        backgroundColor: const Color(0xFF742FE5),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 64,
                color: Color(0xFF742FE5),
              ),
              const SizedBox(height: 16),
              Text(
                'AI Look Oluştur',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'AI look oluşturma özelliği yakında eklenecek',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF5A6062),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
