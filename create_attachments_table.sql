-- Create ticket_attachments table
CREATE TABLE IF NOT EXISTS public.ticket_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES public.tickets(id) ON DELETE CASCADE,
  uploader_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  file_name TEXT NOT NULL,
  file_type TEXT NOT NULL,
  file_url TEXT NOT NULL,
  file_size INTEGER NOT NULL,
  mime_type TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_ticket_attachments_ticket_id ON public.ticket_attachments(ticket_id);
CREATE INDEX IF NOT EXISTS idx_ticket_attachments_uploader_id ON public.ticket_attachments(uploader_id);

-- Enable RLS
ALTER TABLE public.ticket_attachments ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Allow authenticated users to view attachments"
ON public.ticket_attachments FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Allow authenticated users to upload attachments"
ON public.ticket_attachments FOR INSERT
TO authenticated
WITH CHECK (uploader_id = auth.uid());

CREATE POLICY "Allow users to delete their own attachments"
ON public.ticket_attachments FOR DELETE
TO authenticated
USING (uploader_id = auth.uid());

-- Add trigger for updated_at
CREATE OR REPLACE FUNCTION update_ticket_attachments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_ticket_attachments_updated_at
BEFORE UPDATE ON public.ticket_attachments
FOR EACH ROW
EXECUTE FUNCTION update_ticket_attachments_updated_at();
