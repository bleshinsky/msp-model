# MSP Lite - AI Integration Example
# Shows how to use MSP Lite with AI assistants like Claude, GPT, or Cursor

Write-Host "MSP Lite AI Integration Example" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan
Write-Host ""

# Simulate a development session
Write-Host "1. Starting development session..." -ForegroundColor Yellow
& ./msp-lite.ps1 start

# Track some work
Write-Host "`n2. Working on a complex feature..." -ForegroundColor Yellow
& ./msp-lite.ps1 update "Working on payment integration with Stripe" 15
& ./msp-lite.ps1 update "Implemented webhook endpoint for payment events"
& ./msp-lite.ps1 update "Decided to use Stripe's webhook signature verification"
& ./msp-lite.ps1 update "Issue: Webhook signature validation failing with 400 error" 20

# Now we need AI help
Write-Host "`n3. Need help from AI - exporting context..." -ForegroundColor Yellow
Start-Sleep -Seconds 1

Write-Host "`n4. Running context export..." -ForegroundColor Yellow
$contextFile = & ./msp-lite.ps1 context

Write-Host "`n5. Context is now in your clipboard!" -ForegroundColor Green
Write-Host "   You can paste this directly into:" -ForegroundColor White
Write-Host "   - Claude (claude.ai)" -ForegroundColor Gray
Write-Host "   - ChatGPT" -ForegroundColor Gray
Write-Host "   - Cursor AI" -ForegroundColor Gray
Write-Host "   - GitHub Copilot Chat" -ForegroundColor Gray

# Simulate getting help and implementing solution
Write-Host "`n6. After getting AI assistance..." -ForegroundColor Yellow
Start-Sleep -Seconds 2

& ./msp-lite.ps1 update "AI suggested: Express middleware parsing body before raw body middleware"
& ./msp-lite.ps1 update "Fixed by excluding webhook route from body parser" 30
& ./msp-lite.ps1 update "Webhook signature validation now working correctly"

# Continue with AI-assisted development
Write-Host "`n7. Using AI for code generation..." -ForegroundColor Yellow
& ./msp-lite.ps1 update "AI generated TypeScript interfaces for Stripe events"
& ./msp-lite.ps1 update "Implemented payment confirmation flow with AI assistance" 45

# End session
Write-Host "`n8. Completing session..." -ForegroundColor Yellow
& ./msp-lite.ps1 end

Write-Host "`n💡 Pro Tips for AI Integration:" -ForegroundColor Cyan
Write-Host "1. Export context before asking complex questions" -ForegroundColor White
Write-Host "2. Update MSP after implementing AI suggestions" -ForegroundColor White
Write-Host "3. Track which solutions came from AI for future reference" -ForegroundColor White
Write-Host "4. Include error messages in your updates for better context" -ForegroundColor White

Write-Host "`n📝 Example AI Prompt:" -ForegroundColor Yellow
Write-Host @"
"Here's my current development context from MSP:
[PASTE CONTEXT HERE]

I'm getting a 400 error on Stripe webhook validation. 
The signature verification is failing. How can I fix this?"
"@ -ForegroundColor Gray

Write-Host "`n✅ AI Integration example completed!" -ForegroundColor Green
