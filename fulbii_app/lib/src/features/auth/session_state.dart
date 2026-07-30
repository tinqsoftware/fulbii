import '../../core/models/app_user.dart';

class SessionState {
  const SessionState({
    this.initialized = false,
    this.loading = false,
    this.token,
    this.user,
    this.needsOnboarding = false,
    this.errorMessage,
  });

  final bool initialized;
  final bool loading;
  final String? token;
  final AppUser? user;
  final bool needsOnboarding;
  final String? errorMessage;

  bool get isAuthenticated => token != null && token!.isNotEmpty;

  SessionState copyWith({
    bool? initialized,
    bool? loading,
    String? token,
    AppUser? user,
    bool clearToken = false,
    bool? needsOnboarding,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SessionState(
      initialized: initialized ?? this.initialized,
      loading: loading ?? this.loading,
      token: clearToken ? null : (token ?? this.token),
      user: user ?? this.user,
      needsOnboarding: needsOnboarding ?? this.needsOnboarding,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  static const empty = SessionState(initialized: false, loading: false);
}
