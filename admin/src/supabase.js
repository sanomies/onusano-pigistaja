import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL      = 'https://ydbeigrvlsvmrhouguhm.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_jGOeC0DLdJlzI64FNcSPaQ_bZEyM3UN';

export const ADMIN_EMAIL = 'sanel.mittal@delfi.ee';
export const db          = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
