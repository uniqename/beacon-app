// Case records gateway.
// The app sends case writes here instead of writing to the tables with the public key.
// Rules:
//  - The caller must be signed in to Supabase (a valid user access token).
//  - The caller's email must be on the staff allow-list (public.admin_emails).
//  - Only the case tables listed below can be written.
// The service-role key is provided by Supabase to this function at runtime.
// It is never stored in the app or in the repository.
import { createClient } from 'jsr:@supabase/supabase-js@2';

const ALLOWED_TABLES = new Set([
  'client_intakes',
  'case_plans',
  'case_programs',
  'case_notes',
  'case_referrals',
]);

const JSON_HEADERS = { 'Content-Type': 'application/json' };

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: JSON_HEADERS });
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== 'POST') return json({ error: 'method not allowed' }, 405);

  const token = (req.headers.get('Authorization') ?? '').replace(/^Bearer\s+/i, '').trim();
  if (!token) return json({ error: 'not signed in' }, 401);

  const url = Deno.env.get('SUPABASE_URL');
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY');
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!url || !anonKey || !serviceKey) return json({ error: 'server not configured' }, 500);

  // Check who is calling.
  const userClient = createClient(url, anonKey, { auth: { persistSession: false } });
  const { data: userData, error: userError } = await userClient.auth.getUser(token);
  if (userError || !userData?.user) return json({ error: 'not signed in' }, 401);

  const email = (userData.user.email ?? '').trim().toLowerCase();
  const admin = createClient(url, serviceKey, { auth: { persistSession: false } });

  // Check the staff allow-list.
  const { data: staff, error: staffError } = await admin
    .from('admin_emails')
    .select('email')
    .eq('email', email)
    .maybeSingle();
  if (staffError) return json({ error: 'could not check staff list' }, 500);
  if (!staff) return json({ error: 'not authorised' }, 403);

  let body: { table?: string; op?: string; row?: Record<string, unknown>; id?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: 'invalid json' }, 400);
  }

  const table = body.table ?? '';
  if (!ALLOWED_TABLES.has(table)) return json({ error: 'table not allowed' }, 400);

  if (body.op === 'upsert') {
    if (!body.row || typeof body.row !== 'object' || typeof body.row.id !== 'string') {
      return json({ error: 'row with id is required' }, 400);
    }
    const { error } = await admin.from(table).upsert(body.row);
    if (error) return json({ error: error.message }, 500);
    return json({ ok: true });
  }

  if (body.op === 'delete') {
    if (typeof body.id !== 'string' || body.id.length === 0) {
      return json({ error: 'id is required' }, 400);
    }
    const { error } = await admin.from(table).delete().eq('id', body.id);
    if (error) return json({ error: error.message }, 500);
    return json({ ok: true });
  }

  return json({ error: 'unknown op' }, 400);
});
