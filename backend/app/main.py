import asyncio
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings
from app.routers import auth, transient_relay, dnd
from app.services.janitor import run_janitor_loop

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Start ephemeral storage janitor daemon on startup
    janitor_task = asyncio.create_task(run_janitor_loop())
    yield
    # Cancel janitor task on shutdown
    janitor_task.cancel()
    try:
        await janitor_task
    except asyncio.CancelledError:
        pass

app = FastAPI(
    title="Corporate Voicemail Transient Relay",
    version="2.0.0",
    description="Zero-Cloud-Storage Ephemeral Telephony Relay Backend for Indian Telecom Networks",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(transient_relay.router)
app.include_router(dnd.router)
app.include_router(auth.router)

@app.get("/health")
@app.get("/api/v1/health")
async def health_check():
    return {
        "status": "healthy",
        "service": "corporate-voicemail-transient-relay",
        "storage": "volatile-tmpfs-ram-only",
        "cloudPersistence": False
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
