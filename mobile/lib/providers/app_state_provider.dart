import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

// 1. Auth State
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? errorMessage;

  AuthState({this.isAuthenticated = false, this.isLoading = false, this.errorMessage});

  AuthState copyWith({bool? isAuthenticated, bool? isLoading, String? errorMessage}) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService = ApiService();

  AuthNotifier() : super(AuthState());

  Future<void> checkStatus() async {
    state = state.copyWith(isLoading: true);
    final token = await _apiService.getValidTokenForStartup();
    state = state.copyWith(isAuthenticated: token != null, isLoading: false);
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final success = await _apiService.login(username, password);
    if (success) {
      state = state.copyWith(isAuthenticated: true, isLoading: false);
    } else {
      state = state.copyWith(isAuthenticated: false, isLoading: false, errorMessage: 'Invalid credentials');
    }
    return success;
  }

  Future<void> logout() async {
    await _apiService.clearSession();
    state = AuthState(isAuthenticated: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());

// 2. Subscription State
class SubscriptionState {
  final String tier; // FREE, PRO, ELITE
  final bool isActive;
  final int dailyBitesLimit;
  final bool isLoading;

  SubscriptionState({
    this.tier = 'FREE', 
    this.isActive = false, 
    this.dailyBitesLimit = 20,
    this.isLoading = false,
  });

  SubscriptionState copyWith({String? tier, bool? isActive, int? dailyBitesLimit, bool? isLoading}) {
    return SubscriptionState(
      tier: tier ?? this.tier,
      isActive: isActive ?? this.isActive,
      dailyBitesLimit: dailyBitesLimit ?? this.dailyBitesLimit,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  final ApiService _apiService = ApiService();

  SubscriptionNotifier() : super(SubscriptionState());

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    final data = await _apiService.getProgress(); // progress includes subscription data
    if (data != null && data['subscription'] != null) {
      final sub = data['subscription'];
      state = SubscriptionState(
        tier: sub['plan_type'] ?? 'FREE',
        isActive: sub['is_active'] ?? false,
        dailyBitesLimit: sub['daily_bites_limit'] ?? 20,
        isLoading: false,
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
  }
}

final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) => SubscriptionNotifier());
