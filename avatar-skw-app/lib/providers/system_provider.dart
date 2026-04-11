import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import 'auth_provider.dart';
import 'dart:async';

class SystemState {
  final bool maintenanceMode;
  final bool isLoading;
  
  SystemState({
    this.maintenanceMode = false,
    this.isLoading = true,
  });
  
  SystemState copyWith({bool? maintenanceMode, bool? isLoading}) {
    return SystemState(
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SystemNotifier extends StateNotifier<SystemState> with WidgetsBindingObserver {
  final ApiClient _apiClient;
  
  Timer? _timer;

  SystemNotifier(this._apiClient) : super(SystemState()) {
    WidgetsBinding.instance.addObserver(this);
    checkSystemStatus();
    // Poll every 60 seconds
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => checkSystemStatus());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
       // Check immediately when app opens/resumes
       checkSystemStatus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }
  
  Future<void> checkSystemStatus() async {
    try {
      final response = await _apiClient.dio.get('/settings/public-config');
      if (response.statusCode == 200) {
        final data = response.data;
        final isMaintenance = data['maintenance_mode'] == true;
        
        if (state.maintenanceMode != isMaintenance) {
          // print('DEBUG_SYSTEM: Maintenance Mode changed to $isMaintenance');
          state = state.copyWith(
            maintenanceMode: isMaintenance,
            isLoading: false,
          );
        }
      }
    } catch (e) {
      // In case of error (e.g. timeout), do not flip the switch.
      // Just keep current state.
    }
  }
}

final systemProvider = StateNotifierProvider<SystemNotifier, SystemState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SystemNotifier(apiClient);
});
