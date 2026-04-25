# React — Server State com TanStack Query

## Por que TanStack Query para server state

```
useState + useEffect para dados do servidor = reinventar a roda
TanStack Query oferece: cache, deduplicação, refetch automático, loading/error states, otimismo
```

## Configuração

```tsx
// app/providers.tsx
'use client'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { ReactQueryDevtools } from '@tanstack/react-query-devtools'

function makeQueryClient() {
  return new QueryClient({
    defaultOptions: {
      queries: {
        staleTime: 60 * 1000,   // 1min antes de considerar stale
        gcTime: 5 * 60 * 1000,  // 5min antes de remover do cache
        retry: 1,               // 1 tentativa extra em erro
        refetchOnWindowFocus: false,
      },
    },
  })
}

let browserQueryClient: QueryClient | undefined

function getQueryClient() {
  if (typeof window === 'undefined') return makeQueryClient()  // server: sempre novo
  if (!browserQueryClient) browserQueryClient = makeQueryClient()
  return browserQueryClient
}

export function Providers({ children }) {
  const queryClient = getQueryClient()
  return (
    <QueryClientProvider client={queryClient}>
      {children}
      <ReactQueryDevtools />
    </QueryClientProvider>
  )
}
```

## Queries

```tsx
// hooks/useUsers.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'

// Query Keys como constantes (evita typos)
export const userKeys = {
  all: ['users'] as const,
  lists: () => [...userKeys.all, 'list'] as const,
  list: (filters: UserFilters) => [...userKeys.lists(), filters] as const,
  detail: (id: string) => [...userKeys.all, 'detail', id] as const,
}

// Query
export function useUsers(filters: UserFilters) {
  return useQuery({
    queryKey: userKeys.list(filters),
    queryFn: () => fetchUsers(filters),
    select: (data) => data.users,  // transformar dados sem re-fetch
    placeholderData: keepPreviousData,  // mantém dados antigos durante pagination
  })
}

// Mutation com invalidação automática
export function useCreateUser() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (data: CreateUserInput) => createUser(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: userKeys.lists() })
    },
    onError: (error) => {
      toast.error(error.message)
    },
  })
}
```

## Otimistic Updates com React Query

```tsx
export function useLikePost() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({ postId }: { postId: string }) => likePost(postId),

    onMutate: async ({ postId }) => {
      // Cancelar queries em andamento para evitar conflito
      await queryClient.cancelQueries({ queryKey: ['post', postId] })

      // Snapshot do estado anterior (para rollback)
      const previous = queryClient.getQueryData(['post', postId])

      // Atualização otimista
      queryClient.setQueryData(['post', postId], (old: Post) => ({
        ...old,
        liked: !old.liked,
        likeCount: old.liked ? old.likeCount - 1 : old.likeCount + 1,
      }))

      return { previous } // passado para onError
    },

    onError: (err, { postId }, context) => {
      // Rollback em caso de erro
      queryClient.setQueryData(['post', postId], context?.previous)
    },

    onSettled: (data, err, { postId }) => {
      // Sempre refetch após mutação para garantir consistência
      queryClient.invalidateQueries({ queryKey: ['post', postId] })
    },
  })
}
```

## Infinite Queries (paginação infinita)

```tsx
const { data, fetchNextPage, hasNextPage, isFetchingNextPage } = useInfiniteQuery({
  queryKey: ['posts', filters],
  queryFn: ({ pageParam = 1 }) => fetchPosts({ page: pageParam, ...filters }),
  getNextPageParam: (lastPage) => lastPage.nextPage ?? undefined,
  initialPageParam: 1,
})

// Flatmap das páginas
const posts = data?.pages.flatMap(page => page.posts) ?? []
```


---

← [[README|React 19]]
