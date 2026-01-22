# Roadmap - A Better Plugins Screen (ABPS)

## Current Status: Phase 1.1 - UX Enhancements (Planned)

The foundation is complete. Next focus is on improving user experience with drag-and-drop functionality and enhanced visual feedback.

---

## Phase Structure

Development follows a phased approach. Each phase represents a coherent set of functionality.

**Phase Status Legend:**
- Complete
- In Progress
- Planned
- Future Consideration

---

## Phases

### Phase 1.0 - Foundation - Complete
**Objective:** Build a complete, working plugin with core enhancement features
**Completed in v1.0.0 - November 2025**

**Delivered:**
- Link reordering with consistent order (Deactivate > Settings > Others)
- Automatic settings discovery with multiple search methods
- Manual settings dictionary for non-standard plugins
- Real-time plugin filtering/search
- Configuration panel with feature toggles
- Edit mode for per-plugin customization
- Custom settings URLs and notes storage
- Import/export settings functionality
- Notification system
- Debug mode with console logging
- Modular JavaScript architecture (6 modules)
- Three-layer configuration system
- localStorage-based persistence
- WCAG AA accessibility compliance
- Mobile/tablet responsive design
- Zero jQuery dependency

---

### Phase 1.1 - UX Enhancements - Planned
**Objective:** Improve user experience with visual feedback and interaction enhancements
**Target Version:** v1.1.0
**Prerequisites:** Complete Phase 1.0

**Planned Work:**

| Feature | Priority | Description |
|---------|----------|-------------|
| Drag-and-drop link reordering | High | Allow users to drag action links into custom order |
| Plugin information tooltips | Medium | Hover tooltips showing plugin metadata (version, author, update status) |
| Enhanced visual indicators | Medium | Better distinction between discovered vs. existing Settings links |
| Link order persistence | Medium | Save custom link order per plugin to localStorage |

**Technical Notes:**
- Drag-and-drop will use HTML5 Drag and Drop API (no external library)
- Tooltips will be positioned dynamically to avoid viewport overflow
- Configuration stored in existing localStorage structure

---

### Phase 1.2 - Update Management - Planned
**Objective:** Help users manage plugin updates more effectively
**Target Version:** v1.2.0
**Prerequisites:** Complete Phase 1.1

**Planned Work:**

| Feature | Priority | Description |
|---------|----------|-------------|
| Auto-update toggle per plugin | High | Quick toggle for WordPress auto-update feature |
| Never update flag | Medium | Mark plugins that should never be updated |
| PHP code generation | Medium | Generate `auto_update_plugins` filter code for production sites |
| Update notification badges | Low | Visual indicators for pending updates |

**Technical Notes:**
- Auto-update uses WordPress 5.5+ native feature
- PHP generation creates code for wp-config.php or mu-plugin
- This phase interacts with WordPress core functionality

---

### Phase 2.0 - Advanced Features - Future
**Objective:** Advanced plugin management capabilities
**Target Version:** v2.0.0
**Prerequisites:** Complete Phase 1.2

**Planned Work:**

| Feature | Priority | Description |
|---------|----------|-------------|
| Bulk plugin upload | Medium | Upload multiple plugins via ZIP files |
| Git repository installation | Medium | Install plugins directly from GitHub/GitLab URLs |
| Plugin dependency management | Low | Track and display plugin dependencies |
| Usage analytics | Low | Track which plugin features are most used (local only) |

**Technical Notes:**
- Git installation requires zip URL parsing
- Bulk upload uses WordPress upload handling
- Dependencies would be informational only (no automatic management)

---

### Future Considerations

Features that may be considered for later phases:

- **Plugin groups/categories** - Organize plugins into custom groups
- **Quick actions menu** - Right-click context menu for common actions
- **Plugin comparison** - Compare two plugin configurations
- **Backup/restore** - Plugin state snapshots
- **Multi-site support** - Network-level settings synchronization
- **REST API endpoint** - Programmatic access to ABPS features
- **Dark mode** - Match WordPress admin dark mode (if implemented)

---

## Version History

| Version | Phase | Date | Highlights |
|---------|-------|------|------------|
| 1.0.0 | 1.0 | 2025-11-12 | Complete rewrite with modular architecture, new features |
| 0.5.0 | - | 2021-10-04 | Toggle functionality added |
| 0.4.1 | - | 2021 | Git Updater integration |
| 0.3.1 | - | 2021 | Improved discovery, documentation |
| 0.3.0 | - | 2021 | Initial changelog, improved lookups |
| 0.2.x | - | 2021 | Basic functionality |
| 0.1.0 | - | 2020 | Initial release |

---

## Known Issues & Technical Debt

| Issue | Impact | Planned For |
|-------|--------|-------------|
| No automated tests | Medium - relies on manual testing | Future (consider Phase 1.2+) |
| Limited error handling for localStorage quota | Low - rare edge case | Phase 1.1 |
| Manual dictionary needs expansion | Low - fallback discovery usually works | Ongoing |

---

## Contributing to the Roadmap

Have a feature suggestion?

1. Check if it's already planned above
2. [Create a GitHub issue](https://github.com/brandonjp/a-better-plugins-screen/issues) with the "feature request" label
3. Include use case and expected behavior

**When suggesting features:**
- Consider WordPress ecosystem compatibility
- Non-destructive changes preferred
- Accessibility must be maintained
- Performance impact should be minimal

---

## How to Use This Roadmap

**For Development Sessions:**
- "Follow the dev guide and work on phase 1.1"
- "Work on the drag-and-drop feature from phase 1.1"
- "Continue with current phase priorities"

**Updating This Document:**
- Mark phases complete when all features are delivered
- Update version numbers when releases occur
- Add new ideas to Future Considerations
- Move technical debt to appropriate phases

---

*Last Updated: 2026-01-22*
