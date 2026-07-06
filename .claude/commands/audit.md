---
name: audit
description: Run a comprehensive housekeeping and documentation audit of this project
---

<!-- MANAGED BY shared-ai-docs — do not hand-edit here; edit the source in the shared-ai-docs repo and re-sync. Local formatters (Prettier, markdownlint, …) should leave this file alone. -->

# /audit - Universal Project Housekeeping & Documentation Audit

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
   - **For license-related files (LICENSE, COPYING, NOTICE):**
     - Record presence and filename only
     - Do **not** ingest, quote, or summarize full license text

3. **Git Repository Status**
   - Current branch (should be a feature branch for audit work, not main)
   - Uncommitted changes
   - Branch naming conventions in use
   - Remote configuration

---

## Phase 2: Universal Tasks (Apply to ALL projects)

### 1. Documentation Organization

**Root-level Documentation:**
- Ensure primary README exists and is comprehensive
- Verify CHANGELOG/HISTORY exists and is up-to-date
- Check for LICENSE file **or a clearly designated license reference**
- Look for CONTRIBUTING guidelines if collaborative project

**License Handling (Important):**
- If a LICENSE file exists, do **not** load or reproduce its contents
- If no LICENSE file exists:
  - Designate the intended license by **name and SPDX identifier**
  - Link to the canonical external license text (SPDX / OSI / official source)
  - This reference may live in README and/or LICENSE.md
- Do **not** generate or embed full license text unless explicitly instructed

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
- LICENSE / LICENSE.md (reference only, not contents)
- SECURITY.md
- API documentation
- Architecture/design documents

---

### 2. Version Consistency

**Check version numbers across all locations:**
- Package manifest (package.json, composer.json, pyproject.toml, Cargo.toml, etc.)
- Main source file headers/constants
- Documentation references
- Changelog entries
- README badges

**Verify versioning strategy:**
- Semantic versioning (MAJOR.MINOR.PATCH)
- CalVer (calendar-based)
- WordPress-style versioning
- Project-specific conventions

**Fix inconsistencies:**
- Identify canonical version source
- Update all other locations to match
- Document version locations in dev guide if not already

---

### 3. README Review & Enhancement

**Essential README Sections (adapt to project):**
- Project title and description
- Status badges (build, coverage, version, license, etc.)
- Quick start / installation instructions
- Basic usage examples
- Project structure overview
- Links to detailed documentation
- Contribution guidelines (or link to CONTRIBUTING.md)
- **License information (name + SPDX identifier + link; not full text)**
- Contact/support information

**Quality Checks:**
- All code examples are current and functional
- Links are not broken
- Installation instructions actually work
- Screenshots/diagrams are up-to-date (if present)

---

### 4. CHANGELOG Review

**Verify CHANGELOG follows conventions:**
- Keep a Changelog format (preferred)
- Or project's established format
- Entries are in reverse chronological order

**Check content:**
- Unreleased section exists for pending changes
- All significant changes are documented
- Version numbers match releases
- Dates are accurate

---

### 5. ROADMAP & TODO Review

**If ROADMAP.md exists:**
- Update completed items
- Remove obsolete planned items
- Ensure current phase is accurate
- Verify priorities are current

**If TODO.md or similar exists:**
- Remove completed items
- Update priorities
- Archive old/obsolete items

---

### 6. Git Workflow Verification

**Confirm feature branch workflow is documented:**
- Dev guide specifies feature branches are required
- Branch naming conventions are defined
- Merge and cleanup process is documented

**Current audit work:**
- This audit should be performed in a feature branch (e.g., `chore/project-audit`)
- Changes committed and merged following project's standard workflow

---

### 7. Configuration Files Audit

**Common files to check:**
- .gitignore (comprehensive for project type)
- .editorconfig (if used)
- Linter/formatter configs
- CI/CD configuration
- Environment example files (.env.example)

**Verify:**
- No sensitive data in tracked files
- Example configs are complete and documented
- Ignore patterns are appropriate

### 7b. Database Migration File Audit

**If the project uses numbered migration files (e.g., `app/migrations/`):**
- Verify that no migration file has been modified after being applied in production
- Each schema change (new table, new column, new index) must be in its own new numbered migration file
- **NEVER append new DDL to an already-applied migration.** The runner tracks versions by number — appended changes will be silently skipped. This caused a production outage in v1.31.1.
- Migration files should use `IF NOT EXISTS` for idempotency
- Check that migration file numbering is sequential with no gaps

---

### 8. Dev Guide & Commands Verification

**Check for `.claude/commands/dev.md` or equivalent:**
- If exists: verify accuracy and completeness
- If missing: recommend running setup-dev-guide

**Check for `.claude/commands/commit.md`:**
- If exists: verify it covers documentation updates, version bumps, testing, git housekeeping, and final verification
- If missing: create it using the standard pre-commit checklist template

**Dev guide should include:**
- Quick start commands
- Project overview
- Development standards
- Git workflow (including feature branches)
- Reference to `/commit` checklist in the "Completing Work" section
- Current priorities
- Key file locations

---

## Phase 3: Project-Type-Specific Tasks

### WordPress Projects
- Verify plugin/theme headers match version
- Check readme.txt (WordPress.org format) if applicable
- Validate text domain consistency
- Review hook documentation

### JavaScript/Node.js Projects
- Verify package.json is complete (description, keywords, repository, etc.)
- Check for outdated dependencies (note, don't auto-update)
- Review scripts section documentation
- Verify .nvmrc or engines field if applicable

### Python Projects
- Verify pyproject.toml / setup.py completeness
- Check requirements files are current
- Review __version__ consistency
- Verify virtual environment documentation

### PHP Projects (non-WordPress)
- Verify composer.json completeness
- Check PSR compliance documentation
- Review autoloading configuration

---

## Phase 4: Cleanup Tasks

### Remove Clutter
- Identify and flag unused files
- Find duplicate documentation
- Locate orphaned assets
- Check for development artifacts that shouldn't be committed

### Organize Structure
- Ensure consistent directory naming
- Move misplaced files
- Create missing standard directories
- Update .gitignore if needed

### Archive Old Content
- Move obsolete documentation to /docs/archive or similar
- Update references to archived content
- Don't delete without confirmation

---

## Output Requirements

### 1. Summary Report

Provide a clear summary including:

**Project Overview:**
- Project type detected
- Primary language/framework
- Build system identified

**Version Status:**
- Current version found
- Version consistency (pass/fail)
- Locations checked

**Documentation Status:**
- Files audited
- Files modified
- Files created
- Files recommended for creation

**Commands Status:**
- `dev.md` exists and is current (yes/no)
- `commit.md` exists and is current (yes/no)
- Other commands present

**Git Workflow Status:**
- Feature branch workflow documented (yes/no)
- Current branch during audit

**Issues Found:**
- Critical issues (blocking)
- Warnings (should fix)
- Suggestions (nice to have)

**Changes Made:**
- List of files modified with brief description
- List of files created

**Recommendations:**
- Prioritized list of remaining tasks
- Suggested next steps

**Do not include or quote full license text in the summary**

---

### 2. Commit Changes

After completing audit:
- Stage all changes
- Commit with descriptive message: `chore: project documentation audit and cleanup`
- If on feature branch, note ready for merge
- List files changed in commit

---

## Execution Notes

- Be thorough but pragmatic
- Preserve project conventions
- Detect actual tools used
- When in doubt, document
- **Avoid ingesting large legal or third-party license texts**
- Think about the next developer
- **Perform audit work in a feature branch, not directly on main**

---

## Audit Checklist

Use this for quick reference:

- [ ] Project type identified
- [ ] All documentation files located
- [ ] Version consistency verified
- [ ] README reviewed and complete
- [ ] CHANGELOG current
- [ ] ROADMAP/TODO updated
- [ ] Git workflow documented (including feature branches)
- [ ] Config files audited
- [ ] Dev guide exists and is accurate
- [ ] Pre-commit checklist (`commit.md`) exists and is accurate
- [ ] Clutter identified/removed
- [ ] Structure organized
- [ ] Summary report generated
- [ ] Changes committed (in feature branch)

---

*Last Updated: 2026-02-16*
*Run `/audit` to perform a comprehensive project documentation audit.*
