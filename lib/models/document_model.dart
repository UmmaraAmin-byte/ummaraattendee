enum DocumentType { license, permit, certificate, other }

class DocumentModel {
  final String id;
  final String ownerId;
  final String name;
  final DocumentType type;
  final DateTime uploadedAt;
  final String? notes;

  const DocumentModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.type,
    required this.uploadedAt,
    this.notes,
  });

  String get typeLabel {
    switch (type) {
      case DocumentType.license:
        return 'License';
      case DocumentType.permit:
        return 'Permit';
      case DocumentType.certificate:
        return 'Certificate';
      case DocumentType.other:
        return 'Other';
    }
  }
}
