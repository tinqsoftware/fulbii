class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.nick,
    this.sexo,
    this.avatarUrl,
    this.fecNac,
    this.alturaCm,
    this.sportsProfile = const {},
    this.isSuperadmin = false,
    this.isSuspended = false,
    this.onboardingStep = 1,
    this.themeMode,
    this.onboardingCompleted = false,
  });

  final int id;
  final String name;
  final String email;
  final String? nick;
  final String? sexo;
  final String? avatarUrl;
  final String? fecNac;
  final int? alturaCm;
  final Map<String, dynamic> sportsProfile;
  final bool isSuperadmin;
  final bool isSuspended;
  final int onboardingStep;
  final String? themeMode;
  final bool onboardingCompleted;

  bool get needsOnboarding => !onboardingCompleted && (
        nick == null || nick!.isEmpty || sexo == null || sexo!.isEmpty ||
        alturaCm == null || fecNac == null || themeMode == null ||
        sportsProfile['self_rating_locked'] != true
      );

  factory AppUser.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    return AppUser(
      id: parseInt(json['id']) ?? 0,
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      nick: json['nick']?.toString(),
      sexo: json['sexo']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      fecNac: json['fec_nac']?.toString(),
      alturaCm: parseInt(json['altura_cm']),
      sportsProfile:
          (json['sports_profile'] as Map?)?.cast<String, dynamic>() ?? const {},
      isSuperadmin: json['is_superadmin'] == true,
      isSuspended: json['is_suspended'] == true,
      onboardingStep: parseInt(json['onboarding_step']) ?? 1,
      themeMode: json['theme_mode']?.toString(),
      onboardingCompleted: json['onboarding_completed'] == true || json['onboarding_completed_at'] != null,
    );
  }
}
