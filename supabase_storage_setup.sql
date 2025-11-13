-- Create storage buckets if they don't exist
INSERT INTO storage.buckets (id, name, public)
VALUES 
  ('ticket-images', 'ticket-images', true),
  ('ticket-documents', 'ticket-documents', true),
  ('ticket-videos', 'ticket-videos', true)
ON CONFLICT (id) DO NOTHING;

-- Set up storage policies for ticket-images bucket
CREATE POLICY "Allow authenticated users to upload images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'ticket-images');

CREATE POLICY "Allow public to view images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'ticket-images');

CREATE POLICY "Allow users to delete their own images"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'ticket-images' AND (storage.foldername(name))[1] = auth.uid()::text);

-- Set up storage policies for ticket-documents bucket
CREATE POLICY "Allow authenticated users to upload documents"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'ticket-documents');

CREATE POLICY "Allow public to view documents"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'ticket-documents');

CREATE POLICY "Allow users to delete their own documents"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'ticket-documents' AND (storage.foldername(name))[1] = auth.uid()::text);

-- Set up storage policies for ticket-videos bucket
CREATE POLICY "Allow authenticated users to upload videos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'ticket-videos');

CREATE POLICY "Allow public to view videos"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'ticket-videos');

CREATE POLICY "Allow users to delete their own videos"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'ticket-videos' AND (storage.foldername(name))[1] = auth.uid()::text);
