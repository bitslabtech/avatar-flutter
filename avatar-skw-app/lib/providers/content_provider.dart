import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import 'auth_provider.dart';
import '../models/content.dart';

// State for list of contents (Admin)
class ContentListNotifier extends StateNotifier<AsyncValue<List<Content>>> {
  final ApiClient _apiClient;

  ContentListNotifier(this._apiClient) : super(const AsyncValue.loading()) {
    loadContents();
  }

  Future<void> loadContents() async {
    try {
      state = const AsyncValue.loading();
      final response = await _apiClient.get('/content');
      
      print('=== Content API Response ===');
      print('Response type: ${response.data.runtimeType}');
      print('Response data: ${response.data}');
      
      // The API returns {data: [...]} format
      final responseData = response.data;
      List<dynamic> contentList;
      
      if (responseData is Map<String, dynamic>) {
        print('Response is a Map');
        if (responseData.containsKey('data')) {
          final dataField = responseData['data'];
          print('Data field type: ${dataField.runtimeType}');
          print('Data field value: $dataField');
          
          if (dataField is List) {
            contentList = dataField;
          } else {
            throw Exception('Expected data field to be a List, got ${dataField.runtimeType}');
          }
        } else {
          throw Exception('Response Map does not contain "data" key');
        }
      } else if (responseData is List) {
        print('Response is directly a List');
        contentList = responseData;
      } else {
        throw Exception('Unexpected response type: ${responseData.runtimeType}');
      }
      
      print('Content list length: ${contentList.length}');
      final contents = contentList.map((e) {
        print('Parsing content item: $e');
        return Content.fromJson(e as Map<String, dynamic>);
      }).toList();
      
      print('Successfully parsed ${contents.length} contents');
      state = AsyncValue.data(contents);
    } catch (e, st) {
      print('=== Content Loading Error ===');
      print('Error: $e');
      print('Stack trace: $st');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateContent(String key, String title, String body, bool isActive) async {
    try {
      await _apiClient.put('/content/$key', data: {
        'title': title,
        'body': body,
        'isActive': isActive,
      });
      await loadContents(); // Refresh list
    } catch (e) {
      rethrow;
    }
  }
}

final contentListProvider = StateNotifierProvider<ContentListNotifier, AsyncValue<List<Content>>>((ref) {
  return ContentListNotifier(ref.watch(apiClientProvider));
});

// Provider for fetching single content content by key (Consumer/Viewer)
final contentProvider = FutureProvider.family<Content, String>((ref, key) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get('/content/$key');
  
  print('=== Single Content API Response for key: $key ===');
  print('Response type: ${response.data.runtimeType}');
  print('Response data: ${response.data}');
  
  final responseData = response.data;
  Map<String, dynamic> contentData;
  
  if (responseData is Map<String, dynamic>) {
    if (responseData.containsKey('data')) {
      final dataField = responseData['data'];
      if (dataField is Map<String, dynamic>) {
        contentData = dataField;
      } else {
        throw Exception('Expected data field to be a Map, got ${dataField.runtimeType}');
      }
    } else {
      contentData = responseData;
    }
  } else {
    throw Exception('Unexpected response type: ${responseData.runtimeType}');
  }
  
  print('Parsing content data: $contentData');
  return Content.fromJson(contentData);
});
