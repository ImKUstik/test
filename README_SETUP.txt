# Detroit Click Protocol — Supabase setup

This bundle turns the HTML clicker into a shared online leaderboard.

## Files
- `index.html` — the website
- `supabase_setup.sql` — database schema, profile trigger, read policy, and safe click function

## Step 1 — Create Supabase project
1. Go to https://supabase.com/dashboard and create a project.
2. Open **SQL Editor → New query**.
3. Paste the full contents of `supabase_setup.sql` and click **Run**.

## Step 2 — Configure username + password login
Supabase Auth password sign-in natively uses an email address or phone number, not a username alone. This demo maps each username to a synthetic address like `connor_87@detroit-clicker.invalid`. Users only type a username and password; they do not need a real email address.

1. In Supabase Dashboard, open **Authentication → Sign In / Providers → Email** (labels may vary).
2. Turn **Confirm email** OFF. This is required because the synthetic address cannot receive mail.
3. Keep password authentication enabled.
4. Do not use this synthetic-email approach if you need email verification, password reset by email, or production-grade account recovery. For a public production site, use a real email or a purpose-built server-side username authentication system.

## Step 3 — Add the browser connection values
1. Open your Supabase project and find **Connect** / **Project URL** and the **publishable key** (or legacy `anon` key).
2. Open `index.html` in a text editor.
3. At the beginning of the module script, replace:
   - `PASTE_YOUR_SUPABASE_PROJECT_URL_HERE`
   - `PASTE_YOUR_SUPABASE_PUBLISHABLE_KEY_HERE`
4. Save the file.

The publishable/anon key is designed for browser use when RLS is configured. NEVER place the `service_role` or secret key in HTML.

## Step 4 — Publish the website
Upload `index.html` to your static host (for example, GitHub Pages, Netlify, or another host). The SQL file is setup material and does not need to be uploaded to the public website.

## Step 5 — Test
1. Open the deployed website.
2. Register with a test username and a unique password of at least 8 characters.
3. Click the plate. The count should increase and the shared leaderboard should update.
4. Open the site in another browser/device and register a second test account; the leaderboard should show both users.
5. Try clicking very rapidly; the database enforces a 90ms cooldown per account.

## Security notes
- The browser cannot directly update `profiles.clicks`; only the `click_once()` database function can increment it.
- The SQL cooldown slows automated rapid calls, but it is not a complete anti-cheat system. A determined attacker can still automate at the allowed rate or create many accounts. A public competitive leaderboard may need stronger rate limits, abuse monitoring, CAPTCHA, and account recovery.
- The leaderboard is readable only to authenticated users.
- The username-only synthetic-email method is a convenience for a demo, not a recommended long-term identity system.
