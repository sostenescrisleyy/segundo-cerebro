# Supabase RLS — Padrões Avançados e Troubleshooting

## Anatomia de uma Policy

```sql
CREATE POLICY "nome descritivo"
  ON schema.tabela
  FOR operação                 -- SELECT | INSERT | UPDATE | DELETE | ALL
  TO role                      -- authenticated | anon | public (padrão: todos)
  USING (expressão_booleana)   -- Para SELECT, UPDATE, DELETE (filtra linhas existentes)
  WITH CHECK (expressão_bool); -- Para INSERT, UPDATE (valida novos dados)
```

## Regra Crítica: UPDATE precisa de ambas

```sql
-- ❌ UPDATE sem USING: pode atualizar mas não consegue ver a linha depois
CREATE POLICY "update"
  ON posts FOR UPDATE
  WITH CHECK (user_id = auth.uid());

-- ✅ Correto: USING + WITH CHECK para UPDATE
CREATE POLICY "update"
  ON posts FOR UPDATE
  USING (user_id = (select auth.uid()))   -- consegue ler a linha antes de modificar
  WITH CHECK (user_id = (select auth.uid())); -- nova linha também precisa pertencer ao usuário
```

## Performance: `(select auth.uid())` vs `auth.uid()`

```sql
-- ❌ Lento: auth.uid() é chamado para CADA LINHA da tabela
USING (auth.uid() = user_id)

-- ✅ Rápido: (select auth.uid()) é calculado UMA VEZ por statement (initPlan)
USING ((select auth.uid()) = user_id)

-- A diferença em tabelas grandes pode ser 10x-100x de performance
-- Use SEMPRE para funções como auth.uid(), auth.jwt(), is_admin(), etc.
```

## Checklist de RLS por Tabela

```sql
-- Template para qualquer tabela user-owned:
ALTER TABLE public.minha_tabela ENABLE ROW LEVEL SECURITY;

-- Índice obrigatório na coluna de autorização
CREATE INDEX idx_minha_tabela_user_id ON public.minha_tabela (user_id);

-- 4 políticas para CRUD completo
CREATE POLICY "select own" ON public.minha_tabela FOR SELECT
  USING ((select auth.uid()) = user_id);

CREATE POLICY "insert own" ON public.minha_tabela FOR INSERT
  WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "update own" ON public.minha_tabela FOR UPDATE
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "delete own" ON public.minha_tabela FOR DELETE
  USING ((select auth.uid()) = user_id);
```

## Funções Helper (Security Definer)

```sql
-- Verificar se usuário tem role em uma organização
CREATE OR REPLACE FUNCTION public.has_org_role(p_org_id UUID, p_roles TEXT[])
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM memberships
    WHERE user_id = (select auth.uid())
      AND org_id = p_org_id
      AND role = ANY(p_roles)
  );
$$;

-- Uso na policy:
CREATE POLICY "admins can delete"
  ON resources FOR DELETE
  USING ((select has_org_role(org_id, ARRAY['admin', 'owner'])));
```

## Testando RLS no SQL Editor

```sql
-- ATENÇÃO: SQL Editor usa role postgres que BYPASSA RLS
-- Para testar como usuário autenticado:

-- Simular usuário específico
SET LOCAL role TO authenticated;
SET LOCAL request.jwt.claims TO '{"sub": "user-uuid-aqui", "role": "authenticated"}';

-- Agora as queries respeitam RLS
SELECT * FROM posts;

-- Resetar
RESET role;
```

## Erros Comuns e Soluções

| Problema | Causa | Solução |
|---|---|---|
| Tabela retorna vazio após habilitar RLS | Nenhuma policy criada (deny-by-default) | Criar pelo menos uma policy SELECT |
| UPDATE silenciosamente falha | Sem policy USING no UPDATE | Adicionar USING à policy de UPDATE |
| Views ignoram RLS | Views são criadas como postgres (security definer) | Adicionar `security_invoker = true` na view (Postgres 15+) |
| Auth funciona mas query retorna vazio | getSession() não verifica com servidor | Usar getUser() no servidor |
| Performance lenta com RLS | Sem índice na coluna da policy | CREATE INDEX na coluna user_id/org_id |
| service_role burla RLS | É um comportamento intencional | Nunca expor service_role no cliente |

## Verificar Cobertura de RLS

```sql
-- Tabelas sem RLS habilitado no schema público
SELECT tablename
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename NOT IN (
    SELECT tablename FROM pg_tables
    WHERE schemaname = 'public'
      AND EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = pg_tables.tablename
      )
  );
```


---

← [[README|Supabase]]
