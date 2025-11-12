# Changelog

All notable changes to **A Better Plugins Screen** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-11-12

### 🎉 Major Release - Complete Rewrite

This is a complete rewrite of ABPS from the ground up with a modern, modular architecture and powerful new features.

### Added

**Core Features:**
- Real-time plugin filtering with search box
- Configuration panel with intuitive UI
- Edit mode for per-plugin customization
- Import/export settings functionality
- localStorage-based user preferences system
- Version badge on ABPS plugin row
- User notification system
- Debug mode with console logging

**Technical Features:**
- Modular JavaScript architecture (6 separate modules)
- Configuration system with three layers (defaults, site config, user preferences)
- Storage module for localStorage management
- Discovery module for intelligent settings finding
- Features module for core functionality
- UI module for interface rendering
- Main initialization system

**UI/UX:**
- Search/filter box above plugin list
- Configuration panel toggle button
- Edit mode with per-plugin controls
- Notification toasts for user feedback
- Mobile/tablet responsive design
- Full keyboard navigation support
- ARIA labels for screen readers

**Developer Features:**
- Public JavaScript API (`ABPS_API`)
- Custom event dispatching
- Extensible configuration system
- Well-documented code
- PHP compatibility checks
- WordPress coding standards

### Changed

**Breaking Changes:**
- Removed jQuery dependency (now pure vanilla JavaScript)
- New modular file structure (old `a_better_plugins_screen.js` deprecated)
- Minimum PHP version increased to 7.0
- Minimum WordPress version increased to 5.0

**Improvements:**
- Better performance and efficiency
- Improved settings discovery algorithm
- More intelligent filename matching
- Better error handling and logging
- Consistent UX across all features
- Enhanced accessibility (WCAG AA)
- Mobile-friendly interface
- Better code organization

**Technical:**
- Singleton pattern for main PHP class
- Proper WordPress hooks usage
- Script dependencies correctly declared
- CSS properly enqueued
- Activation/deactivation hooks added
- Compatibility checks on activation

### Removed

- jQuery dependency
- Old monolithic JavaScript file
- Support for WordPress < 5.0
- Support for PHP < 7.0

### Fixed

- Link ordering consistency issues
- Settings discovery edge cases
- Performance issues with large plugin lists
- Mobile display issues
- Accessibility concerns

### Security

- Added nonce verification for future AJAX
- Proper capability checks
- Input sanitization
- No eval() or similar dangerous functions
- No external API calls
- No database modifications

### Documentation

- Complete rewrite of README.md
- Updated readme.txt for WordPress.org
- Added inline code documentation
- Added JSDoc comments
- Improved installation instructions
- Added troubleshooting section
- Added contribution guidelines

---

## [0.5.0] - 2021-10-04

### Added
- Toggle to switch between original and better row action links
- Debug info display toggle

### Changed
- Enhanced toggle functionality

---

## [0.4.1] - 2021

### Added
- WP Dependency Installer as dependency
- Git Updater for updates from public git repo

### Changed
- Dependency management improvements

---

## [0.3.1] - 2021

### Added
- Content and FAQ to readme.txt
- Comments to the 'betterLinks' object in JavaScript
- Support for additional plugins

### Documentation
- Improved README
- Added FAQ section

---

## [0.3.0] - 2021

### Added
- Initial changelog entry
- Improved lookup of admin links

### Changed
- Enhanced settings discovery logic

---

## [0.2.x] - 2021

### Added
- Initial plugin functionality
- Basic link reordering
- Simple settings discovery
- Manual dictionary for known plugins

---

## [0.1.0] - 2020

### Added
- Initial release
- Basic proof of concept

---

## Future Releases

See [Roadmap](README.md#roadmap) for planned features.

### Planned for 1.1.0
- Drag-and-drop link reordering
- Plugin information tooltips
- Enhanced visual indicators

### Planned for 1.2.0
- Plugin update management
- Auto-update controls per plugin
- PHP code generation for update prevention

### Planned for 2.0.0
- Bulk plugin upload integration
- Git repository installation
- Plugin dependency management
- Usage analytics

---

[1.0.0]: https://github.com/brandonjp/a-better-plugins-screen/compare/v0.5.0...v1.0.0
[0.5.0]: https://github.com/brandonjp/a-better-plugins-screen/compare/v0.4.1...v0.5.0
[0.4.1]: https://github.com/brandonjp/a-better-plugins-screen/compare/v0.3.1...v0.4.1
[0.3.1]: https://github.com/brandonjp/a-better-plugins-screen/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/brandonjp/a-better-plugins-screen/compare/v0.2.0...v0.3.0
