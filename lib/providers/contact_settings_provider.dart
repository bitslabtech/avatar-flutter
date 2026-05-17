import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import 'auth_provider.dart';
import '../models/contact_settings.dart';

// State for contact settings
class ContactSettingsNotifier extends StateNotifier<AsyncValue<ContactSettings>> {
  final ApiClient _apiClient;

  ContactSettingsNotifier(this._apiClient) : super(const AsyncValue.loading()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      print('🔍 DEBUG: Loading contact settings...');
      state = const AsyncValue.loading();
      final response = await _apiClient.get('/contact-settings');
      
      print('🔍 DEBUG: Response received: ${response.data}');
      
      // Handle both {data: {...}} and direct {...} formats
      final responseData = response.data;
      final settingsData = responseData is Map && responseData.containsKey('data')
          ? responseData['data']
          : responseData;
      
      print('🔍 DEBUG: Settings data to parse: $settingsData');
      
      final settings = ContactSettings.fromJson(settingsData as Map<String, dynamic>);
      print('🔍 DEBUG: Settings parsed successfully: $settings');
      state = AsyncValue.data(settings);
    } catch (e, st) {
      print('❌ ERROR loading contact settings: $e');
      print('❌ Stack trace: $st');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateSettings({
    String? supportEmail,
    String? whatsappNumber,
    String? callNumber,
    bool? isActive,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (supportEmail != null) data['supportEmail'] = supportEmail;
      if (whatsappNumber != null) data['whatsappNumber'] = whatsappNumber;
      if (callNumber != null) data['callNumber'] = callNumber;
      if (isActive != null) data['isActive'] = isActive;
      
      await _apiClient.put('/contact-settings', data: data);
      await loadSettings(); // Refresh
    } catch (e) {
      rethrow;
    }
  }
}

final contactSettingsProvider = StateNotifierProvider<ContactSettingsNotifier, AsyncValue<ContactSettings>>((ref) {
  return ContactSettingsNotifier(ref.watch(apiClientProvider));
});
