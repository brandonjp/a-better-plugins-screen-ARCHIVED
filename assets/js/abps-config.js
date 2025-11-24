/**
 * ABPS Configuration System
 * Handles default configuration, site configuration, and user preferences
 *
 * @since 1.0.0
 */

(function(window) {
    'use strict';

    /**
     * Default configuration - immutable base settings
     */
    const ABPS_DEFAULTS = {
        version: '1.0.0',

        // Feature flags
        features: {
            linkReordering: true,
            settingsDiscovery: true,
            pluginFiltering: true,
            editMode: true,
            updateManagement: false, // Disabled by default for v1.0
            tooltips: false,         // Disabled by default for v1.0
            configPanel: true,
            dragDropReordering: false // Disabled by default for v1.0
        },

        // Link reordering settings
        linkReordering: {
            enabled: true,
            defaultOrder: ['deactivate', 'settings', '*'],
            alwaysShowDeactivate: true,
            persistOrder: true
        },

        // Settings discovery configuration
        settingsDiscovery: {
            enabled: true,
            searchMethods: {
                manualDictionary: { enabled: true, priority: 1 },
                slugMatch: { enabled: true, priority: 2 },
                nameMatch: { enabled: true, priority: 3 },
                filenameMatch: { enabled: true, priority: 4 },
                filenameVariations: { enabled: true, priority: 5 },
                descriptionScan: { enabled: true, priority: 6 }
            },
            fallbackText: 'No Settings Found',
            fallbackTextColor: '#999'
        },

        // Plugin filtering settings
        filterBox: {
            enabled: true,
            placement: 'above_plugins_list',
            placeholder: 'Search plugins (powered by A Better Plugins Screen)',
            searchableFields: ['name', 'slug', 'description', 'author'],
            matchType: 'partial',
            caseSensitive: false,
            highlightMatches: true,
            highlightColor: '#fff9c4',
            debounceMs: 300
        },

        // Configuration panel settings
        configPanel: {
            enabled: true,
            buttonText: 'ABPS Settings',
            buttonIcon: '⚙️',
            backgroundColor: '#f5f5f5',
            borderColor: '#ddd',
            position: 'above_plugins_list',
            expandDirection: 'down',
            animationDuration: 300
        },

        // Edit mode settings
        editMode: {
            enabled: true,
            buttonStyle: 'text',
            buttonLabel: 'Edit ABPS',
            storageMethod: 'localStorage',
            allowExport: true,
            allowImport: true,
            persistSettings: true
        },

        // Update management settings (future feature)
        updateManagement: {
            enabled: false,
            enableNeverUpdate: false,
            generatePHP: false
        },

        // Tooltips settings (future feature)
        tooltips: {
            enabled: false,
            trigger: 'hover',
            position: 'right'
        },

        // Debug settings
        debug: {
            enabled: false,
            verbose: false,
            showPluginInfo: false
        }
    };

    /**
     * Manual dictionary for plugins with non-standard settings URLs
     */
    const MANUAL_SETTINGS_DICTIONARY = {
        'all-in-one-event-calendar': 'admin.php?page=timely_signin',
        'divimenus': 'admin.php?page=dondivi_main_menu',
        'divimenus-on-media': 'admin.php?page=dondivi_main_menu',
        'divimenus-sharing': 'admin.php?page=dondivi_main_menu',
        'divipasswords': 'admin.php?page=dondivi_main_menu',
        'floating-divimenus': 'admin.php?page=dondivi_main_menu',
        'feedzy-rss-feeds': 'edit.php?post_type=feedzy_imports',
        'oxygen-gutenberg-integration': 'admin.php?page=oxygen_vsb_settings&tab=gutenberg',
        'peters-login-redirect': 'options-general.php?page=wplogin_redirect.php',
        'plainview-protect-passwords': 'options-general.php?page=pv_protect_passwords',
        'user-access-manager': 'admin.php?page=uam_user_group',
        'varnish-http-purge': 'admin.php?page=varnish-page'
    };

    /**
     * Configuration Manager Class
     */
    class ABPSConfig {
        constructor() {
            this.defaults = ABPS_DEFAULTS;
            this.manualDictionary = MANUAL_SETTINGS_DICTIONARY;
            this.siteConfig = {};
            this.userPreferences = {};
            this.mergedConfig = {};

            this.init();
        }

        /**
         * Initialize configuration
         */
        init() {
            this.loadSiteConfig();
            this.loadUserPreferences();
            this.mergeConfigurations();
        }

        /**
         * Load site-specific configuration from window.ABPS_CONFIG
         */
        loadSiteConfig() {
            if (window.ABPS_CONFIG && typeof window.ABPS_CONFIG === 'object') {
                this.siteConfig = window.ABPS_CONFIG;
                this.log('Site configuration loaded', this.siteConfig);
            }
        }

        /**
         * Load user preferences from localStorage
         */
        loadUserPreferences() {
            try {
                const stored = localStorage.getItem('abps_user_preferences');
                if (stored) {
                    this.userPreferences = JSON.parse(stored);
                    this.log('User preferences loaded', this.userPreferences);
                }
            } catch (e) {
                console.error('ABPS: Error loading user preferences', e);
            }
        }

        /**
         * Merge configurations (defaults < site config < user preferences)
         */
        mergeConfigurations() {
            this.mergedConfig = this.deepMerge(
                this.deepMerge({}, this.defaults),
                this.deepMerge(this.siteConfig, this.userPreferences)
            );

            // Merge manual dictionary with site config custom settings
            if (this.siteConfig.customSettingsMaps) {
                Object.assign(this.manualDictionary, this.siteConfig.customSettingsMaps);
            }

            this.log('Configuration merged', this.mergedConfig);
        }

        /**
         * Deep merge objects
         */
        deepMerge(target, source) {
            const output = Object.assign({}, target);

            if (this.isObject(target) && this.isObject(source)) {
                Object.keys(source).forEach(key => {
                    if (this.isObject(source[key])) {
                        if (!(key in target)) {
                            Object.assign(output, { [key]: source[key] });
                        } else {
                            output[key] = this.deepMerge(target[key], source[key]);
                        }
                    } else {
                        Object.assign(output, { [key]: source[key] });
                    }
                });
            }

            return output;
        }

        /**
         * Check if value is object
         */
        isObject(item) {
            return item && typeof item === 'object' && !Array.isArray(item);
        }

        /**
         * Get configuration value
         */
        get(path, defaultValue = null) {
            const keys = path.split('.');
            let value = this.mergedConfig;

            for (const key of keys) {
                if (value && typeof value === 'object' && key in value) {
                    value = value[key];
                } else {
                    return defaultValue;
                }
            }

            return value;
        }

        /**
         * Set user preference
         */
        set(path, value) {
            const keys = path.split('.');
            let current = this.userPreferences;

            for (let i = 0; i < keys.length - 1; i++) {
                const key = keys[i];
                if (!(key in current)) {
                    current[key] = {};
                }
                current = current[key];
            }

            current[keys[keys.length - 1]] = value;
            this.saveUserPreferences();
            this.mergeConfigurations();
        }

        /**
         * Save user preferences to localStorage
         */
        saveUserPreferences() {
            try {
                localStorage.setItem('abps_user_preferences', JSON.stringify(this.userPreferences));
                this.log('User preferences saved');
            } catch (e) {
                console.error('ABPS: Error saving user preferences', e);
            }
        }

        /**
         * Reset user preferences to defaults
         */
        resetUserPreferences() {
            this.userPreferences = {};
            try {
                localStorage.removeItem('abps_user_preferences');
                this.mergeConfigurations();
                this.log('User preferences reset');
            } catch (e) {
                console.error('ABPS: Error resetting user preferences', e);
            }
        }

        /**
         * Export configuration as JSON
         */
        exportConfig() {
            return JSON.stringify(this.userPreferences, null, 2);
        }

        /**
         * Import configuration from JSON
         */
        importConfig(jsonString) {
            try {
                const imported = JSON.parse(jsonString);
                this.userPreferences = imported;
                this.saveUserPreferences();
                this.mergeConfigurations();
                this.log('Configuration imported successfully');
                return true;
            } catch (e) {
                console.error('ABPS: Error importing configuration', e);
                return false;
            }
        }

        /**
         * Get manual settings dictionary
         */
        getManualDictionary() {
            return this.manualDictionary;
        }

        /**
         * Add to manual dictionary
         */
        addToManualDictionary(slug, url) {
            this.manualDictionary[slug] = url;

            // Save to user preferences
            if (!this.userPreferences.customSettingsMaps) {
                this.userPreferences.customSettingsMaps = {};
            }
            this.userPreferences.customSettingsMaps[slug] = url;
            this.saveUserPreferences();
        }

        /**
         * Logging helper
         */
        log(...args) {
            if (this.get('debug.enabled')) {
                console.log('[ABPS Config]', ...args);
            }
        }
    }

    // Initialize and expose configuration
    window.ABPSConfig = new ABPSConfig();

    // Also expose class for testing
    window.ABPSConfigClass = ABPSConfig;

})(window);
