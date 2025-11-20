/**
 * ABPS Main Entry Point
 * Initializes and coordinates all ABPS modules
 *
 * @since 1.0.0
 */

(function(window, document) {
    'use strict';

    /**
     * Main ABPS Application Class
     */
    class ABPS {
        constructor() {
            this.version = '1.0.0';
            this.initialized = false;
            this.config = null;
            this.storage = null;
            this.discovery = null;
            this.features = null;
            this.ui = null;
        }

        /**
         * Initialize ABPS
         */
        init() {
            if (this.initialized) {
                this.log('ABPS already initialized');
                return;
            }

            this.log('Initializing ABPS v' + this.version);

            // Check if we're on the plugins page
            if (!this.isPluginsPage()) {
                this.log('Not on plugins page, skipping initialization');
                return;
            }

            // Wait for DOM to be ready
            if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', () => this.start());
            } else {
                this.start();
            }
        }

        /**
         * Start ABPS application
         */
        start() {
            try {
                // Initialize configuration
                this.config = window.ABPSConfig;
                if (!this.config) {
                    console.error('ABPS: Configuration not loaded');
                    return;
                }

                // Initialize storage
                this.storage = window.ABPSStorage;
                if (!this.storage) {
                    console.error('ABPS: Storage not loaded');
                    return;
                }

                // Initialize discovery
                this.discovery = new window.ABPSDiscoveryClass(this.config);

                // Initialize features
                this.features = new window.ABPSFeaturesClass(
                    this.config,
                    this.storage,
                    this.discovery
                );

                // Initialize UI
                this.ui = new window.ABPSUIClass(
                    this.config,
                    this.storage,
                    this.features
                );

                // Run initialization
                this.features.init();
                this.ui.init();

                this.initialized = true;
                this.log('ABPS initialized successfully');

                // Dispatch initialization event
                document.dispatchEvent(new CustomEvent('abps:initialized', {
                    detail: { version: this.version }
                }));

                // Watch for WordPress native search replacing the plugin table
                this.watchForTableChanges();

            } catch (error) {
                console.error('ABPS: Initialization error', error);
            }
        }

        /**
         * Watch for plugin table changes (e.g., WordPress native search)
         */
        watchForTableChanges() {
            const pluginList = document.querySelector('#the-list');
            if (!pluginList) return;

            // Create observer to watch for table changes
            const observer = new MutationObserver((mutations) => {
                // Check if significant changes occurred
                const significantChange = mutations.some(mutation =>
                    mutation.addedNodes.length > 0 || mutation.removedNodes.length > 0
                );

                if (significantChange) {
                    this.log('Plugin table changed, re-initializing ABPS...');

                    // Small delay to let WP finish its updates
                    setTimeout(() => {
                        this.features.init();
                        // Don't re-init UI (Settings link, config panel already exist)
                    }, 100);
                }
            });

            // Start observing
            observer.observe(pluginList, {
                childList: true,
                subtree: false
            });

            this.log('Watching for plugin table changes');
        }

        /**
         * Check if we're on the plugins page
         */
        isPluginsPage() {
            // Check by page parameter
            const urlParams = new URLSearchParams(window.location.search);
            const isPluginsParam = window.location.pathname.includes('plugins.php');

            // Check for plugins table
            const hasPluginsTable = document.querySelector('table.plugins') !== null;

            return isPluginsParam || hasPluginsTable;
        }

        /**
         * Get ABPS instance information
         */
        getInfo() {
            return {
                version: this.version,
                initialized: this.initialized,
                config: this.config ? this.config.mergedConfig : null,
                features: {
                    linkReordering: this.config?.get('features.linkReordering'),
                    settingsDiscovery: this.config?.get('features.settingsDiscovery'),
                    pluginFiltering: this.config?.get('features.pluginFiltering'),
                    editMode: this.config?.get('features.editMode'),
                    configPanel: this.config?.get('features.configPanel')
                }
            };
        }

        /**
         * Enable debug mode
         */
        enableDebug() {
            this.config?.set('debug.enabled', true);
            console.log('ABPS: Debug mode enabled');
        }

        /**
         * Disable debug mode
         */
        disableDebug() {
            this.config?.set('debug.enabled', false);
            console.log('ABPS: Debug mode disabled');
        }

        /**
         * Logging helper
         */
        log(...args) {
            if (this.config?.get('debug.enabled')) {
                console.log('[ABPS]', ...args);
            }
        }

        /**
         * Expose API methods
         */
        getAPI() {
            return {
                version: this.version,
                initialized: this.initialized,
                getInfo: () => this.getInfo(),
                enableDebug: () => this.enableDebug(),
                disableDebug: () => this.disableDebug(),
                reloadConfig: () => this.config?.init(),
                clearStorage: () => this.storage?.clear(),
                exportSettings: () => this.config?.exportConfig(),
                importSettings: (json) => this.config?.importConfig(json),
                resetSettings: () => {
                    this.config?.resetUserPreferences();
                    this.storage?.clear();
                    window.location.reload();
                }
            };
        }
    }

    // Create global ABPS instance
    const abpsInstance = new ABPS();

    // Initialize on load
    abpsInstance.init();

    // Expose ABPS instance and API to window
    window.ABPS = abpsInstance;
    window.ABPSInstance = abpsInstance;
    window.ABPS_API = abpsInstance.getAPI();

    // Console message
    if (window.location.search.includes('page=plugins') || window.location.pathname.includes('plugins.php')) {
        console.log(
            '%c⚡ A Better Plugins Screen %cv' + abpsInstance.version,
            'font-weight: bold; font-size: 14px; color: #2271b1;',
            'font-size: 11px; color: #666;'
        );
        console.log('Type ABPS_API.getInfo() for details');
    }

})(window, document);
