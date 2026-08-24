from fastapi import FastAPI

app = FastAPI(
    title="ModuNexa API",
    description="API inteligente para gestão de marcenarias",
    version="0.1.0",
)

@app.get("/health")
async def health_check() -> dict[str,str]:
    return {"status": "ok"}
