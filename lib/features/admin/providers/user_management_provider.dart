import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../models/user.dart';
import '../../../providers/auth_provider.dart';

// User stats (consumers only)
class UserStats {
  final int totalUsers;
  final int activeUsers;
  final int inactiveUsers;

  UserStats({
    this.totalUsers = 0,
    this.activeUsers = 0,
    this.inactiveUsers = 0,
  });
}

// Status filter options
enum UserStatusFilter { all, active, inactive }

// Role filter options
enum UserRoleFilter { all, admin, consumer, dealer }

// State class
class UserManagementState {
  final List<User> users;
  final List<User> filteredUsers;
  final bool isLoading;
  final String? error;
  final UserStats stats;
  final UserStatusFilter statusFilter;
  final UserRoleFilter roleFilter;
  final String searchQuery;

  UserManagementState({
    this.users = const [],
    this.filteredUsers = const [],
    this.isLoading = false,
    this.error,
    UserStats? stats,
    this.statusFilter = UserStatusFilter.all,
    this.roleFilter = UserRoleFilter.all,
    this.searchQuery = '',
  }) : stats = stats ?? UserStats();

  UserManagementState copyWith({
    List<User>? users,
    List<User>? filteredUsers,
    bool? isLoading,
    String? error,
    UserStats? stats,
    UserStatusFilter? statusFilter,
    UserRoleFilter? roleFilter,
    String? searchQuery,
  }) {
    return UserManagementState(
      users: users ?? this.users,
      filteredUsers: filteredUsers ?? this.filteredUsers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      stats: stats ?? this.stats,
      statusFilter: statusFilter ?? this.statusFilter,
      roleFilter: roleFilter ?? this.roleFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}


// Provider
final userManagementProvider =
    StateNotifierProvider.autoDispose<UserManagementNotifier, UserManagementState>((ref) {
  return UserManagementNotifier(ref.read(apiClientProvider));
});

class UserManagementNotifier extends StateNotifier<UserManagementState> {
  final ApiClient _apiClient;

  UserManagementNotifier(this._apiClient) : super(UserManagementState());

  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiClient.get('/users');
      
      if (response.data is List) {
        // Filter to exclude super_admin only (keep dealers for other screens)
        final allUsers = (response.data as List)
            .map((json) => User.fromJson(json as Map<String, dynamic>))
            .where((u) => u.role != 'super_admin') 
            .toList();

        // Calculate stats
        final stats = UserStats(
          totalUsers: allUsers.length,
          activeUsers: allUsers.where((u) => u.isActive).length,
          inactiveUsers: allUsers.where((u) => !u.isActive).length,
        );

        state = state.copyWith(
          users: allUsers,
          stats: stats,
          isLoading: false,
        );
        _applyFilters();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void setStatusFilter(UserStatusFilter filter) {
    state = state.copyWith(statusFilter: filter);
    _applyFilters();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  void setRoleFilter(UserRoleFilter filter) {
    state = state.copyWith(roleFilter: filter);
    _applyFilters();
  }

  void clearFilters() {
    state = state.copyWith(
      statusFilter: UserStatusFilter.all, 
      roleFilter: UserRoleFilter.all,
      searchQuery: '',
    );
    _applyFilters();
  }

  void _applyFilters() {
    var filtered = List<User>.from(state.users);

    // Apply status filter
    switch (state.statusFilter) {
      case UserStatusFilter.active:
        filtered = filtered.where((u) => u.isActive).toList();
        break;
      case UserStatusFilter.inactive:
        filtered = filtered.where((u) => !u.isActive).toList();
        break;
      case UserStatusFilter.all:
        break;
    }

    // Apply role filter
    switch (state.roleFilter) {
      case UserRoleFilter.admin:
        filtered = filtered.where((u) => u.role == 'admin').toList();
        break;
      case UserRoleFilter.consumer:
        filtered = filtered.where((u) => u.role == 'consumer').toList();
        break;
      case UserRoleFilter.dealer:
        filtered = filtered.where((u) => u.role == 'dealer').toList();
        break;
      case UserRoleFilter.all:
        break;
    }

    // Apply search
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered.where((u) =>
          u.name.toLowerCase().contains(query) ||
          (u.email?.toLowerCase().contains(query) ?? false) ||
          u.phone.contains(query)).toList();
    }

    state = state.copyWith(filteredUsers: filtered);
  }

  Future<void> updateUserStatus(String userId, String newStatus) async {
    try {
      await _apiClient.patch('/users/$userId/status', data: {'status': newStatus});
      await loadUsers();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _apiClient.patch('/users/$userId', data: data);
      await loadUsers();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _apiClient.delete('/users/$userId');
      await loadUsers();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
