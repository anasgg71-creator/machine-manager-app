# Ticket Attachments Feature - Implementation Summary

## ✅ What Has Been Created

### 1. Database Schema
**File**: `supabase/migrations/create_ticket_attachments.sql`
- Creates `ticket_attachments` table
- Stores: ticket_id, uploader_id, file_name, file_type, file_url, file_size, mime_type
- Includes RLS policies for security
- Auto-updates timestamps

### 2. Data Model
**File**: `lib/models/ticket_attachment.dart`
- `TicketAttachment` class with all fields
- Support for 3 file types: document, image, video
- Helper methods: `fileSizeFormatted`, `fileExtension`, `isImage`, `isVideo`, `isDocument`

### 3. File Upload Service
**File**: `lib/services/file_upload_service.dart`
- `uploadDocument()` - Pick and upload documents (PDF, Word, Excel, CSV, TXT)
- `uploadImage()` - Pick and upload images (JPG, PNG, GIF, WebP)
- `uploadVideo()` - Pick and upload videos (MP4, WebM, MOV, AVI)
- `getTicketAttachments()` - Fetch all attachments for a ticket
- `deleteAttachment()` - Delete file from storage and database
- File size limits: Documents 50MB, Images 10MB, Videos 100MB
- MIME type validation
- Progress tracking support

### 4. Dependencies Added
**File**: `pubspec.yaml`
- `file_picker: ^8.0.0+1` - For selecting files
- `mime: ^1.0.5` - For detecting MIME types

## 🔧 What You Need to Do

### Step 1: Install Dependencies
```bash
flutter pub get
```

### Step 2: Create Supabase Storage Buckets

Go to your Supabase Dashboard → Storage → Create 3 new buckets:

#### Bucket 1: `ticket-documents`
- Public: **No** (private)
- File size limit: 50MB
- Allowed MIME types: PDF, Word, Excel, TXT, CSV

#### Bucket 2: `ticket-images`
- Public: **No** (private)
- File size limit: 10MB
- Allowed MIME types: JPEG, PNG, GIF, WebP

#### Bucket 3: `ticket-videos`
- Public: **No** (private)
- File size limit: 100MB
- Allowed MIME types: MP4, WebM, MOV, AVI

### Step 3: Set Storage Policies

For **each bucket** (`ticket-documents`, `ticket-images`, `ticket-videos`), add these policies:

**Select (Read) Policy:**
```sql
bucket_id = 'ticket-documents' AND auth.role() = 'authenticated'
```

**Insert (Upload) Policy:**
```sql
bucket_id = 'ticket-documents' AND auth.role() = 'authenticated'
```

**Delete Policy:**
```sql
bucket_id = 'ticket-documents' AND auth.uid()::text = (storage.foldername(name))[1]
```

(Replace 'ticket-documents' with 'ticket-images' and 'ticket-videos' for those buckets)

### Step 4: Apply Database Migration

Go to Supabase Dashboard → SQL Editor → Run this file:
`supabase/migrations/create_ticket_attachments.sql`

Or copy-paste the SQL content from that file.

## 📱 How to Use in Your App

### In Chat Screen or Ticket Details:

```dart
import '../services/file_upload_service.dart';
import '../models/ticket_attachment.dart';

// Upload a document
void _uploadDocument() async {
  try {
    final attachment = await FileUploadService.uploadDocument(
      ticketId: widget.ticketId,
      onProgress: (progress) {
        print('Upload progress: ${(progress * 100).toStringAsFixed(0)}%');
      },
    );

    if (attachment != null) {
      print('Document uploaded: ${attachment.fileName}');
      // Refresh attachments list
    }
  } catch (e) {
    print('Error: $e');
  }
}

// Upload an image
void _uploadImage() async {
  try {
    final attachment = await FileUploadService.uploadImage(
      ticketId: widget.ticketId,
      onProgress: (progress) {
        setState(() {
          _uploadProgress = progress;
        });
      },
    );

    if (attachment != null) {
      print('Image uploaded: ${attachment.fileName}');
    }
  } catch (e) {
    print('Error: $e');
  }
}

// Upload a video
void _uploadVideo() async {
  try {
    final attachment = await FileUploadService.uploadVideo(
      ticketId: widget.ticketId,
      onProgress: (progress) => print('Progress: $progress'),
    );

    if (attachment != null) {
      print('Video uploaded: ${attachment.fileName}');
    }
  } catch (e) {
    print('Error: $e');
  }
}

// Get all attachments
void _loadAttachments() async {
  try {
    final attachments = await FileUploadService.getTicketAttachments(widget.ticketId);
    setState(() {
      _attachments = attachments;
    });
  } catch (e) {
    print('Error: $e');
  }
}

// Delete an attachment
void _deleteAttachment(TicketAttachment attachment) async {
  try {
    await FileUploadService.deleteAttachment(attachment);
    print('Attachment deleted');
    _loadAttachments(); // Refresh list
  } catch (e) {
    print('Error: $e');
  }
}
```

## 🎨 UI Implementation Next Steps

You can now add UI components to your chat screen or ticket details:

1. **Upload Buttons Section**:
   - 3 separate buttons: "Upload Document", "Upload Image", "Upload Video"
   - Each button calls the respective upload method
   - Show progress indicator during upload

2. **Attachments List**:
   - Display all uploaded files grouped by type
   - Show file name, size, upload date
   - Preview images as thumbnails
   - Download button for each file
   - Delete button (only for uploader)

3. **Upload at Any Time**:
   - Users can add more files after initial submission
   - No limit on number of files per ticket
   - Each upload is independent

## 🔒 Security Features

- ✅ Only authenticated users can upload
- ✅ Files stored in private buckets
- ✅ File paths include user ID
- ✅ Users can only delete their own files
- ✅ MIME type validation
- ✅ File size limits enforced
- ✅ RLS policies protect data

## 📝 File Organization

Files are stored in Supabase Storage with this structure:
```
bucket-name/
  └── user-id/
      └── ticket-id/
          └── timestamp.extension
```

Example:
```
ticket-images/
  └── 123e4567-e89b-12d3-a456-426614174000/
      └── abc-def-ticket-id/
          └── 1234567890.jpg
```

## ✨ Features Included

- ✅ Separate upload methods for documents, images, videos
- ✅ File picker with extension filtering
- ✅ File size validation
- ✅ MIME type detection and validation
- ✅ Progress tracking
- ✅ Automatic metadata storage
- ✅ Secure file URLs
- ✅ Delete functionality
- ✅ Fetch attachments by ticket
- ✅ User information (uploader profile)

## 🚀 Next: Add UI

The backend is complete! Now you can add UI components to:
1. Show upload buttons in chat/ticket screen
2. Display list of uploaded files
3. Handle upload progress
4. Show success/error messages
5. Preview images
6. Download files

Would you like me to create the UI components next?
