-- Confirm all pending users
UPDATE auth.users
SET email_confirmed_at = NOW()
WHERE email_confirmed_at IS NULL;

-- Show confirmed users
SELECT email, email_confirmed_at
FROM auth.users
WHERE email_confirmed_at IS NOT NULL;