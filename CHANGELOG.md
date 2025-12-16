# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-12-16

### Added

- **Initial release of zerodice0-plugins marketplace**
- **gemini-design-updater plugin** with the following features:
  - Git branch isolation workflow for safe Gemini operations
  - Scope-based change tracking with IDE integration (`@file#L10-50` format)
  - Automatic Claude review of Gemini changes
  - 4-option decision flow (apply all, scope only, revert all, revert out-of-scope)
  - Out-of-scope change detection and classification

### Scripts

- `create-branch.sh` - Creates isolated work branch with timestamp
- `analyze-changes.sh` - Analyzes changes with scope validation
- `apply-partial.sh` - Partial apply/revert functionality
- `cleanup-branch.sh` - Work branch cleanup

### Documentation

- Comprehensive SKILL.md with 6-phase workflow guide
- Review checklist (`references/review-checklist.md`)
- Rollback procedures (`references/rollback-procedures.md`)
- Scope examples (`examples/scope-examples.md`)
- Bilingual README (English/한국어)

### CI/CD

- ShellCheck validation for all bash scripts
- Automated GitHub Release on version tags
- Plugin structure validation

---

## Future Plans

- [ ] Additional Gemini-related plugins
- [ ] Enhanced scope validation with AST parsing
- [ ] Integration with more AI models
