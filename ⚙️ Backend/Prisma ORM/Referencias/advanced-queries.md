# Prisma — Queries Avançadas

## Raw SQL

```typescript
// Query raw tipada
const users = await prisma.$queryRaw<User[]>`
  SELECT * FROM users
  WHERE created_at > ${new Date('2025-01-01')}
  ORDER BY name ASC
`

// Execute (sem retorno)
await prisma.$executeRaw`
  UPDATE posts SET view_count = view_count + 1
  WHERE id = ${postId}
`
```

## Aggregations

```typescript
const stats = await prisma.post.aggregate({
  _count: { id: true },
  _avg:   { viewCount: true },
  _max:   { viewCount: true },
  _sum:   { viewCount: true },
  where:  { published: true },
})
// stats._avg.viewCount → média de views

// GroupBy
const byAuthor = await prisma.post.groupBy({
  by: ['authorId'],
  _count: { id: true },
  _avg:   { viewCount: true },
  orderBy: { _count: { id: 'desc' } },
})
```

## Relações Many-to-Many (connect/disconnect)

```typescript
// Adicionar tags a um post
await prisma.post.update({
  where: { id: postId },
  data: {
    tags: {
      connect:    [{ id: 'tag-1' }, { id: 'tag-2' }],
      disconnect: [{ id: 'tag-old' }],
      set:        [{ id: 'tag-only' }],  // substitui todos
    }
  }
})
```

## Soft Delete (padrão com deletedAt)

```typescript
// No schema: deletedAt DateTime?

// Middleware para filtrar deletados automaticamente
prisma.$use(async (params, next) => {
  if (params.action === 'findMany') {
    params.args.where = { ...params.args.where, deletedAt: null }
  }
  return next(params)
})
```


---

← [[README|Prisma ORM]]
