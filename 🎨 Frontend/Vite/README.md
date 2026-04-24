---
tags: [frontend]
categoria: "🎨 Frontend"
---

# Vite — Build Tool Moderno

**Versão:** Vite 6+  
**Princípio:** Dev server instantâneo com ESM nativo. Build de produção via Rollup. Zero config para casos comuns.

---

## vite.config.ts Completo

```typescript
import { defineConfig, loadEnv } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'node:path'

export default defineConfig(({ command, mode }) => {
  // Carregar variáveis de ambiente do .env
  const env = loadEnv(mode, process.cwd(), '')

  return {
    plugins: [
      react(),
      // VitePWA({ registerType: 'autoUpdate' }),  // PWA
      // svgr(),       // import SVG como componente React
    ],

    // Aliases de caminho
    resolve: {
      alias: {
        '@':          path.resolve(__dirname, 'src'),
        '@components': path.resolve(__dirname, 'src/components'),
        '@hooks':     path.resolve(__dirname, 'src/hooks'),
        '@utils':     path.resolve(__dirname, 'src/utils'),
        '@assets':    path.resolve(__dirname, 'src/assets'),
      },
    },

    // Servidor de desenvolvimento
    server: {
      port: 3000,
      strictPort: true,
      // Proxy para evitar CORS durante dev
      proxy: {
        '/api': {
          target: 'http://localhost:8000',
          changeOrigin: true,
          rewrite: (path) => path.replace(/^\/api/, ''),
        },
        '/ws': {
          target: 'ws://localhost:8000',
          ws: true,
        },
      },
    },

    // Build de produção
    build: {
      outDir: 'dist',
      sourcemap: mode !== 'production',
      // Code splitting manual
      rollupOptions: {
        output: {
          manualChunks: {
            'vendor-react': ['react', 'react-dom', 'react-router-dom'],
            'vendor-ui':    ['@radix-ui/react-dialog', '@radix-ui/react-dropdown-menu'],
            'vendor-query': ['@tanstack/react-query'],
          },
        },
      },
      // Otimizações
      minify: 'esbuild',
      chunkSizeWarningLimit: 1000,
    },

    // Pré-bundle de deps pesadas
    optimizeDeps: {
      include: ['react', 'react-dom', 'react-router-dom'],
    },

    // Variáveis de env disponíveis no código
    define: {
      __APP_VERSION__: JSON.stringify(process.env.npm_package_version),
    },
  }
})
```

---

## Variáveis de Ambiente

```bash
# .env              → todos os ambientes
# .env.local        → local, ignorado pelo git
# .env.development  → só em dev
# .env.production   → só em prod

# Variáveis DEVEM começar com VITE_ para ficar disponíveis no browser
VITE_API_URL=http://localhost:8000
VITE_APP_NAME="Minha App"

# Sem VITE_ = só no Node.js (vite.config.ts), NÃO no código do browser
DATABASE_URL=postgresql://...
SECRET_KEY=...
```

```typescript
// Acessar no código
const apiUrl = import.meta.env.VITE_API_URL
const isProd  = import.meta.env.PROD
const isDev   = import.meta.env.DEV
const mode    = import.meta.env.MODE  // 'development' | 'production'

// TypeScript: tipar as variáveis
// src/vite-env.d.ts
interface ImportMetaEnv {
  readonly VITE_API_URL:   string
  readonly VITE_APP_NAME:  string
}
interface ImportMeta {
  readonly env: ImportMetaEnv
}
```

---

## Library Mode (publicar pacote npm)

```typescript
// vite.config.ts para biblioteca
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import dts from 'vite-plugin-dts'

export default defineConfig({
  plugins: [react(), dts({ include: ['src'] })],
  build: {
    lib: {
      entry:   'src/index.ts',
      name:    'MinhaBiblioteca',
      formats: ['es', 'cjs'],
      fileName: (format) => `index.${format === 'es' ? 'mjs' : 'cjs'}`,
    },
    rollupOptions: {
      // Não incluir no bundle (peer deps)
      external: ['react', 'react-dom'],
      output: {
        globals: { react: 'React', 'react-dom': 'ReactDOM' },
      },
    },
  },
})
```

---

## Plugins Essenciais

```bash
# React com SWC (compilador mais rápido que Babel)
npm install -D @vitejs/plugin-react-swc

# Vue
npm install -D @vitejs/plugin-vue

# Tipos TypeScript automáticos
npm install -D vite-plugin-dts

# SVG como componente React
npm install -D vite-plugin-svgr

# PWA
npm install -D vite-plugin-pwa

# Bundle analyzer
npm install -D rollup-plugin-visualizer
```


---

## Relacionado

[[React 19]] | [[Vue 3 e Nuxt]] | [[TypeScript]]


---

## Referencias

- [[Referencias/extra]]
