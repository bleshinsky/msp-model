# Changelog

All notable changes to MSP will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial repository structure
- Three MSP variants: Lite, Standard, and Advanced
- R³ Protocol implementation (Route-Recall-Record)
- Context Engineering documentation
- Neo4j knowledge graph integration
- Obsidian markdown documentation support
- Linear issue tracking integration
- Docker support for easy Neo4j setup
- Comprehensive documentation and examples

### Changed
- Migrated from complex microservices architecture to simple, effective design
- Adopted ATAI pattern (generate queries, don't execute)

### Fixed
- N/A (Initial release)

## [v0.1.0]

### Added
- MSP Lite variant for zero-dependency usage
- Basic session tracking with JSON state files
- Progress tracking and decision recording
- Session recovery functionality

### Changed
- Refactored from prototype to production-ready structure
- Improved error handling and user feedback

### Fixed
- Session state corruption issues
- PowerShell 5 compatibility problems

## [v0.5.0] 

### Added
- Original ATAI pattern implementation
- Basic Neo4j query generation
- Obsidian file creation
- Linear comment formatting

### Changed
- Moved from direct API execution to query generation
- Simplified configuration approach

### Fixed
- Connection timeout issues
- State synchronization problems



---

## Version History Context

### The Journey to Simplicity

**v0.1.0 (June 28 2025)**: Started with enterprise ambitions - microservices, event sourcing, CQRS. Complexity was the enemy we didn't see.

**v0.5.0 (July 04 2025)**: The ATAI discovery - "Generate, don't execute." Reduced complexity by 90%.

**v0.9.0 (July 09 2025)**: Created MSP Lite - proving the concept works with zero dependencies. Simplicity wins.

**v1.0.0 (Coming Soon)**: The R³ Protocol emerges. Route-Recall-Record. Three words that capture everything. This is MSP's final form.

### What We Learned

1. **Complexity doesn't equal capability** - Our simplest version (Lite) is often the most loved
2. **Transparency beats automation** - Showing queries builds trust and understanding  
3. **Integration should be optional** - Start simple, add tools as needed
4. **Context is everything** - The feature that matters most is never losing it

---

[Unreleased]: https://github.com/msp-framework/msp/compare/v0.9.0...HEAD
[0.9.0]: https://github.com/msp-framework/msp/compare/v0.5.0...v0.9.0
[0.5.0]: https://github.com/msp-framework/msp/compare/v0.1.0...v0.5.0
[0.1.0]: https://github.com/msp-framework/msp/releases/tag/v0.1.0
