class UserModel {
  final String id;
  final String msv;
  final String name;
  final String university;
  final String email;
  final int points;
  final List<String> inventory;

  UserModel({
    required this.id,
    required this.msv,
    required this.name,
    required this.university,
    required this.email,
    required this.points,
    required this.inventory,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      id: docId,
      msv: map['msv'] ?? map['studentId'] ?? '',
      name: map['name'] ?? '',
      university: map['university'] ?? '',
      email: map['email'] ?? '',
      points: map['points'] ?? 0,
      inventory: List<String>.from(map['inventory'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'msv': msv,
      'name': name,
      'university': university,
      'email': email,
      'points': points,
      'inventory': inventory,
    };
  }
}