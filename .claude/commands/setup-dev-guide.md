# Universal Development Guide & Workflow Setup

**Create a comprehensive development workflow system for this project that any developer (human or AI) can use to quickly understand and continue development.**

**This directive is a GUIDE. First analyze this codebase thoroughly, then adapt these principles to fit this project's type, structure, tooling, and needs.**

---

## IMPORTANT: Save This Prompt for Future Use

**On first run, save this entire prompt to `.claude/commands/setup-dev-guide.md` in this project.**

This allows future sessions to simply say "Set up the development workflow guide" without needing to paste this full prompt again.

---

## Phase 1: Project Discovery & Analysis

### Automatically Detect and Document:

**1. Project Identity**
- Project name and purpose (one-line and detailed)
- Project type (web app, API, library, CLI tool, WordPress plugin/theme, etc.)
- Primary language(s) and framework(s)
- Target runtime/platform

**2. Technology Stack**
- Build system and package manager (detect what's actually used: npm/yarn/pnpm/bun, Composer, pip/Poetry/pipenv, etc.)
- Testing framework (detect what's configured)
- Linting/formatting tools (detect what exists)
- Database (if applicable)
- Other key dependencies

**3. Project Architecture**
- Structure type (monorepo, single package, modular, etc.)
- Directory organization and key folders
- Entry points and main files
- Configuration files and their purposes
- Environment variable requirements

**4. Current State Assessment**
- What's implemented and working
- What's incomplete or in progress
- Current version number and where it's defined
- Existing documentation
- Test coverage status
- Known issues or technical debt

**5. Deployment & Operations**
- Deployment target (detect from configuration)
- Build/deployment process
- Environment requirements
- Admin/monitoring capabilities
- CI/CD setup (if any)

---

## Phase 2: Create Development Workflow System

### 1. Create `.claude/commands/dev.md`

This is your primary development workflow reference. Adapt this template to the actual project:

```markdown
# /dev - [Project Name] Development Workflow

> One-line project description

---

## Quick Start

**Install:**
```bash
[actual installation commands for this project]
```

**Run Development:**
```bash
[actual dev server command]
```

**Build Production:**
```bash
[actual build command]
```

**Run Tests:**
```bash
[actual test command]
```

**Lint/Format:**
```bash
[actual linting commands]
```

---

## Project Overview

**Type:** [Actual project type]
**Stack:** [Actual tech stack]
**Version:** [current version] ([versioning strategy used])
**Package Manager:** [npm/yarn/pnpm/bun/composer/pip/poetry - detect actual]
**Deployment:** [actual deployment target and process]

### Project Structure
```
[Key directories and their purposes - actual structure]
```

### Key Configuration Files
| File | Purpose |
|------|---------|
| [actual config files] | [what they do] |

---

## Development Phases & Roadmap

### Phase Structure

Development is organized into phases. Each phase represents a coherent set of functionality.

**Phase Status Legend:**
- Complete
- In Progress
- Planned
- Future Consideration

### Current Focus: Phase [X.X]

[Brief description of current phase objective]

### Phase History & Roadmap

[Organized list of phases with status, or reference to ROADMAP.md]

**To work on a specific phase:** "Follow the dev guide and work on phase [X.X]"

---

## What to Work On

**Priority Order:**
1. [Highest priority item - reference phase if applicable]
2. [Next priority]
3. [Third priority]

**Quick Links:**
- See `docs/ROADMAP.md` for detailed phases and milestones
- See `CHANGELOG.md` for version history
- See `docs/TODO.md` or issue tracker for granular tasks

---

## Development Standards

### Code Quality
[Detect and document actual standards used in this project]
- Coding standards: [WordPress Coding Standards / PSR-12 / PEP 8 / Airbnb / etc. - detect actual]
- Naming conventions: [actual conventions used]
- File organization rules: [actual organization]
- Comment/documentation requirements: [actual requirements]

### User Experience (if applicable)
- Frictionless interactions - minimize clicks/steps
- Clear feedback for all user actions
- Consistent UI patterns throughout
- Accessible (WCAG AA minimum)
- Mobile-responsive (if web-based)

### Configuration Management
- Environment variables in `.env.example` documented
- Sensible defaults where possible
- Configuration validation on startup
- [Project-specific config requirements]

### Version Management
- **Strategy:** [Detect actual strategy: Semantic versioning / CalVer / WordPress version / other]
- **Bump version when:** [Define criteria based on project type]
- **Version locations:** [All actual files that contain version numbers]
- **Always update:** [List actual files that need version updates]

### Testing Strategy
- **Philosophy:** Test what matters - critical paths, edge cases, regressions
- **Priority areas to test:**
  - Authentication and authorization
  - Data integrity and validation
  - API endpoints and integrations
  - Core business logic
  - Payment/financial operations (if applicable)
- **Don't bother testing:**
  - Trivial getters/setters
  - Simple UI components without logic
  - Framework internals
  - Third-party library behavior
- **Test types:** [Document what test types are actually used in this project]
- **Test commands:** [Actual commands to run tests]
- **Coverage goal:** Focus on quality over quantity - 100% of critical features, not 100% of code

### Git Workflow
- **Commit format:** [Detect actual format: Conventional commits / other]
- **Branch strategy:** [Detect actual strategy]
- **Required before commit:**
  - Tests pass
  - Linter passes
  - Version bumped if code changed
  - CHANGELOG updated
  - Documentation updated

### CI/CD (if exists)
- **CI Platform:** [GitHub Actions / GitLab CI / other - detect actual]
- **What CI tests:** [Document what's actually configured]
- **What CI doesn't test:** [Note what runs locally only]
- **CI runs in:** [Actual runtime]
- **Status badge:** [Link to CI badge if exists]
- **Failure Reporting:** CI outputs detailed failure summaries that can be copied to AI for troubleshooting (test names, file locations, error messages, stack traces, environment info, reproduce commands)

### Documentation Standards
- Code comments: [Actual standards - inline, docblocks, etc.]
- Function/method documentation: [Actual format used]
- API documentation: [If applicable, format used]
- Keep README, CHANGELOG, ROADMAP current
- Update docs in same commit as code changes

---

## Key Files & Directories

| Path | Purpose | When to Modify |
|------|---------|----------------|
| [actual paths] | [what they do] | [when to touch them] |

---

## Development Workflow Steps

### Starting a Work Session

1. **Review current state:**
   - Check `docs/ROADMAP.md` for current phase
   - Review `CHANGELOG.md` Unreleased section
   - Check for any blockers or prerequisites

2. **Choose work item:**
   - Follow priority order above
   - Or specify: "work on phase [X.X]"
   - Or pick from TODO/issues

### During Development

1. **Make changes following standards above**
2. **Write/update tests as you go**
3. **Update documentation in same commit**
4. **Test frequently:** `[actual test command]`
5. **Lint/format:** `[actual lint command]`

### Completing Work

1. **Verify all tests pass**
2. **Update version number** (if code changed)
3. **Update CHANGELOG.md** with changes
4. **Update ROADMAP.md** if phase completed
5. **Commit with descriptive message**
6. **Summarize what was done and suggest next steps**

---

## Common Tasks

### Adding a New Feature
1. Plan feature scope (document in ROADMAP if significant)
2. Create tests (TDD approach)
3. Implement feature
4. Update documentation
5. Add to CHANGELOG under Unreleased
6. Bump version appropriately

### Fixing a Bug
1. Write test that reproduces bug
2. Fix bug
3. Verify test passes
4. Add to CHANGELOG under Unreleased > Fixed
5. Bump patch version

### Refactoring
1. Ensure tests exist for affected code
2. Refactor
3. Verify all tests still pass
4. Update comments/docs if needed
5. Note in CHANGELOG if significant

---

## Project-Specific Notes

[Any unique aspects of this project]
[Special considerations]
[Known gotchas]
[Integration details]
[Deployment specifics]

---

## Troubleshooting

### Common Issues

[Document actual common issues discovered in this project]

---

## Admin Dashboard / Monitoring (if applicable)

[Location of admin interface]
[What can be monitored/configured]
[How to access in dev vs production]

---

## Resources & References

- [Link to main documentation]
- [API documentation if applicable]
- [Framework documentation]
- [Important external resources]

---

*Last Updated: [Date]*
*Developer: Run this workflow to maintain project standards and move development forward systematically.*
```

### 2. Adapt Dev Guide to Project Type

**For WordPress Plugins/Themes:**
- Include WordPress plugin/theme header requirements and versioning
- WordPress Coding Standards (WPCS) configuration
- Hook/filter documentation requirements
- WordPress.org deployment process (if applicable)
- SVN workflow (if WordPress.org plugin)
- readme.txt standards for WordPress.org
- wp-cli commands if used
- Localization/translation workflow

**For JavaScript/TypeScript Projects:**
- Actual package manager detection (npm/yarn/pnpm/bun)
- Package.json scripts documentation
- Build optimization notes
- Component documentation standards (if React/Vue)
- Bundle analysis process (if configured)

**For Python Projects:**
- Actual dependency manager (pip/pipenv/poetry)
- Virtual environment setup
- Package distribution process (if applicable)
- Docstring format (detect actual: Google/NumPy/reST)
- Type hinting standards

**For PHP Projects (Non-WordPress):**
- Composer scripts and autoloading
- PSR standards if applicable
- Framework-specific conventions (Laravel, Symfony, etc.)

**For Backend APIs:**
- API documentation format (detect: OpenAPI/Swagger/other)
- Authentication testing process
- Database migration workflow
- API versioning strategy

**For CLI Tools:**
- Command documentation format
- Help text standards
- Configuration file locations
- Distribution/installation process

### 3. Create `.claude/commands/` Directory

If it doesn't exist, create it and add:
- **`dev.md`** - The primary development workflow (this file)
- **`setup-dev-guide.md`** - This prompt itself (for future updates)

---

## Phase 3: Create/Update Supporting Documentation

### 1. `docs/ROADMAP.md`

Create with phase-based structure:

```markdown
# Roadmap - [Project Name]

## Current Status: Phase [X.X] - [Phase Name]

### Phase Structure

Development follows a phased approach.

**Phase Status Legend:**
- Complete | In Progress | Planned | Future

---

## Phases

### Phase 1.0 - Foundation
**Objective:** [What was accomplished]
**Completed in v[X.X.X] - [Date]**
- [Completed items]

### Phase 2.0 - [Current Phase]
**Objective:** [What this accomplishes]
**Started: v[X.X.X]**

**Completed:**
- [Done items]

**In Progress:**
- [Current work]

**Remaining:**
- [Todo] - Priority: High/Medium/Low

### Phase 3.0 - [Next Phase]
**Objective:** [Planned work]
**Prerequisites:** Complete Phase 2.0
**Planned Work:**
- [Features]

---

## Version History

| Version | Phase | Date | Highlights |
|---------|-------|------|------------|
| [X.X.X] | [Phase] | [Date] | [Changes] |

---

## Known Issues & Technical Debt

- [Issue] - [Impact] - Planned for: [Phase]
```

### 2. `CHANGELOG.md`

Create using Keep a Changelog format:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added - Phase [X.X]
- [New features]

### Changed - Phase [X.X]
- [Modifications]

### Fixed
- [Bug fixes]

## [X.X.X] - YYYY-MM-DD - Phase [X.X] Complete

### Added
- [Features]

### Changed
- [Changes]

### Fixed
- [Fixes]
```

### 3. `README.md`

Ensure it includes:
- Quick project description
- Installation instructions
- Basic usage
- Link to full documentation: "See `.claude/commands/dev.md` for complete development workflow"
- Link to roadmap
- License

### 4. `.gitignore`

Comprehensive coverage appropriate for the detected technology stack.

---

## Phase 4: Optional Enhancements

### Admin Dashboard (if web application)

If this is a web application, consider planning for:
- Usage metrics and analytics
- Feature flags/toggles
- System configuration interface
- Maintenance mode toggle
- Health checks and diagnostics

### CI/CD Setup (if beneficial and not present)

**Only add if project would benefit and doesn't have CI yet:**

Create pragmatic CI configuration appropriate for the project:
- Fast and focused (target: under 3 minutes)
- Linting/code style checks
- Unit tests only (no DB/network dependencies)
- Build verification
- Use ONE language version (current stable)

**Detect actual tools and create appropriate config:**
- For npm/yarn/pnpm/bun projects: Use actual package manager
- For Composer projects: Use actual PHP version
- For Poetry/pip projects: Use actual Python version

**CRITICAL: Ensure detailed test failure reporting:**

When tests fail in CI, the output should include a detailed summary that can be copied and pasted to AI for troubleshooting. This summary should include:

**Required in failure output:**
1. **Clear failure summary header** (e.g., "DETAILED FAILURE SUMMARY")
2. **For each failed test:**
   - Full test name and class
   - File path and line number
   - Error message
   - Relevant stack trace (not full trace)
   - Debugging hints if possible
3. **Quick reference section:**
   - List of all failed test names
   - Command to run each test individually
   - Environment info (language version, framework version, test framework version)

**Implementation examples:**

For **PHPUnit/Laravel** projects:
- Use custom PHPUnit extensions or result printers
- Configure in `phpunit.xml` to output detailed failures
- Example: Create a custom failure formatter that outputs structured summaries

For **Jest/Node.js** projects:
- Use custom reporters or format test output
- Configure in `jest.config.js`

For **pytest/Python** projects:
- Use pytest plugins or custom reporters
- Configure in `pytest.ini` or `pyproject.toml`

The goal: After any CI failure, a developer should be able to copy the failure summary and paste it into Claude/ChatGPT to get immediate help troubleshooting.

**Don't add CI if:**
- Project is early stage prototype
- Tests require complex setup
- CI would add more burden than value

---

## Phase 5: Universal Standards Application

Apply these principles (adapt as needed):

### 1. Clean, Standards-Compliant Codebase
- Follow language/framework idioms and actual standards used
- Consistent formatting (use existing tools configured)
- Meaningful names
- DRY principle without over-abstraction

### 2. Frictionless User Experience (if user-facing)
- Intuitive interactions
- Minimize steps to complete tasks
- Clear, actionable error messages
- Immediate feedback

### 3. Pragmatic Testing
- Test what matters (critical paths, edge cases, regressions)
- Avoid testing implementation details or trivial code
- Fast test execution
- Easy to run locally

### 4. Living Documentation
- Documentation updated with code changes
- Code comments explain "why" not "what"
- Examples are current and working

### 5. Version Discipline
- Consistent versioning strategy
- Version bumps for all code changes
- Version numbers consistent across all files
- CHANGELOG documents all changes

### 6. Configurable Without Complexity
- Environment variables for deployment differences
- Sensible defaults
- Configuration documented

### 7. Observable Systems
- Adequate logging
- Errors include context for debugging
- Easy to diagnose issues

### 8. Deployment Ready
- Complete deployment documentation
- Environment-specific configuration
- Rollback process documented

### 9. Developer Friendly
- Clear for both human and AI developers
- Quick start works without deep knowledge
- Common tasks have documented workflows
- Project structure is logical

---

## Phase 6: Validation & Output

### Before Finalizing:

**1. Validate Everything Works:**
- Run installation from scratch
- Execute all documented commands
- Verify tests run and pass
- Ensure build process completes

**2. Self-Review Checklist:**
- [ ] `.claude/commands/dev.md` is comprehensive
- [ ] `.claude/commands/setup-dev-guide.md` saved (this prompt)
- [ ] `docs/ROADMAP.md` has clear phases with status
- [ ] `CHANGELOG.md` follows Keep a Changelog format
- [ ] `README.md` has quick start and links to detailed docs
- [ ] `.gitignore` covers necessary files
- [ ] Version numbers are consistent
- [ ] All key files are documented
- [ ] Development standards match actual project
- [ ] Tool commands use actual tools (not assumed)
- [ ] Project can be built and run from documentation

### Output Summary:

**Provide a clear summary:**

1. **Key Files Created/Updated:**
   - `.claude/commands/dev.md` - [description]
   - `.claude/commands/setup-dev-guide.md` - This prompt saved
   - `docs/ROADMAP.md` - [current phase, status]
   - `CHANGELOG.md` - [current version]
   - `README.md` - [improvements]
   - [Other files]

2. **Project State:**
   - **Current Version:** [X.X.X]
   - **Current Phase:** [Phase X.X - Name]
   - **Detected Tools:** [Actual package manager, test framework, etc.]
   - **Status:** [Assessment]

3. **Top 3 Development Priorities:**
   1. [Priority with phase reference]
   2. [Priority with phase reference]
   3. [Priority with phase reference]

4. **Items Needing Human Input:**
   - [Decisions needed]
   - [Information that couldn't be determined]

5. **Version Bump:**
   - [Did you bump version? Why or why not?]

6. **Quick Start Verification:**
   - Installation: `[actual command]`
   - Run dev: `[actual command]`
   - Run tests: `[actual command]`

### Next Session Examples:

- "Follow the dev guide and continue current phase"
- "Follow the dev guide and work on phase 3.5"
- "Follow the dev guide and work on the highest priority item"

---

## Execution Philosophy

- **Comprehensive but not bureaucratic** - documentation serves developers
- **Adapt to project reality** - use actual tools, don't assume
- **Detect, don't prescribe** - see what's actually used
- **Working code over perfect docs** - but keep docs close behind
- **Clarity for the next developer** - could someone new get productive quickly?
- **Phase-based thinking** - organize work into coherent chunks
- **Standards serve the goal** - enable quality and speed

---

## Important Notes

### Self-Reference
**First action:** Save this entire prompt to `.claude/commands/setup-dev-guide.md` so it can be easily re-run or updated in future sessions.
