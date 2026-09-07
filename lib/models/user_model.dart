class UserModel {
  final String uid;
  final String email;
  final String name;
  final String msv;
  final String university;
  final int points;
  final List<String> inventory; // Danh sách vật phẩm/danh hiệu đã mua
  final Map<String, String> equipped;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.msv,
    required this.university,
    required this.points,
    required this.inventory,
    required this.equipped,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      msv: map['msv'] ?? '',
      university: map['university'] ?? '',
      points: map['points'] ?? 0,
      inventory: List<String>.from(map['inventory'] ?? []),
      equipped: Map<String, String>.from(map['equipped'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'msv': msv,
      'university': university,
      'points': points,
      'inventory': inventory,
    };
  }
}