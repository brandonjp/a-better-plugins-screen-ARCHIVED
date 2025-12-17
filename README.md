# ⚡ A Better Plugins Screen (ABPS)

**Version 1.0.1** - Transform your WordPress plugins page into an intelligent management dashboard

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

## 💡 How to Use

### What Does This Plugin Do?

**A Better Plugins Screen** enhances your WordPress Plugins page with these immediate improvements:

1. **🔍 Enhanced Search** - Replaces the default WordPress search with a powerful real-time filter that searches plugin names, descriptions, authors, and slugs instantly
2. **🔗 Consistent Link Order** - All plugins show action links in the same order (Deactivate | Settings | Other links)
3. **⚡ Automatic Settings Discovery** - Finds plugin settings pages automatically, even when plugins don't provide a Settings link
4. **✏️ Edit Mode** - Customize individual plugins with custom settings URLs and personal notes
5. **⚙️ Configuration** - Adjust all features through an easy-to-use settings panel

### Quick Start (Zero Configuration!)

**No setup required!** Just activate the plugin and visit your Plugins page (`/wp-admin/plugins.php`).

You'll immediately see:
- ✅ A search box at the top that says "Search plugins (powered by A Better Plugins Screen)"
- ✅ All plugin action links in consistent order: **Deactivate | Settings | ...**
- ✅ Settings links automatically added to plugins that were missing them
- ✅ "Settings | Edit Mode" links in the ABPS plugin row

### Using the Search Feature

The search box appears where the native WordPress search used to be.

**To search:**
1. Type anything in the search box
2. Results filter instantly (no page reload!)
3. Searches: Plugin names, descriptions, authors, slugs
4. Press **ESC** or click the **×** button to clear

**Example searches:**
- Type "security" to find all security-related plugins
- Type "editor" to find content editors
- Type "author name" to find all plugins by that author

### Using Edit Mode

Edit Mode lets you customize individual plugins:

**To enable Edit Mode:**
1. Find "A Better Plugins Screen" in your plugin list
2. Click **Edit Mode** in its action links
3. Edit controls appear below each visible plugin

**What you can do:**
- **Custom Settings URL**: Override the settings link with your own URL
- **Notes**: Add personal notes about each plugin (reminders, configuration notes, etc.)

**To exit Edit Mode:**
- Click **Exit Edit Mode** in the ABPS plugin row

**Important:**
- Edit controls only show for visible (not filtered) plugins
- If you filter first, then enable edit mode: Only filtered plugins show controls
- If you enable edit mode first, then filter: Controls hide for filtered-out plugins

### Configuration Panel

Access advanced settings:

**To open settings:**
1. Find "A Better Plugins Screen" in your plugin list
2. Click **Settings** in its action links
3. The configuration panel appears above the plugin list

**Available settings:**
- **Features Toggle** - Enable/disable individual features
- **Link Order** - Customize default link ordering (future feature)
- **Filter Settings** - Configure search behavior
- **Import/Export** - Share settings across sites or backup your config
- **Debug Mode** - Enable console logging for troubleshooting

**To close settings:**
- Click **Settings** again or just close the panel

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
├── vendor/                        # Composer dependencies
├── README.md
├── readme.txt                     # WordPress.org readme
└── LICENSE
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

# Install dependencies
composer install

# Link to WordPress plugins directory
ln -s $(pwd) /path/to/wordpress/wp-content/plugins/
```

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

### Version 1.0.1 (December 2025)

🐛 **Bug Fixes & UX Improvements**

**Fixed:**
- Search box now appears in native WordPress location (not below)
- Edit mode controls properly hide when parent plugin is filtered
- Duplicate search boxes no longer appear
- Proper spacing between ABPS action links (Deactivate | Settings | Edit Mode)
- Update notification rows properly hide during filtering
- Navigation links no longer appear between search forms

**Improved:**
- Search box matches native WordPress styling (280px width, proper padding)
- Edit mode message clarified: "edit controls displayed below each plugin"
- Better state management for edit rows during filtering
- Works correctly in both workflows: Filter→Edit Mode and Edit Mode→Filter

See [CHANGELOG.md](CHANGELOG.md) for complete details.

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

## 🗺️ Roadmap

### Future Features (Not in v1.0)

- 🎯 Drag-and-drop link reordering
- 🔔 Plugin update management
- 💬 Plugin tooltips with metadata
- 📦 Bulk operations
- 🔗 Git repository installation
- 📊 Plugin usage analytics
- 🔐 Plugin dependency management

---

**Made with ❤️ for the WordPress community**
