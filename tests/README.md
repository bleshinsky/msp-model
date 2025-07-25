# MSP Test Suite

Comprehensive test coverage for all MSP versions.

## Quick Start

Run all tests:
```powershell
.\tests\run-all.ps1
```

Run specific version tests:
```powershell
.\tests\run-all.ps1 -Version lite
.\tests\run-all.ps1 -Version standard
.\tests\run-all.ps1 -Version integration
```

## Test Structure

```
tests/
├── run-all.ps1              # Main test runner
├── lite/
│   └── test-msp-lite.ps1    # MSP Lite tests
├── standard/
│   └── test-msp-standard.ps1 # MSP Standard tests
└── integration/
    └── test-integration.ps1  # Cross-version integration tests
```

## Test Categories

### MSP Lite Tests
- Basic functionality (start, update, end)
- Session management
- Context export
- Error handling
- Recovery features
- Performance benchmarks

### MSP Standard Tests
- File structure validation
- Configuration management
- Module loading
- Integration detection
- Command availability
- Validation tools

### Integration Tests
- Cross-version compatibility
- Migration scenarios
- Tool detection
- AI format consistency
- Performance comparison
- Error handling parity

## Running Tests

### Basic Usage
```powershell
# Run all tests
.\tests\run-all.ps1

# Run with verbose output
.\tests\run-all.ps1 -Verbose

# Stop on first failure
.\tests\run-all.ps1 -StopOnFailure

# Generate test report
.\tests\run-all.ps1 -GenerateReport
```

### Individual Test Suites
```powershell
# Run only Lite tests
Set-Location tests\lite
.\test-msp-lite.ps1

# Run only Standard tests
Set-Location tests\standard
.\test-msp-standard.ps1

# Run only Integration tests
Set-Location tests\integration
.\test-integration.ps1
```

## Test Environment

Tests run in isolated temporary directories to avoid affecting your actual MSP installation.

### Prerequisites
- PowerShell 7.0 or higher
- Write access to temp directory
- For integration tests: Neo4j, Obsidian, or Linear (optional)

### Environment Variables
Set these for integration tests:
```powershell
$env:NEO4J_HOME = "C:\neo4j"
$env:OBSIDIAN_VAULT_PATH = "C:\ObsidianVault"
$env:LINEAR_API_KEY = "your-api-key"
```

## Writing New Tests

### Test Structure
```powershell
Test-Case "Description of what you're testing" {
    # Test code here
    # Return $true for pass, $false for fail
    $result = Some-Command
    $result -eq "expected value"
}
```

### Best Practices
1. Test one thing per test case
2. Use descriptive test names
3. Clean up after tests
4. Don't depend on test order
5. Mock external dependencies

### Example Test
```powershell
Test-Case "Session starts successfully" {
    $output = & .\msp.ps1 start 2>&1
    $output -match "Session started" -and 
    (Test-Path ".\.msp\current-session.json")
}
```

## Continuous Integration

### GitHub Actions
```yaml
name: Test MSP
on: [push, pull_request]
jobs:
  test:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v2
      - run: |
          pwsh -Command "& ./tests/run-all.ps1 -GenerateReport"
      - uses: actions/upload-artifact@v2
        with:
          name: test-report
          path: tests/test-report-*.json
```

### Local Pre-commit Hook
```powershell
# .git/hooks/pre-commit
#!/usr/bin/env pwsh
Write-Host "Running MSP tests..."
& ./tests/run-all.ps1 -Version lite
if ($LASTEXITCODE -ne 0) {
    Write-Error "Tests failed! Commit aborted."
    exit 1
}
```

## Troubleshooting Tests

### Common Issues

**Tests hang**: 
- Check for infinite loops
- Add timeout to long operations
- Use `-Verbose` for more output

**Permission errors**:
- Run as Administrator
- Check temp directory access
- Ensure no antivirus interference

**Integration tests fail**:
- Verify external tools are installed
- Check environment variables
- Tools may need to be running

### Debug Mode
```powershell
$env:MSP_TEST_DEBUG = "true"
.\tests\run-all.ps1 -Verbose
```

## Test Reports

Generated reports include:
- Test execution time
- Pass/fail counts
- Failure details
- Environment information
- Coverage metrics

View report:
```powershell
Get-Content .\tests\test-report-*.json | ConvertFrom-Json | Format-List
```

## Contributing Tests

When adding new features:
1. Write tests first (TDD)
2. Ensure all tests pass
3. Add integration tests if needed
4. Update this README

Test checklist:
- [ ] Happy path works
- [ ] Error cases handled
- [ ] Edge cases covered
- [ ] Performance acceptable
- [ ] Cross-version compatible