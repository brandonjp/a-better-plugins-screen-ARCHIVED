# ⚡ A Better Plugins Screen (ABPS)

**Version 1.0.0** - Transform your WordPress plugins page into an intelligent management dashboard

[![WordPress Plugin Version](https://img.shields.io/badge/WordPress-5.0%2B-blue.svg)](https://wordpress.org/)
[![PHP Version](https://img.shields.io/badge/PHP-7.0%2B-purple.svg)](https://php.net/)
[![License](https://img.shields.io/badge/License-GPLv3-green.svg)](LICENSE)

## 📖 Overview

**A Better Plugins Screen** dramatically improves the WordPress plugin management experience with intelligent enhancements that work immediately upon activation. No configuration required!

Stop hunting for plugin settings. Stop dealing with inconsistent link orders. Start managing plugins efficiently.

## ✨ Key Features

### 🔗 Intelligent Link Reordering
Action links are now in a **consistent, predictable order** across all plugins:
- **Deactivate** always first
- **Settings** always second
- Other links follow logically
- No more hunting for common actions!

### 🔍 Automatic Settings Discovery
ABPS automatically finds plugin settings pages even when plugins don't provide links. Uses multiple intelligent search methods:
- Manual dictionary lookup
- Plugin slug matching
- Plugin name matching
- Filename matching with variations
- Description scanning

If settings can't be found, it clearly shows "No Settings Found" so you know it tried.

### ⚡ Real-Time Plugin Filtering
Instantly search and filter your plugin list:
- Search by name, slug, description, or author
- No page reloads
- Debounced for performance
- Keyboard accessible (ESC to clear)

### ⚙️ Configuration Panel
Easy-to-use settings panel accessible from the plugins page:
- Toggle features on/off
- Configure behavior
- Export/import settings
- Reset to defaults
- All changes saved per-user

### ✏️ Edit Mode
Power users can customize individual plugins:
- Add custom settings URLs
- Create plugin notes
- Organize with tags
- All stored in localStorage (per-user)

### 🎨 Modern Architecture
- **Vanilla JavaScript** - No jQuery dependency
- **Modular design** - Clean, maintainable code
- **Accessible** - WCAG AA compliant
- **Responsive** - Works on mobile/tablet
- **Non-destructive** - No database changes

## 🚀 Installation

### From WordPress Admin

1. Go to **Plugins > Add New**
2. Search for **"A Better Plugins Screen"**
3. Click **Install Now** then **Activate**
4. Visit your **Plugins page** to see the improvements!

### From GitHub

```bash
cd wp-content/plugins/
git clone https://github.com/brandonjp/a-better-plugins-screen.git
```

Then activate through the WordPress admin.

### Manual Installation

1. Download the [latest release](https://github.com/brandonjp/a-better-plugins-screen/releases)
2. Upload to `/wp-content/plugins/`
3. Activate through the Plugins menu

## 💡 Usage

### Basic Usage

**No configuration required!** Just activate the plugin and visit your Plugins page.

You'll immediately see:
- ✅ Consistent link ordering
- ✅ Auto-discovered settings links
- ✅ Real-time search box
- ✅ ABPS Settings button

### Configuration Panel

Click the **⚙️ ABPS Settings** button to access:

- **Features Toggle** - Enable/disable individual features
- **Link Order** - Customize default link ordering
- **Filter Settings** - Configure search behavior
- **Import/Export** - Share settings across sites
- **Debug Mode** - Enable console logging

### Edit Mode

1. Click **Edit Mode** in the ABPS plugin row
2. Hover over any plugin to see edit controls
3. Add custom settings URLs
4. Add notes for organization
5. Changes save automatically to localStorage

### JavaScript API

ABPS exposes a public API for developers:

```javascript
// Get ABPS information
ABPS_API.getInfo()

// Enable debug mode
ABPS_API.enableDebug()

// Export settings
const settings = ABPS_API.exportSettings()

// Import settings
ABPS_API.importSettings(jsonString)

// Reset to defaults
ABPS_API.resetSettings()
```

## 🏗️ Architecture

### File Structure

```
a-better-plugins-screen/
├── a_better_plugins_screen.php    # Main plugin file
├── assets/
│   ├── js/
│   │   ├── abps-config.js         # Configuration system
│   │   ├── abps-storage.js        # localStorage management
│   │   ├── abps-discovery.js      # Settings discovery
│   │   ├── abps-features.js       # Core features
│   │   ├── abps-ui.js             # UI rendering
│   │   └── abps-main.js           # Initialization
│   └── css/
│       └── abps-main.css          # Styles
├── docs/
│   └── ROADMAP.md                 # Development roadmap
├── .claude/
│   └── commands/
│       ├── dev.md                 # Development workflow guide
│       ├── audit.md               # Project audit command
│       └── setup-dev-guide.md     # Dev guide setup prompt
├── README.md                      # This file
├── readme.txt                     # WordPress.org readme
├── CHANGELOG.md                   # Version history
├── LICENSE                        # GPLv3 license
└── .gitignore                     # Git ignore rules
```

### Module Dependencies

```
abps-main.js
├── abps-config.js (Configuration)
├── abps-storage.js (Storage)
├── abps-discovery.js (Settings Discovery)
│   └── abps-config.js
├── abps-features.js (Core Features)
│   ├── abps-config.js
│   ├── abps-storage.js
│   └── abps-discovery.js
└── abps-ui.js (User Interface)
    ├── abps-config.js
    ├── abps-storage.js
    └── abps-features.js
```

## 🔧 Configuration

### Site-Wide Configuration

Create a configuration file or add to `functions.php`:

```javascript
window.ABPS_CONFIG = {
    features: {
        linkReordering: true,
        settingsDiscovery: true,
        pluginFiltering: true,
        editMode: true
    },
    customSettingsMaps: {
        'my-plugin': 'admin.php?page=my-settings'
    },
    filterBox: {
        placeholder: 'Search plugins...',
        searchableFields: ['name', 'slug', 'description']
    }
};
```

### Per-User Settings

All user preferences are automatically saved to localStorage:
- Feature toggles
- Custom plugin URLs
- Plugin notes
- Link order preferences

## 🤝 Contributing

We welcome contributions!

### Adding Plugins to Dictionary

If a plugin's settings aren't found, you can add it to the manual dictionary:

1. Fork the repository
2. Edit `assets/js/abps-config.js`
3. Add to `MANUAL_SETTINGS_DICTIONARY`:
   ```javascript
   'plugin-slug': 'admin.php?page=plugin_settings'
   ```
4. Submit a pull request

### Reporting Issues

Found a bug or have a feature request?

- [Create an issue](https://github.com/brandonjp/a-better-plugins-screen/issues)
- Include WordPress version
- Include PHP version
- Describe expected vs actual behavior

### Development Setup

```bash
# Clone repository
git clone https://github.com/brandonjp/a-better-plugins-screen.git
cd a-better-plugins-screen

# Link to WordPress plugins directory
ln -s $(pwd) /path/to/wordpress/wp-content/plugins/

# Or copy directly
cp -r a-better-plugins-screen /path/to/wordpress/wp-content/plugins/
```

### Development Workflow

For complete development documentation, see:
- **[`.claude/commands/dev.md`](.claude/commands/dev.md)** - Full development workflow guide with standards, testing checklist, and troubleshooting
- **[`docs/ROADMAP.md`](docs/ROADMAP.md)** - Phase-based development roadmap

## 📋 Requirements

- **WordPress:** 5.0 or higher
- **PHP:** 7.0 or higher
- **Browser:** Modern browsers (Chrome, Firefox, Safari, Edge)
- **JavaScript:** Enabled

## 🐛 Troubleshooting

### Settings Link Not Found

**Problem:** A plugin's settings link isn't showing

**Solutions:**
1. Enable Edit Mode and add custom URL
2. [Submit an issue](https://github.com/brandonjp/a-better-plugins-screen/issues) with plugin details

### Features Not Working

**Problem:** ABPS features aren't appearing

**Solutions:**
1. Check browser console for errors
2. Enable debug mode: `ABPS_API.enableDebug()`
3. Verify you're on the plugins page
4. Check WordPress and PHP versions meet requirements

### localStorage Errors

**Problem:** Settings not saving

**Solutions:**
1. Check browser allows localStorage
2. Check available storage space
3. Try private/incognito mode to test

## 🔐 Privacy & Security

### Data Collection

**ABPS does not collect any data.** All settings are stored locally in your browser's localStorage.

### Security Features

- ✅ No external API calls
- ✅ No database modifications
- ✅ Nonce verification for AJAX
- ✅ Capability checks for admin access
- ✅ Sanitized user inputs
- ✅ No eval() or similar functions

## 📜 License

This project is licensed under the **GNU General Public License v3.0** - see the [LICENSE](LICENSE) file for details.

## 👤 Author

**Brandon Pfeiffer**
- Website: [brandonjp.com](http://brandonjp.com)
- GitHub: [@brandonjp](https://github.com/brandonjp)

## 💝 Support

If you find this plugin helpful:

- ⭐ Star the repository
- 🐛 [Report issues](https://github.com/brandonjp/a-better-plugins-screen/issues)
- 💰 [Donate via PayPal](https://paypal.me/brandonjp)
- 📝 Write a review on WordPress.org

## 📚 Changelog

### Version 1.0.0 (November 2025)

🎉 **Major Release - Complete Rewrite**

**New Features:**
- Real-time plugin filtering
- Configuration panel with UI
- Edit mode for customization
- Import/export settings
- Enhanced settings discovery
- Vanilla JavaScript (no jQuery)
- Accessibility improvements
- Mobile responsive design

**Technical Changes:**
- Modular architecture
- localStorage-based storage
- Better performance
- Improved code quality
- PHP 7.0+ and WordPress 5.0+ required

See [CHANGELOG.md](CHANGELOG.md) for complete version history.

## 🗺️ Roadmap

See **[`docs/ROADMAP.md`](docs/ROADMAP.md)** for detailed phase-based roadmap.

### Upcoming Features

**Phase 1.1 - UX Enhancements (Planned for v1.1.0):**
- 🎯 Drag-and-drop link reordering
- 💬 Plugin tooltips with metadata
- Enhanced visual indicators

**Phase 1.2 - Update Management (Planned for v1.2.0):**
- 🔔 Plugin update management
- Auto-update controls per plugin

**Phase 2.0 - Advanced Features (Future):**
- 📦 Bulk operations
- 🔗 Git repository installation
- 🔐 Plugin dependency management

---

**Made with ❤️ for the WordPress community**
