-- Create suppliers table
CREATE TABLE IF NOT EXISTS suppliers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    company_name VARCHAR(255) NOT NULL,
    contact_person VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(50) NOT NULL,
    address TEXT NOT NULL,
    products_services TEXT NOT NULL,
    logo_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create suppliers storage bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('suppliers', 'suppliers', true)
ON CONFLICT (id) DO NOTHING;

-- Enable RLS
ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Enable read access for all users" ON suppliers
    FOR SELECT USING (true);

CREATE POLICY "Enable insert for authenticated users only" ON suppliers
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable update for authenticated users only" ON suppliers
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Enable delete for authenticated users only" ON suppliers
    FOR DELETE USING (auth.role() = 'authenticated');

-- Create updated_at trigger function if it doesn't exist
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updated_at
CREATE TRIGGER update_suppliers_updated_at
    BEFORE UPDATE ON suppliers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create index on company name for faster searches
CREATE INDEX IF NOT EXISTS idx_suppliers_company_name ON suppliers(company_name);
CREATE INDEX IF NOT EXISTS idx_suppliers_created_at ON suppliers(created_at DESC);

-- Add comments
COMMENT ON TABLE suppliers IS 'Supplier companies that provide parts and services';
COMMENT ON COLUMN suppliers.company_name IS 'Name of the supplier company';
COMMENT ON COLUMN suppliers.contact_person IS 'Primary contact person name';
COMMENT ON COLUMN suppliers.email IS 'Contact email address';
COMMENT ON COLUMN suppliers.phone IS 'Contact phone number';
COMMENT ON COLUMN suppliers.address IS 'Physical address of the supplier';
COMMENT ON COLUMN suppliers.products_services IS 'Description of products or services provided';
COMMENT ON COLUMN suppliers.logo_url IS 'URL to the supplier company logo in storage';
