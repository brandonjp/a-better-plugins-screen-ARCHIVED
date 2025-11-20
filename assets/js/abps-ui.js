/**
 * ABPS UI Module
 * Handles user interface rendering and interactions
 *
 * @since 1.0.0
 */

(function(window) {
    'use strict';

    /**
     * UI Manager Class
     */
    class ABPSUI {
        constructor(config, storage, features) {
            this.config = config;
            this.storage = storage;
            this.features = features;
            this.configPanelVisible = false;
            this.editModeActive = false;
        }

        /**
         * Initialize UI
         */
        init() {
            // Render config panel (hidden by default)
            if (this.config.get('features.configPanel')) {
                this.renderConfigPanel();
            }

            // Add Settings link to ABPS plugin row
            this.addABPSSettingsLink();

            if (this.config.get('features.editMode')) {
                this.addEditModeToggle();
            }
        }

        /**
         * Add Settings link to ABPS plugin row
         */
        addABPSSettingsLink() {
            const abpsRow = document.querySelector('tr[data-slug="a-better-plugins-screen"]');
            if (!abpsRow) return;

            const rowActions = abpsRow.querySelector('.row-actions');
            if (!rowActions) return;

            // Find or create settings span
            let settingsSpan = rowActions.querySelector('span.settings');

            if (!settingsSpan) {
                settingsSpan = document.createElement('span');
                settingsSpan.className = 'settings';
                // Insert after deactivate link
                const deactivateSpan = rowActions.querySelector('span.deactivate');
                if (deactivateSpan && deactivateSpan.nextSibling) {
                    rowActions.insertBefore(settingsSpan, deactivateSpan.nextSibling);
                } else {
                    rowActions.appendChild(settingsSpan);
                }
            }

            // Create settings link
            const settingsLink = document.createElement('a');
            settingsLink.href = '#';
            settingsLink.textContent = 'Settings';
            settingsLink.addEventListener('click', (e) => {
                e.preventDefault();
                this.toggleConfigPanel();
            });

            settingsSpan.innerHTML = '';
            settingsSpan.appendChild(settingsLink);
        }

        /**
         * Toggle configuration panel
         */
        toggleConfigPanel() {
            const content = document.querySelector('#abps-config-content');
            const toggleButton = document.querySelector('.abps-config-toggle');

            if (!content || !toggleButton) return;

            this.configPanelVisible = !this.configPanelVisible;

            if (this.configPanelVisible) {
                content.style.display = 'block';
                toggleButton.setAttribute('aria-expanded', 'true');
            } else {
                content.style.display = 'none';
                toggleButton.setAttribute('aria-expanded', 'false');
            }
        }

        /**
         * Render configuration panel
         */
        renderConfigPanel() {
            const config = this.config.get('configPanel');
            const table = document.querySelector('table.plugins');

            if (!table) return;

            // Create panel container (without visible toggle button)
            const panel = document.createElement('div');
            panel.className = 'abps-config-panel';
            panel.id = 'abps-config-panel';

            // Create hidden toggle button for accessibility
            const toggleButton = document.createElement('button');
            toggleButton.type = 'button';
            toggleButton.className = 'abps-config-toggle button button-secondary';
            toggleButton.innerHTML = `${config.buttonIcon} ${config.buttonText}`;
            toggleButton.setAttribute('aria-expanded', 'false');
            toggleButton.setAttribute('aria-controls', 'abps-config-content');
            toggleButton.style.display = 'none'; // Hide the button

            // Create panel content
            const content = document.createElement('div');
            content.className = 'abps-config-content';
            content.id = 'abps-config-content';
            content.style.display = 'none';

            content.innerHTML = this.getConfigPanelHTML();

            // Assemble panel
            panel.appendChild(toggleButton);
            panel.appendChild(content);

            // Insert before table
            table.parentNode.insertBefore(panel, table);

            // Set up events
            this.setupConfigPanelEvents(toggleButton, content);
        }

        /**
         * Get configuration panel HTML
         */
        getConfigPanelHTML() {
            const features = this.config.get('features');

            return `
                <div class="abps-config-section">
                    <h3>🔧 Features</h3>
                    <label>
                        <input type="checkbox" name="feature-linkReordering" ${features.linkReordering ? 'checked' : ''}>
                        Link Reordering - Consistent order for action links
                    </label>
                    <label>
                        <input type="checkbox" name="feature-settingsDiscovery" ${features.settingsDiscovery ? 'checked' : ''}>
                        Settings Discovery - Automatically find settings pages
                    </label>
                    <label>
                        <input type="checkbox" name="feature-pluginFiltering" ${features.pluginFiltering ? 'checked' : ''}>
                        Plugin Filtering - Real-time search box
                    </label>
                    <label>
                        <input type="checkbox" name="feature-editMode" ${features.editMode ? 'checked' : ''}>
                        Edit Mode - Customize per-plugin settings
                    </label>
                </div>

                <div class="abps-config-section">
                    <h3>🎯 Default Link Order</h3>
                    <p class="description">Drag to reorder links (feature coming soon)</p>
                    <div class="abps-link-order-preview">
                        <span class="abps-order-item">Deactivate</span>
                        <span class="abps-order-item">Settings</span>
                        <span class="abps-order-item">* (Others)</span>
                    </div>
                </div>

                <div class="abps-config-section">
                    <h3>🔍 Filter Settings</h3>
                    <label>
                        Filter placement:
                        <select name="filter-placement">
                            <option value="above_plugins_list" selected>Above plugin list</option>
                            <option value="sidebar">Sidebar (future)</option>
                        </select>
                    </label>
                    <p class="description">Searchable fields: Name, Slug, Description, Author</p>
                </div>

                <div class="abps-config-section">
                    <h3>↔️ Import/Export Settings</h3>
                    <div class="abps-import-export">
                        <button type="button" class="button" id="abps-export-btn">Export Settings</button>
                        <button type="button" class="button" id="abps-import-btn">Import Settings</button>
                    </div>
                    <textarea id="abps-import-export-data" class="abps-import-export-textarea" placeholder="Paste settings JSON here to import" style="display:none;"></textarea>
                </div>

                <div class="abps-config-section">
                    <h3>🐛 Debug Options</h3>
                    <label>
                        <input type="checkbox" name="debug-enabled" ${this.config.get('debug.enabled') ? 'checked' : ''}>
                        Enable debug logging
                    </label>
                </div>

                <div class="abps-config-actions">
                    <button type="button" class="button button-primary" id="abps-save-settings">Save Changes</button>
                    <button type="button" class="button button-secondary" id="abps-reload-page">Save & Reload</button>
                    <button type="button" class="button button-link-delete" id="abps-reset-settings">Reset to Defaults</button>
                </div>

                <div class="abps-config-footer">
                    <p class="description">
                        Settings are saved per-user in localStorage.
                        <br>Version: ${this.config.get('version')}
                    </p>
                </div>
            `;
        }

        /**
         * Setup configuration panel events
         */
        setupConfigPanelEvents(toggleButton, content) {
            // Toggle panel visibility
            toggleButton.addEventListener('click', (e) => {
                e.preventDefault(); // Prevent any default action
                this.configPanelVisible = !this.configPanelVisible;

                if (this.configPanelVisible) {
                    content.style.display = 'block';
                    toggleButton.setAttribute('aria-expanded', 'true');
                } else {
                    content.style.display = 'none';
                    toggleButton.setAttribute('aria-expanded', 'false');
                }
            });

            // Save settings
            const saveButton = content.querySelector('#abps-save-settings');
            if (saveButton) {
                saveButton.addEventListener('click', () => this.saveConfigSettings());
            }

            // Save and reload
            const reloadButton = content.querySelector('#abps-reload-page');
            if (reloadButton) {
                reloadButton.addEventListener('click', () => {
                    this.saveConfigSettings();
                    window.location.reload();
                });
            }

            // Reset settings
            const resetButton = content.querySelector('#abps-reset-settings');
            if (resetButton) {
                resetButton.addEventListener('click', () => this.resetSettings());
            }

            // Export settings
            const exportButton = content.querySelector('#abps-export-btn');
            if (exportButton) {
                exportButton.addEventListener('click', () => this.exportSettings());
            }

            // Import settings
            const importButton = content.querySelector('#abps-import-btn');
            if (importButton) {
                importButton.addEventListener('click', () => this.importSettings());
            }
        }

        /**
         * Save configuration settings
         */
        saveConfigSettings() {
            const content = document.querySelector('#abps-config-content');

            // Save feature toggles
            const featureCheckboxes = content.querySelectorAll('input[name^="feature-"]');
            featureCheckboxes.forEach(checkbox => {
                const featureName = checkbox.name.replace('feature-', '');
                this.config.set(`features.${featureName}`, checkbox.checked);
            });

            // Save debug setting
            const debugCheckbox = content.querySelector('input[name="debug-enabled"]');
            if (debugCheckbox) {
                this.config.set('debug.enabled', debugCheckbox.checked);
            }

            this.showNotification('Settings saved successfully!', 'success');
        }

        /**
         * Reset settings to defaults
         */
        resetSettings() {
            if (confirm('Are you sure you want to reset all settings to defaults? This will reload the page.')) {
                this.config.resetUserPreferences();
                this.storage.clear();
                window.location.reload();
            }
        }

        /**
         * Export settings
         */
        exportSettings() {
            const data = this.config.exportConfig();
            const textarea = document.querySelector('#abps-import-export-data');

            if (textarea) {
                textarea.style.display = 'block';
                textarea.value = data;
                textarea.select();

                // Copy to clipboard
                try {
                    document.execCommand('copy');
                    this.showNotification('Settings copied to clipboard!', 'success');
                } catch (e) {
                    this.showNotification('Settings exported. Please copy manually.', 'info');
                }
            }
        }

        /**
         * Import settings
         */
        importSettings() {
            const textarea = document.querySelector('#abps-import-export-data');

            if (textarea) {
                textarea.style.display = 'block';
                textarea.focus();

                const importButton = document.querySelector('#abps-import-btn');
                importButton.textContent = 'Confirm Import';

                const confirmHandler = () => {
                    const data = textarea.value;

                    if (!data) {
                        this.showNotification('Please paste settings JSON first', 'error');
                        return;
                    }

                    if (this.config.importConfig(data)) {
                        this.showNotification('Settings imported successfully! Reloading...', 'success');
                        setTimeout(() => window.location.reload(), 1000);
                    } else {
                        this.showNotification('Invalid settings JSON', 'error');
                    }

                    importButton.textContent = 'Import Settings';
                    importButton.removeEventListener('click', confirmHandler);
                };

                importButton.addEventListener('click', confirmHandler);
            }
        }

        /**
         * Add edit mode toggle
         */
        addEditModeToggle() {
            // Find ABPS plugin row
            const abpsRow = document.querySelector('tr[data-slug="a-better-plugins-screen"]');

            if (!abpsRow) return;

            const rowActions = abpsRow.querySelector('.row-actions');

            if (!rowActions) return;

            // Create edit mode toggle
            const editToggle = document.createElement('span');
            editToggle.className = 'abps-edit-toggle';
            editToggle.innerHTML = `<a href="#" id="abps-edit-mode-toggle">Edit Mode</a>`;

            rowActions.appendChild(document.createTextNode(' | '));
            rowActions.appendChild(editToggle);

            // Set up event
            const toggleLink = editToggle.querySelector('a');
            toggleLink.addEventListener('click', (e) => {
                e.preventDefault();
                this.toggleEditMode();
            });
        }

        /**
         * Toggle edit mode
         */
        toggleEditMode() {
            this.editModeActive = !this.editModeActive;

            const body = document.body;
            const toggleLink = document.querySelector('#abps-edit-mode-toggle');

            if (this.editModeActive) {
                body.classList.add('abps-edit-mode');
                if (toggleLink) toggleLink.textContent = 'Exit Edit Mode';
                this.renderEditModeUI();
                this.showNotification('Edit Mode enabled - hover over plugins to customize', 'info');

                // Dispatch event
                document.dispatchEvent(new CustomEvent('abps:edit_mode_enabled'));
            } else {
                body.classList.remove('abps-edit-mode');
                if (toggleLink) toggleLink.textContent = 'Edit Mode';
                this.removeEditModeUI();
                this.showNotification('Edit Mode disabled', 'info');

                // Dispatch event
                document.dispatchEvent(new CustomEvent('abps:edit_mode_disabled'));
            }
        }

        /**
         * Render edit mode UI controls
         */
        renderEditModeUI() {
            const pluginRows = document.querySelectorAll('table.plugins #the-list tr.active:not(.plugin-update-tr)');

            pluginRows.forEach(row => {
                const slug = row.dataset.slug;

                // Skip if edit row already exists
                if (row.nextElementSibling?.classList.contains('abps-edit-row')) {
                    return;
                }

                // Create a new table row for edit controls (full width)
                const editRow = document.createElement('tr');
                editRow.className = 'abps-edit-row';
                editRow.dataset.pluginSlug = slug;

                // Create a single td that spans all columns
                const editTd = document.createElement('td');
                editTd.setAttribute('colspan', '100'); // Span all columns
                editTd.className = 'abps-edit-controls-container';

                // Create edit controls
                editTd.innerHTML = `
                    <div class="abps-edit-controls">
                        <div class="abps-edit-controls-grid">
                            <div class="abps-edit-control">
                                <label>
                                    <strong>Custom Settings URL:</strong>
                                    <input type="text" class="abps-custom-url-input" placeholder="admin.php?page=..." value="${this.storage.loadCustomSettingsUrl(slug) || ''}">
                                </label>
                                <button type="button" class="button button-small abps-save-url">Save URL</button>
                            </div>
                            <div class="abps-edit-control">
                                <label>
                                    <strong>Notes:</strong>
                                    <input type="text" class="abps-notes-input" placeholder="Add notes about this plugin..." value="${this.storage.loadPluginNotes(slug) || ''}">
                                </label>
                                <button type="button" class="button button-small abps-save-notes">Save Notes</button>
                            </div>
                        </div>
                    </div>
                `;

                editRow.appendChild(editTd);

                // Insert the edit row right after the plugin row
                row.parentNode.insertBefore(editRow, row.nextSibling);

                // Set up events
                const saveUrlButton = editTd.querySelector('.abps-save-url');
                saveUrlButton.addEventListener('click', () => {
                    const input = editTd.querySelector('.abps-custom-url-input');
                    this.storage.saveCustomSettingsUrl(slug, input.value);
                    this.showNotification('Custom URL saved!', 'success');
                });

                const saveNotesButton = editTd.querySelector('.abps-save-notes');
                saveNotesButton.addEventListener('click', () => {
                    const input = editTd.querySelector('.abps-notes-input');
                    this.storage.savePluginNotes(slug, input.value);
                    this.showNotification('Notes saved!', 'success');
                });
            });
        }

        /**
         * Remove edit mode UI controls
         */
        removeEditModeUI() {
            const editRows = document.querySelectorAll('.abps-edit-row');
            editRows.forEach(row => row.remove());
        }

        /**
         * Show notification
         */
        showNotification(message, type = 'info') {
            // Remove existing notification
            const existing = document.querySelector('.abps-notification');
            if (existing) {
                existing.remove();
            }

            // Create notification
            const notification = document.createElement('div');
            notification.className = `abps-notification abps-notification-${type}`;
            notification.textContent = message;

            // Add to page
            document.body.appendChild(notification);

            // Auto-remove after 3 seconds
            setTimeout(() => {
                notification.classList.add('abps-notification-fadeout');
                setTimeout(() => notification.remove(), 300);
            }, 3000);
        }

        /**
         * Logging helper
         */
        log(...args) {
            if (this.config.get('debug.enabled')) {
                console.log('[ABPS UI]', ...args);
            }
        }
    }

    // Expose class
    window.ABPSUIClass = ABPSUI;

})(window);
