# Contributing to MSP

Thank you for your interest in contributing to MSP! This document provides guidelines and instructions for contributing.

## Code of Conduct

By participating in this project, you agree to abide by our Code of Conduct:

- Be respectful and inclusive
- Welcome newcomers and help them get started
- Focus on what is best for the community
- Show empathy towards other community members

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- MSP version and variant (Lite/Standard/Advanced)
- PowerShell version (`$PSVersionTable`)
- Operating system and version
- Detailed steps to reproduce
- Expected behavior vs actual behavior
- Error messages and logs

### Suggesting Enhancements

Enhancement suggestions are welcome! Please include:

- Clear use case and motivation
- Detailed description of the proposed solution
- Alternative solutions you've considered
- Any potential drawbacks

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests if applicable
5. Update documentation
6. Commit with clear messages (`git commit -m 'Add amazing feature'`)
7. Push to your fork (`git push origin feature/amazing-feature`)
8. Open a Pull Request

## Development Setup

### Prerequisites

- PowerShell 7+
- Git
- Neo4j Desktop (for Standard/Advanced development)
- Docker (optional, for testing)

### Getting Started

```powershell
# Clone the repository
git clone https://github.com/msp-framework/msp.git
cd msp

# Run tests
.\scripts\run-tests.ps1

# Test all versions
.\scripts\test-all-versions.ps1
```

## Coding Standards

### PowerShell Style Guide

- Use PascalCase for function names: `Start-MSPSession`
- Use camelCase for variable names: `$sessionId`
- Always include comment-based help for functions
- Use proper parameter validation
- Handle errors gracefully with try/catch

Example:
```powershell
function Start-MSPSession {
    <#
    .SYNOPSIS
        Starts a new MSP session
    .DESCRIPTION
        Initializes session tracking across all configured tools
    .PARAMETER Project
        The project name for this session
    .EXAMPLE
        Start-MSPSession -Project "MyAPI"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$Project = "Default"
    )
    
    try {
        # Implementation
    }
    catch {
        Write-Error "Failed to start session: $_"
        throw
    }
}
```

### Documentation Standards

- All public functions must have comment-based help
- Update README.md for user-facing changes
- Add examples for new features
- Keep documentation in sync with code

### Testing

- Write Pester tests for new functionality
- Ensure all tests pass before submitting PR
- Test on multiple platforms if possible
- Include integration tests for tool interactions

## Project Structure

```
msp/
├── lite/           # MSP Lite - single file implementation
├── standard/       # MSP Standard - full featured version
├── advanced/       # MSP Advanced - enterprise features
├── docs/           # Documentation
├── examples/       # Usage examples
├── tests/          # Test suites
└── scripts/        # Development scripts
```

## Commit Messages

Follow conventional commits format:

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes (formatting, etc)
- `refactor:` Code refactoring
- `test:` Test additions or changes
- `chore:` Maintenance tasks

Examples:
```
feat: add Redis support for session caching
fix: correct Neo4j query for session recovery
docs: update quickstart guide with Docker instructions
```

## Release Process

1. Update version numbers in module manifests
2. Update CHANGELOG.md
3. Create release notes
4. Tag release: `git tag -a v1.2.3 -m "Release version 1.2.3"`
5. Push tags: `git push origin --tags`

## Getting Help

- Check [existing discussions](https://github.com/[TBC]/msp/discussions)
- Email: contributors@sessionprotocol.dev


Thank you for helping make MSP better for everyone! 🙏
