-- Create ticket_attachments table
CREATE TABLE IF NOT EXISTS ticket_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
  uploader_id UUID NOT NULL REFERENCES profiles(id),
  file_name TEXT NOT NULL,
  file_type TEXT NOT NULL, -- 'document', 'image', 'video'
  file_url TEXT NOT NULL,
  file_size BIGINT,
  mime_type TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_ticket_attachments_ticket_id ON ticket_attachments(ticket_id);
CREATE INDEX IF NOT EXISTS idx_ticket_attachments_uploader_id ON ticket_attachments(uploader_id);
CREATE INDEX IF NOT EXISTS idx_ticket_attachments_file_type ON ticket_attachments(file_type);

-- Add RLS policies
ALTER TABLE ticket_attachments ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view attachments for tickets they can see
CREATE POLICY "Users can view ticket attachments" ON ticket_attachments
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM tickets
      WHERE tickets.id = ticket_attachments.ticket_id
    )
  );

-- Policy: Authenticated users can upload attachments
CREATE POLICY "Authenticated users can upload attachments" ON ticket_attachments
  FOR INSERT
  WITH CHECK (auth.uid() = uploader_id);

-- Policy: Users can delete their own attachments
CREATE POLICY "Users can delete own attachments" ON ticket_attachments
  FOR DELETE
  USING (auth.uid() = uploader_id);

-- Add trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_ticket_attachments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_ticket_attachments_updated_at
  BEFORE UPDATE ON ticket_attachments
  FOR EACH ROW
  EXECUTE FUNCTION update_ticket_attachments_updated_at();

-- Add comment
COMMENT ON TABLE ticket_attachments IS 'Stores file attachments (documents, images, videos) for tickets';
