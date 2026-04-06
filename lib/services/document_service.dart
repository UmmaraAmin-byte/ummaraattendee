import '../models/document_model.dart';

class DocumentService {
  static final DocumentService _instance = DocumentService._internal();
  factory DocumentService() => _instance;
  DocumentService._internal();

  final List<DocumentModel> _documents = [];

  List<DocumentModel> documentsForOwner(String ownerId) {
    return _documents
        .where((d) => d.ownerId == ownerId)
        .toList()
      ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
  }

  void addDocument({
    required String ownerId,
    required String name,
    required DocumentType type,
    String? notes,
  }) {
    _documents.add(DocumentModel(
      id: 'doc_${DateTime.now().microsecondsSinceEpoch}',
      ownerId: ownerId,
      name: name.trim(),
      type: type,
      uploadedAt: DateTime.now(),
      notes: notes?.trim(),
    ));
  }

  void deleteDocument(String documentId) {
    _documents.removeWhere((d) => d.id == documentId);
  }

  void seedDocuments(List<DocumentModel> documents) {
    for (final d in documents) {
      final exists = _documents.any((e) => e.id == d.id);
      if (!exists) _documents.add(d);
    }
  }
}
