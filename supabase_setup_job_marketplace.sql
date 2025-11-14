-- ========================================
-- JOB MARKETPLACE SCHEMA
-- ========================================

-- Create job_seeker_profiles table
CREATE TABLE IF NOT EXISTS public.job_seeker_profiles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone_number TEXT,
    nationality TEXT NOT NULL,
    current_location TEXT,
    job_title TEXT NOT NULL,
    summary TEXT,
    experience_years INTEGER NOT NULL DEFAULT 0,
    experience_level TEXT NOT NULL CHECK (experience_level IN ('entry', 'mid', 'senior', 'expert')),
    skills TEXT[] DEFAULT '{}',
    certifications TEXT[] DEFAULT '{}',
    cv_url TEXT,
    portfolio_url TEXT,
    linkedin_url TEXT,
    expected_salary NUMERIC(12, 2),
    salary_currency TEXT DEFAULT 'USD',
    is_available BOOLEAN DEFAULT TRUE,
    availability TEXT CHECK (availability IN ('immediate', '2_weeks', '1_month', 'negotiable')),
    app_score INTEGER DEFAULT 0,
    tickets_solved INTEGER DEFAULT 0,
    average_rating NUMERIC(3, 2) DEFAULT 0.0,
    preferred_job_types TEXT[] DEFAULT '{}',
    preferred_locations TEXT[] DEFAULT '{}',
    willing_to_relocate BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Create job_postings table
CREATE TABLE IF NOT EXISTS public.job_postings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    company_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    company_name TEXT NOT NULL,
    company_logo TEXT,
    company_website TEXT,
    company_description TEXT,
    job_title TEXT NOT NULL,
    job_description TEXT NOT NULL,
    job_type TEXT NOT NULL CHECK (job_type IN ('engineer', 'technician', 'supervisor', 'manager', 'operator')),
    employment_type TEXT NOT NULL CHECK (employment_type IN ('full_time', 'part_time', 'contract', 'temporary')),
    experience_level TEXT NOT NULL CHECK (experience_level IN ('entry', 'mid', 'senior', 'expert')),
    min_experience_years INTEGER NOT NULL DEFAULT 0,
    max_experience_years INTEGER,
    location TEXT NOT NULL,
    country TEXT NOT NULL,
    remote_allowed BOOLEAN DEFAULT FALSE,
    relocation_assistance BOOLEAN DEFAULT FALSE,
    required_skills TEXT[] DEFAULT '{}',
    preferred_skills TEXT[] DEFAULT '{}',
    certifications TEXT[] DEFAULT '{}',
    education_requirement TEXT,
    min_salary NUMERIC(12, 2),
    max_salary NUMERIC(12, 2),
    salary_currency TEXT DEFAULT 'USD',
    salary_period TEXT CHECK (salary_period IN ('hourly', 'monthly', 'yearly')),
    benefits TEXT[] DEFAULT '{}',
    open_positions INTEGER DEFAULT 1,
    application_deadline TIMESTAMP WITH TIME ZONE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    status TEXT DEFAULT 'open' CHECK (status IN ('open', 'closed', 'filled')),
    view_count INTEGER DEFAULT 0,
    application_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create job_applications table (to track applications)
CREATE TABLE IF NOT EXISTS public.job_applications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    job_posting_id UUID NOT NULL REFERENCES public.job_postings(id) ON DELETE CASCADE,
    job_seeker_id UUID NOT NULL REFERENCES public.job_seeker_profiles(id) ON DELETE CASCADE,
    applicant_name TEXT NOT NULL,
    applicant_email TEXT NOT NULL,
    cover_letter TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'shortlisted', 'rejected', 'accepted')),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(job_posting_id, job_seeker_id)
);

-- ========================================
-- INDEXES
-- ========================================

CREATE INDEX IF NOT EXISTS idx_job_seeker_profiles_user_id ON public.job_seeker_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_job_seeker_profiles_available ON public.job_seeker_profiles(is_available);
CREATE INDEX IF NOT EXISTS idx_job_seeker_profiles_job_types ON public.job_seeker_profiles USING GIN(preferred_job_types);
CREATE INDEX IF NOT EXISTS idx_job_seeker_profiles_locations ON public.job_seeker_profiles USING GIN(preferred_locations);

CREATE INDEX IF NOT EXISTS idx_job_postings_company_id ON public.job_postings(company_id);
CREATE INDEX IF NOT EXISTS idx_job_postings_status ON public.job_postings(status);
CREATE INDEX IF NOT EXISTS idx_job_postings_active ON public.job_postings(is_active);
CREATE INDEX IF NOT EXISTS idx_job_postings_deadline ON public.job_postings(application_deadline);
CREATE INDEX IF NOT EXISTS idx_job_postings_job_type ON public.job_postings(job_type);
CREATE INDEX IF NOT EXISTS idx_job_postings_country ON public.job_postings(country);

CREATE INDEX IF NOT EXISTS idx_job_applications_posting_id ON public.job_applications(job_posting_id);
CREATE INDEX IF NOT EXISTS idx_job_applications_seeker_id ON public.job_applications(job_seeker_id);
CREATE INDEX IF NOT EXISTS idx_job_applications_status ON public.job_applications(status);

-- ========================================
-- ROW LEVEL SECURITY (RLS)
-- ========================================

ALTER TABLE public.job_seeker_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_postings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_applications ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Anyone can view active job seeker profiles" ON public.job_seeker_profiles;
DROP POLICY IF EXISTS "Users can manage their own job seeker profile" ON public.job_seeker_profiles;
DROP POLICY IF EXISTS "Anyone can view active job postings" ON public.job_postings;
DROP POLICY IF EXISTS "Companies can manage their own job postings" ON public.job_postings;
DROP POLICY IF EXISTS "Job seekers can view their applications" ON public.job_applications;
DROP POLICY IF EXISTS "Companies can view applications to their jobs" ON public.job_applications;
DROP POLICY IF EXISTS "Job seekers can create applications" ON public.job_applications;

-- Job Seeker Profiles Policies
CREATE POLICY "Anyone can view active job seeker profiles"
ON public.job_seeker_profiles FOR SELECT
TO authenticated
USING (is_available = true);

CREATE POLICY "Users can manage their own job seeker profile"
ON public.job_seeker_profiles FOR ALL
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Job Postings Policies
CREATE POLICY "Anyone can view active job postings"
ON public.job_postings FOR SELECT
TO authenticated
USING (is_active = true AND status = 'open');

CREATE POLICY "Companies can manage their own job postings"
ON public.job_postings FOR ALL
TO authenticated
USING (auth.uid() = company_id)
WITH CHECK (auth.uid() = company_id);

-- Job Applications Policies
CREATE POLICY "Job seekers can view their applications"
ON public.job_applications FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.job_seeker_profiles
        WHERE id = job_seeker_id AND user_id = auth.uid()
    )
);

CREATE POLICY "Companies can view applications to their jobs"
ON public.job_applications FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.job_postings
        WHERE id = job_posting_id AND company_id = auth.uid()
    )
);

CREATE POLICY "Job seekers can create applications"
ON public.job_applications FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.job_seeker_profiles
        WHERE id = job_seeker_id AND user_id = auth.uid()
    )
);

-- ========================================
-- TRIGGERS FOR UPDATED_AT
-- ========================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for job_seeker_profiles
DROP TRIGGER IF EXISTS update_job_seeker_profiles_updated_at ON public.job_seeker_profiles;
CREATE TRIGGER update_job_seeker_profiles_updated_at
    BEFORE UPDATE ON public.job_seeker_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Triggers for job_postings
DROP TRIGGER IF EXISTS update_job_postings_updated_at ON public.job_postings;
CREATE TRIGGER update_job_postings_updated_at
    BEFORE UPDATE ON public.job_postings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Triggers for job_applications
DROP TRIGGER IF EXISTS update_job_applications_updated_at ON public.job_applications;
CREATE TRIGGER update_job_applications_updated_at
    BEFORE UPDATE ON public.job_applications
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ========================================
-- STORAGE BUCKET FOR CVS AND DOCUMENTS
-- ========================================

-- Note: Storage bucket creation must be done via Supabase Dashboard
-- Create a bucket named 'job-cvs' with the following settings:
-- - Public: false (authenticated access only)
-- - File size limit: 10MB
-- - Allowed MIME types: application/pdf, application/msword, application/vnd.openxmlformats-officedocument.wordprocessingml.document

-- Storage policies (run after creating 'job-cvs' bucket):
-- CREATE POLICY "Authenticated users can upload CVs"
-- ON storage.objects FOR INSERT
-- TO authenticated
-- WITH CHECK (bucket_id = 'job-cvs');

-- CREATE POLICY "Users can view all CVs"
-- ON storage.objects FOR SELECT
-- TO authenticated
-- USING (bucket_id = 'job-cvs');

-- CREATE POLICY "Users can update their own CVs"
-- ON storage.objects FOR UPDATE
-- TO authenticated
-- USING (bucket_id = 'job-cvs' AND auth.uid()::text = (storage.foldername(name))[1]);

-- CREATE POLICY "Users can delete their own CVs"
-- ON storage.objects FOR DELETE
-- TO authenticated
-- USING (bucket_id = 'job-cvs' AND auth.uid()::text = (storage.foldername(name))[1]);
