# Universal Project Housekeeping & Documentation Audit

**Run a comprehensive audit and cleanup of this project's documentation and structure.**

**This directive is a GUIDE. First analyze this codebase thoroughly to understand its project type, structure, tooling, and needs. Then apply these principles appropriately.**

---

## IMPORTANT: Save This Prompt for Future Use

**On first run, save this entire prompt to `.claude/commands/audit.md` in this project.**

This allows future sessions to simply say "Run a project audit" without needing to paste this full prompt again.

---

## Phase 1: Project Analysis

**Automatically detect and document:**

1. **Project Type Identification**
   - Language(s): Python, PHP, JavaScript/TypeScript, Java, Go, Rust, etc.
   - Framework(s): React, Next.js, WordPress, Django, Flask, Laravel, Spring Boot, etc.
   - Build system: npm/yarn/pnpm/bun, Composer, pip/Poetry, Maven/Gradle, Cargo, etc.
   - Monorepo or single project structure

2. **Existing Documentation Audit**
   - List all documentation files found (README, CHANGELOG, etc.)
   - Note documentation format conventions being used
   - Identify the project's documentation standards (if any)

---

## Phase 2: Universal Tasks (Apply to ALL projects)

### 1. Documentation Organization

**Root-level Documentation:**
- Ensure primary README exists and is comprehensive
- Verify CHANGELOG/HISTORY exists and is up-to-date
- Check for LICENSE file
- Look for CONTRIBUTING guidelines if collaborative project

**Documentation Directory Structure:**
- Review `/docs`, `/documentation`, or equivalent
- Identify and remove duplicate content
- Move misplaced files to logical locations
- Create clear directory hierarchy if documentation is scattered

**Common Documentation Files to Audit:**
- README.md / README.rst / README.txt
- CHANGELOG.md / HISTORY.md / CHANGES.md
- ROADMAP.md / TODO.md
- CONTRIBUTING.md
- LICENSE / LICENSE.md
- SECURITY.md
- API documentation
- Architecture/design documents

### 2. Version Consistency

**Identify all version sources in the project:**
- Configuration files (package.json, composer.json, pyproject.toml, Cargo.toml, pom.xml, etc.)
- Plugin/module headers (WordPress plugins, Python modules, etc.)
- Documentation references (README, CHANGELOG)
- Version constants in source code
- Git tags

**Verify and synchronize:**
- All version numbers match across files
- CHANGELOG latest entry matches current version
- ROADMAP/TODO completed sections reflect current version
- Update version if changes warrant it
- Document version bumping strategy if unclear

### 3. README Review & Enhancement

**Essential README Sections (adapt to project):**
- Project title and description
- Status badges (build, coverage, version, license, etc.)
- Quick start / installation instructions
- Basic usage examples
- Project structure overview
- Links to detailed documentation
- Contribution guidelines (or link to CONTRIBUTING.md)
- License information
- Contact/support information

**Verify:**
- All links work (internal and external)
- Installation steps are current and accurate
- Examples run without errors
- Project structure diagram matches reality
- Technology stack is clearly stated

### 4. Progress Tracking & Roadmap

**ROADMAP.md / TODO.md Review:**
- Move completed items to appropriate sections
- Remove or update stale items
- Ensure "In Progress" reflects current work
- Version milestones align with actual releases
- Consider moving detailed tasks to issue tracker

**CHANGELOG.md Verification:**
- Follows consistent format (Keep a Changelog, conventional commits, etc.)
- Latest changes are documented
- Each version has a date
- Breaking changes are clearly marked
- Links to commits/PRs if applicable

### 5. Developer Workflow & Onboarding

**Development Guide Verification:**
- **Check for `.claude/commands/dev.md`** - This is the primary development workflow document
- If missing or inadequate, flag for creation
- If present, verify it contains:
  - Project overview and quick start
  - Clear phase-based roadmap reference
  - Development standards (code quality, testing, versioning, commits)
  - Key files documentation
  - Common tasks workflow
  - "How to continue development" guidance

**Quick Start Validation:**
- Test that setup instructions actually work
- Verify prerequisites are clearly listed
- Check that environment setup steps are complete
- Ensure development workflow is documented and accessible

**Developer Documentation:**
- Code style guidelines (or reference to them)
- Testing instructions and commands
- Build/deployment process
- Architecture overview
- Key file/directory explanations
- Common troubleshooting issues

**Workflow Accessibility:**
- Can a new developer (human or AI) get started quickly?
- Is it clear what to work on next?
- Are development standards easy to find and follow?
- Can you easily reference specific work phases? (e.g., "work on phase 3.5")

### 6. Cleanup & Maintenance

**Remove or Fix:**
- Stale or orphaned documentation
- Broken internal links
- Outdated screenshots or examples
- Redundant or conflicting information
- Old script references that no longer exist
- TODOs embedded in documentation that belong in issue tracker

**File Organization:**
- Ensure consistent naming conventions
- Move documentation to standard locations
- Create .gitignore or equivalent if missing
- Check for sensitive data in documentation

### 7. CI/CD Health Check

**If CI configuration exists:**
- Check `.github/workflows/`, `.gitlab-ci.yml`, etc.
- Verify CI runs are reasonably fast (under 5 minutes ideal)
- Check if testing multiple language versions unnecessarily
- Ensure it tests appropriate things for the project
- **Verify test failure reporting:** Check if CI outputs detailed, AI-friendly failure summaries when tests fail (test names, file locations, error messages, stack traces, environment info, reproduce commands). If not, recommend adding this.

**If CI is Missing:**
- Note in recommendations if project would benefit from pragmatic CI

**If CI is Problematic:**
- Identify slow-running workflows
- Note unnecessary complexity
- Suggest simplification if warranted
- Check if test failures are difficult to debug (missing detailed output)

---

## Phase 3: Project-Type-Specific Tasks

### For JavaScript/TypeScript Projects (React, Next.js, Node.js, etc.)

**Configuration Files:**
- package.json: Verify scripts, dependencies, version
- Detect package manager (npm/yarn/pnpm/bun) and document it
- tsconfig.json / jsconfig.json: Check for outdated settings
- .eslintrc / .prettierrc: Ensure coding standards are documented

**Documentation:**
- Component documentation (if React/Vue)
- API endpoint documentation (if backend)
- Environment variables documentation (.env.example)
- Deployment guide

**Scripts:**
- Verify all package manager scripts work
- Document custom scripts in README
- Check build/test/deploy pipelines

### For PHP Projects (WordPress, Laravel, etc.)

**Configuration Files:**
- composer.json: Verify dependencies, version, scripts
- WordPress plugin/theme headers: Match version numbers
- .env.example: Document all required environment variables

**WordPress-Specific:**
- Plugin/Theme header comments are accurate and follow WordPress standards
- readme.txt follows WordPress.org standards if applicable
- Installation instructions cover WordPress-specific steps
- Hooks/filters are documented
- Shortcodes are documented
- Coding standards: Note if following WordPress Coding Standards (WPCS)
- PHPCS configuration for WordPress standards if applicable

**Laravel-Specific:**
- Artisan commands documented
- Service providers listed
- Middleware explained
- Configuration files documented

### For Python Projects (Django, Flask, CLI tools, etc.)

**Configuration Files:**
- setup.py / setup.cfg / pyproject.toml: Verify metadata, version
- requirements.txt / Pipfile / poetry.lock: Check dependencies
- Detect dependency manager (pip/pipenv/poetry) and document it
- .python-version: Document Python version requirements

**Module Documentation:**
- Ensure __init__.py files have docstrings
- Verify module-level documentation
- Check that CLI commands are documented (if applicable)

**Django-Specific:**
- settings.py configuration documented
- URL patterns explained
- Management commands documented
- Migration strategy explained

### For Other Project Types

**Adapt the above patterns to:**
- Java (Maven/Gradle, Spring Boot)
- Go (go.mod, module documentation)
- Rust (Cargo.toml, crate documentation)
- Ruby (Gemfile, Rails)
- .NET (csproj, NuGet)

---

## Phase 4: Quality Assurance

**Before finalizing:**

1. **Run Available Linters/Validators**
   - Use whatever linters are configured in the project
   - Markdown linters if available
   - Link checkers if available

2. **Verify Key Workflows**
   - Installation steps work from scratch
   - Build process completes successfully
   - Tests run (if test command exists)
   - Key scripts execute without errors

3. **Consistency Check**
   - Terminology is consistent across documents
   - File naming follows project conventions
   - Code examples use consistent style
   - Version references are synchronized

---

## Output Requirements

### 1. Summary Report

Provide a clear summary including:
- **Project type detected:** [Language/Framework/Tools]
- **Version status:** Current version, whether bumped, rationale
- **Files modified:** List of changed documentation files
- **Dev guide status:** Present/Missing/Needs improvement - Action taken or recommended
- **CI/CD status:** Present and reasonable / Present but needs optimization / Missing / Not applicable
- **Issues found and fixed:** Categorized list
- **Issues found but not fixed:** With explanation why
- **Recommendations:** Suggestions for improvement

### 2. Commit Strategy

- **Commit all changes** with descriptive message following project's commit convention
- If version bumped, update all relevant files and tag if appropriate
- Keep documentation changes in logical, atomic commits if multiple areas affected

### 3. Next Steps

**Suggest the next development priority:**
- Based on ROADMAP/TODO if available
- Based on incomplete documentation areas
- Based on code debt identified during audit
- Provide a clear, actionable prompt for the next session

---

## Success Criteria

- All documentation is organized and up-to-date
- Version numbers are consistent across the project
- README provides clear project overview and getting started guide
- CHANGELOG reflects actual project history
- No broken links in documentation
- Development workflow guide exists and is comprehensive (`.claude/commands/dev.md`)
- Developer onboarding is smooth and complete
- Stale/redundant documentation is removed
- Project structure is clear and logical
- Next development steps are clearly identified
- CI/CD is appropriate for project stage
- This audit prompt is saved to `.claude/commands/audit.md` for future use

---

## Execution Notes

- **Be thorough but pragmatic** - fix what matters, note what's optional
- **Preserve project conventions** - adapt to existing patterns rather than imposing new ones
- **Detect actual tools used** - don't assume npm when they use bun, don't assume pip when they use poetry
- **When in doubt, document** - better to over-communicate than under-communicate
- **Think about the next developer** - would someone new understand this project?
- **First action: Save this prompt to `.claude/commands/audit.md`** for future reference
