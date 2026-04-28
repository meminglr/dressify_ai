import 'package:flutter/material.dart';
import 'package:dressifyai/features/ai_look_generator/viewmodels/generation_queue_view_model.dart';

/// Test script to verify queue system is working
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🔍 Testing Queue System...\n');
  
  final queueVm = GenerationQueueViewModel.instance;
  
  print('1. Checking initialization status:');
  print('   - Is initialized: ${queueVm.isInitialized}');
  print('   - Is loading: ${queueVm.isLoading}');
  
  print('\n2. Checking queue state:');
  print('   - Active generation: ${queueVm.activeGeneration != null ? "Yes" : "No"}');
  print('   - Queue length: ${queueVm.queue.length}');
  print('   - History length: ${queueVm.history.length}');
  print('   - Total pending: ${queueVm.totalPending}');
  
  print('\n3. Checking bottom sheet state:');
  print('   - Is visible: ${queueVm.isBottomSheetVisible}');
  print('   - Is minimized: ${queueVm.isMinimized}');
  
  print('\n✅ Test completed!');
  print('\nIf you see "Is initialized: false", run:');
  print('   await GenerationQueueViewModel.instance.initialize();');
}
