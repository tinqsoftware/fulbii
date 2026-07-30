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
    this.isSuperadmin = false,
    this.isSuspended = false,
  });

  final int id;
  final String name;
  final String email;
  final String? nick;
  final String? sexo;
  final String? avatarUrl;
  final String? fecNac;
  final int? alturaCm;
  final bool isSuperadmin;
  final bool isSuspended;

  bool get needsOnboarding =>
      (nick == null || nick!.isEmpty) || (sexo == null || sexo!.isEmpty);

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
      isSuperadmin: json['is_superadmin'] == true,
      isSuspended: json['is_suspended'] == true,
    );
  }
}
