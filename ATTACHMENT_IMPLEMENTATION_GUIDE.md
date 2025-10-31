# Ticket Attachments Implementation Guide

This guide provides step-by-step instructions to add document, image, and video upload functionality to tickets.

## Step 1: Create Database Table

Go to your Supabase Dashboard → SQL Editor and run the migration file:
`supabase/migrations/create_ticket_attachments.sql`

This creates:
- `ticket_attachments` table
- Proper indexes for performance
- RLS policies for security
- Automatic timestamp updates

## Step 2: Create Storage Buckets

In Supabase Dashboard → Storage, create these buckets:

### Bucket: `ticket-documents`
- **Public**: No
- **File size limit**: 50MB
- **Allowed MIME types**:
  - application/pdf
  - application/msword
  - application/vnd.openxmlformats-officedocument.wordprocessingml.document
  - application/vnd.ms-excel
  - application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
  - text/plain
  - text/csv

### Bucket: `ticket-images`
- **Public**: No
- **File size limit**: 10MB
- **Allowed MIME types**:
  - image/jpeg
  - image/png
  - image/gif
  - image/webp

### Bucket: `ticket-videos`
- **Public**: No
- **File size limit**: 100MB
- **Allowed MIME types**:
  - video/mp4
  - video/webm
  - video/quicktime
  - video/x-msvideo

### Storage Policies

For each bucket, add these policies in Storage → Policies:

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

Repeat for `ticket-images` and `ticket-videos` buckets.

## Step 3: File Structure

The following files have been created:

### Models
- `lib/models/ticket_attachment.dart` ✅ Created
  - Defines attachment data structure
  - Supports document, image, video types
  - File size formatting

### Services
- `lib/services/file_upload_service.dart` ⏳ To be created
  - Handles file uploads to Supabase Storage
  - Saves metadata to database
  - Provides download URLs

### Widgets
- `lib/widgets/attachment_upload_section.dart` ⏳ To be created
  - UI for uploading files by type
  - Shows upload progress
  - Allows adding more files anytime

- `lib/widgets/attachment_list.dart` ⏳ To be created
  - Displays uploaded attachments
  - Preview for images
  - Download links for documents/videos

## Step 4: Dependencies

Add these to `pubspec.yaml`:

```yaml
dependencies:
  file_picker: ^8.0.0+1  # For selecting files
  mime: ^1.0.5           # For detecting MIME types
  path: ^1.9.0           # Already included
```

Run: `flutter pub get`

## Step 5: Implementation Files

The following implementation files need to be created. I will create them in the next steps.

## Testing Checklist

After implementation:

- [ ] Upload document (.pdf, .docx, .xlsx)
- [ ] Upload image (.jpg, .png)
- [ ] Upload video (.mp4)
- [ ] View uploaded attachments in ticket
- [ ] Add more attachments after initial submission
- [ ] Delete own attachments
- [ ] Download attachments
- [ ] Check file size limits
- [ ] Verify security (only authenticated users)

## Notes

- Files are stored in Supabase Storage (not in database)
- Database only stores metadata (filename, URL, size, type)
- Each user can only delete their own attachments
- All uploads require authentication
- File paths include user ID for security
