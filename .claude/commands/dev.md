# A Better Plugins Screen - Development Guide

## Project Overview

**A Better Plugins Screen (ABPS)** is a WordPress plugin that enhances the WordPress plugins management page with intelligent link reordering, settings discovery, real-time filtering, and configuration options.

**Current Version:** 1.0.0
**License:** GPLv3

## Quick Start

1. Clone the repository to your WordPress plugins directory:
   ```bash
   cd /path/to/wordpress/wp-content/plugins/
   git clone https://github.com/brandonjp/a-better-plugins-screen.git
   ```

2. Activate the plugin in WordPress Admin > Plugins

3. Visit the Plugins page to see the enhancements

## Architecture

### Technology Stack

- **Backend:** PHP 7.0+ (WordPress plugin)
- **Frontend:** Vanilla JavaScript (ES6+, no jQuery dependency)
- **Styling:** CSS3
- **Build System:** None (no compilation required)

### File Structure

```
a-better-plugins-screen/
├── a_better_plugins_screen.php    # Main plugin file (entry point)
├── assets/
│   ├── js/
│   │   ├── abps-config.js         # Configuration system
│   │   ├── abps-storage.js        # localStorage management
│   │   ├── abps-discovery.js      # Settings page discovery
│   │   ├── abps-features.js       # Core feature implementation
│   │   ├── abps-ui.js             # UI components and rendering
│   │   └── abps-main.js           # Entry point and coordination
│   └── css/
│       └── abps-main.css          # All styles
├── README.md                      # User documentation
├── readme.txt                     # WordPress.org readme
├── CHANGELOG.md                   # Version history
├── LICENSE                        # GPLv3 license
└── .claude/
    └── commands/
        ├── dev.md                 # This file
        └── audit.md               # Project audit command
```

### Module Dependencies

```
abps-main.js (entry point)
├── abps-config.js (Configuration - loads first)
├── abps-storage.js (Storage - loads first)
├── abps-discovery.js (depends on config)
├── abps-features.js (depends on config, storage, discovery)
└── abps-ui.js (depends on config, storage, features)
```

### Key Files

| File | Purpose |
|------|---------|
| `a_better_plugins_screen.php` | WordPress plugin bootstrap, asset enqueueing |
| `abps-config.js` | Three-layer config: defaults, site config, user prefs |
| `abps-storage.js` | localStorage abstraction with prefix management |
| `abps-discovery.js` | Intelligent settings page finder (multiple strategies) |
| `abps-features.js` | Link reordering, duplicate detection, edit mode |
| `abps-ui.js` | Settings panel, notifications, DOM manipulation |
| `abps-main.js` | ABPS class, initialization, public API |

## Development Standards

### Code Quality

- Follow WordPress Coding Standards (PHP)
- Use ES6+ JavaScript features
- No jQuery dependency (vanilla JS only)
- Accessible by default (WCAG AA)
- Mobile-responsive design

### Versioning

**Version locations (keep synchronized):**
1. `a_better_plugins_screen.php` - Plugin header (line 7)
2. `a_better_plugins_screen.php` - `ABPS_VERSION` constant (line 27)
3. `abps-main.js` - `this.version` property (line 16)
4. `README.md` - Version badge (line 3)
5. `readme.txt` - Stable tag (line 8)
6. `CHANGELOG.md` - Latest version entry

**Versioning scheme:** Semantic Versioning (MAJOR.MINOR.PATCH)

### Commit Messages

Use descriptive commit messages:
- `feat:` New features
- `fix:` Bug fixes
- `docs:` Documentation changes
- `refactor:` Code restructuring
- `style:` Formatting, no code change
- `chore:` Maintenance tasks

## Common Tasks

### Adding a Plugin to the Manual Settings Dictionary

1. Open `assets/js/abps-config.js`
2. Find `MANUAL_SETTINGS_DICTIONARY`
3. Add entry in format: `'plugin-slug': 'admin.php?page=settings_page'`
4. Test the discovery works correctly

### Adding a New Feature

1. Implement in `abps-features.js` if it's a core feature
2. Add UI controls in `abps-ui.js` if needed
3. Add configuration option in `abps-config.js`
4. Update documentation

### Testing

- No automated tests currently (vanilla JS, visual testing)
- Test on WordPress 5.0+ with PHP 7.0+
- Test with various plugins installed
- Check browser console for errors

### Debugging

```javascript
// Enable debug mode in browser console
ABPS_API.enableDebug()

// Get current state
ABPS_API.getInfo()

// Export settings
ABPS_API.exportSettings()
```

## Roadmap

### Planned for 1.1.0
- Drag-and-drop link reordering
- Plugin information tooltips
- Enhanced visual indicators

### Planned for 1.2.0
- Plugin update management
- Auto-update controls per plugin

### Planned for 2.0.0
- Bulk plugin upload integration
- Git repository installation
- Plugin dependency management

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes following the coding standards
4. Test thoroughly
5. Submit a pull request

## How to Continue Development

**Next development priorities:**

1. Add more plugins to the manual settings dictionary
2. Implement drag-and-drop link reordering (Roadmap 1.1.0)
3. Add plugin tooltips with metadata
4. Consider adding automated testing

**To start a development session:**

1. Ensure WordPress dev environment is set up
2. Symlink or copy plugin to wp-content/plugins/
3. Activate plugin and navigate to Plugins page
4. Open browser DevTools for console output
5. Enable debug mode: `ABPS_API.enableDebug()`
