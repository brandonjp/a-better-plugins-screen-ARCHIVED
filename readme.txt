=== A Better Plugins Screen ===
Contributors: brandonjp
Tags: plugins, admin, settings, management, ux
Donate link: https://paypal.me/brandonjp
Requires at least: 5.0
Tested up to: 6.4
Requires PHP: 7.0
Stable tag: 1.0.0
License: GPLv3 or later
License URI: https://www.gnu.org/licenses/gpl-3.0.html

Transform the WordPress plugins page into an intelligent, intuitive management dashboard with zero configuration required. 

== Description ==

**A Better Plugins Screen (ABPS)** dramatically improves the WordPress plugin management experience with intelligent enhancements that work immediately upon activation.

= 🚀 Key Features =

**✨ Zero Configuration Required**
Works perfectly out of the box. No setup, no configuration files to edit. Just activate and enjoy the improvements!

**🔗 Intelligent Link Reordering**
Action links (Deactivate, Settings, etc.) are now in a consistent, predictable order across all plugins. No more hunting for the Deactivate or Settings link!

**🔍 Automatic Settings Discovery**
ABPS automatically finds plugin settings pages even when plugins don't provide links. Uses multiple intelligent search methods to locate hidden configuration pages.

**⚡ Real-Time Plugin Filtering**
Instantly search and filter your plugin list by name, slug, description, or author. No page reloads, no waiting.

**⚙️ Configuration Panel**
Easy-to-use settings panel lets you customize features, export/import settings, and control ABPS behavior without editing files.

**✏️ Edit Mode**
Power users can customize individual plugin settings, add custom URLs, and create notes - all stored per-user in localStorage.

= 🎯 Perfect For =

* WordPress administrators managing multiple plugins
* Development teams with custom plugin dependencies
* Agency personnel managing client sites
* Anyone frustrated with the default plugins page UX

= 💡 How It Works =

ABPS enhances the plugins page using vanilla JavaScript - no database changes, no file modifications. Everything is reversible and non-destructive.

**Default Enhancements (Automatic):**
* Deactivate link always first
* Settings link always second (or auto-discovered)
* Remaining links in logical order
* Real-time search box for quick filtering

**Advanced Features (Optional):**
* Per-plugin customization in Edit Mode
* Custom settings URLs for non-standard plugins
* Plugin notes and organization
* Import/export your settings

= 🔧 Technical Details =

* Pure vanilla JavaScript - no jQuery dependency
* Modular architecture for performance
* localStorage-based user preferences
* Fully accessible (WCAG AA compliant)
* Mobile/tablet responsive
* Works with all modern WordPress themes

= 🌟 What's New in v1.0.0 =

Complete rewrite with modern architecture and powerful new features:

* Real-time plugin filtering
* Configuration panel with UI
* Edit mode for customization
* Import/export settings
* Better settings discovery
* Improved accessibility
* Zero jQuery dependency 


== Installation ==

= Automatic Installation =

1. Go to your WordPress admin dashboard
2. Navigate to Plugins > Add New
3. Search for "A Better Plugins Screen"
4. Click "Install Now" and then "Activate"
5. Visit your Plugins page to see the improvements!

= Manual Installation =

1. Download the plugin ZIP file
2. Go to Plugins > Add New > Upload Plugin
3. Choose the ZIP file and click "Install Now"
4. Click "Activate Plugin"
5. Visit your Plugins page to see the improvements!

= From GitHub =

1. Download the latest release from GitHub
2. Extract to your `/wp-content/plugins/` directory
3. Activate through the 'Plugins' menu in WordPress

**That's it!** No configuration required. The plugin works immediately upon activation.

== Frequently Asked Questions ==

= Does this require any configuration? =

No! ABPS works perfectly right out of the box. Just activate and visit your plugins page.

= What does it do? =

ABPS enhances the plugins page with:
* Consistent link ordering (Deactivate always first, Settings always second)
* Automatic settings discovery for plugins without Settings links
* Real-time search/filter functionality
* Configuration panel for customization
* Edit mode for per-plugin settings

= How does settings discovery work? =

ABPS uses multiple intelligent search methods:
1. Manual dictionary of known plugins
2. Plugin slug matching in admin menu
3. Plugin name matching
4. Filename matching with variations
5. Description scanning

If it can't find settings, it shows "No Settings Found" so you know it tried.

= Does this modify my database or files? =

No! ABPS is completely non-destructive. It uses JavaScript to enhance the page display only. All user settings are stored in browser localStorage.

= Can I customize the behavior? =

Yes! Click the "⚙️ ABPS Settings" button on the plugins page to access the configuration panel. You can:
* Toggle features on/off
* Export/import your settings
* Enable debug mode
* Customize per-plugin settings in Edit Mode

= Can different users have different settings? =

Yes! Settings are stored per-user in localStorage, so each admin can have their own preferences.

= A plugin's settings link is wrong or missing. How can I fix it? =

Two ways:
1. **Easy**: Enable Edit Mode, click on the plugin row, and enter a custom Settings URL
2. **Permanent**: [Create an issue on GitHub](https://github.com/brandonjp/a-better-plugins-screen/issues) and we'll add it to the manual dictionary

= Does this work with multisite? =

Yes! ABPS works on both single-site and multisite WordPress installations.

= Is this accessible? =

Yes! ABPS is built with accessibility in mind:
* Full keyboard navigation support
* ARIA labels for screen readers
* WCAG AA compliant
* Supports reduced motion preferences

= Will this slow down my admin? =

No! ABPS is lightweight and only loads on the plugins page. It uses vanilla JavaScript with no external dependencies.

= Can I disable specific features? =

Yes! Use the ABPS Settings panel to toggle individual features on/off.

= How do I reset to defaults? =

Click the "⚙️ ABPS Settings" button, then click "Reset to Defaults" at the bottom of the panel.

= How can I contribute? =

We welcome contributions!
* [Submit issues](https://github.com/brandonjp/a-better-plugins-screen/issues)
* [Create pull requests](https://github.com/brandonjp/a-better-plugins-screen/pulls)
* [Add plugins to the dictionary](https://github.com/brandonjp/a-better-plugins-screen)

= Where can I get support? =

For support, please visit the [GitHub repository](https://github.com/brandonjp/a-better-plugins-screen) and create an issue. 

== Changelog ==

= 1.0.0 - November 2025 =

**🎉 Major Release - Complete Rewrite**

This is a complete rewrite of ABPS with a modern, modular architecture and powerful new features.

**New Features:**
* Real-time plugin filtering with search box
* Configuration panel with intuitive UI
* Edit mode for per-plugin customization
* Import/export settings functionality
* Enhanced settings discovery algorithm
* localStorage-based user preferences
* Vanilla JavaScript (removed jQuery dependency)
* Full WCAG AA accessibility compliance
* Mobile/tablet responsive design
* Version badge on ABPS plugin row
* User notifications system
* Debug mode with console logging

**Improvements:**
* Modular JavaScript architecture
* Better performance and efficiency
* Improved code maintainability
* Better error handling
* More intelligent settings discovery
* Consistent UX across all features
* Better documentation

**Technical Changes:**
* Removed jQuery dependency
* New modular file structure (assets/js, assets/css)
* Configuration system with three layers (defaults, site config, user preferences)
* Storage module for localStorage management
* Discovery module for settings finding
* Features module for core functionality
* UI module for interface rendering
* Main initialization system
* PHP compatibility checks
* Proper WordPress coding standards

**Breaking Changes:**
* Removed inline jQuery code
* New file structure (old a_better_plugins_screen.js is now deprecated)
* Minimum PHP version now 7.0
* Minimum WordPress version now 5.0

**Migration:**
* Plugin will automatically use new system on activation
* No user action required
* Previous functionality is preserved and enhanced

= 0.5.0 - October 2021 =
* Add toggle to switch between original and better row action links

= 0.4.1 - 2021 =
* Add WP Dependency Installer as dependency
* Add Git Updater to allow updates from public git repo

= 0.3.1 - 2021 =
* Add content and FAQ to readme.txt
* JS: Add comments to the 'betterLinks' object
* JS: Add support for a couple new plugins

= 0.3.0 - 2021 =
* Initial changelog entry
* JS: Improve lookup of admin links

== Upgrade Notice ==

= 1.0.0 =
Major update with complete rewrite! New features include real-time filtering, configuration panel, edit mode, and much more. Requires PHP 7.0+ and WordPress 5.0+. All existing functionality is preserved and enhanced.
