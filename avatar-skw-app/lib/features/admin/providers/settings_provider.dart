
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/api/api_client.dart';
import '../../../providers/auth_provider.dart';

class AdminSettingsState {
  final bool twoFactorAuth;
  final bool newOrderAlerts;
  final bool newDealerAlert;
  final bool newConsumerAlert;
  final bool maintenanceMode;
  final bool priceIncludesGst;
  final String themeMode; // 'system', 'light', 'dark'
  final String language;
  final Map<String, String> whatsAppConfig;
  final int lastUserCount;
  final double minOrderValue;
  final double shippingCharge;
  final bool isLoading;
  final String? error;

  AdminSettingsState({
    this.twoFactorAuth = false,
    this.newOrderAlerts = true,
    this.newDealerAlert = true,
    this.newConsumerAlert = false,
    this.maintenanceMode = false,
    this.priceIncludesGst = false,
    this.themeMode = 'system',
    this.language = 'en',
    this.whatsAppConfig = const {},
    this.lastUserCount = 0,
    this.minOrderValue = 0.0,
    this.shippingCharge = 0.0,
    this.isLoading = false,
    this.error,
  });

  AdminSettingsState copyWith({
    bool? twoFactorAuth,
    bool? newOrderAlerts,
    bool? newDealerAlert,
    bool? newConsumerAlert,
    bool? maintenanceMode,
    bool? priceIncludesGst,
    String? themeMode,
    String? language,
    Map<String, String>? whatsAppConfig,
    int? lastUserCount,
    double? minOrderValue,
    double? shippingCharge,
    bool? isLoading,
    String? error,
  }) {
    return AdminSettingsState(
      twoFactorAuth: twoFactorAuth ?? this.twoFactorAuth,
      newOrderAlerts: newOrderAlerts ?? this.newOrderAlerts,
      newDealerAlert: newDealerAlert ?? this.newDealerAlert,
      newConsumerAlert: newConsumerAlert ?? this.newConsumerAlert,
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      priceIncludesGst: priceIncludesGst ?? this.priceIncludesGst,
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      whatsAppConfig: whatsAppConfig ?? this.whatsAppConfig,
      lastUserCount: lastUserCount ?? this.lastUserCount,
      minOrderValue: minOrderValue ?? this.minOrderValue,
      shippingCharge: shippingCharge ?? this.shippingCharge,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AdminSettingsNotifier extends StateNotifier<AdminSettingsState> {
  final ApiClient _apiClient;
  
  AdminSettingsNotifier(this._apiClient) : super(AdminSettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load Local Settings
      final newOrderAlerts = prefs.getBool('admin_alert_orders') ?? true;
      final newDealerAlert = prefs.getBool('admin_alert_dealer') ?? true;
      final newConsumerAlert = prefs.getBool('admin_alert_consumer') ?? false;
      final themeMode = prefs.getString('admin_theme') ?? 'system';
      final language = prefs.getString('admin_language') ?? 'en';
      final lastUserCount = prefs.getInt('admin_last_user_count') ?? 0;

      // Load Server Settings
      bool maintenanceMode = false;
      bool priceIncludesGst = false;
      double minOrderValue = 500.0;
      double shippingCharge = 0.0;
      Map<String, String> waConfig = {};
      
      try {
        final response = await _apiClient.get('/settings');
        final List<dynamic> settingsList = response.data; // Expecting list of {key, value}

        // Helper to find value from list
        String? getValue(String key) {
          final item = settingsList.firstWhere(
            (element) => element['key'] == key,
            orElse: () => null,
          );
          return item?['value'];
        }

        maintenanceMode = getValue('system.maintenance_mode') == 'true';
        priceIncludesGst = getValue('system.price_includes_gst') == 'true';
        minOrderValue = double.tryParse(getValue('system.min_order_value') ?? '500') ?? 500.0;
        shippingCharge = double.tryParse(getValue('system.shipping_charge') ?? '0') ?? 0.0;
        
        // Populate WhatsApp Config
        waConfig = {
          'number': getValue('whatsapp.business_number') ?? '',
          'mode': getValue('whatsapp.integration_mode') ?? 'cloud_api',
          'templateId': getValue('whatsapp.template_id') ?? '', // Legacy
          'phoneId': getValue('whatsapp.phone_id') ?? '',
          'accessToken': getValue('whatsapp.access_token') ?? '',
          
          // Templates
          'otp_name': getValue('whatsapp.template.otp.name') ?? '',
          'otp_lang': getValue('whatsapp.template.otp.lang') ?? 'en_US',
          'otp_enabled': getValue('whatsapp.template.otp.enabled') ?? 'true',
          'user_reg_name': getValue('whatsapp.template.user_reg.name') ?? '',
          'user_reg_lang': getValue('whatsapp.template.user_reg.lang') ?? 'en_US',
          'user_reg_enabled': getValue('whatsapp.template.user_reg.enabled') ?? 'true',
          'dealer_reg_name': getValue('whatsapp.template.dealer_reg.name') ?? '',
          'dealer_reg_lang': getValue('whatsapp.template.dealer_reg.lang') ?? 'en_US',
          'dealer_reg_enabled': getValue('whatsapp.template.dealer_reg.enabled') ?? 'true',
          'dealer_approved_name': getValue('whatsapp.template.dealer_approved.name') ?? '',
          'dealer_approved_lang': getValue('whatsapp.template.dealer_approved.lang') ?? 'en_US',
          'dealer_approved_enabled': getValue('whatsapp.template.dealer_approved.enabled') ?? 'true',
          'dealer_rejected_name': getValue('whatsapp.template.dealer_rejected.name') ?? '',
          'dealer_rejected_lang': getValue('whatsapp.template.dealer_rejected.lang') ?? 'en_US',
          'dealer_rejected_enabled': getValue('whatsapp.template.dealer_rejected.enabled') ?? 'true',
          'order_placed_name': getValue('whatsapp.template.order_placed.name') ?? '',
          'order_placed_lang': getValue('whatsapp.template.order_placed.lang') ?? 'en_US',
          'order_placed_enabled': getValue('whatsapp.template.order_placed.enabled') ?? 'true',
          'order_status_name': getValue('whatsapp.template.order_status.name') ?? '',
          'order_status_lang': getValue('whatsapp.template.order_status.lang') ?? 'en_US',
          'order_status_enabled': getValue('whatsapp.template.order_status.enabled') ?? 'true',
          'abandoned_cart_name': getValue('whatsapp.template.abandoned_cart.name') ?? '',
          'abandoned_cart_lang': getValue('whatsapp.template.abandoned_cart.lang') ?? 'en_US',
          'abandoned_cart_enabled': getValue('whatsapp.template.abandoned_cart.enabled') ?? 'true',
        };

      } catch (e) {
        // Only log in debug, don't crash
        print('Error loading global settings: $e');
      }

      state = state.copyWith(
        newOrderAlerts: newOrderAlerts,
        newDealerAlert: newDealerAlert,
        newConsumerAlert: newConsumerAlert,
        themeMode: themeMode,
        language: language,
        maintenanceMode: maintenanceMode,
        priceIncludesGst: priceIncludesGst,
        minOrderValue: minOrderValue,
        shippingCharge: shippingCharge,
        whatsAppConfig: waConfig,
        lastUserCount: lastUserCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> toggleLocalSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    
    // Update State
    switch (key) {
      case 'admin_alert_orders':
        state = state.copyWith(newOrderAlerts: value);
        break;
      case 'admin_alert_dealer':
        state = state.copyWith(newDealerAlert: value);
        break;
      case 'admin_alert_consumer':
        state = state.copyWith(newConsumerAlert: value);
        break;
    }
  }

  Future<void> setMaintenanceMode(bool value) async {
    state = state.copyWith(isLoading: true);
    try {
      await _apiClient.post('/settings', data: {
        'key': 'system.maintenance_mode',
        'value': value.toString(),
        'isSecret': false,
      });
      state = state.copyWith(maintenanceMode: value, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to update maintenance mode');
    }
  }

  Future<void> setPriceIncludesGst(bool value) async {
    state = state.copyWith(isLoading: true);
    try {
      await _apiClient.post('/settings', data: {
        'key': 'system.price_includes_gst',
        'value': value.toString(),
        'isSecret': false,
      });
      state = state.copyWith(priceIncludesGst: value, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to update GST pricing mode');
    }
  }

  Future<void> saveWhatsAppConfig(Map<String, String> config) async {
    state = state.copyWith(isLoading: true);
    try {
      final futures = <Future>[];
      
      // Helper to add update future
      void addUpdate(String key, String? val) {
        if (val != null) {
          futures.add(_apiClient.post('/settings', data: {'key': key, 'value': val, 'isSecret': false}));
        }
      }

      addUpdate('whatsapp.business_number', config['number']);
      addUpdate('whatsapp.integration_mode', config['mode']);
      addUpdate('whatsapp.template_id', config['templateId']);
      addUpdate('whatsapp.phone_id', config['phoneId']);
      addUpdate('whatsapp.access_token', config['accessToken']);
      
      // Templates
      addUpdate('whatsapp.template.otp.name', config['otp_name']);
      addUpdate('whatsapp.template.otp.lang', config['otp_lang']);
      addUpdate('whatsapp.template.otp.enabled', config['otp_enabled']);
      addUpdate('whatsapp.template.user_reg.name', config['user_reg_name']);
      addUpdate('whatsapp.template.user_reg.lang', config['user_reg_lang']);
      addUpdate('whatsapp.template.user_reg.enabled', config['user_reg_enabled']);
      addUpdate('whatsapp.template.dealer_reg.name', config['dealer_reg_name']);
      addUpdate('whatsapp.template.dealer_reg.lang', config['dealer_reg_lang']);
      addUpdate('whatsapp.template.dealer_reg.enabled', config['dealer_reg_enabled']);
      addUpdate('whatsapp.template.dealer_approved.name', config['dealer_approved_name']);
      addUpdate('whatsapp.template.dealer_approved.lang', config['dealer_approved_lang']);
      addUpdate('whatsapp.template.dealer_approved.enabled', config['dealer_approved_enabled']);
      addUpdate('whatsapp.template.dealer_rejected.name', config['dealer_rejected_name']);
      addUpdate('whatsapp.template.dealer_rejected.lang', config['dealer_rejected_lang']);
      addUpdate('whatsapp.template.dealer_rejected.enabled', config['dealer_rejected_enabled']);
      addUpdate('whatsapp.template.order_placed.name', config['order_placed_name']);
      addUpdate('whatsapp.template.order_placed.lang', config['order_placed_lang']);
      addUpdate('whatsapp.template.order_placed.enabled', config['order_placed_enabled']);
      addUpdate('whatsapp.template.order_status.name', config['order_status_name']);
      addUpdate('whatsapp.template.order_status.lang', config['order_status_lang']);
      addUpdate('whatsapp.template.order_status.enabled', config['order_status_enabled']);
      addUpdate('whatsapp.template.abandoned_cart.name', config['abandoned_cart_name']);
      addUpdate('whatsapp.template.abandoned_cart.lang', config['abandoned_cart_lang']);
      addUpdate('whatsapp.template.abandoned_cart.enabled', config['abandoned_cart_enabled']);

      await Future.wait(futures);
      
      // Reload to ensure state consistency
      await _loadSettings();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to update WhatsApp config');
    }
  }

  Future<void> updateLastUserCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('admin_last_user_count', count);
    state = state.copyWith(lastUserCount: count);
  }

  // Change Password via API
  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _apiClient.patch('/users/me/change-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  // Save display preferences to SharedPreferences and update in-memory state
  Future<void> saveDisplaySettings({required String themeMode, required String language}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin_theme', themeMode);
    await prefs.setString('admin_language', language);
    state = state.copyWith(themeMode: themeMode, language: language);
  }

  // Placeholder for 2FA - In real app, this calls Users API
  Future<void> toggleTwoFactor(bool value) async {
      state = state.copyWith(twoFactorAuth: value);
      // TODO: Implement API call to user profile
  }
  Future<void> updateShippingConfig(double minOrder, double shipping) async {
    state = state.copyWith(isLoading: true);
    try {
      await Future.wait([
        _apiClient.post('/settings', data: {
          'key': 'system.min_order_value',
          'value': minOrder.toString(),
          'isSecret': false,
        }),
        _apiClient.post('/settings', data: {
          'key': 'system.shipping_charge',
          'value': shipping.toString(),
          'isSecret': false,
        }),
      ]);
      
      state = state.copyWith(
        minOrderValue: minOrder,
        shippingCharge: shipping,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to update shipping config');
    }
  }
}

final adminSettingsProvider = StateNotifierProvider<AdminSettingsNotifier, AdminSettingsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AdminSettingsNotifier(apiClient);
});
