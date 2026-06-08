import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

class TransportItem {
  final String id;
  final String name;
  final String? gst;
  final String? contact;
  final bool isActive;

  TransportItem({
    required this.id,
    required this.name,
    this.gst,
    this.contact,
    required this.isActive,
  });

  factory TransportItem.fromJson(Map<String, dynamic> json) {
    return TransportItem(
      id: json['id'],
      name: json['name'],
      gst: json['gst'],
      contact: json['contact'],
      isActive: json['isActive'] ?? true,
    );
  }
}

class TransportState {
  final bool isLoading;
  final List<TransportItem> transports;
  final String? error;

  TransportState({
    this.isLoading = false,
    this.transports = const [],
    this.error,
  });

  TransportState copyWith({
    bool? isLoading,
    List<TransportItem>? transports,
    String? error,
  }) {
    return TransportState(
      isLoading: isLoading ?? this.isLoading,
      transports: transports ?? this.transports,
      error: error,
    );
  }
}

final transportProvider = StateNotifierProvider<TransportNotifier, TransportState>((ref) {
  return TransportNotifier(ref.read(apiClientProvider));
});

class TransportNotifier extends StateNotifier<TransportState> {
  final ApiClient _apiClient;

  TransportNotifier(this._apiClient) : super(TransportState());

  Future<void> loadTransports({bool activeOnly = false}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final response = await _apiClient.get('/transports', queryParameters: activeOnly ? {'activeOnly': 'true'} : null);
      final List<dynamic> data = response.data;
      final transports = data.map((e) => TransportItem.fromJson(e)).toList();
      state = state.copyWith(isLoading: false, transports: transports);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createTransport({required String name, String? gst, String? contact, bool isActive = true}) async {
    try {
      await _apiClient.post('/transports', data: {
        'name': name,
        'gst': gst,
        'contact': contact,
        'isActive': isActive,
      });
      await loadTransports();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateTransport({required String id, required String name, String? gst, String? contact, required bool isActive}) async {
    try {
      await _apiClient.put('/transports/$id', data: {
        'name': name,
        'gst': gst,
        'contact': contact,
        'isActive': isActive,
      });
      await loadTransports();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteTransport(String id) async {
    try {
      await _apiClient.delete('/transports/$id');
      await loadTransports();
      return true;
    } catch (e) {
      return false;
    }
  }
}
