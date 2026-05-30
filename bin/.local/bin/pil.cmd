<# : batch portion
Windows install:
  1. Copy this file to a folder on PATH.
  2. Rename or keep it as: pil.cmd
  3. Open a new terminal.
  4. Run: pil setup

Run:
  - If this file is on PATH: pil
  - If this file is in the current folder: .\pil.cmd
  - Help: pil --help
#>
@echo off
setlocal
set "POWERSHELL_EXE="
where pwsh >nul 2>nul && set "POWERSHELL_EXE=pwsh"
if not defined POWERSHELL_EXE where powershell >nul 2>nul && set "POWERSHELL_EXE=powershell"
if not defined POWERSHELL_EXE (
  echo error: PowerShell not found on PATH 1>&2
  echo install PowerShell 7 ^(pwsh^) or run from Windows PowerShell. 1>&2
  echo then run pil or .\pil.cmd 1>&2
  exit /b 127
)
"%POWERSHELL_EXE%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~f0" %*
exit /b %ERRORLEVEL%
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Show-Usage {
    @'
Usage:
  pil setup
  pil init [--provider NAME] --base-url URL [--model MODEL] [--scoped-models LIST]
  pil add --key KEY [--local | --global | --path PATH]
  pil key add KEY
  pil project use KEY
  pil config show [--json]
  pil doctor [--json]
  pil sync
  pil --key KEY_NAME
  pil [pi args...]

How to run on Windows:
  1. Put pil.cmd in a folder on PATH.
  2. Open a new Command Prompt, PowerShell, or Windows Terminal.
  3. Run: pil setup
  4. Later run: pil

If it is not on PATH yet:
  - from Command Prompt: .\pil.cmd
  - from PowerShell: .\pil.cmd

Windows notes:
  - config: %APPDATA%\pil\config
  - key list: %APPDATA%\pil\keys
  - secrets: %APPDATA%\pil\secrets\<key>.txt (DPAPI user-scoped)
  - project overrides: .pil and .pi\settings.json
'@ | Write-Host
}

function Write-Section([string]$Title) {
    Write-Host ""
    Write-Host $Title
}

function Write-Kv([string]$Key, [string]$Value) {
    Write-Host ('  {0,-8} {1}' -f $Key, $Value)
}

function Fail([string]$Message, [int]$Code = 1) {
    Write-Error $Message
    exit $Code
}

function Need-Arg([string]$Flag, $Value) {
    if ([string]::IsNullOrWhiteSpace([string]$Value)) {
        Fail "$Flag needs a value" 2
    }
}

function Get-PilRoot {
    Join-Path $env:APPDATA 'pil'
}

function Get-PilConfigPath {
    Join-Path (Get-PilRoot) 'config'
}

function Get-PilKeysPath {
    Join-Path (Get-PilRoot) 'keys'
}

function Get-PilSecretsDir {
    Join-Path (Get-PilRoot) 'secrets'
}

function Get-ModelsJsonPath {
    $piDir = if ($env:PI_CODING_AGENT_DIR) { $env:PI_CODING_AGENT_DIR } else { Join-Path $HOME '.pi\agent' }
    Join-Path $piDir 'models.json'
}

function Get-ProjectConfigFile {
    $dir = (Get-Location).Path
    $homePath = [IO.Path]::GetFullPath($HOME)
    while ($true) {
        if ([IO.Path]::GetFullPath($dir) -eq $homePath) {
            return $null
        }
        $candidate = Join-Path $dir '.pil'
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return $candidate
        }
        $parent = Split-Path -Path $dir -Parent
        if ($parent -eq $dir -or [string]::IsNullOrEmpty($parent)) {
            return $null
        }
        $dir = $parent
    }
}

function Quote-ConfigValue([string]$Value) {
    if ($null -eq $Value) {
        return "''"
    }
    return "'" + ($Value -replace "'", "'\\''") + "'"
}

function Parse-ConfigValue([string]$Value) {
    $trimmed = $Value.Trim()
    if ($trimmed.Length -ge 2 -and $trimmed.StartsWith("'") -and $trimmed.EndsWith("'")) {
        return $trimmed.Substring(1, $trimmed.Length - 2) -replace "'\\''", "'"
    }
    if ($trimmed.Length -ge 2 -and $trimmed.StartsWith('"') -and $trimmed.EndsWith('"')) {
        return $trimmed.Substring(1, $trimmed.Length - 2)
    }
    return $trimmed
}

function Set-ConfigValue($Config, [string]$Key, [string]$Value, [bool]$AllowProjectKey) {
    switch ($Key) {
        'PIL_PROVIDER' { $Config.PIL_PROVIDER = $Value }
        'PIL_BASE_URL' { $Config.PIL_BASE_URL = $Value }
        'PIL_KEY_NAME' { if ($AllowProjectKey) { $Config.PIL_KEY_NAME = $Value } }
        'PIL_MODEL' { $Config.PIL_MODEL = $Value }
        'PIL_MODELS' { $Config.PIL_MODELS = $Value }
    }
}

function Load-ConfigFile($Config, [string]$Path, [bool]$AllowProjectKey) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return
    }
    foreach ($line in Get-Content -LiteralPath $Path) {
        if ($line -match '^\s*($|#)') {
            continue
        }
        if ($line -notmatch '^\s*(PIL_[A-Z_]+)=(.*)$') {
            Fail "invalid config line in $Path: $line"
        }
        Set-ConfigValue $Config $Matches[1] (Parse-ConfigValue $Matches[2]) $AllowProjectKey
    }
}

function New-DefaultConfig {
    [ordered]@{
        PIL_PROVIDER = if ($env:PIL_PROVIDER) { $env:PIL_PROVIDER } else { 'litellm' }
        PIL_BASE_URL = if ($env:PIL_BASE_URL) { $env:PIL_BASE_URL } else { '' }
        PIL_KEY_NAME = if ($env:PIL_KEY_NAME) { $env:PIL_KEY_NAME } else { '' }
        PIL_MODEL = if ($env:PIL_MODEL) { $env:PIL_MODEL } else { '' }
        PIL_MODELS = if ($env:PIL_MODELS) { $env:PIL_MODELS } else { '' }
    }
}

function Load-Config {
    $config = New-DefaultConfig
    Load-ConfigFile $config (Get-PilConfigPath) $false
    Load-ConfigFile $config (Join-Path $HOME '.pil') $false
    $projectConfig = Get-ProjectConfigFile
    if ($projectConfig) {
        Load-ConfigFile $config $projectConfig $true
    }
    return $config
}

function Ensure-ParentDir([string]$Path) {
    $parent = Split-Path -Path $Path -Parent
    if ($parent) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
}

function Write-Utf8File([string]$Path, [string]$Content) {
    Ensure-ParentDir $Path
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function Write-ConfigFile([string]$Path, $Config, [bool]$IncludeKey) {
    Ensure-ParentDir $Path
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add("PIL_PROVIDER=$(Quote-ConfigValue $Config.PIL_PROVIDER)")
    $lines.Add("PIL_BASE_URL=$(Quote-ConfigValue $Config.PIL_BASE_URL)")
    if ($IncludeKey) {
        $lines.Add("PIL_KEY_NAME=$(Quote-ConfigValue $Config.PIL_KEY_NAME)")
    }
    $lines.Add("PIL_MODEL=$(Quote-ConfigValue $Config.PIL_MODEL)")
    $lines.Add("PIL_MODELS=$(Quote-ConfigValue $Config.PIL_MODELS)")
    Write-Utf8File $Path (($lines -join [Environment]::NewLine) + [Environment]::NewLine)
    Write-Section 'Wrote pil config'
    Write-Kv 'file' $Path
}

function Validate-BaseUrl($Config) {
    if ([string]::IsNullOrWhiteSpace($Config.PIL_BASE_URL)) {
        Fail 'set PIL_BASE_URL or pass --base-url'
    }
    if ($Config.PIL_BASE_URL -notmatch '^https?://\S+$') {
        Fail 'base URL must start with http:// or https://' 2
    }
    $Config.PIL_BASE_URL = $Config.PIL_BASE_URL.TrimEnd('/')
}

function Get-ScopedModels($Config) {
    if ([string]::IsNullOrWhiteSpace($Config.PIL_MODELS)) {
        return @()
    }
    return @($Config.PIL_MODELS.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
}

function Validate-ScopedModels($Config) {
    if ($Config.PIL_MODELS -and (Get-ScopedModels $Config).Count -eq 0) {
        Fail '--scoped-models must contain at least one model' 2
    }
}

function Read-HostDefault([string]$Prompt, [string]$Default) {
    $label = if ($Default) { "${Prompt} [${Default}]" } else { $Prompt }
    $value = Read-Host $label
    if ([string]::IsNullOrWhiteSpace($value)) {
        return $Default
    }
    return $value
}

function Add-GlobalKey([string]$KeyName) {
    $keysPath = Get-PilKeysPath
    Ensure-ParentDir $keysPath
    if (-not (Test-Path -LiteralPath $keysPath)) {
        New-Item -ItemType File -Path $keysPath | Out-Null
    }
    $existing = @()
    if (Test-Path -LiteralPath $keysPath) {
        $existing = @(Get-Content -LiteralPath $keysPath | Where-Object { $_.Trim() })
    }
    if ($existing -contains $KeyName) {
        Write-Section 'Key'
        Write-Kv 'name' $KeyName
        Write-Kv 'status' 'already registered'
        return
    }
    Add-Content -LiteralPath $keysPath -Value $KeyName
    Write-Section 'Key'
    Write-Kv 'name' $KeyName
    Write-Kv 'list' $keysPath
    Write-Kv 'status' 'registered'
}

function Get-SecretFile([string]$KeyName) {
    $safe = ($KeyName -replace '[^A-Za-z0-9._-]', '_')
    Join-Path (Get-PilSecretsDir) ($safe + '.txt')
}

function Store-Key([string]$KeyName, [string]$ApiKey) {
    $secretDir = Get-PilSecretsDir
    New-Item -ItemType Directory -Force -Path $secretDir | Out-Null
    $secure = ConvertTo-SecureString -String $ApiKey -AsPlainText -Force
    $encrypted = ConvertFrom-SecureString -SecureString $secure
    $secretFile = Get-SecretFile $KeyName
    Write-Utf8File $secretFile $encrypted
    Write-Section 'Secret'
    Write-Kv 'name' $KeyName
    Write-Kv 'store' 'Windows DPAPI'
    Write-Kv 'status' 'stored'
}

function Read-Key([string]$KeyName) {
    $secretFile = Get-SecretFile $KeyName
    if (-not (Test-Path -LiteralPath $secretFile -PathType Leaf)) {
        return $null
    }
    $encrypted = Get-Content -LiteralPath $secretFile -Raw
    $secure = ConvertTo-SecureString -String $encrypted
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    }
    finally {
        if ($bstr -ne [IntPtr]::Zero) {
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
        }
    }
}

function Prompt-Secret([string]$KeyName) {
    if (-not [Environment]::UserInteractive) {
        return
    }
    $existing = Read-Key $KeyName
    if ($existing) {
        Write-Section 'Secret'
        Write-Kv 'name' $KeyName
        Write-Kv 'status' 'exists'
        $overwrite = Read-Host 'Overwrite [y/N]'
        if ($overwrite -notmatch '^(y|yes)$') {
            return
        }
    }
    $secure = Read-Host 'Paste API key, or press Enter to skip' -AsSecureString
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        $plain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    }
    finally {
        if ($ptr -ne [IntPtr]::Zero) {
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
        }
    }
    if ([string]::IsNullOrEmpty($plain)) {
        return
    }
    Store-Key $KeyName $plain
}

function Select-Key {
    $keysPath = Get-PilKeysPath
    if (-not (Test-Path -LiteralPath $keysPath -PathType Leaf)) {
        Fail "add key names to $keysPath"
    }
    $keys = @(Get-Content -LiteralPath $keysPath | Where-Object { $_.Trim() })
    if ($keys.Count -eq 0) {
        Fail "no keys found in $keysPath"
    }
    Write-Section 'LiteLLM key'
    for ($i = 0; $i -lt $keys.Count; $i++) {
        Write-Host ('  {0}) {1}' -f ($i + 1), $keys[$i])
    }
    $choice = Read-Host ("Select key [1-{0}]" -f $keys.Count)
    if ([string]::IsNullOrWhiteSpace($choice)) {
        return $keys[0]
    }
    $index = 0
    if (-not [int]::TryParse($choice, [ref]$index) -or $index -lt 1 -or $index -gt $keys.Count) {
        Fail 'invalid key selection'
    }
    return $keys[$index - 1]
}

function Resolve-UserPath([string]$PathValue) {
    $expanded = [Environment]::ExpandEnvironmentVariables($PathValue)
    if ($expanded.StartsWith('~')) {
        $expanded = Join-Path $HOME $expanded.Substring(1).TrimStart('\\', '/')
    }
    if ([IO.Path]::IsPathRooted($expanded)) {
        return $expanded
    }
    return (Join-Path (Get-Location).Path $expanded)
}

function Get-TargetPilFile([string]$Target) {
    if ([string]::IsNullOrWhiteSpace($Target)) {
        return (Join-Path (Get-Location).Path '.pil')
    }
    $expanded = Resolve-UserPath $Target
    if ([IO.Path]::GetFileName($expanded) -eq '.pil') {
        return $expanded
    }
    return (Join-Path $expanded '.pil')
}

function ConvertTo-Hashtable($Value) {
    if ($null -eq $Value) {
        return $null
    }
    if ($Value -is [System.Collections.IDictionary]) {
        $table = @{}
        foreach ($key in $Value.Keys) {
            $table[$key] = ConvertTo-Hashtable $Value[$key]
        }
        return $table
    }
    if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
        $items = New-Object System.Collections.ArrayList
        foreach ($item in $Value) {
            [void]$items.Add((ConvertTo-Hashtable $item))
        }
        return ,$items.ToArray()
    }
    if ($Value.PSObject -and $Value.PSObject.Properties.Count -gt 0) {
        $table = @{}
        foreach ($property in $Value.PSObject.Properties) {
            $table[$property.Name] = ConvertTo-Hashtable $property.Value
        }
        return $table
    }
    return $Value
}

function Get-JsonObject([string]$Path, [string]$FallbackJson) {
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        return (ConvertTo-Hashtable (Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json))
    }
    return (ConvertTo-Hashtable ($FallbackJson | ConvertFrom-Json))
}

function Write-JsonFile([string]$Path, $Object) {
    $json = $Object | ConvertTo-Json -Depth 20
    Write-Utf8File $Path ($json + [Environment]::NewLine)
}

function Ensure-Provider($Config) {
    $modelsPath = Get-ModelsJsonPath
    $doc = Get-JsonObject $modelsPath '{"providers":{}}'
    if (-not $doc.ContainsKey('providers')) {
        $doc['providers'] = @{}
    }
    if (-not $doc['providers'].ContainsKey($Config.PIL_PROVIDER)) {
        $doc['providers'][$Config.PIL_PROVIDER] = @{}
    }
    $provider = $doc['providers'][$Config.PIL_PROVIDER]
    $provider['baseUrl'] = $Config.PIL_BASE_URL.TrimEnd('/')
    if (-not $provider.ContainsKey('api')) {
        $provider['api'] = 'openai-completions'
    }
    $provider['apiKey'] = 'PIL_GATE'
    if (-not $provider.ContainsKey('models')) {
        $provider['models'] = @()
    }
    Write-JsonFile $modelsPath $doc
    Write-Section 'Updated pi provider config'
    Write-Kv 'provider' $Config.PIL_PROVIDER
    Write-Kv 'file' $modelsPath
}

function Write-ProjectPiSettings([string]$ProjectDir, $Config) {
    $settingsPath = Join-Path $ProjectDir '.pi\settings.json'
    $settings = Get-JsonObject $settingsPath '{}'
    $settings['defaultProvider'] = $Config.PIL_PROVIDER
    if (-not [string]::IsNullOrWhiteSpace($Config.PIL_MODEL)) {
        $settings['defaultModel'] = $Config.PIL_MODEL
    }
    $scoped = Get-ScopedModels $Config
    if ($scoped.Count -gt 0) {
        $settings['enabledModels'] = @($scoped)
    }
    else {
        $settings['enabledModels'] = @("$($Config.PIL_PROVIDER)/*")
    }
    Write-JsonFile $settingsPath $settings
    Write-Section 'Wrote pi project settings'
    Write-Kv 'file' $settingsPath
}

function Sync-Models($Config, [string]$ApiKey) {
    $headers = @{ Authorization = "Bearer $ApiKey" }
    $response = Invoke-RestMethod -Method Get -Headers $headers -Uri ($Config.PIL_BASE_URL.TrimEnd('/') + '/models')
    $ids = @()
    if ($response.data) {
        $ids = @($response.data | ForEach-Object { $_.id } | Where-Object { $_ } | Sort-Object -Unique)
    }
    elseif ($response -is [System.Collections.IEnumerable]) {
        $ids = @($response | ForEach-Object { if ($_ -is [string]) { $_ } else { $_.id } } | Where-Object { $_ } | Sort-Object -Unique)
    }
    if ($ids.Count -eq 0) {
        Fail 'no models returned'
    }

    $modelsPath = Get-ModelsJsonPath
    $doc = Get-JsonObject $modelsPath '{"providers":{}}'
    if (-not $doc.ContainsKey('providers')) {
        $doc['providers'] = @{}
    }
    if (-not $doc['providers'].ContainsKey($Config.PIL_PROVIDER)) {
        $doc['providers'][$Config.PIL_PROVIDER] = @{}
    }
    $provider = $doc['providers'][$Config.PIL_PROVIDER]
    $provider['baseUrl'] = $Config.PIL_BASE_URL.TrimEnd('/')
    if (-not $provider.ContainsKey('api')) {
        $provider['api'] = 'openai-completions'
    }
    $provider['apiKey'] = 'PIL_GATE'
    $existing = @{}
    foreach ($entry in @($provider['models'])) {
        if ($entry -is [hashtable] -and $entry['id']) {
            $existing[$entry['id']] = $entry
        }
    }
    $provider['models'] = @($ids | ForEach-Object {
        if ($existing.ContainsKey($_)) { $existing[$_] } else { @{ id = $_; name = $_ } }
    })
    Write-JsonFile $modelsPath $doc
    Write-Section 'Synced models'
    Write-Kv 'count' ([string]$ids.Count)
    Write-Kv 'file' $modelsPath
}

function Command-Init([string[]]$Args, $Config) {
    for ($i = 0; $i -lt $Args.Count; $i++) {
        switch ($Args[$i]) {
            '--provider' { Need-Arg '--provider' $Args[$i + 1]; $Config.PIL_PROVIDER = $Args[++$i] }
            '--base-url' { Need-Arg '--base-url' $Args[$i + 1]; $Config.PIL_BASE_URL = $Args[++$i] }
            '--model' { Need-Arg '--model' $Args[$i + 1]; $Config.PIL_MODEL = $Args[++$i] }
            '--scoped-models' { Need-Arg '--scoped-models' $Args[$i + 1]; $Config.PIL_MODELS = $Args[++$i] }
            '-h' { Show-Usage; exit 0 }
            '--help' { Show-Usage; exit 0 }
            default { Fail "unknown pil init option: $($Args[$i])" 2 }
        }
    }

    $Config.PIL_PROVIDER = Read-HostDefault 'Provider name' $Config.PIL_PROVIDER
    $Config.PIL_BASE_URL = Read-HostDefault 'LiteLLM base URL' $Config.PIL_BASE_URL
    $Config.PIL_MODEL = Read-HostDefault 'Default model' $Config.PIL_MODEL
    $Config.PIL_MODELS = Read-HostDefault 'Scoped models for Ctrl+P' $Config.PIL_MODELS

    Validate-BaseUrl $Config
    Validate-ScopedModels $Config
    Write-ConfigFile (Get-PilConfigPath) $Config $false
    Ensure-Provider $Config

    $keyName = Read-HostDefault 'Add a secret item name to %APPDATA%\pil\keys (optional)' ''
    if ($keyName) {
        Add-GlobalKey $keyName
        Prompt-Secret $keyName
    }
}

function Command-Add([string[]]$Args, $Config) {
    $targetMode = 'ask'
    $targetPath = ''
    $writeGlobal = $false

    for ($i = 0; $i -lt $Args.Count; $i++) {
        switch ($Args[$i]) {
            '--global' { $writeGlobal = $true; $targetMode = 'global' }
            '--local' { $targetMode = 'local' }
            '--path' { Need-Arg '--path' $Args[$i + 1]; $targetPath = $Args[++$i]; $targetMode = 'path' }
            '--provider' { Need-Arg '--provider' $Args[$i + 1]; $Config.PIL_PROVIDER = $Args[++$i] }
            '--base-url' { Need-Arg '--base-url' $Args[$i + 1]; $Config.PIL_BASE_URL = $Args[++$i] }
            '--key' { Need-Arg '--key' $Args[$i + 1]; $Config.PIL_KEY_NAME = $Args[++$i] }
            '--select-key' { $Config.PIL_KEY_NAME = Select-Key }
            '--model' { Need-Arg '--model' $Args[$i + 1]; $Config.PIL_MODEL = $Args[++$i] }
            '--scoped-models' { Need-Arg '--scoped-models' $Args[$i + 1]; $Config.PIL_MODELS = $Args[++$i] }
            '-h' { Show-Usage; exit 0 }
            '--help' { Show-Usage; exit 0 }
            default { Fail "unknown pil add option: $($Args[$i])" 2 }
        }
    }

    if (-not $Config.PIL_KEY_NAME) {
        $typed = Read-HostDefault 'LiteLLM key name' ''
        $Config.PIL_KEY_NAME = if ($typed) { $typed } else { Select-Key }
    }

    if ($writeGlobal) {
        Add-GlobalKey $Config.PIL_KEY_NAME
        Prompt-Secret $Config.PIL_KEY_NAME
        return
    }

    switch ($targetMode) {
        'ask' {
            Write-Section 'Key scope'
            Write-Kv '[1]' ('local   ' + (Get-Location).Path)
            Write-Kv '[2]' 'global  %APPDATA%\pil\keys'
            Write-Kv '[3]' 'path    choose another location'
            $scopeChoice = Read-Host 'Select [1]'
            switch ($scopeChoice) {
                '' { $targetPath = (Get-Location).Path }
                '1' { $targetPath = (Get-Location).Path }
                '2' { Add-GlobalKey $Config.PIL_KEY_NAME; Prompt-Secret $Config.PIL_KEY_NAME; return }
                '3' { $targetPath = Read-HostDefault 'Project directory or .pil path' (Get-Location).Path }
                default { Fail 'expected 1, 2, or 3' }
            }
        }
        'local' { $targetPath = (Get-Location).Path }
    }

    Validate-BaseUrl $Config
    Validate-ScopedModels $Config
    $pilFile = Get-TargetPilFile $targetPath
    $projectDir = Split-Path -Path $pilFile -Parent
    Write-ConfigFile $pilFile $Config $true
    Write-ProjectPiSettings $projectDir $Config
    Prompt-Secret $Config.PIL_KEY_NAME
}

function Command-ConfigShow([string[]]$Args, $Config) {
    $json = $false
    foreach ($arg in $Args) {
        switch ($arg) {
            '--json' { $json = $true }
            '-h' { Show-Usage; exit 0 }
            '--help' { Show-Usage; exit 0 }
            default { Fail "unknown pil config option: $arg" 2 }
        }
    }
    $output = [ordered]@{
        provider = $Config.PIL_PROVIDER
        baseUrl = $Config.PIL_BASE_URL
        keyName = $Config.PIL_KEY_NAME
        model = $Config.PIL_MODEL
        scopedModels = $Config.PIL_MODELS
        modelsJson = Get-ModelsJsonPath
        apiKey = 'redacted'
    }
    if ($json) {
        $output | ConvertTo-Json -Depth 10 | Write-Host
        return
    }
    Write-Section 'pil config'
    foreach ($entry in $output.GetEnumerator()) {
        Write-Kv $entry.Key ([string]$entry.Value)
    }
}

function Command-Doctor([string[]]$Args, $Config) {
    $json = $false
    foreach ($arg in $Args) {
        switch ($arg) {
            '--json' { $json = $true }
            '-h' { Show-Usage; exit 0 }
            '--help' { Show-Usage; exit 0 }
            default { Fail "unknown pil doctor option: $arg" 2 }
        }
    }

    $status = 'ok'
    $keyStatus = 'missing'
    $modelsStatus = 'not checked'
    $pi = Get-Command pi -ErrorAction SilentlyContinue
    if (-not $pi) { $status = 'fail' }
    $secret = if ($Config.PIL_KEY_NAME) { Read-Key $Config.PIL_KEY_NAME } else { $null }
    if ($secret) { $keyStatus = 'found' } else { $status = 'fail' }

    if ($Config.PIL_BASE_URL -and $secret) {
        try {
            $headers = @{ Authorization = "Bearer $secret" }
            Invoke-RestMethod -Method Get -Headers $headers -Uri ($Config.PIL_BASE_URL.TrimEnd('/') + '/models') | Out-Null
            $modelsStatus = 'ok'
        }
        catch {
            $modelsStatus = 'failed'
            $status = 'fail'
        }
    }

    $output = [ordered]@{
        status = $status
        pi = if ($pi) { 'ok' } else { 'missing' }
        key = $keyStatus
        models = $modelsStatus
        provider = $Config.PIL_PROVIDER
        baseUrl = $Config.PIL_BASE_URL
        keysFile = Get-PilKeysPath
        secretsDir = Get-PilSecretsDir
    }

    if ($json) {
        $output | ConvertTo-Json -Depth 10 | Write-Host
    }
    else {
        Write-Section 'Dependencies'
        Write-Kv 'pi' $output.pi
        Write-Kv 'secret' 'Windows DPAPI files'
        Write-Section 'Config'
        Write-Kv 'provider' $Config.PIL_PROVIDER
        Write-Kv 'baseUrl' $Config.PIL_BASE_URL
        Write-Kv 'keyName' $Config.PIL_KEY_NAME
        Write-Kv 'apiKey' $keyStatus
        Write-Kv '/models' $modelsStatus
    }

    if ($status -ne 'ok') {
        exit 1
    }
}

function Start-Pi([string[]]$Args, $Config) {
    $sync = $false
    $dryRun = $false
    $piArgs = [System.Collections.Generic.List[string]]::new()

    for ($i = 0; $i -lt $Args.Count; $i++) {
        switch ($Args[$i]) {
            'sync' { $sync = $true }
            '--provider' { Need-Arg '--provider' $Args[$i + 1]; $Config.PIL_PROVIDER = $Args[++$i] }
            '--base-url' { Need-Arg '--base-url' $Args[$i + 1]; $Config.PIL_BASE_URL = $Args[++$i] }
            '--key' { Need-Arg '--key' $Args[$i + 1]; $Config.PIL_KEY_NAME = $Args[++$i] }
            '--select-key' { $Config.PIL_KEY_NAME = Select-Key }
            '--model' { Need-Arg '--model' $Args[$i + 1]; $Config.PIL_MODEL = $Args[++$i] }
            '--scoped-models' { Need-Arg '--scoped-models' $Args[$i + 1]; $Config.PIL_MODELS = $Args[++$i] }
            '--sync-models' { $sync = $true }
            '--dry-run' { $dryRun = $true }
            '--print-command' { $dryRun = $true }
            '--' {
                for ($j = $i + 1; $j -lt $Args.Count; $j++) { $piArgs.Add($Args[$j]) }
                break
            }
            default {
                if ($Args[$i].StartsWith('-')) {
                    $piArgs.Add($Args[$i])
                }
                else {
                    $piArgs.Add($Args[$i])
                }
            }
        }
    }

    Validate-BaseUrl $Config
    Validate-ScopedModels $Config
    if (-not $Config.PIL_KEY_NAME -and -not $dryRun) {
        $Config.PIL_KEY_NAME = Select-Key
    }
    $apiKey = if ($Config.PIL_KEY_NAME) { Read-Key $Config.PIL_KEY_NAME } else { $null }
    if ((-not $dryRun -or $sync) -and -not $apiKey) {
        Fail "key '$($Config.PIL_KEY_NAME)' not found in %APPDATA%\pil\secrets"
    }
    if ($sync) {
        Sync-Models $Config $apiKey
    }

    $piCommand = Get-Command pi -ErrorAction SilentlyContinue
    if (-not $piCommand) {
        Fail 'pi is required to launch pi' 127
    }

    $cmd = [System.Collections.Generic.List[string]]::new()
    $cmd.Add('--provider')
    $cmd.Add($Config.PIL_PROVIDER)
    if ($Config.PIL_MODEL) {
        $cmd.Add('--model')
        $cmd.Add($Config.PIL_MODEL)
    }
    if ($Config.PIL_MODELS) {
        $cmd.Add('--models')
        $cmd.Add($Config.PIL_MODELS)
    }
    foreach ($arg in $piArgs) { $cmd.Add($arg) }

    if ($dryRun) {
        Write-Host ('PIL_GATE=redacted pi ' + (($cmd | ForEach-Object {
            if ($_ -match '\s') { '"' + ($_ -replace '"', '\"') + '"' } else { $_ }
        }) -join ' '))
        return
    }

    $env:PIL_GATE = $apiKey
    & pi @cmd
    exit $LASTEXITCODE
}

$config = Load-Config
$argsList = [System.Collections.Generic.List[string]]::new()
foreach ($arg in $args) { $argsList.Add([string]$arg) }

if ($argsList.Count -eq 0) {
    Start-Pi ([string[]]$argsList.ToArray()) $config
    exit 0
}

switch ($argsList[0]) {
    '-h' { Show-Usage; exit 0 }
    '--help' { Show-Usage; exit 0 }
    'help' { Show-Usage; exit 0 }
    'setup' {
        Command-Init @() $config
        Command-Add @('--local') $config
        exit 0
    }
    'init' {
        Command-Init ([string[]]$argsList.GetRange(1, $argsList.Count - 1).ToArray()) $config
        exit 0
    }
    'add' {
        Command-Add ([string[]]$argsList.GetRange(1, $argsList.Count - 1).ToArray()) $config
        exit 0
    }
    'config' {
        if ($argsList.Count -lt 2 -or $argsList[1] -ne 'show') {
            Fail 'usage: pil config show [--json]' 2
        }
        Command-ConfigShow ([string[]]$argsList.GetRange(2, $argsList.Count - 2).ToArray()) $config
        exit 0
    }
    'key' {
        if ($argsList.Count -lt 3 -or $argsList[1] -ne 'add') {
            Fail 'usage: pil key add KEY' 2
        }
        Command-Add @('--global', '--key', $argsList[2]) $config
        exit 0
    }
    'project' {
        if ($argsList.Count -lt 3 -or $argsList[1] -ne 'use') {
            Fail 'usage: pil project use KEY' 2
        }
        Command-Add @('--local', '--key', $argsList[2]) $config
        exit 0
    }
    'doctor' {
        Command-Doctor ([string[]]$argsList.GetRange(1, $argsList.Count - 1).ToArray()) $config
        exit 0
    }
    default {
        Start-Pi ([string[]]$argsList.ToArray()) $config
        exit 0
    }
}
