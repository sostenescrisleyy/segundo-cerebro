# GitHub Actions — CI/CD

## Workflow de CI (Node.js)

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:    { branches: [main, develop] }
  pull_request: { branches: [main] }

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '22', cache: 'npm' }
      - run: npm ci
      - run: npm run lint
      - run: npm run type-check
      - run: npm test -- --coverage
```

## Deploy para VPS

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push: { branches: [main] }

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Deploy via SSH
        uses: appleboy/ssh-action@v1
        with:
          host:     ${{ secrets.SERVER_HOST }}
          username: ${{ secrets.SERVER_USER }}
          key:      ${{ secrets.SERVER_SSH_KEY }}
          script: |
            cd /app
            git pull origin main
            docker compose up -d --build
            docker system prune -f
```

## Build e Push Docker

```yaml
- name: Build and push
  uses: docker/build-push-action@v5
  with:
    context: .
    push: true
    tags: |
      usuario/app:latest
      usuario/app:${{ github.sha }}
    cache-from: type=gha
    cache-to:   type=gha,mode=max
```


---

← [[README|Git e GitHub Actions]]
