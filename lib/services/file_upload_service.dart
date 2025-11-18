import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ticket_attachment.dart';
import 'supabase_service.dart';

class FileUploadService {
  static const String documentsBucket = 'ticket-documents';
  static const String imagesBucket = 'ticket-images';
  static const String videosBucket = 'ticket-videos';

  // File size limits in bytes
  static const int maxDocumentSize = 50 * 1024 * 1024; // 50 MB
  static const int maxImageSize = 10 * 1024 * 1024; // 10 MB
  static const int maxVideoSize = 100 * 1024 * 1024; // 100 MB

  // Allowed MIME types
  static const List<String> documentMimeTypes = [
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'text/plain',
    'text/csv',
  ];

  static const List<String> imageMimeTypes = [
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
  ];

  static const List<String> videoMimeTypes = [
    'video/mp4',
    'video/webm',
    'video/quicktime',
    'video/x-msvideo',
  ];

  /// Pick and upload a document file
  static Future<TicketAttachment?> uploadDocument({
    required String ticketId,
    required Function(double) onProgress,
  }) async {
    return await _pickAndUploadFile(
      ticketId: ticketId,
      fileType: AttachmentType.document,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'csv'],
      maxSize: maxDocumentSize,
      onProgress: onProgress,
    );
  }

  /// Pick and upload an image file
  static Future<TicketAttachment?> uploadImage({
    required String ticketId,
    required Function(double) onProgress,
  }) async {
    return await _pickAndUploadFile(
      ticketId: ticketId,
      fileType: AttachmentType.image,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
      maxSize: maxImageSize,
      onProgress: onProgress,
    );
  }

  /// Pick and upload a video file
  static Future<TicketAttachment?> uploadVideo({
    required String ticketId,
    required Function(double) onProgress,
  }) async {
    return await _pickAndUploadFile(
      ticketId: ticketId,
      fileType: AttachmentType.video,
      allowedExtensions: ['mp4', 'webm', 'mov', 'avi'],
      maxSize: maxVideoSize,
      onProgress: onProgress,
    );
  }

  /// Capture photo from camera and upload
  static Future<TicketAttachment?> capturePhoto({
    required String ticketId,
    required Function(double) onProgress,
  }) async {
    try {
      final ImagePicker picker = ImagePicker();

      // Capture photo from camera
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85, // Compress to save bandwidth/storage
      );

      if (photo == null) {
        return null; // User cancelled
      }

      print('📸 Photo captured: ${photo.name}');

      // Read photo bytes
      final Uint8List imageBytes = await photo.readAsBytes();
      final int fileSize = imageBytes.length;

      // Validate file size
      if (fileSize > maxImageSize) {
        final maxSizeMB = maxImageSize / (1024 * 1024);
        throw Exception('Photo size exceeds ${maxSizeMB}MB limit');
      }

      // Detect MIME type
      final mimeType = lookupMimeType(photo.name, headerBytes: imageBytes) ?? 'image/jpeg';

      // Get bucket name
      final bucket = imagesBucket;

      // Generate unique file path
      final userId = SupabaseService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '$userId/$ticketId/$timestamp.jpg';

      print('📤 Uploading photo: ${photo.name} ($fileSize bytes) to $bucket/$filePath');

      // Upload to Supabase Storage
      final String uploadPath = await SupabaseService.client.storage
          .from(bucket)
          .uploadBinary(
            filePath,
            imageBytes,
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: false,
            ),
          );

      print('✅ Photo uploaded successfully: $uploadPath');

      // Get public URL
      final String fileUrl = SupabaseService.client.storage
          .from(bucket)
          .getPublicUrl(filePath);

      // Save metadata to database
      final attachmentData = {
        'ticket_id': ticketId,
        'uploader_id': userId,
        'file_name': photo.name,
        'file_type': AttachmentType.image.name,
        'file_url': fileUrl,
        'file_size': fileSize,
        'mime_type': mimeType,
      };

      final response = await SupabaseService.client
          .from('ticket_attachments')
          .insert(attachmentData)
          .select('*, uploader:profiles!uploader_id(*)')
          .single();

      print('✅ Photo attachment metadata saved: ${response['id']}');

      return TicketAttachment.fromJson(response);
    } catch (e) {
      print('❌ Error capturing/uploading photo: $e');
      rethrow;
    }
  }

  /// Internal method to pick and upload file
  static Future<TicketAttachment?> _pickAndUploadFile({
    required String ticketId,
    required AttachmentType fileType,
    required List<String> allowedExtensions,
    required int maxSize,
    required Function(double) onProgress,
  }) async {
    try {
      // Pick file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return null; // User cancelled
      }

      final file = result.files.first;

      if (file.bytes == null) {
        throw Exception('Failed to read file data');
      }

      // Validate file size
      if (file.size > maxSize) {
        final maxSizeMB = maxSize / (1024 * 1024);
        throw Exception('File size exceeds ${maxSizeMB}MB limit');
      }

      // Detect MIME type
      final mimeType = lookupMimeType(file.name, headerBytes: file.bytes) ??
          'application/octet-stream';

      // Validate MIME type
      if (!_isAllowedMimeType(mimeType, fileType)) {
        throw Exception('File type not allowed: $mimeType');
      }

      // Get bucket name
      final bucket = _getBucketForFileType(fileType);

      // Generate unique file path
      final userId = SupabaseService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = file.extension ?? '';
      final filePath = '$userId/$ticketId/$timestamp${extension.isNotEmpty ? '.$extension' : ''}';

      print('📤 Uploading file: ${file.name} (${file.size} bytes) to $bucket/$filePath');

      // Upload to Supabase Storage
      final String uploadPath = await SupabaseService.client.storage
          .from(bucket)
          .uploadBinary(
            filePath,
            file.bytes!,
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: false,
            ),
          );

      print('✅ File uploaded successfully: $uploadPath');

      // Get public URL
      final String fileUrl = SupabaseService.client.storage
          .from(bucket)
          .getPublicUrl(filePath);

      // Save metadata to database
      final attachmentData = {
        'ticket_id': ticketId,
        'uploader_id': userId,
        'file_name': file.name,
        'file_type': fileType.name,
        'file_url': fileUrl,
        'file_size': file.size,
        'mime_type': mimeType,
      };

      final response = await SupabaseService.client
          .from('ticket_attachments')
          .insert(attachmentData)
          .select('*, uploader:profiles!uploader_id(*)')
          .single();

      print('✅ Attachment metadata saved: ${response['id']}');

      return TicketAttachment.fromJson(response);
    } catch (e) {
      print('❌ Error uploading file: $e');
      rethrow;
    }
  }

  /// Get attachments for a ticket
  static Future<List<TicketAttachment>> getTicketAttachments(String ticketId) async {
    try {
      final response = await SupabaseService.client
          .from('ticket_attachments')
          .select('*, uploader:profiles!uploader_id(*)')
          .eq('ticket_id', ticketId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => TicketAttachment.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error fetching attachments: $e');
      rethrow;
    }
  }

  /// Delete an attachment
  static Future<void> deleteAttachment(TicketAttachment attachment) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(attachment.fileUrl);
      final pathSegments = uri.pathSegments;
      final filePath = pathSegments.sublist(pathSegments.indexOf('object') + 2).join('/');

      // Determine bucket
      final bucket = _getBucketForFileType(attachment.fileType);

      // Delete from storage
      await SupabaseService.client.storage
          .from(bucket)
          .remove([filePath]);

      // Delete metadata from database
      await SupabaseService.client
          .from('ticket_attachments')
          .delete()
          .eq('id', attachment.id);

      print('✅ Attachment deleted: ${attachment.fileName}');
    } catch (e) {
      print('❌ Error deleting attachment: $e');
      rethrow;
    }
  }

  /// Get bucket name for file type
  static String _getBucketForFileType(AttachmentType fileType) {
    switch (fileType) {
      case AttachmentType.document:
        return documentsBucket;
      case AttachmentType.image:
        return imagesBucket;
      case AttachmentType.video:
        return videosBucket;
    }
  }

  /// Check if MIME type is allowed for file type
  static bool _isAllowedMimeType(String mimeType, AttachmentType fileType) {
    switch (fileType) {
      case AttachmentType.document:
        return documentMimeTypes.contains(mimeType);
      case AttachmentType.image:
        return imageMimeTypes.contains(mimeType);
      case AttachmentType.video:
        return videoMimeTypes.contains(mimeType);
    }
  }

  /// Download attachment (opens in browser)
  static Future<void> downloadAttachment(TicketAttachment attachment) async {
    try {
      // For web, the public URL will automatically trigger download
      // For mobile, you'd need to use url_launcher or similar
      print('📥 Downloading: ${attachment.fileUrl}');
      // In a real implementation, you'd use url_launcher here
      // await launchUrl(Uri.parse(attachment.fileUrl));
    } catch (e) {
      print('❌ Error downloading attachment: $e');
      rethrow;
    }
  }

  /// Generic file upload method for any bucket
  static Future<String> uploadFile({
    required Uint8List bytes,
    required String fileName,
    required String bucket,
  }) async {
    try {
      // Get current user ID
      final userId = SupabaseService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Generate unique file path
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = fileName.split('.').last;
      final filePath = '$userId/$timestamp.$extension';

      print('📤 Uploading file: $fileName (${bytes.length} bytes) to $bucket/$filePath');

      // Detect MIME type
      final mimeType = lookupMimeType(fileName, headerBytes: bytes) ?? 'application/octet-stream';

      // Upload to Supabase Storage
      await SupabaseService.client.storage
          .from(bucket)
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: false,
            ),
          );

      print('✅ File uploaded successfully: $filePath');

      // Get public URL
      final String fileUrl = SupabaseService.client.storage
          .from(bucket)
          .getPublicUrl(filePath);

      return fileUrl;
    } catch (e) {
      print('❌ Error uploading file: $e');
      rethrow;
    }
  }
}
