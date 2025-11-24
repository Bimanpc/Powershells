<# 
.SYNOPSIS
    AI LLM Photo Sending App (PowerShell .ps1)

.DESCRIPTION
    Sends an image and a prompt to a multimodal LLM endpoint (e.g., OpenAI/Azure OpenAI) 
    and prints the model’s response. Uses data URLs for local files so you don't need to host the image.

.PARAMETER ImagePath
    Path to the local image file (png, jpg, jpeg, webp, gif).

.PARAMETER Prompt
    Instruction or question for the model related to the image.

.PARAMETER ApiKey
    API key for the LLM provider.

.PARAMETER Model
    Model name (e.g., gpt-4o, gpt-4o-mini, gpt-4.1-mini). Adjust to your provider.

.PARAMETER ApiUrl
    Endpoint URL for chat completions with multimodal content.
    Example (OpenAI): https://api.openai.com/v1/chat/completions
    Example (Azure OpenAI): https://{your-resource}.openai.azure.com/openai/deployments/{deployment}/chat/completions?api-version=2024-08-01-preview

.PARAMETER Proxy
    Optional proxy URL if required.

.NOTES
    - Uses JSON content parts: text + image_url (data URL with base64).
    - Prints assistant text response and (if present) reasoning excluded.
    - Safe error handling, no external dependencies.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ImagePath,

    [Parameter(Mandatory=$true)]
    [string]$Prompt,

    [Parameter(Mandatory=$true)]
    [string]$ApiKey,

    [Parameter(Mandatory=$false)]
    [string]$Model = "gpt-4o-mini",

    [Parameter(Mandatory=$false)]
    [string]$ApiUrl = "https://api.openai.com/v1/chat/completions",

    [Parameter(Mandatory=$false)]
    [string]$Proxy
)

function Get-MimeType {
    param([string]$Path)
    $ext = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()
    switch ($ext) {
        ".png"  { return "image/png" }
        ".jpg"  { return "image/jpeg" }
        ".jpeg" { return "image/jpeg" }
        ".webp" { return "image/webp" }
        ".gif"  { return "image/gif" }
        default { throw "Unsupported image type: $ext" }
    }
}

function Get-ImageDataUrl {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { throw "Image not found: $Path" }
    $mime = Get-MimeType -Path $Path
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $b64   = [Convert]::ToBase64String($bytes)
    return "data:$mime;base64,$b64"
}

function Send-ImageToLLM {
    param(
        [string]$ApiUrl,
        [string]$ApiKey,
        [string]$Model,
        [string]$Prompt,
        [string]$ImageDataUrl,
        [string]$Proxy
    )

    # Build messages payload with multimodal content parts (text + image_url)
    $body = @{
        model = $Model
        messages = @(
            @{
                role = "user"
                content = @(
                    @{ type = "text";      text = $Prompt },
                    @{ type = "image_url"; image_url = @{ url = $ImageDataUrl } }
                )
            }
        )
        # You can tune these:
        temperature = 0.2
        top_p = 1
        max_tokens = 800
    } | ConvertTo-Json -Depth 6

    $headers = @{
        "Authorization" = "Bearer $ApiKey"
        "Content-Type"  = "application/json"
    }

    $invokeParams = @{
        Method  = "Post"
        Uri     = $ApiUrl
        Headers = $headers
        Body    = $body
        ErrorAction = "Stop"
    }
    if ($Proxy) { $invokeParams["Proxy"] = $Proxy }

    try {
        $response = Invoke-RestMethod @invokeParams

        # Extract assistant text (handles OpenAI-like schema)
        if ($response.choices -and $response.choices[0].message.content) {
            # content might be an array of parts or a single string
            $assistantContent = $response.choices[0].message.content
            if ($assistantContent -is [System.Array]) {
                # Join text parts if provider returns structured content
                $textParts = @()
                foreach ($part in $assistantContent) {
                    if ($part.type -eq "text" -and $part.text) { $textParts += $part.text }
                }
                if ($textParts.Count -gt 0) {
                    return ($textParts -join "`n")
                }
            }
            # Fallback: just output the content
            return $assistantContent
        }

        # Azure/OpenAI may return 'choices.message.content' as string
        if ($response.choices -and $response.choices[0].message -and $response.choices[0].message.content) {
            return $response.choices[0].message.content
        }

        # If none matched, dump compact JSON
        return ($response | ConvertTo-Json -Depth 6)
    }
    catch {
        Write-Error "LLM request failed: $($_.Exception.Message)"
        if ($_.ErrorDetails.Message) {
            Write-Host "`nDetails:" -ForegroundColor Yellow
            Write-Host ($_.ErrorDetails.Message)
        }
        throw
    }
}

# --- Main ---
try {
    Write-Host "Preparing image..." -ForegroundColor Cyan
    $dataUrl = Get-ImageDataUrl -Path $ImagePath

    Write-Host "Sending to model '$Model'..." -ForegroundColor Cyan
    $result = Send-ImageToLLM -ApiUrl $ApiUrl -ApiKey $ApiKey -Model $Model -Prompt $Prompt -ImageDataUrl $dataUrl -Proxy $Proxy

    Write-Host "`n--- Assistant response ---" -ForegroundColor Green
    if ($result -is [string]) {
        Write-Output $result
    } else {
        $result | ConvertTo-Json -Depth 6 | Write-Output
    }
}
catch {
    Write-Error "Error: $($_.Exception.Message)"
    exit 1
}
