/**
 * ABPS Storage Module
 * Handles data persistence using localStorage
 *
 * @since 1.0.0
 */

(function(window) {
    'use strict';

    /**
     * Storage Manager Class
     */
    class ABPSStorage {
        constructor() {
            this.prefix = 'abps_';
            this.available = this.checkAvailability();
        }

        /**
         * Check if localStorage is available
         */
        checkAvailability() {
            try {
                const test = '__abps_storage_test__';
                localStorage.setItem(test, test);
                localStorage.removeItem(test);
                return true;
            } catch (e) {
                console.warn('ABPS: localStorage is not available', e);
                return false;
            }
        }

        /**
         * Get prefixed key
         */
        getKey(key) {
            return this.prefix + key;
        }

        /**
         * Save data to localStorage
         */
        save(key, data) {
            if (!this.available) {
                console.warn('ABPS: Cannot save - localStorage not available');
                return false;
            }

            try {
                const jsonData = JSON.stringify(data);
                localStorage.setItem(this.getKey(key), jsonData);
                return true;
            } catch (e) {
                console.error('ABPS: Error saving to localStorage', e);
                return false;
            }
        }

        /**
         * Load data from localStorage
         */
        load(key, defaultValue = null) {
            if (!this.available) {
                return defaultValue;
            }

            try {
                const jsonData = localStorage.getItem(this.getKey(key));
                if (jsonData === null) {
                    return defaultValue;
                }
                return JSON.parse(jsonData);
            } catch (e) {
                console.error('ABPS: Error loading from localStorage', e);
                return defaultValue;
            }
        }

        /**
         * Remove data from localStorage
         */
        remove(key) {
            if (!this.available) {
                return false;
            }

            try {
                localStorage.removeItem(this.getKey(key));
                return true;
            } catch (e) {
                console.error('ABPS: Error removing from localStorage', e);
                return false;
            }
        }

        /**
         * Clear all ABPS data from localStorage
         */
        clear() {
            if (!this.available) {
                return false;
            }

            try {
                const keys = Object.keys(localStorage);
                keys.forEach(key => {
                    if (key.startsWith(this.prefix)) {
                        localStorage.removeItem(key);
                    }
                });
                return true;
            } catch (e) {
                console.error('ABPS: Error clearing localStorage', e);
                return false;
            }
        }

        /**
         * Get all ABPS keys from localStorage
         */
        getAllKeys() {
            if (!this.available) {
                return [];
            }

            try {
                const keys = Object.keys(localStorage);
                return keys.filter(key => key.startsWith(this.prefix))
                    .map(key => key.replace(this.prefix, ''));
            } catch (e) {
                console.error('ABPS: Error getting keys from localStorage', e);
                return [];
            }
        }

        /**
         * Save per-plugin settings
         */
        savePluginSettings(slug, settings) {
            const allSettings = this.load('plugin_settings', {});
            allSettings[slug] = settings;
            return this.save('plugin_settings', allSettings);
        }

        /**
         * Load per-plugin settings
         */
        loadPluginSettings(slug, defaultValue = null) {
            const allSettings = this.load('plugin_settings', {});
            return allSettings[slug] || defaultValue;
        }

        /**
         * Load all plugin settings
         */
        loadAllPluginSettings() {
            return this.load('plugin_settings', {});
        }

        /**
         * Remove per-plugin settings
         */
        removePluginSettings(slug) {
            const allSettings = this.load('plugin_settings', {});
            delete allSettings[slug];
            return this.save('plugin_settings', allSettings);
        }

        /**
         * Save link order for a plugin
         */
        saveLinkOrder(slug, order) {
            const pluginSettings = this.loadPluginSettings(slug, {});
            pluginSettings.linkOrder = order;
            return this.savePluginSettings(slug, pluginSettings);
        }

        /**
         * Load link order for a plugin
         */
        loadLinkOrder(slug) {
            const pluginSettings = this.loadPluginSettings(slug, {});
            return pluginSettings.linkOrder || null;
        }

        /**
         * Save custom settings URL for a plugin
         */
        saveCustomSettingsUrl(slug, url) {
            const pluginSettings = this.loadPluginSettings(slug, {});
            pluginSettings.customSettingsUrl = url;
            return this.savePluginSettings(slug, pluginSettings);
        }

        /**
         * Load custom settings URL for a plugin
         */
        loadCustomSettingsUrl(slug) {
            const pluginSettings = this.loadPluginSettings(slug, {});
            return pluginSettings.customSettingsUrl || null;
        }

        /**
         * Save plugin notes
         */
        savePluginNotes(slug, notes) {
            const pluginSettings = this.loadPluginSettings(slug, {});
            pluginSettings.notes = notes;
            return this.savePluginSettings(slug, pluginSettings);
        }

        /**
         * Load plugin notes
         */
        loadPluginNotes(slug) {
            const pluginSettings = this.loadPluginSettings(slug, {});
            return pluginSettings.notes || '';
        }

        /**
         * Get storage size in bytes
         */
        getStorageSize() {
            if (!this.available) {
                return 0;
            }

            try {
                let totalSize = 0;
                const keys = Object.keys(localStorage);
                keys.forEach(key => {
                    if (key.startsWith(this.prefix)) {
                        totalSize += localStorage.getItem(key).length;
                    }
                });
                return totalSize;
            } catch (e) {
                console.error('ABPS: Error calculating storage size', e);
                return 0;
            }
        }

        /**
         * Export all ABPS data
         */
        exportAll() {
            if (!this.available) {
                return null;
            }

            const data = {};
            const keys = this.getAllKeys();

            keys.forEach(key => {
                data[key] = this.load(key);
            });

            return data;
        }

        /**
         * Import all ABPS data
         */
        importAll(data) {
            if (!this.available) {
                return false;
            }

            try {
                Object.keys(data).forEach(key => {
                    this.save(key, data[key]);
                });
                return true;
            } catch (e) {
                console.error('ABPS: Error importing data', e);
                return false;
            }
        }
    }

    // Initialize and expose storage
    window.ABPSStorage = new ABPSStorage();

    // Also expose class for testing
    window.ABPSStorageClass = ABPSStorage;

})(window);
