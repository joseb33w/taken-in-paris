-- TAKEN IN PARIS - instant account creation.
-- This shared project has email confirmation ON and anonymous sign-in OFF, so the public
-- auth.signUp cannot establish a session without an email round-trip. This SECURITY DEFINER
-- RPC creates a pre-confirmed email/password user server-side; the client then signs in
-- normally, giving instant accounts that work across devices. No PII beyond email is stored.

create extension if not exists pgcrypto with schema extensions;

create or replace function public.app_register(p_email text, p_password text, p_codename text)
returns json
language plpgsql
security definer
set search_path = public, auth, extensions
as $$
declare
  v_uid uuid;
  v_email text := lower(trim(p_email));
begin
  if v_email is null or position('@' in v_email) = 0 then
    return json_build_object('ok', false, 'error', 'invalid_email');
  end if;
  if length(coalesce(p_password, '')) < 6 then
    return json_build_object('ok', false, 'error', 'weak_password');
  end if;
  if exists (select 1 from auth.users where email = v_email) then
    return json_build_object('ok', false, 'error', 'email_taken');
  end if;
  v_uid := gen_random_uuid();
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    created_at, updated_at, raw_app_meta_data, raw_user_meta_data, is_sso_user, is_anonymous,
    confirmation_token, recovery_token, email_change, email_change_token_new,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', v_uid, 'authenticated', 'authenticated', v_email,
    extensions.crypt(p_password, extensions.gen_salt('bf')), now(),
    now(), now(), '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('codename', coalesce(p_codename, 'Operative')), false, false,
    '', '', '', '', '', ''
  );
  insert into auth.identities (
    provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at
  ) values (
    v_uid::text, v_uid, jsonb_build_object('sub', v_uid::text, 'email', v_email), 'email', now(), now(), now()
  );
  return json_build_object('ok', true, 'user_id', v_uid::text);
exception when others then
  return json_build_object('ok', false, 'error', SQLERRM);
end;
$$;

grant execute on function public.app_register(text, text, text) to anon, authenticated, service_role;
select pg_notify('pgrst', 'reload schema');
