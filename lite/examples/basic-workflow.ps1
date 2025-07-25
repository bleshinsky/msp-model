# MSP Lite - Basic Workflow Example
# This example shows a typical development session with MSP Lite

Write-Host "MSP Lite Basic Workflow Example" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan
Write-Host ""

# Start a new session
Write-Host "1. Starting a new session..." -ForegroundColor Yellow
& ./msp-lite.ps1 start

Start-Sleep -Seconds 2

# Make some progress
Write-Host "`n2. Tracking initial work..." -ForegroundColor Yellow
& ./msp-lite.ps1 update "Set up project structure" 10

Start-Sleep -Seconds 1

Write-Host "`n3. Working on features..." -ForegroundColor Yellow
& ./msp-lite.ps1 update "Created user model and database schema" 25

Start-Sleep -Seconds 1

# Track a decision
Write-Host "`n4. Making architectural decisions..." -ForegroundColor Yellow
& ./msp-lite.ps1 update "Decided to use JWT tokens instead of sessions for stateless auth"

Start-Sleep -Seconds 1

# More progress
Write-Host "`n5. Implementing core features..." -ForegroundColor Yellow
& ./msp-lite.ps1 update "Implemented login and registration endpoints" 40
& ./msp-lite.ps1 update "Added password hashing with bcrypt"

Start-Sleep -Seconds 1

# Hit a blocker
Write-Host "`n6. Encountering issues..." -ForegroundColor Yellow
& ./msp-lite.ps1 update "Issue: CORS errors when calling from frontend"

Start-Sleep -Seconds 1

# Resolve it
Write-Host "`n7. Problem solving..." -ForegroundColor Yellow
& ./msp-lite.ps1 update "Fixed CORS by configuring proper headers" 50
& ./msp-lite.ps1 update "Chose to whitelist specific origins instead of using wildcard"

Start-Sleep -Seconds 1

# Check status
Write-Host "`n8. Checking session status..." -ForegroundColor Yellow
& ./msp-lite.ps1 status

Start-Sleep -Seconds 2

# End session
Write-Host "`n9. Ending the session..." -ForegroundColor Yellow
& ./msp-lite.ps1 end

# Show recall
Write-Host "`n10. Viewing session history..." -ForegroundColor Yellow
Start-Sleep -Seconds 2
& ./msp-lite.ps1 recall

Write-Host "`n✅ Example completed! This is how you use MSP Lite in your daily workflow." -ForegroundColor Green
