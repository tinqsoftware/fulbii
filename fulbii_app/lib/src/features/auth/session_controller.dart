import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../config/app_config.dart';
import '../../core/models/app_user.dart';
import '../../core/network/api_error.dart';
import '../../core/storage/token_store.dart';
import '../../services/widget/widget_weekly_service.dart';
import '../profile/data/profile_repository.dart';
import 'data/auth_repository.dart';
import 'session_state.dart';

class SessionController extends StateNotifier<SessionState> {
  SessionController(this._ref)
    : _tokenStore = _ref.read(tokenStoreProvider),
      super(SessionState.empty) {
    bootstrap();
  }

  final Ref _ref;
  final TokenStore _tokenStore;
  bool _googleInitialized = false;

  AuthRepository get _authRepository => _ref.read(authRepositoryProvider);
  ProfileRepository get _profileRepository =>
      _ref.read(profileRepositoryProvider);
  AppConfig get _config => _ref.read(appConfigProvider);

  Future<void> bootstrap() async {
    state = state.copyWith(loading: true, clearError: true);

    final token = await _tokenStore.loadToken();
    if (token == null || token.isEmpty) {
      await _ref
          .read(widgetWeeklyServiceProvider)
          .clearForLoggedOut(ignoreErrors: true);
      state = state.copyWith(
        initialized: true,
        loading: false,
        clearToken: true,
      );
      return;
    }

    try {
      final me = await _profileRepository.me();
      final user = AppUser.fromJson(me);
      state = state.copyWith(
        initialized: true,
        loading: false,
        token: token,
        user: user,
        needsOnboarding: user.needsOnboarding,
      );
    } catch (error) {
      // A temporary network/API failure must not log a player out. The token
      // is only deleted after the server conclusively rejects it.
      if (error is ApiError && error.statusCode == 401) {
        await _tokenStore.clear();
        await _ref
            .read(widgetWeeklyServiceProvider)
            .clearForLoggedOut(ignoreErrors: true);
        state = state.copyWith(
          initialized: true,
          loading: false,
          clearToken: true,
          user: null,
          needsOnboarding: false,
        );
        return;
      }

      state = state.copyWith(
        initialized: true,
        loading: false,
        token: token,
        user: null,
        needsOnboarding: false,
        errorMessage:
            'No se pudo validar la sesión. Intenta nuevamente al recuperar conexión.',
      );
    }
  }

  Future<void> signInWithGoogle() async {
    if (state.loading) {
      return;
    }

    state = state.copyWith(loading: true, clearError: true);
    try {
      final googleSignIn = GoogleSignIn.instance;
      if (!_googleInitialized) {
        await googleSignIn.initialize(
          serverClientId: _config.googleWebClientId.isEmpty
              ? null
              : _config.googleWebClientId,
        );
        _googleInitialized = true;
      }

      final account = await googleSignIn.authenticate().timeout(
        const Duration(seconds: 45),
        onTimeout: () => throw ApiError(
          'Google no respondió. Cierra la ventana de Google y vuelve a intentarlo.',
        ),
      );
      final auth = account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw ApiError(
          'No se obtuvo id_token de Google. Verifica GOOGLE_WEB_CLIENT_ID.',
        );
      }

      final response = await _authRepository.loginSocial(
        provider: 'google',
        idToken: idToken,
        email: account.email,
        name: account.displayName,
        avatarUrl: account.photoUrl,
        providerUid: account.id,
      );

      await _consumeLoginResponse(response);
    } catch (e) {
      final message = e is ApiError
          ? e.message
          : e is GoogleSignInException
          ? 'Google: ${e.description ?? e.code.name}'
          : 'No se pudo iniciar sesión con Google.';
      state = state.copyWith(loading: false, errorMessage: message);
    }
  }

  Future<void> signInWithApple() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final available = await SignInWithApple.isAvailable();
      if (!available) {
        throw ApiError('Apple Sign In no está disponible en este dispositivo.');
      }

      final nonce = _appleNonce();
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256.convert(utf8.encode(nonce)).toString(),
      );

      final idToken = credential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw ApiError('Apple no devolvió identity token.');
      }

      final fullName = [credential.givenName, credential.familyName]
          .whereType<String>()
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .join(' ');

      final response = await _authRepository.loginSocial(
        provider: 'apple',
        idToken: idToken,
        nonce: nonce,
        email: credential.email,
        name: fullName.isEmpty ? null : fullName,
        providerUid: credential.userIdentifier,
      );

      await _consumeLoginResponse(response);
    } catch (e) {
      state = state.copyWith(
        loading: false,
        errorMessage: e is ApiError
            ? e.message
            : 'No se pudo iniciar sesión con Apple.',
      );
    }
  }

  String _appleNonce() {
    const alphabet =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List<String>.generate(
      32,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
  }

  Future<void> completeOnboarding({
    required String nick,
    required String sexo,
  }) async {
    state = state.copyWith(loading: true, clearError: true);

    try {
      final response = await _profileRepository.completeOnboarding(
        nick: nick,
        sexo: sexo,
      );
      final userJson =
          (response['user'] as Map?)?.cast<String, dynamic>() ?? {};
      final user = AppUser.fromJson(userJson);
      state = state.copyWith(
        loading: false,
        user: user,
        needsOnboarding: false,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        errorMessage: e is ApiError
            ? e.message
            : 'No se pudo completar onboarding.',
      );
    }
  }

  Future<void> refreshMe() async {
    if (!state.isAuthenticated) {
      return;
    }

    try {
      final me = await _profileRepository.me();
      final user = AppUser.fromJson(me);
      state = state.copyWith(user: user, needsOnboarding: user.needsOnboarding);
    } catch (_) {
      // no-op
    }
  }

  Future<void> logout() async {
    state = state.copyWith(loading: true, clearError: true);

    try {
      await _authRepository.logout();
    } catch (_) {
      // The API call is best effort.
    }

    await _tokenStore.clear();
    await _resetGoogleSession();
    await _ref
        .read(widgetWeeklyServiceProvider)
        .clearForLoggedOut(ignoreErrors: true);
    state = const SessionState(initialized: true, loading: false);
  }

  Future<void> _resetGoogleSession() async {
    if (!_googleInitialized) {
      return;
    }

    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // The native session may already be closed; local logout still wins.
    }
  }

  Future<void> _consumeLoginResponse(Map<String, dynamic> response) async {
    final token = (response['access_token'] ?? '').toString();
    if (token.isEmpty) {
      throw ApiError('El backend no devolvió access_token.');
    }

    final userJson = (response['user'] as Map?)?.cast<String, dynamic>() ?? {};
    final user = AppUser.fromJson(userJson);

    await _tokenStore.saveToken(token);

    state = state.copyWith(
      initialized: true,
      loading: false,
      token: token,
      user: user,
      needsOnboarding:
          response['needs_onboarding'] == true || user.needsOnboarding,
    );
  }
}

final sessionControllerProvider =
    StateNotifierProvider<SessionController, SessionState>(
      (ref) => SessionController(ref),
    );
