import '../models/evidence_log.dart';
import 'local_database_service.dart';

class DocumentVaultService {
  Future<SecureDocument> uploadDocument({
    required String userId,
    required String title,
    required String category,
    required String filePath,
  }) async {
    final documentId = await LocalDatabaseService.saveSecureDocument(userId, {
      'title': title,
      'category': category,
      'file_path': filePath,
    });

    return SecureDocument(
      id: documentId,
      userId: userId,
      title: title,
      category: category,
      filePath: filePath,
      uploadedAt: DateTime.now(),
      isEncrypted: true,
    );
  }

  Future<List<SecureDocument>> getAllDocuments(String userId) async {
    final docs = await LocalDatabaseService.getSecureDocuments(userId);
    return docs.map((doc) {
      return SecureDocument(
        id: doc['id'] as String,
        userId: doc['user_id'] as String,
        title: doc['title'] as String,
        category: doc['category'] as String,
        filePath: doc['file_path'] as String,
        uploadedAt: DateTime.parse(doc['uploaded_at'] as String),
        isEncrypted: doc['is_encrypted'] as bool,
      );
    }).toList();
  }

  Future<void> deleteDocument(String documentId) async {
    await LocalDatabaseService.deleteSecureDocument(documentId);
  }

  List<String> getDocumentCategories() {
    return ['ID Documents', 'Legal', 'Medical Records', 'Financial', 'Educational', 'Other'];
  }

  List<String> getMissingDocuments(List<SecureDocument> documents) {
    final essential = ['National ID', 'Birth Certificate', 'Medical Records', 'Bank Statements'];
    final existing = documents.map((d) => d.title).toList();
    return essential.where((e) => !existing.contains(e)).toList();
  }
}
