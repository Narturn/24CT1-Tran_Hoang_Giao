# Mạng Xã Hội Sinh Viên - Flutter + Firebase

## 1. Cài package

Từ thư mục Flutter project:

```bash
flutter pub add firebase_core firebase_auth cloud_firestore firebase_storage file_picker url_launcher
```

Bạn đã có `lib/firebase_options.dart`, nên không cần tạo lại file đó. Code dùng riêng `DefaultFirebaseOptions.web` theo yêu cầu.

## 2. Copy source

Copy các thư mục `lib/models`, `lib/services`, `lib/views`, và `lib/main.dart` vào project.

## 3. Firebase Console

Bật:
- Authentication > Sign-in method > Email/Password
- Firestore Database
- Storage

Deploy rules:

```bash
firebase deploy --only firestore:rules,storage
```

Nếu chưa có Firebase CLI/config, có thể copy nội dung `firestore.rules` và `storage.rules` vào Firebase Console để test trước.

## 4. Chạy

```bash
flutter pub get
flutter run -d chrome
```

## 5. Lưu ý production

App hiện đã dùng Firestore transaction cho tạo bài, review, upload document reward và mua item để tránh race condition đơn giản.

Tuy nhiên, reward points vẫn được client gọi thông qua Firestore. Với production thật, không nên tin client ở các nghiệp vụ kinh tế như +10/+5/+15 hoặc trừ points. Hãy chuyển các mutation reward/purchase sang Cloud Functions hoặc backend tin cậy và viết Rules chặt hơn.
