---
tags: [backend]
categoria: "⚙️ Backend"
---

# FastAPI — APIs Python Modernas

**Versão:** FastAPI 0.115+ | Python 3.12+  
**Princípio:** Type hints são tudo. Pydantic valida automaticamente. async/await para I/O.

---

## Setup e Estrutura

```bash
pip install fastapi uvicorn[standard] pydantic[email] python-jose[cryptography] bcrypt sqlalchemy alembic
```

```
app/
├── main.py           ← instância FastAPI + routers
├── routers/
│   ├── users.py
│   └── auth.py
├── models/           ← SQLAlchemy models
├── schemas/          ← Pydantic schemas
├── services/         ← lógica de negócio
├── dependencies.py   ← deps reutilizáveis
└── config.py         ← configurações com Pydantic Settings
```

---

## App Principal

```python
# main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from app.routers import users, auth
from app.database import init_db

@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()       # startup
    yield
    # teardown aqui se necessário

app = FastAPI(
    title="Minha API",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_methods=["*"],
    allow_headers=["*"],
    allow_credentials=True,
)

app.include_router(auth.router,  prefix="/api/auth",  tags=["auth"])
app.include_router(users.router, prefix="/api/users", tags=["users"])

@app.get("/health")
async def health(): return {"status": "ok"}
```

---

## Schemas Pydantic

```python
# schemas/user.py
from pydantic import BaseModel, EmailStr, field_validator
from datetime import datetime
from typing import Optional

class UserBase(BaseModel):
    name:  str
    email: EmailStr

class UserCreate(UserBase):
    password: str

    @field_validator('password')
    @classmethod
    def validate_password(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError('Mínimo 8 caracteres')
        return v

class UserUpdate(BaseModel):
    name:  Optional[str] = None
    email: Optional[EmailStr] = None

class UserResponse(UserBase):
    id:         int
    role:       str
    created_at: datetime

    model_config = {"from_attributes": True}  # permite criar de ORM
```

---

## Router com CRUD

```python
# routers/users.py
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas.user import UserCreate, UserResponse, UserUpdate
from app.dependencies import get_current_user
from app import services

router = APIRouter()

@router.get("/", response_model=list[UserResponse])
async def list_users(
    skip:   int = Query(0, ge=0),
    limit:  int = Query(20, ge=1, le=100),
    search: str | None = None,
    db:     AsyncSession = Depends(get_db),
    current_user = Depends(get_current_user),
):
    return await services.users.list(db, skip=skip, limit=limit, search=search)

@router.post("/", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(
    body: UserCreate,
    db:   AsyncSession = Depends(get_db),
):
    existing = await services.users.get_by_email(db, body.email)
    if existing:
        raise HTTPException(status.HTTP_409_CONFLICT, "E-mail já cadastrado")
    return await services.users.create(db, body)

@router.get("/{user_id}", response_model=UserResponse)
async def get_user(user_id: int, db: AsyncSession = Depends(get_db)):
    user = await services.users.get(db, user_id)
    if not user:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Usuário não encontrado")
    return user

@router.patch("/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: int,
    body:    UserUpdate,
    db:      AsyncSession = Depends(get_db),
    current  = Depends(get_current_user),
):
    if current.id != user_id and current.role != "admin":
        raise HTTPException(status.HTTP_403_FORBIDDEN)
    return await services.users.update(db, user_id, body)
```

---

## Autenticação JWT

```python
# dependencies.py
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from app.config import settings

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/token")

async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db:    AsyncSession = Depends(get_db),
):
    credentials_error = HTTPException(
        status.HTTP_401_UNAUTHORIZED,
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.JWT_SECRET, algorithms=["HS256"])
        user_id: int = payload.get("sub")
        if user_id is None: raise credentials_error
    except JWTError:
        raise credentials_error

    user = await services.users.get(db, user_id)
    if not user: raise credentials_error
    return user
```

---

## Background Tasks

```python
from fastapi import BackgroundTasks

@router.post("/users/")
async def create_user(
    body: UserCreate,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
):
    user = await services.users.create(db, body)
    background_tasks.add_task(send_welcome_email, user.email, user.name)
    return user

async def send_welcome_email(email: str, name: str):
    # executa em background sem bloquear a resposta
    await email_service.send(to=email, template="welcome", data={"name": name})
```

---

## Configuração com Pydantic Settings

```python
# config.py
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    DATABASE_URL: str
    JWT_SECRET:   str
    JWT_EXPIRE:   int = 30
    REDIS_URL:    str | None = None
    DEBUG:        bool = False

    model_config = {"env_file": ".env"}

settings = Settings()

# Iniciar: uvicorn app.main:app --reload --port 8000
```

---

## Referências

→ `references/sqlalchemy-async.md` — SQLAlchemy async, modelos, queries, Alembic migrations


---

## Relacionado

[[PostgreSQL]] | [[Docker e Compose]] | [[Multi Agentes]]


---

## Referencias

- [[Referencias/extra]]
