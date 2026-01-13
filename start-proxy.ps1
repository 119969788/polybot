# PolyBot Proxy Start Script

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  PolyBot Proxy Configuration Script  " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Proxy Configuration
$PROXY_HOST = "127.0.0.1"
$PROXY_PORT = "7890"
$PROXY_URL = "http://$PROXY_HOST`:$PROXY_PORT"

Write-Host "Proxy Configuration:" -ForegroundColor Yellow
Write-Host "  Proxy Address: $PROXY_URL"
Write-Host ""

# Set Environment Variables
Write-Host "Setting proxy environment variables..." -ForegroundColor Yellow
$env:HTTP_PROXY = $PROXY_URL
$env:HTTPS_PROXY = $PROXY_URL
$env:http_proxy = $PROXY_URL
$env:https_proxy = $PROXY_URL

$env:NO_PROXY = "localhost,127.0.0.1"
$env:no_proxy = "localhost,127.0.0.1"

Write-Host "Proxy environment variables set" -ForegroundColor Green
Write-Host ""

# Test Proxy Connection
Write-Host "Testing proxy connection..." -ForegroundColor Yellow
try {
    $testUrl = "https://polymarket.com"
    Write-Host "  Testing URL: $testUrl" -NoNewline
    
    $response = Invoke-WebRequest -Uri $testUrl -Proxy $PROXY_URL -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
    Write-Host " OK (Status: $($response.StatusCode))" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host " Failed" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Warning: Proxy connection test failed, but will continue" -ForegroundColor Yellow
    Write-Host "Tip: Please check if proxy address/port is correct, or proxy software is running" -ForegroundColor Yellow
    Write-Host ""
    
    $continue = Read-Host "Continue running program? (Y/N)"
    if ($continue -ne "Y" -and $continue -ne "y") {
        Write-Host "Cancelled" -ForegroundColor Yellow
        exit
    }
    Write-Host ""
}

# Check Private Key
if (-not $env:POLYMARKET_PRIVATE_KEY) {
    Write-Host "Checking private key..." -ForegroundColor Yellow
    Write-Host "  Private key not found in environment variables" -ForegroundColor Gray
    Write-Host "  Will read from config.js" -ForegroundColor Gray
    Write-Host ""
}

# Run Program
Write-Host "Starting PolyBot..." -ForegroundColor Cyan
Write-Host ""
Write-Host "----------------------------------------" -ForegroundColor Gray
Write-Host ""

# Change to script directory
Set-Location $PSScriptRoot

# Run program
npm start
