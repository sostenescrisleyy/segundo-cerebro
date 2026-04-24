---
tags: [frontend]
categoria: "🎨 Frontend"
---

# shadcn/ui — Componentes e Customização

**Base:** Radix UI + Tailwind CSS + cva  
**Princípio:** Componentes que você POSSUI (copiados para o projeto). Não é uma lib — é código seu.

---

## Setup

```bash
npx shadcn@latest init

# Adicionar componentes (cada um é um arquivo em src/components/ui/)
npx shadcn@latest add button input dialog form table tabs toast
```

---

## Utilitário `cn`

```typescript
// lib/utils.ts — gerado automaticamente
import { clsx, type ClassValue } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

// Uso: merge inteligente de classes Tailwind
<div className={cn(
  'base-classes',
  isActive && 'active-class',
  variant === 'danger' && 'text-red-500',
  className   // props de fora não sobrescrevem errado
)} />
```

---

## Componentes Mais Usados

### Button com variantes

```tsx
import { Button } from '@/components/ui/button'

<Button variant="default">Salvar</Button>
<Button variant="destructive">Excluir</Button>
<Button variant="outline">Cancelar</Button>
<Button variant="ghost">Menu</Button>
<Button variant="link">Ver mais</Button>
<Button size="sm" disabled>Processando...</Button>
<Button asChild>
  <Link href="/login">Entrar</Link>
</Button>
```

### Dialog (Modal)

```tsx
import {
  Dialog, DialogContent, DialogHeader,
  DialogTitle, DialogDescription, DialogFooter,
} from '@/components/ui/dialog'

function DeleteDialog({ open, onOpenChange, onConfirm }) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Confirmar exclusão</DialogTitle>
          <DialogDescription>
            Esta ação não pode ser desfeita.
          </DialogDescription>
        </DialogHeader>
        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            Cancelar
          </Button>
          <Button variant="destructive" onClick={onConfirm}>
            Excluir
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
```

### Form com React Hook Form + Zod

```tsx
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import {
  Form, FormControl, FormField,
  FormItem, FormLabel, FormMessage,
} from '@/components/ui/form'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'

const schema = z.object({
  name:  z.string().min(2, 'Mínimo 2 caracteres'),
  email: z.string().email('E-mail inválido'),
})

export function UserForm() {
  const form = useForm({ resolver: zodResolver(schema) })

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(console.log)} className="space-y-4">

        <FormField
          control={form.control}
          name="name"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Nome</FormLabel>
              <FormControl>
                <Input placeholder="Seu nome" {...field} />
              </FormControl>
              <FormMessage /> {/* exibe erro automático */}
            </FormItem>
          )}
        />

        <FormField
          control={form.control}
          name="email"
          render={({ field }) => (
            <FormItem>
              <FormLabel>E-mail</FormLabel>
              <FormControl>
                <Input type="email" placeholder="seu@email.com" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <Button type="submit" disabled={form.formState.isSubmitting}>
          {form.formState.isSubmitting ? 'Salvando...' : 'Salvar'}
        </Button>
      </form>
    </Form>
  )
}
```

### Toast com Sonner

```tsx
// Instalar e configurar
// npx shadcn@latest add sonner

import { Toaster } from '@/components/ui/sonner'
import { toast } from 'sonner'

// No layout raiz:
<Toaster position="top-right" richColors />

// Usar em qualquer lugar:
toast.success('Usuário criado com sucesso!')
toast.error('Erro ao salvar. Tente novamente.')
toast.loading('Processando...')
toast.promise(saveUser(), {
  loading: 'Salvando...',
  success: 'Salvo com sucesso!',
  error:   'Erro ao salvar.',
})
```

### DataTable com TanStack Table

```tsx
import {
  flexRender,
  getCoreRowModel,
  getSortedRowModel,
  useReactTable,
} from '@tanstack/react-table'
import {
  Table, TableBody, TableCell,
  TableHead, TableHeader, TableRow,
} from '@/components/ui/table'

const columns: ColumnDef<User>[] = [
  { accessorKey: 'name',  header: 'Nome' },
  { accessorKey: 'email', header: 'E-mail' },
  {
    id: 'actions',
    cell: ({ row }) => (
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <Button variant="ghost" size="sm">⋮</Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent>
          <DropdownMenuItem onClick={() => editUser(row.original)}>
            Editar
          </DropdownMenuItem>
          <DropdownMenuItem className="text-red-500"
            onClick={() => deleteUser(row.original.id)}>
            Excluir
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
    )
  }
]
```

---

## Customizar Tema

```css
/* globals.css — variáveis do tema */
:root {
  --background: 0 0% 100%;
  --foreground: 222.2 47.4% 11.2%;
  --primary: 262 83% 58%;          /* roxo */
  --primary-foreground: 210 40% 98%;
  --muted: 210 40% 96.1%;
  --border: 214.3 31.8% 91.4%;
  --radius: 0.5rem;
}

.dark {
  --background: 224 71% 4%;
  --foreground: 213 31% 91%;
  --primary: 263 70% 50%;
}
```

---

## Referências

→ `references/advanced-components.md` — Command palette, Combobox, Calendar, Sheet, Tabs


---

## Relacionado

[[React 19]] | [[Tailwind CSS v4]] | [[Zod Validacao]]


---

## Referencias

- [[Referencias/extra]]
