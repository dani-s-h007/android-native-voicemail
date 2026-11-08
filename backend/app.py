import os
import gradio as gr
from app.main import app as fastapi_app

# Create a clean Gradio dashboard interface
with gr.Blocks(title="Visual Voicemail Relay Backend") as demo:
    gr.Markdown("# 🎙️ Indian Visual Voicemail — Transient Relay")
    gr.Markdown(
        "Zero-Cloud-Storage Ephemeral Telephony Relay Backend for Indian Telecom Networks.\n\n"
        "### 🔗 Available Endpoints:\n"
        "- **Interactive API Docs (Swagger):** [`/docs`](/docs)\n"
        "- **Health Check:** [`/health`](/health)\n"
        "- **Transient Audio Relay:** `/api/v1/relay/incoming`\n"
        "- **Dynamic DND Greetings:** `/api/v1/dnd/custom-greeting`"
    )
    
    with gr.Row():
        status_box = gr.Textbox(
            value="Online • RAM Storage Active • Zero Cloud Persistence",
            label="Service Status",
            interactive=False
        )

# Mount Gradio onto the existing FastAPI application
# This exposes the Gradio UI at "/" and preserves all FastAPI routes (/docs, /health, /api/v1/...)
app = gr.mount_gradio_app(fastapi_app, demo, path="/")

if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 7860))
    uvicorn.run("app:app", host="0.0.0.0", port=port, reload=False)

