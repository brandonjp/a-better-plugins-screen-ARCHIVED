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
            if (this.config.get('features.configPanel')) {
                this.renderConfigPanel();
            }

            if (this.config.get('features.editMode')) {
                this.addEditModeToggle();
            }
        }

        /**
         * Render configuration panel
         */
        renderConfigPanel() {
            const config = this.config.get('configPanel');
            const table = document.querySelector('table.plugins');

            if (!table) return;

            // Create panel container
            const panel = document.createElement('div');
            panel.className = 'abps-config-panel';
            panel.id = 'abps-config-panel';

            // Create toggle button
            const toggleButton = document.createElement('button');
            toggleButton.className = 'abps-config-toggle button button-secondary';
            toggleButton.innerHTML = `${config.buttonIcon} ${config.buttonText}`;
            toggleButton.setAttribute('aria-expanded', 'false');
            toggleButton.setAttribute('aria-controls', 'abps-config-content');

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
            toggleButton.addEventListener('click', () => {
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
                const td = row.querySelector('.plugin-title');

                if (!td) return;

                // Create edit controls
                const editControls = document.createElement('div');
                editControls.className = 'abps-edit-controls';
                editControls.innerHTML = `
                    <div class="abps-edit-control">
                        <label>
                            Custom Settings URL:
                            <input type="text" class="abps-custom-url-input" placeholder="admin.php?page=..." value="${this.storage.loadCustomSettingsUrl(slug) || ''}">
                        </label>
                        <button type="button" class="button button-small abps-save-url">Save</button>
                    </div>
                    <div class="abps-edit-control">
                        <label>
                            Notes:
                            <input type="text" class="abps-notes-input" placeholder="Add notes..." value="${this.storage.loadPluginNotes(slug) || ''}">
                        </label>
                        <button type="button" class="button button-small abps-save-notes">Save</button>
                    </div>
                `;

                td.appendChild(editControls);

                // Set up events
                const saveUrlButton = editControls.querySelector('.abps-save-url');
                saveUrlButton.addEventListener('click', () => {
                    const input = editControls.querySelector('.abps-custom-url-input');
                    this.storage.saveCustomSettingsUrl(slug, input.value);
                    this.showNotification('Custom URL saved!', 'success');
                });

                const saveNotesButton = editControls.querySelector('.abps-save-notes');
                saveNotesButton.addEventListener('click', () => {
                    const input = editControls.querySelector('.abps-notes-input');
                    this.storage.savePluginNotes(slug, input.value);
                    this.showNotification('Notes saved!', 'success');
                });
            });
        }

        /**
         * Remove edit mode UI controls
         */
        removeEditModeUI() {
            const editControls = document.querySelectorAll('.abps-edit-controls');
            editControls.forEach(control => control.remove());
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
