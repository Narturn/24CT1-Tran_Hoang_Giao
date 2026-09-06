class StorageService {
  // Không cần Firebase Storage nữa.
  // Trả về thẳng đường link công khai do người dùng nhập vào.
  Future<({String downloadUrl, String storagePath})> uploadDocument({
    required String fileUrl,
    required String userId,
    required String fileName,
  }) async {
    return (downloadUrl: fileUrl, storagePath: 'external_link');
  }
}