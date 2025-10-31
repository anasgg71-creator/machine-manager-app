import 'user_profile.dart';

enum AttachmentType {
  document,
  image,
  video;

  String get displayName {
    switch (this) {
      case AttachmentType.document:
        return 'Document';
      case AttachmentType.image:
        return 'Image';
      case AttachmentType.video:
        return 'Video';
    }
  }

  static AttachmentType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'document':
        return AttachmentType.document;
      case 'image':
        return AttachmentType.image;
      case 'video':
        return AttachmentType.video;
      default:
        return AttachmentType.document;
    }
  }
}

class TicketAttachment {
  final String id;
  final String ticketId;
  final String uploaderId;
  final String fileName;
  final AttachmentType fileType;
  final String fileUrl;
  final int? fileSize;
  final String? mimeType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserProfile? uploader;

  TicketAttachment({
    required this.id,
    required this.ticketId,
    required this.uploaderId,
    required this.fileName,
    required this.fileType,
    required this.fileUrl,
    this.fileSize,
    this.mimeType,
    required this.createdAt,
    required this.updatedAt,
    this.uploader,
  });

  factory TicketAttachment.fromJson(Map<String, dynamic> json) {
    return TicketAttachment(
      id: json['id'] as String,
      ticketId: json['ticket_id'] as String,
      uploaderId: json['uploader_id'] as String,
      fileName: json['file_name'] as String,
      fileType: AttachmentType.fromString(json['file_type'] as String),
      fileUrl: json['file_url'] as String,
      fileSize: json['file_size'] as int?,
      mimeType: json['mime_type'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      uploader: json['uploader'] != null
          ? UserProfile.fromJson(json['uploader'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_id': ticketId,
      'uploader_id': uploaderId,
      'file_name': fileName,
      'file_type': fileType.name,
      'file_url': fileUrl,
      'file_size': fileSize,
      'mime_type': mimeType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (uploader != null) 'uploader': uploader!.toJson(),
    };
  }

  String get fileSizeFormatted {
    if (fileSize == null) return 'Unknown size';

    final sizeInKB = fileSize! / 1024;
    if (sizeInKB < 1024) {
      return '${sizeInKB.toStringAsFixed(1)} KB';
    }

    final sizeInMB = sizeInKB / 1024;
    if (sizeInMB < 1024) {
      return '${sizeInMB.toStringAsFixed(1)} MB';
    }

    final sizeInGB = sizeInMB / 1024;
    return '${sizeInGB.toStringAsFixed(1)} GB';
  }

  String get fileExtension {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toUpperCase() : '';
  }

  bool get isImage => fileType == AttachmentType.image;
  bool get isVideo => fileType == AttachmentType.video;
  bool get isDocument => fileType == AttachmentType.document;

  TicketAttachment copyWith({
    String? id,
    String? ticketId,
    String? uploaderId,
    String? fileName,
    AttachmentType? fileType,
    String? fileUrl,
    int? fileSize,
    String? mimeType,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserProfile? uploader,
  }) {
    return TicketAttachment(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      uploaderId: uploaderId ?? this.uploaderId,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      fileUrl: fileUrl ?? this.fileUrl,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      uploader: uploader ?? this.uploader,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TicketAttachment &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TicketAttachment{id: $id, fileName: $fileName, fileType: $fileType, fileSize: $fileSizeFormatted}';
  }
}
