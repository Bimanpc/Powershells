# Filename: start-llm-webui.ps1

# Ρύθμιση Περιβάλλοντος
$ErrorActionPreference = "Stop"
Write-Host "🔧 Προετοιμασία περιβάλλοντος AI Web Terminal..." -ForegroundColor Cyan

# Φόρτωση του Python Virtual Environment (αν υπάρχει)
$venvPath = ".\venv\Scripts\Activate.ps1"
if (Test-Path $venvPath) {
    Write-Host "✅ Ενεργοποίηση του Python venv..."
    . $venvPath
} else {
    Write-Host "⚠️ Δεν βρέθηκε εικονικό περιβάλλον, παραλείπεται..."
}

# Εκκίνηση τοπικού AI LLM (π.χ. llama.cpp ή Ollama)
Write-Host "🚀 Εκκίνηση LLM backend (llama.cpp ή Ollama)..."
Start-Process -NoNewWindow -FilePath "ollama" -ArgumentList "serve"

Start-Sleep -Seconds 2

# Εκκίνηση του Web Terminal Interface (π.χ. Text Generation WebUI ή Custom Flask Web UI)
Write-Host "🌐 Εκκίνηση Web UI..."
Start-Process -NoNewWindow -FilePath "python" -ArgumentList "app.py"

# Προαιρετικά: Άνοιγμα φυλλομετρητή
Start-Sleep -Seconds 3
Start-Process "http://localhost:5000"

Write-Host "✅ Το Web UI είναι έτοιμο στη διεύθυνση: http://localhost:5000" -ForegroundColor Green
