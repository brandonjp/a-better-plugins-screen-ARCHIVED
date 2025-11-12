/**
 * ABPS Settings Discovery Module
 * Intelligently discovers plugin settings pages
 *
 * @since 1.0.0
 */

(function(window) {
    'use strict';

    /**
     * Settings Discovery Class
     */
    class ABPSDiscovery {
        constructor(config) {
            this.config = config;
            this.adminMenu = null;
            this.cache = {};
        }

        /**
         * Initialize discovery
         */
        init() {
            this.adminMenu = document.querySelector('#adminmenu');
        }

        /**
         * Find settings URL for a plugin
         * @param {Object} pluginData - Plugin data object
         * @returns {string|null} Settings URL or null
         */
        findSettingsUrl(pluginData) {
            const { slug, name, file, description } = pluginData;

            // Check cache first
            if (this.cache[slug]) {
                this.log(`Using cached settings URL for ${name}`);
                return this.cache[slug];
            }

            const methods = this.config.get('settingsDiscovery.searchMethods');

            // Sort methods by priority
            const sortedMethods = Object.keys(methods)
                .filter(method => methods[method].enabled)
                .sort((a, b) => methods[a].priority - methods[b].priority);

            // Try each method in priority order
            for (const methodName of sortedMethods) {
                let url = null;

                switch (methodName) {
                    case 'manualDictionary':
                        url = this.searchManualDictionary(slug);
                        break;
                    case 'slugMatch':
                        url = this.searchBySlug(slug);
                        break;
                    case 'nameMatch':
                        url = this.searchByName(name);
                        break;
                    case 'filenameMatch':
                        url = this.searchByFilename(file);
                        break;
                    case 'filenameVariations':
                        url = this.searchByFilenameVariations(file);
                        break;
                    case 'descriptionScan':
                        url = this.searchInDescription(description);
                        break;
                }

                if (url && this.isValidUrl(url)) {
                    this.log(`Found settings for ${name} using ${methodName}: ${url}`);
                    this.cache[slug] = url;
                    return url;
                }
            }

            this.log(`No settings found for ${name}`);
            return null;
        }

        /**
         * Search in manual dictionary
         */
        searchManualDictionary(slug) {
            const dictionary = this.config.getManualDictionary();
            return dictionary[slug] || null;
        }

        /**
         * Search admin menu by slug
         */
        searchBySlug(slug) {
            if (!this.adminMenu) return null;

            const link = this.adminMenu.querySelector(`a[href*="${slug}"]`);
            return link ? link.getAttribute('href') : null;
        }

        /**
         * Search admin menu by plugin name
         */
        searchByName(name) {
            if (!this.adminMenu) return null;

            // Find links containing the plugin name (case-insensitive)
            const links = this.adminMenu.querySelectorAll('a');
            for (const link of links) {
                if (this.textContains(link.textContent, name)) {
                    return link.getAttribute('href');
                }
            }

            return null;
        }

        /**
         * Search by plugin filename
         */
        searchByFilename(file) {
            if (!this.adminMenu) return null;

            const link = this.adminMenu.querySelector(`a[href*="${file}"]`);
            return link ? link.getAttribute('href') : null;
        }

        /**
         * Search by filename variations
         */
        searchByFilenameVariations(file) {
            if (!this.adminMenu) return null;

            // Extract filename parts
            const variations = this.generateFilenameVariations(file);

            // Try each variation
            for (const variation of variations) {
                const link = this.adminMenu.querySelector(`a[href*="${variation}"]`);
                if (link) {
                    const url = link.getAttribute('href');
                    if (this.isValidUrl(url)) {
                        return url;
                    }
                }
            }

            return null;
        }

        /**
         * Generate filename variations
         */
        generateFilenameVariations(file) {
            const variations = new Set();

            // Remove .php extension and split by /
            const parts = file.replace('.php', '').split('/');

            parts.forEach(part => {
                // Original
                variations.add(part);

                // Replace hyphens with underscores
                variations.add(part.replace(/-/g, '_'));

                // Replace underscores with hyphens
                variations.add(part.replace(/_/g, '-'));

                // Remove all separators
                variations.add(part.replace(/[-_]/g, ''));

                // CamelCase variations
                variations.add(this.toCamelCase(part));
            });

            return Array.from(variations);
        }

        /**
         * Convert string to camelCase
         */
        toCamelCase(str) {
            return str.replace(/[-_](.)/g, (_, char) => char.toUpperCase());
        }

        /**
         * Search in plugin description
         */
        searchInDescription(description) {
            if (!description) return null;

            // Create a temporary element to parse HTML
            const temp = document.createElement('div');
            temp.innerHTML = description;

            // Look for links containing 'settings'
            const links = temp.querySelectorAll('a');
            for (const link of links) {
                if (this.textContains(link.textContent, 'settings')) {
                    return link.getAttribute('href');
                }
            }

            return null;
        }

        /**
         * Check if text contains substring (case-insensitive)
         */
        textContains(text, search) {
            return text.toLowerCase().includes(search.toLowerCase());
        }

        /**
         * Validate URL (check if it's internal and on same host)
         */
        isValidUrl(url) {
            if (!url || !url.length) return false;

            try {
                // Relative URLs are valid
                if (url.startsWith('/') || url.startsWith('admin.php') || url.startsWith('options')) {
                    return true;
                }

                // Check if absolute URL matches current host
                const urlObj = new URL(url, window.location.origin);
                return urlObj.host === window.location.host;
            } catch (e) {
                return false;
            }
        }

        /**
         * Get fallback text when no settings found
         */
        getFallbackText() {
            return this.config.get('settingsDiscovery.fallbackText', 'No Settings Found');
        }

        /**
         * Get fallback text color
         */
        getFallbackTextColor() {
            return this.config.get('settingsDiscovery.fallbackTextColor', '#999');
        }

        /**
         * Clear cache
         */
        clearCache() {
            this.cache = {};
        }

        /**
         * Logging helper
         */
        log(...args) {
            if (this.config.get('debug.enabled')) {
                console.log('[ABPS Discovery]', ...args);
            }
        }
    }

    // Expose class
    window.ABPSDiscoveryClass = ABPSDiscovery;

})(window);
