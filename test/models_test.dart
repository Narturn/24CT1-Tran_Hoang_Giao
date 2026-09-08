import 'package:flutter_test/flutter_test.dart';
import 'package:dau_24ct1_tran_hoang_giao/models/user_model.dart';
import 'package:dau_24ct1_tran_hoang_giao/models/post_model.dart';

void main() {
  group('UserModel Tests', () {
    test('User default role is user and isAdmin is false', () {
      final user = UserModel(
        uid: 'user_1',
        email: 'user@test.com',
        name: 'Nguyen Van A',
        msv: '24CT101',
        university: 'DAU',
        points: 50,
        inventory: ['item_1'],
        equipped: {'badge': 'item_1'},
      );

      expect(user.role, equals('user'));
      expect(user.isAdmin, isFalse);

      final map = user.toMap();
      expect(map['role'], equals('user'));
      expect(map['equipped'], equals({'badge': 'item_1'}));
      expect(map['inventory'], equals(['item_1']));
    });

    test('Admin role returns isAdmin = true', () {
      final admin = UserModel.fromMap({
        'email': 'admin@test.com',
        'name': 'Quản Trị Viên',
        'msv': 'ADMIN01',
        'university': 'DAU',
        'points': 500,
        'inventory': [],
        'equipped': {},
        'role': 'admin',
      }, 'admin_uid');

      expect(admin.role, equals('admin'));
      expect(admin.isAdmin, isTrue);
    });
  });

  group('PostModel Tests', () {
    test('PostModel fromMap and toMap', () {
      final post = PostModel(
        id: 'post_1',
        authorId: 'user_1',
        authorName: 'Nguyen Van A',
        content: 'Bài viết kiểm tra',
        likes: ['user_2'],
        commentsCount: 3,
      );

      expect(post.authorName, equals('Nguyen Van A'));
      expect(post.likes.contains('user_2'), isTrue);

      final map = post.toMap();
      expect(map['authorId'], equals('user_1'));
      expect(map['content'], equals('Bài viết kiểm tra'));
      expect(map['likes'], equals(['user_2']));
    });
  });
}
