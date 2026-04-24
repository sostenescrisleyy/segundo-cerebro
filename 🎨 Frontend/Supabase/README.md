---
tags: [frontend]
categoria: "🎨 Frontend"
---

# Supabase — Guia de Referência

**Docs:** https://supabase.com/docs  
**Cliente JS:** `@supabase/supabase-js`  
**CLI:** `supabase` (gerenciamento local e migrações)

---

## Setup do Cliente

```typescript
// lib/supabase/client.ts — para componentes Client (browser)
import { createBrowserClient } from '@supabase/ssr'

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  )
}

// lib/supabase/server.ts — para Server Components, Server Actions, Route Handlers
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'

export async function createClient() {
  const cookieStore = await cookies()
  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll: () => cookieStore.getAll(),
        setAll: (cookiesToSet) => {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            )
          } catch {}
        },
      },
    }
  )
}

// lib/supabase/admin.ts — APENAS no servidor, NUNCA no cliente
import { createClient } from '@supabase/supabase-js'

export const supabaseAdmin = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!, // ← NUNCA expor no frontend!
  { auth: { autoRefreshToken: false, persistSession: false } }
)
```

---

## Autenticação

```typescript
// Server Action de login
'use server'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'

export async function signIn(formData: FormData) {
  const supabase = await createClient()
  const { error } = await supabase.auth.signInWithPassword({
    email: formData.get('email') as string,
    password: formData.get('password') as string,
  })
  if (error) return { error: error.message }
  redirect('/dashboard')
}

export async function signUp(formData: FormData) {
  const supabase = await createClient()
  const { error } = await supabase.auth.signUp({
    email: formData.get('email') as string,
    password: formData.get('password') as string,
    options: {
      emailRedirectTo: `${process.env.NEXT_PUBLIC_APP_URL}/auth/callback`,
      data: { name: formData.get('name') } // user_metadata
    }
  })
  if (error) return { error: error.message }
  return { success: 'Verifique seu email!' }
}

export async function signOut() {
  const supabase = await createClient()
  await supabase.auth.signOut()
  redirect('/login')
}
```

```typescript
// Obter sessão em Server Component
export default async function Dashboard() {
  const supabase = await createClient()
  const { data: { user }, error } = await supabase.auth.getUser()
  // ⚠️ SEMPRE use getUser() — nunca getSession() no servidor
  // getSession() não verifica JWT com o servidor, getUser() sim
  if (!user) redirect('/login')
  return <div>Olá {user.email}</div>
}
```

---

## Row Level Security (RLS) — Não Opcional

```sql
-- SEMPRE habilitar RLS ao criar tabela
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;

-- Policy: usuário só vê seus próprios posts
CREATE POLICY "Users can read own posts"
  ON public.posts FOR SELECT
  USING ((select auth.uid()) = user_id);  -- select() = cached = mais rápido

-- Policy: usuário só insere com seu próprio ID
CREATE POLICY "Users can insert own posts"
  ON public.posts FOR INSERT
  WITH CHECK ((select auth.uid()) = user_id);

-- Policy: usuário só atualiza seus próprios posts
CREATE POLICY "Users can update own posts"
  ON public.posts FOR UPDATE
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);
  -- UPDATE sempre precisa de USING + WITH CHECK

-- Policy: usuário só deleta seus próprios posts
CREATE POLICY "Users can delete own posts"
  ON public.posts FOR DELETE
  USING ((select auth.uid()) = user_id);

-- Policy: posts públicos visíveis para todos
CREATE POLICY "Published posts are public"
  ON public.posts FOR SELECT
  USING (published = true);
```

### RLS com Índices (performance obrigatória)

```sql
-- SEMPRE adicionar índice nas colunas usadas em RLS
CREATE INDEX idx_posts_user_id ON public.posts (user_id);
CREATE INDEX idx_posts_published ON public.posts (published) WHERE published = true;

-- Para RLS em tabelas grandes, sem índice = 100x mais lento
```

### RLS para Multi-tenant (teams/organizations)

```sql
-- Tabela de membros da organização
CREATE TABLE public.memberships (
  user_id UUID REFERENCES auth.users NOT NULL,
  org_id  UUID NOT NULL,
  role    TEXT NOT NULL DEFAULT 'member', -- 'owner', 'admin', 'member'
  PRIMARY KEY (user_id, org_id)
);

-- Função helper (security definer = bypassa RLS nas tabelas que acessa)
CREATE OR REPLACE FUNCTION public.user_has_role_in_org(p_org_id UUID, p_role TEXT)
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.memberships
    WHERE user_id = (select auth.uid())
      AND org_id = p_org_id
      AND role = p_role
  );
$$;

-- RLS de recurso da organização
CREATE POLICY "Members can read org resources"
  ON public.resources FOR SELECT
  USING (
    org_id IN (
      SELECT org_id FROM public.memberships
      WHERE user_id = (select auth.uid())
    )
  );

CREATE POLICY "Admins can delete org resources"
  ON public.resources FOR DELETE
  USING ((select user_has_role_in_org(org_id, 'admin')));
```

---

## Queries com supabase-js

```typescript
// SELECT com filtros
const { data, error } = await supabase
  .from('posts')
  .select(`
    id, title, created_at,
    author: profiles (id, name, avatar_url),
    tags (name)
  `)
  .eq('published', true)
  .order('created_at', { ascending: false })
  .range(0, 19)  // paginação: items 0-19

// INSERT com retorno
const { data: post, error } = await supabase
  .from('posts')
  .insert({ title, content, user_id: user.id })
  .select('id, title')  // retorna os campos criados
  .single()             // espera um único resultado

// UPSERT (insert ou update)
const { data } = await supabase
  .from('profiles')
  .upsert({ id: user.id, name, bio })
  .select()

// UPDATE com condição
const { error } = await supabase
  .from('posts')
  .update({ title: 'Novo título' })
  .eq('id', postId)
  .eq('user_id', user.id)  // condição extra de segurança

// DELETE
await supabase.from('posts').delete().eq('id', postId)

// Filtragem avançada
await supabase.from('products')
  .select('*')
  .gte('price', 10)              // price >= 10
  .lte('price', 100)             // price <= 100
  .ilike('name', '%camiseta%')   // ILIKE (case insensitive)
  .in('category', ['roupas', 'acessórios'])
  .not('deleted_at', 'is', null) // deleted_at IS NOT NULL
```

---

## Storage — Upload e Download

```typescript
// Upload de arquivo
async function uploadAvatar(file: File, userId: string) {
  const ext = file.name.split('.').pop()
  const path = `${userId}/avatar.${ext}`

  const { data, error } = await supabase.storage
    .from('avatars')  // nome do bucket
    .upload(path, file, {
      upsert: true,    // sobrescreve se existir
      contentType: file.type,
    })

  if (error) throw error

  // URL pública (para buckets públicos)
  const { data: { publicUrl } } = supabase.storage
    .from('avatars')
    .getPublicUrl(path)

  return publicUrl
}

// URL assinada (para buckets privados — expira)
const { data: { signedUrl } } = await supabase.storage
  .from('documents')
  .createSignedUrl(path, 60 * 60)  // 1 hora

// Deletar arquivo
await supabase.storage.from('avatars').remove([path])
```

**RLS no Storage** (SQL):
```sql
-- Usuários só sobem arquivos na pasta deles
CREATE POLICY "Users upload to own folder"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = (select auth.uid())::text
  );
```

---

## Realtime

```typescript
// Escutar mudanças em tempo real (requer RLS no SELECT)
'use client'
import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase/client'

export function useRealtimePosts(channelId: string) {
  const [posts, setPosts] = useState<Post[]>([])
  const supabase = createClient()

  useEffect(() => {
    // Fetch inicial
    supabase.from('posts').select('*').eq('channel_id', channelId).then(({ data }) => {
      if (data) setPosts(data)
    })

    // Subscription
    const channel = supabase
      .channel(`posts-${channelId}`)
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'posts', filter: `channel_id=eq.${channelId}` },
        (payload) => {
          if (payload.eventType === 'INSERT') setPosts(p => [...p, payload.new as Post])
          if (payload.eventType === 'DELETE') setPosts(p => p.filter(post => post.id !== payload.old.id))
          if (payload.eventType === 'UPDATE') setPosts(p => p.map(post => post.id === payload.new.id ? payload.new as Post : post))
        }
      )
      .subscribe()

    return () => { supabase.removeChannel(channel) }
  }, [channelId])

  return posts
}
```

---

## Migrations com Supabase CLI

```bash
# Criar nova migration
supabase migration new create_posts_table

# Editar o arquivo gerado em supabase/migrations/
# Aplicar localmente
supabase db reset

# Push para produção
supabase db push

# Gerar tipos TypeScript do schema
supabase gen types typescript --project-id YOUR_PROJECT_ID > database.types.ts
```

---

## Referências

→ `references/rls-patterns.md` — políticas avançadas: RBAC, multi-tenant, Storage  
→ `references/edge-functions.md` — Edge Functions, webhooks, cron jobs


---

## Relacionado

[[Next.js 15]] | [[Prisma ORM]] | [[Backend Security]]


---

## Referencias

- [[Referencias/rls-patterns]]
