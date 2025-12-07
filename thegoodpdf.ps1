<# 
AI LLM PDF SIGNER APP (.ps1)
Requirements:
- Windows PowerShell 5.1
- itextsharp.dll (5.x) and BouncyCastle.Crypto.dll in the same directory as this script
- A valid PFX (PKCS#12) certificate and its password
- Optional: A signature image (PNG/JPG) for visible signature appearance

LLM assist:
- Provide an endpoint URL (e.g., https://api.openai.com/v1/chat/completions or your local LLM REST)
- Provide API key and a short instruction prompt; it will attempt to fill Reason/Location/Name
- Adjust the payload in Invoke-LLM to fit your endpoint contract (marked clearly below)

Author: Copilot
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Web

# Region: Assembly Loading -----------------------------------------------------
function Load-ExternalAssemblies {
    param(
        [string]$BasePath
    )
    $iTextPath = Join-Path $BasePath 'itextsharp.dll'
    $bcPath    = Join-Path $BasePath 'BouncyCastle.Crypto.dll'

    foreach ($dll in @($bcPath, $iTextPath)) {
        if (-not (Test-Path $dll)) {
            [System.Windows.Forms.MessageBox]::Show("Missing DLL: $dll`nPlace it in the script folder.","Dependency Error",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
            throw "Missing DLL: $dll"
        }
        [Reflection.Assembly]::LoadFrom($dll) | Out-Null
    }
}
try {
    $scriptDir = Split-Path -Parent $PSCommandPath
} catch {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}
Load-ExternalAssemblies -BasePath $scriptDir

# Import namespaces (iTextSharp 5.x and BouncyCastle)
$null = [Reflection.Assembly]::GetAssembly([iTextSharp.text.pdf.PdfReader])
$null = [Reflection.Assembly]::GetAssembly([Org.BouncyCastle.Pkcs.Pkcs12Store])

# Region: Utilities ------------------------------------------------------------
function Safe-FileName([string]$path) {
    if ([string]::IsNullOrWhiteSpace($path)) { return "" }
    return [System.IO.Path]::GetFileName($path)
}

function Show-Error([string]$msg) {
    [System.Windows.Forms.MessageBox]::Show($msg,"Error",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
}

function Show-Info([string]$msg) {
    [System.Windows.Forms.MessageBox]::Show($msg,"Info",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
}

# Region: PDF Signing ----------------------------------------------------------
function Get-CertFromPfx {
    param(
        [Parameter(Mandatory)][string]$PfxPath,
        [Parameter(Mandatory)][string]$Password
    )
    # Load PFX into BouncyCastle store
    $fs = [System.IO.File]::Open($PfxPath,[System.IO.FileMode]::Open,[System.IO.FileAccess]::Read)
    try {
        $store = New-Object Org.BouncyCastle.Pkcs.Pkcs12Store($fs,$Password.ToCharArray())
    } finally {
        $fs.Close()
    }

    # Locate key entry
    $alias = ($store.Aliases | Where-Object { $store.IsKeyEntry($_) }) | Select-Object -First 1
    if (-not $alias) { throw "No private key entry found in PFX." }
    $keyEntry = $store.GetKey($alias)
    $chain    = $store.GetCertificateChain($alias)

    # Convert chain to iTextSharp format
    $itextChain = New-Object System.Collections.Generic.List[iTextSharp.text.pdf.security.X509Certificate]
    foreach ($c in $chain) {
        $itextChain.Add($c.Certificate)
    }

    # Return key + chain
    return [PSCustomObject]@{
        PrivateKey = $keyEntry.Key
        Chain      = $itextChain.ToArray()
        Alias      = $alias
    }
}

function Sign-Pdf {
    param(
        [Parameter(Mandatory)][string]$InputPdf,
        [Parameter(Mandatory)][string]$OutputPdf,
        [Parameter(Mandatory)][string]$PfxPath,
        [Parameter(Mandatory)][string]$Password,
        [string]$SignerName,
        [string]$Reason,
        [string]$Location,
        [string]$ContactInfo,
        [int]$Page = 1,
        [switch]$Visible,
        [int]$X = 36,
        [int]$Y = 36,
        [int]$Width = 200,
        [int]$Height = 50,
        [string]$ImagePath
    )

    if (-not (Test-Path $InputPdf)) { throw "Input PDF not found." }
    if (-not (Test-Path $PfxPath))  { throw "PFX not found." }

    $certObj = Get-CertFromPfx -PfxPath $PfxPath -Password $Password

    # iTextSharp reader and stamper
    $reader = New-Object iTextSharp.text.pdf.PdfReader($InputPdf)
    try {
        $os = New-Object System.IO.FileStream($OutputPdf,[System.IO.FileMode]::Create,[System.IO.FileAccess]::ReadWrite)
        try {
            $stamper = New-Object iTextSharp.text.pdf.PdfStamper($reader,$os,'\0', $true)
            try {
                $appearance = $stamper.SignatureAppearance
                $appearance.Reason   = $Reason
                $appearance.Location = $Location
                $appearance.Contact  = $ContactInfo

                if ($SignerName) { $appearance.SignatureCreator = $SignerName }

                if ($Visible) {
                    # Define a rectangle for the signature appearance
                    $rect = New-Object iTextSharp.text.Rectangle($X,$Y,$X + $Width, $Y + $Height)
                    $appearance.SetVisibleSignature($rect,$Page,"Sig1")

                    if ($ImagePath -and (Test-Path $ImagePath)) {
                        $img = [iTextSharp.text.Image]::GetInstance($ImagePath)
                        $appearance.SignatureGraphic = $img
                        $appearance.RenderingMode = [iTextSharp.text.pdf.PdfSignatureAppearance+RenderingMode]::GRAPHIC_AND_DESCRIPTION
                    } else {
                        $appearance.RenderingMode = [iTextSharp.text.pdf.PdfSignatureAppearance+RenderingMode]::DESCRIPTION
                    }
                }

                # Configure signature (CMS, SHA256)
                $extSig = New-Object iTextSharp.text.pdf.security.PrivateKeySignature($certObj.PrivateKey, "SHA256")
                $standard = New-Object iTextSharp.text.pdf.security.BouncyCastleDigest

                # Create chain array
                $chain = $certObj.Chain

                # Sign (detached PAdES-like)
                [iTextSharp.text.pdf.security.MakeSignature]::SignDetached(
                    $appearance,
                    $standard,
                    $extSig,
                    $chain,
                    $null, # CRL
                    $null, # OCSP
                    $null, # TSA
                    0,
                    [iTextSharp.text.pdf.security.CryptoStandard]::CMS
                )
            } finally {
                $stamper.Close()
            }
        } finally {
            $os.Close()
        }
    } finally {
        $reader.Close()
    }
}

# Region: LLM Assist -----------------------------------------------------------
function Invoke-LLM {
    param(
        [Parameter(Mandatory)][string]$EndpointUrl,
        [Parameter(Mandatory)][string]$ApiKey,
        [Parameter(Mandatory)][string]$Prompt,
        [string]$ContextJson
    )
    try {
        # NOTE: Adjust payload to match your LLM endpoint contract.
        # Example payload for OpenAI Chat Completions-like API (simplified).
        $body = @{
            model = "gpt-4o-mini"        # <-- change to your model
            messages = @(
                @{ role = "system"; content = "You suggest concise signature metadata (name, reason, location, contact) for a PDF signing operation." },
                @{ role = "user"; content = $Prompt },
                @{ role = "user"; content = "Context: " + ($ContextJson ?? "{}") }
            )
            temperature = 0.2
        } | ConvertTo-Json -Depth 6

        $headers = @{
            "Authorization" = "Bearer $ApiKey"
            "Content-Type"  = "application/json"
        }

        $resp = Invoke-RestMethod -Uri $EndpointUrl -Method POST -Headers $headers -Body $body -TimeoutSec 30

        # Parse generic response text
        $text = $null
        if ($resp.choices && $resp.choices[0].message.content) {
            $text = $resp.choices[0].message.content
        } elseif ($resp.output) {
            $text = $resp.output
        } else {
            $text = ($resp | ConvertTo-Json -Depth 6)
        }

        # Attempt to parse key-value suggestions from the text
        # Expecting lines like:
        # Name: John Doe
        # Reason: Approval of contract
        # Location: Athens, GR
        # Contact: john@example.com
        $result = @{
            Name    = ""
            Reason  = ""
            Location= ""
            Contact = ""
        }
        foreach ($line in ($text -split "`r?`n")) {
            if ($line -match "^\s*Name\s*:\s*(.+)$")     { $result.Name     = $Matches[1].Trim() }
            elseif ($line -match "^\s*Reason\s*:\s*(.+)$"){ $result.Reason   = $Matches[1].Trim() }
            elseif ($line -match "^\s*Location\s*:\s*(.+)$"){ $result.Location = $Matches[1].Trim() }
            elseif ($line -match "^\s*Contact\s*:\s*(.+)$"){ $result.Contact  = $Matches[1].Trim() }
        }

        return $result
    } catch {
        Show-Error "LLM request failed: $($_.Exception.Message)"
        return $null
    }
}

# Region: GUI -----------------------------------------------------------------
$form                 = New-Object System.Windows.Forms.Form
$form.Text            = "AI LLM PDF Signer"
$form.Size            = New-Object System.Drawing.Size(820, 640)
$form.StartPosition   = "CenterScreen"
$form.TopMost         = $false

# Panels
$panel = New-Object System.Windows.Forms.Panel
$panel.Dock = "Fill"
$form.Controls.Add($panel)

# Labels & Inputs
function New-Label($text,$x,$y){ $l=New-Object System.Windows.Forms.Label; $l.Text=$text; $l.Location=New-Object System.Drawing.Point($x,$y); $l.AutoSize=$true; return $l }
function New-Text($x,$y,$w=480){ $t=New-Object System.Windows.Forms.TextBox; $t.Location=New-Object System.Drawing.Point($x,$y); $t.Size=New-Object System.Drawing.Size($w,22); return $t }
function New-Button($text,$x,$y,$w=120){ $b=New-Object System.Windows.Forms.Button; $b.Text=$text; $b.Location=New-Object System.Drawing.Point($x,$y); $b.Size=New-Object System.Drawing.Size($w,28); return $b }
function New-Checkbox($text,$x,$y){ $c=New-Object System.Windows.Forms.CheckBox; $c.Text=$text; $c.Location=New-Object System.Drawing.Point($x,$y); $c.AutoSize=$true; return $c }
function New-Numeric($x,$y,$min=1,$max=9999,$val=1){ $n=New-Object System.Windows.Forms.NumericUpDown; $n.Location=New-Object System.Drawing.Point($x,$y); $n.Minimum=$min; $n.Maximum=$max; $n.Value=$val; $n.Size=New-Object System.Drawing.Size(80,22); return $n }

# File pickers
$dlgOpenPdf = New-Object System.Windows.Forms.OpenFileDialog
$dlgOpenPdf.Filter = "PDF files (*.pdf)|*.pdf"
$dlgOpenPfx = New-Object System.Windows.Forms.OpenFileDialog
$dlgOpenPfx.Filter = "PFX files (*.pfx)|*.pfx"
$dlgSavePdf = New-Object System.Windows.Forms.SaveFileDialog
$dlgSavePdf.Filter = "PDF files (*.pdf)|*.pdf"
$dlgOpenImg = New-Object System.Windows.Forms.OpenFileDialog
$dlgOpenImg.Filter = "Image files (*.png;*.jpg)|*.png;*.jpg"

# Row Y positions
$y = 20
$gap = 34

# PDF
$panel.Controls.Add((New-Label "Input PDF:" 20 $y))
$txtPdf = New-Text 140 $y
$panel.Controls.Add($txtPdf)
$btnPdf = New-Button "Browse..." 640 $y
$btnPdf.Add_Click({
    if ($dlgOpenPdf.ShowDialog() -eq "OK") { $txtPdf.Text = $dlgOpenPdf.FileName }
})
$panel.Controls.Add($btnPdf)
$y += $gap

# PFX
$panel.Controls.Add((New-Label "PFX certificate:" 20 $y))
$txtPfx = New-Text 140 $y
$panel.Controls.Add($txtPfx)
$btnPfx = New-Button "Browse..." 640 $y
$btnPfx.Add_Click({
    if ($dlgOpenPfx.ShowDialog() -eq "OK") { $txtPfx.Text = $dlgOpenPfx.FileName }
})
$panel.Controls.Add($btnPfx)
$y += $gap

# Password
$panel.Controls.Add((New-Label "PFX password:" 20 $y))
$txtPass = New-Object System.Windows.Forms.TextBox
$txtPass.Location = New-Object System.Drawing.Point(140,$y)
$txtPass.Size     = New-Object System.Drawing.Size(480,22)
$txtPass.UseSystemPasswordChar = $true
$panel.Controls.Add($txtPass)
$y += $gap

# Output
$panel.Controls.Add((New-Label "Output PDF:" 20 $y))
$txtOut = New-Text 140 $y
$panel.Controls.Add($txtOut)
$btnOut = New-Button "Choose..." 640 $y
$btnOut.Add_Click({
    $dlgSavePdf.FileName = ("signed_" + Safe-FileName($txtPdf.Text))
    if ($dlgSavePdf.ShowDialog() -eq "OK") { $txtOut.Text = $dlgSavePdf.FileName }
})
$panel.Controls.Add($btnOut)
$y += $gap

# Metadata
$panel.Controls.Add((New-Label "Signer name:" 20 $y))
$txtName = New-Text 140 $y
$panel.Controls.Add($txtName)
$y += $gap

$panel.Controls.Add((New-Label "Reason:" 20 $y))
$txtReason = New-Text 140 $y
$panel.Controls.Add($txtReason)
$y += $gap

$panel.Controls.Add((New-Label "Location:" 20 $y))
$txtLocation = New-Text 140 $y
$panel.Controls.Add($txtLocation)
$y += $gap

$panel.Controls.Add((New-Label "Contact info:" 20 $y))
$txtContact = New-Text 140 $y
$panel.Controls.Add($txtContact)
$y += $gap

# Visible signature controls
$chkVisible = New-Checkbox "Visible signature" 20 $y
$panel.Controls.Add($chkVisible)

$panel.Controls.Add((New-Label "Page:" 160 $y))
$numPage = New-Numeric 200 $y 1 9999 1
$panel.Controls.Add($numPage)

$panel.Controls.Add((New-Label "X:" 300 $y))
$numX = New-Numeric 330 $y 0 2000 36
$panel.Controls.Add($numX)
$panel.Controls.Add((New-Label "Y:" 420 $y))
$numY = New-Numeric 450 $y 0 2000 36
$panel.Controls.Add($numY)
$panel.Controls.Add((New-Label "Width:" 540 $y))
$numW = New-Numeric 590 $y 10 2000 200
$panel.Controls.Add($numW)
$panel.Controls.Add((New-Label "Height:" 680 $y))
$numH = New-Numeric 730 $y 10 2000 50
$panel.Controls.Add($numH)
$y += $gap

$panel.Controls.Add((New-Label "Signature image:" 20 $y))
$txtImg = New-Text 140 $y
$panel.Controls.Add($txtImg)
$btnImg = New-Button "Browse..." 640 $y
$btnImg.Add_Click({
    if ($dlgOpenImg.ShowDialog() -eq "OK") { $txtImg.Text = $dlgOpenImg.FileName }
})
$panel.Controls.Add($btnImg)
$y += $gap

# LLM assist
$panel.Controls.Add((New-Label "LLM endpoint URL:" 20 $y))
$txtLLMUrl = New-Text 140 $y
$txtLLMUrl.Text = "" # e.g., https://api.openai.com/v1/chat/completions
$panel.Controls.Add($txtLLMUrl)
$y += $gap

$panel.Controls.Add((New-Label "LLM API key:" 20 $y))
$txtLLMKey = New-Text 140 $y
$txtLLMKey.UseSystemPasswordChar = $true
$panel.Controls.Add($txtLLMKey)
$y += $gap

$panel.Controls.Add((New-Label "LLM prompt:" 20 $y))
$txtLLMPrompt = New-Object System.Windows.Forms.TextBox
$txtLLMPrompt.Location = New-Object System.Drawing.Point(140,$y)
$txtLLMPrompt.Size     = New-Object System.Drawing.Size(480,60)
$txtLLMPrompt.Multiline = $true
$txtLLMPrompt.Text = "Suggest concise Reason, Location, and Name for signing this document."
$panel.Controls.Add($txtLLMPrompt)
$btnLLM = New-Button "Assist (Fill)" 640 ($y+16)
$btnLLM.Add_Click({
    $url = $txtLLMUrl.Text.Trim()
    $key = $txtLLMKey.Text.Trim()
    $prompt = $txtLLMPrompt.Text.Trim()

    if ([string]::IsNullOrWhiteSpace($url) -or [string]::IsNullOrWhiteSpace($key) -or [string]::IsNullOrWhiteSpace($prompt)) {
        Show-Error "Provide LLM URL, API key, and prompt."
        return
    }

    $context = @{
        pdf     = Safe-FileName($txtPdf.Text)
        signer  = $txtName.Text
        reason  = $txtReason.Text
        location= $txtLocation.Text
        contact = $txtContact.Text
    } | ConvertTo-Json -Depth 3

    $res = Invoke-LLM -EndpointUrl $url -ApiKey $key -Prompt $prompt -ContextJson $context
    if ($res) {
        if ($res.Name)     { $txtName.Text     = $res.Name }
        if ($res.Reason)   { $txtReason.Text   = $res.Reason }
        if ($res.Location) { $txtLocation.Text = $res.Location }
        if ($res.Contact)  { $txtContact.Text  = $res.Contact }
        Show-Info "LLM suggestions applied."
    }
})
$panel.Controls.Add($btnLLM)
$y += ($gap + 40)

# Sign button
$btnSign = New-Button "Sign PDF" 20 $y 200
$btnSign.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
$btnSign.Add_Click({
    try {
        $inPdf  = $txtPdf.Text.Trim()
        $outPdf = $txtOut.Text.Trim()
        $pfx    = $txtPfx.Text.Trim()
        $pwd    = $txtPass.Text

        if ([string]::IsNullOrWhiteSpace($inPdf) -or -not (Test-Path $inPdf)) { Show-Error "Select an input PDF."; return }
        if ([string]::IsNullOrWhiteSpace($pfx) -or -not (Test-Path $pfx))     { Show-Error "Select a PFX certificate."; return }
        if ([string]::IsNullOrWhiteSpace($pwd))                                { Show-Error "Enter the PFX password."; return }
        if ([string]::IsNullOrWhiteSpace($outPdf))                              { 
            $outPdf = Join-Path (Split-Path $inPdf -Parent) ("signed_" + Safe-FileName($inPdf))
            $txtOut.Text = $outPdf
        }

        Sign-Pdf -InputPdf $inPdf -OutputPdf $outPdf -PfxPath $pfx -Password $pwd `
            -SignerName $txtName.Text.Trim() -Reason $txtReason.Text.Trim() -Location $txtLocation.Text.Trim() -ContactInfo $txtContact.Text.Trim() `
            -Page ([int]$numPage.Value) -Visible:$chkVisible.Checked `
            -X ([int]$numX.Value) -Y ([int]$numY.Value) -Width ([int]$numW.Value) -Height ([int]$numH.Value) `
            -ImagePath $txtImg.Text.Trim()

        Show-Info "Signed successfully: `n$outPdf"
    } catch {
        Show-Error "Signing failed: $($_.Exception.Message)"
    }
})
$panel.Controls.Add($btnSign)

# Status strip
$status = New-Object System.Windows.Forms.StatusStrip
$lblStatus = New-Object System.Windows.Forms.ToolStripStatusLabel
$lblStatus.Text = "Ready."
$status.Items.Add($lblStatus) | Out-Null
$form.Controls.Add($status)

# Run
[void]$form.ShowDialog()
