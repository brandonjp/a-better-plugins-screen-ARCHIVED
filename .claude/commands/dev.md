# /dev - A Better Plugins Screen (ABPS) Development Workflow

> WordPress plugin that transforms the plugins page into an intelligent management dashboard with link reordering, settings discovery, and real-time filtering.

---

## Quick Start

**Install:**
```bash
# Clone to WordPress plugins directory
cd /path/to/wordpress/wp-content/plugins/
git clone https://github.com/brandonjp/a-better-plugins-screen.git

# Or symlink for development
ln -s /path/to/repo /path/to/wordpress/wp-content/plugins/a-better-plugins-screen
```

**Activate:**
1. Go to WordPress Admin > Plugins
2. Find "A Better Plugins Screen" and click Activate
3. Visit the Plugins page to see enhancements

**Test/Debug:**
```javascript
// In browser console on plugins page
ABPS_API.enableDebug()  // Enable debug logging
ABPS_API.getInfo()      // Get current state
```

---

## Project Overview

| Property | Value |
|----------|-------|
| **Type** | WordPress Plugin |
| **Stack** | PHP 7.0+, Vanilla JavaScript (ES6+), CSS3 |
| **Version** | 1.0.0 |
| **Versioning** | Semantic Versioning (MAJOR.MINOR.PATCH) |
| **Build System** | None (no compilation required) |
| **Package Manager** | None |
| **Deployment** | WordPress.org / GitHub / Manual upload |
| **License** | GPLv3 |

### Project Structure

```
a-better-plugins-screen/
├── a_better_plugins_screen.php    # Main plugin file (WordPress entry point)
├── assets/
│   ├── js/
│   │   ├── abps-config.js         # Configuration system (3-layer)
│   │   ├── abps-storage.js        # localStorage management
│   │   ├── abps-discovery.js      # Settings page discovery algorithms
│   │   ├── abps-features.js       # Core features (reordering, filtering)
│   │   ├── abps-ui.js             # UI components and rendering
│   │   └── abps-main.js           # Entry point and coordination
│   └── css/
│       └── abps-main.css          # All styles
├── README.md                      # User documentation
├── readme.txt                     # WordPress.org readme
├── CHANGELOG.md                   # Version history
├── LICENSE                        # GPLv3 license
├── .gitignore                     # Git ignore rules
├── docs/
│   └── ROADMAP.md                 # Development roadmap
└── .claude/
    └── commands/
        ├── dev.md                 # This file
        ├── audit.md               # Project audit command
        └── setup-dev-guide.md     # Dev guide setup prompt
```

### Module Dependencies (JavaScript)

```
abps-main.js (entry point)
├── abps-config.js (Configuration - loads first, no deps)
├── abps-storage.js (Storage - loads first, no deps)
├── abps-discovery.js (depends on: config)
├── abps-features.js (depends on: config, storage, discovery)
└── abps-ui.js (depends on: config, storage, features)
```

### Key Configuration Files

| File | Purpose |
|------|---------|
| `a_better_plugins_screen.php` | WordPress plugin bootstrap, hooks, asset enqueueing |
| `abps-config.js` | Default config, manual settings dictionary, user preferences |
| `readme.txt` | WordPress.org plugin directory readme (follows WP standards) |

---

## Development Phases & Roadmap

### Phase Structure

Development is organized into phases. Each phase represents a coherent set of functionality.

**Phase Status Legend:**
- [x] Complete
- [ ] In Progress
- [ ] Planned
- [ ] Future Consideration

### Current Focus: Phase 1.1 - UX Enhancements

Improving the user experience with drag-and-drop link ordering and plugin tooltips.

### Phase History & Roadmap

| Phase | Name | Status | Version | Description |
|-------|------|--------|---------|-------------|
| 1.0 | Foundation | Complete | v1.0.0 | Core features: link reordering, settings discovery, filtering, config panel |
| 1.1 | UX Enhancements | Planned | v1.1.0 | Drag-and-drop, tooltips, visual indicators |
| 1.2 | Update Management | Planned | v1.2.0 | Plugin update controls, auto-update settings |
| 2.0 | Advanced Features | Future | v2.0.0 | Bulk upload, git installation, dependency management |

**See `docs/ROADMAP.md` for detailed phase breakdown.**

**To work on a specific phase:** "Follow the dev guide and work on phase 1.1"

---

## What to Work On

**Priority Order:**

1. **[Phase 1.1]** Implement drag-and-drop link reordering
2. **[Phase 1.1]** Add plugin information tooltips
3. **[Phase 1.1]** Enhanced visual indicators for discovered vs. existing settings
4. **[Ongoing]** Expand manual settings dictionary with more plugins

**Quick Links:**
- See `docs/ROADMAP.md` for detailed phases and milestones
- See `CHANGELOG.md` for version history
- See [GitHub Issues](https://github.com/brandonjp/a-better-plugins-screen/issues) for bug reports

---

## Development Standards

### Code Quality

**PHP Standards:**
- Follow [WordPress Coding Standards](https://developer.wordpress.org/coding-standards/wordpress-coding-standards/php/)
- Use tabs for indentation (not spaces)
- Prefix all functions/classes with `abps_` or `ABPS_`
- Use proper escaping and sanitization

**JavaScript Standards:**
- ES6+ features (no jQuery dependency)
- Module pattern with IIFE
- Expose classes via `window.ABPSClassName`
- JSDoc comments for all public methods
- Use strict mode

**CSS Standards:**
- BEM-like naming: `.abps-component-element`
- Mobile-first responsive design
- Support for reduced motion and high contrast
- WordPress admin color scheme compatible

### User Experience

- **Zero configuration required** - works immediately on activation
- **Non-destructive** - no database modifications, uses localStorage
- **Frictionless** - minimize clicks to complete actions
- **Accessible** - WCAG AA compliant, full keyboard navigation
- **Mobile-responsive** - works on tablets and phones

### Version Management

**Strategy:** Semantic Versioning (MAJOR.MINOR.PATCH)
- MAJOR: Breaking changes
- MINOR: New features (backward compatible)
- PATCH: Bug fixes

**Version locations (keep synchronized):**

| File | Location | Line |
|------|----------|------|
| `a_better_plugins_screen.php` | Plugin header `Version:` | 7 |
| `a_better_plugins_screen.php` | `ABPS_VERSION` constant | 27 |
| `assets/js/abps-main.js` | `this.version` property | 16 |
| `assets/js/abps-config.js` | `ABPS_DEFAULTS.version` | 15 |
| `README.md` | Version badge | 3 |
| `readme.txt` | `Stable tag:` | 8 |
| `CHANGELOG.md` | Latest version entry | varies |

**Bump version when:**
- Any code change (JavaScript or PHP)
- Documentation updates that affect functionality
- Bug fixes

### Testing Strategy

**Current state:** No automated tests (visual testing only)

**Manual Testing Checklist:**
- [ ] Activate plugin on fresh WordPress install
- [ ] Verify all features work on plugins page
- [ ] Test with various plugins installed (5, 20, 50+)
- [ ] Check browser console for errors
- [ ] Test Settings panel toggle
- [ ] Test Edit Mode functionality
- [ ] Test search/filter with various terms
- [ ] Verify link reordering is consistent
- [ ] Test on mobile viewport
- [ ] Enable debug mode and verify logging

**Debug Commands:**
```javascript
ABPS_API.enableDebug()    // Enable console logging
ABPS_API.getInfo()        // Get current state
ABPS_API.exportSettings() // Export settings as JSON
ABPS_API.resetSettings()  // Reset to defaults (reloads page)
```

### Git Workflow

**Commit Format:** Conventional commits
```
feat: Add drag-and-drop link reordering
fix: Correct settings discovery for plugin-name
docs: Update README with new feature
refactor: Simplify link ordering logic
style: Format JavaScript files
chore: Update version to 1.1.0
```

**Branch Strategy:**
- `main` - Stable releases
- `develop` - Active development
- `feature/*` - New features
- `fix/*` - Bug fixes

**Required Before Commit:**
- [ ] Visual testing passes
- [ ] No console errors
- [ ] Version bumped if code changed
- [ ] CHANGELOG updated
- [ ] Documentation updated

### Documentation Standards

**Code Comments:**
- JSDoc for JavaScript functions
- PHPDoc for PHP functions
- Explain "why" not "what"

**File Headers:**
```javascript
/**
 * ABPS [Module Name]
 * [Brief description]
 *
 * @since 1.0.0
 */
```

---

## Key Files & Directories

| Path | Purpose | When to Modify |
|------|---------|----------------|
| `a_better_plugins_screen.php` | Plugin bootstrap, asset loading | Adding new assets, PHP hooks |
| `assets/js/abps-config.js` | Configuration, manual dictionary | Adding plugin URLs, changing defaults |
| `assets/js/abps-features.js` | Core feature logic | Modifying link reordering, filtering |
| `assets/js/abps-discovery.js` | Settings URL finder | Improving discovery algorithms |
| `assets/js/abps-ui.js` | UI components | Modifying settings panel, edit mode |
| `assets/js/abps-main.js` | Initialization, public API | Changing startup, adding API methods |
| `assets/css/abps-main.css` | All styles | Visual changes |
| `readme.txt` | WordPress.org readme | Before WordPress.org submissions |

---

## Development Workflow Steps

### Starting a Work Session

1. **Review current state:**
   ```bash
   git status
   git log --oneline -5
   ```

2. **Check documentation:**
   - Review `docs/ROADMAP.md` for current phase
   - Check `CHANGELOG.md` Unreleased section
   - Look for blockers or prerequisites

3. **Set up testing environment:**
   - Ensure WordPress dev site is running
   - Plugin is activated
   - Navigate to Plugins page
   - Open browser DevTools

4. **Enable debug mode:**
   ```javascript
   ABPS_API.enableDebug()
   ```

### During Development

1. **Make changes following standards above**
2. **Test frequently** - Refresh plugins page after JS/CSS changes
3. **Check browser console** for errors and debug output
4. **Test edge cases** - Many plugins, few plugins, various states

### Completing Work

1. **Verify no console errors**
2. **Update version number** in all 7 locations
3. **Update CHANGELOG.md** with changes
4. **Update ROADMAP.md** if phase milestone reached
5. **Commit with descriptive message:**
   ```bash
   git add .
   git commit -m "feat: Add [feature description]"
   ```
6. **Summarize** what was done and suggest next steps

---

## Common Tasks

### Adding a Plugin to the Manual Settings Dictionary

1. Open `assets/js/abps-config.js`
2. Find `MANUAL_SETTINGS_DICTIONARY` object (around line 113)
3. Add entry:
   ```javascript
   'plugin-slug': 'admin.php?page=settings_page'
   ```
4. Test discovery works correctly
5. Commit: `feat: Add [plugin-name] to settings dictionary`

### Adding a New Feature

1. Plan feature scope - document in ROADMAP if significant
2. Implement in appropriate module:
   - Core logic -> `abps-features.js`
   - UI components -> `abps-ui.js`
   - Configuration -> `abps-config.js`
3. Add feature flag in `ABPS_DEFAULTS.features` if toggleable
4. Update documentation
5. Add to CHANGELOG under Unreleased
6. Bump minor version

### Fixing a Bug

1. Reproduce the bug
2. Enable debug mode to gather information
3. Fix the issue
4. Verify fix doesn't break other features
5. Add to CHANGELOG under Unreleased > Fixed
6. Bump patch version

### Updating for New WordPress Version

1. Test plugin on new WordPress version
2. Update `Tested up to:` in:
   - `a_better_plugins_screen.php` (line 11)
   - `readme.txt` (line 6)
3. Test all features work correctly
4. Note compatibility in CHANGELOG

---

## Project-Specific Notes

### WordPress Plugin Requirements

- Plugin header must include all required fields
- `readme.txt` follows [WordPress.org standards](https://developer.wordpress.org/plugins/wordpress-org/how-your-readme-txt-works/)
- Text domain must match plugin slug: `a-better-plugins-screen`
- All user-facing strings must be translatable

### JavaScript Architecture

- **No jQuery dependency** - uses vanilla JavaScript only
- **Module pattern** - each file is an IIFE exposing to window
- **Three-layer configuration:**
  1. Defaults (immutable)
  2. Site config (`window.ABPS_CONFIG`)
  3. User preferences (localStorage)

### Data Storage

- All user data stored in browser localStorage
- Prefix: `abps_`
- Key data:
  - `abps_user_preferences` - Feature toggles, config
  - `abps_plugin_settings` - Per-plugin custom URLs, notes

### Settings Discovery Algorithm

Priority order (configurable):
1. Manual dictionary lookup
2. Plugin slug matching in admin menu
3. Plugin name matching
4. Filename matching
5. Filename variations (with/without hyphens, underscores)
6. Description scanning for settings links

---

## Troubleshooting

### Common Issues

**Features not appearing:**
- Check you're on the plugins page (`plugins.php`)
- Verify plugin is activated
- Check browser console for JavaScript errors
- Ensure JavaScript is enabled

**Settings link not found:**
- Check manual dictionary for the plugin
- Enable Edit Mode and add custom URL
- Submit issue for adding to dictionary

**Settings not saving:**
- Check localStorage is available and not full
- Try in incognito mode
- Check for browser extensions blocking storage

**Visual glitches:**
- Clear browser cache
- Check for CSS conflicts with other plugins
- Test in different browser

### Debug Information

```javascript
// Get complete state information
ABPS_API.getInfo()

// Check localStorage usage
ABPSStorage.getStorageSize()

// Export all data for debugging
ABPSStorage.exportAll()
```

---

## Resources & References

- **WordPress Plugin Handbook:** https://developer.wordpress.org/plugins/
- **WordPress Coding Standards:** https://developer.wordpress.org/coding-standards/
- **Plugin Directory README Standard:** https://developer.wordpress.org/plugins/wordpress-org/how-your-readme-txt-works/
- **Keep a Changelog:** https://keepachangelog.com/
- **Semantic Versioning:** https://semver.org/

---

*Last Updated: 2026-01-22*
*Run `/dev` to reference this workflow during development.*
