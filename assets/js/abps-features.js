/**
 * ABPS Features Module
 * Implements core features: link reordering, filtering, etc.
 *
 * @since 1.0.0
 */

(function(window) {
    'use strict';

    /**
     * Features Manager Class
     */
    class ABPSFeatures {
        constructor(config, storage, discovery) {
            this.config = config;
            this.storage = storage;
            this.discovery = discovery;
            this.pluginRows = [];
            this.filterTimeout = null;
        }

        /**
         * Initialize all enabled features
         */
        init() {
            this.collectPluginRows();

            // Run settings discovery BEFORE link reordering
            // This ensures discovered settings get properly ordered with separators
            if (this.config.get('features.settingsDiscovery')) {
                this.initSettingsDiscovery();
            }

            if (this.config.get('features.linkReordering')) {
                this.initLinkReordering();
            }

            if (this.config.get('features.pluginFiltering')) {
                this.initPluginFiltering();
            }
        }

        /**
         * Collect all plugin rows
         */
        collectPluginRows() {
            const table = document.querySelector('table.plugins');
            if (!table) {
                this.log('Plugin table not found');
                return;
            }

            const rows = table.querySelectorAll('#the-list tr.active');
            this.pluginRows = Array.from(rows).filter(row => {
                // Exclude update rows and ABPS itself
                return !row.classList.contains('plugin-update-tr');
            });

            this.log(`Collected ${this.pluginRows.length} plugin rows`);
        }

        /**
         * Initialize link reordering feature
         */
        initLinkReordering() {
            this.log('Initializing link reordering');

            this.pluginRows.forEach(row => {
                const slug = row.dataset.slug;
                const rowActions = row.querySelector('.row-actions');

                if (!rowActions) return;

                // Get all action links
                const actionSpans = Array.from(rowActions.querySelectorAll(':scope > span'));

                // Store original order
                actionSpans.forEach((span, index) => {
                    span.dataset.abpsOriginalOrder = index;
                    span.dataset.abpsOriginalClass = span.className;
                });

                // Get custom link order for this plugin, or use default
                const customOrder = this.storage.loadLinkOrder(slug);
                const linkOrder = customOrder || this.config.get('linkReordering.defaultOrder');

                // Reorder links
                this.reorderLinks(rowActions, actionSpans, linkOrder);
            });
        }

        /**
         * Reorder action links based on specified order
         */
        reorderLinks(container, actionSpans, order) {
            // Remove pipe separators
            actionSpans.forEach(span => {
                const html = span.innerHTML;
                span.innerHTML = html.replace(/\s*\|\s*/g, '');
            });

            // Create ordered array
            const ordered = [];
            let wildcardIndex = order.indexOf('*');

            order.forEach((linkName, index) => {
                if (linkName === '*') {
                    // Wildcard - add remaining links
                    actionSpans.forEach(span => {
                        if (!ordered.includes(span)) {
                            ordered.push(span);
                        }
                    });
                } else {
                    // Find specific link by class name
                    const span = actionSpans.find(s => s.classList.contains(linkName));
                    if (span && !ordered.includes(span)) {
                        ordered.push(span);
                    }
                }
            });

            // Add any remaining links not in order
            actionSpans.forEach(span => {
                if (!ordered.includes(span)) {
                    if (wildcardIndex >= 0) {
                        ordered.splice(wildcardIndex, 0, span);
                        wildcardIndex++;
                    } else {
                        ordered.push(span);
                    }
                }
            });

            // Clear container and re-append in new order
            container.innerHTML = '';
            ordered.forEach((span, index) => {
                span.dataset.abpsNewOrder = index;
                container.appendChild(span);
            });

            // Add pipe separators
            const spans = container.querySelectorAll(':scope > span');
            spans.forEach((span, index) => {
                if (index > 0) {
                    span.insertAdjacentHTML('beforebegin', ' | ');
                }
            });
        }

        /**
         * Initialize settings discovery feature
         */
        initSettingsDiscovery() {
            this.log('Initializing settings discovery');

            this.discovery.init();

            this.pluginRows.forEach(row => {
                const slug = row.dataset.slug;
                const pluginTitle = row.querySelector('.plugin-title strong');
                const rowActions = row.querySelector('.row-actions');

                if (!pluginTitle || !rowActions) return;

                // Check if Settings link already exists
                let settingsSpan = rowActions.querySelector('span.settings');

                if (settingsSpan && settingsSpan.querySelector('a')) {
                    // Settings link exists, no need to discover
                    return;
                }

                // Gather plugin data
                const pluginData = {
                    slug: slug,
                    name: pluginTitle.textContent,
                    file: row.dataset.plugin,
                    description: row.querySelector('.plugin-description')?.innerHTML || ''
                };

                // Check for custom settings URL first
                let settingsUrl = this.storage.loadCustomSettingsUrl(slug);

                // If no custom URL, try to discover
                if (!settingsUrl) {
                    settingsUrl = this.discovery.findSettingsUrl(pluginData);
                }

                // Create or update settings link
                if (settingsUrl) {
                    if (settingsSpan) {
                        settingsSpan.innerHTML = `<a href="${settingsUrl}">Settings</a>`;
                    } else {
                        settingsSpan = document.createElement('span');
                        settingsSpan.className = 'settings abps-discovered';
                        settingsSpan.innerHTML = `<a href="${settingsUrl}">Settings</a>`;
                        rowActions.insertBefore(settingsSpan, rowActions.firstChild);
                    }
                } else {
                    // No settings found - add placeholder
                    if (settingsSpan) {
                        settingsSpan.innerHTML = `<span style="color: ${this.discovery.getFallbackTextColor()}">${this.discovery.getFallbackText()}</span>`;
                    } else {
                        settingsSpan = document.createElement('span');
                        settingsSpan.className = 'settings abps-no-settings';
                        settingsSpan.innerHTML = `<span style="color: ${this.discovery.getFallbackTextColor()}">${this.discovery.getFallbackText()}</span>`;
                        rowActions.insertBefore(settingsSpan, rowActions.firstChild);
                    }
                }
            });
        }

        /**
         * Initialize plugin filtering feature
         */
        initPluginFiltering() {
            this.log('Initializing plugin filtering');

            const filterConfig = this.config.get('filterBox');
            const table = document.querySelector('table.plugins');

            if (!table) return;

            // Create filter box
            const filterBox = this.createFilterBox(filterConfig);

            // Insert filter box based on placement
            if (filterConfig.placement === 'above_plugins_list') {
                table.parentNode.insertBefore(filterBox, table);
            }

            // Set up filter event
            const filterInput = filterBox.querySelector('.abps-filter-input');
            const clearButton = filterBox.querySelector('.abps-filter-clear');

            if (filterInput) {
                filterInput.addEventListener('input', (e) => {
                    clearTimeout(this.filterTimeout);
                    this.filterTimeout = setTimeout(() => {
                        this.filterPlugins(e.target.value, filterConfig);
                    }, filterConfig.debounceMs);
                });

                filterInput.addEventListener('keyup', (e) => {
                    if (e.key === 'Escape') {
                        filterInput.value = '';
                        this.filterPlugins('', filterConfig);
                    }
                });
            }

            if (clearButton) {
                clearButton.addEventListener('click', () => {
                    filterInput.value = '';
                    this.filterPlugins('', filterConfig);
                    filterInput.focus();
                });
            }
        }

        /**
         * Create filter box HTML
         */
        createFilterBox(config) {
            const container = document.createElement('div');
            container.className = 'abps-filter-container';
            container.innerHTML = `
                <div class="abps-filter-wrapper">
                    <input
                        type="text"
                        class="abps-filter-input"
                        placeholder="${config.placeholder}"
                        aria-label="Filter plugins"
                    />
                    <button class="abps-filter-clear" title="Clear filter" aria-label="Clear filter">×</button>
                </div>
            `;

            return container;
        }

        /**
         * Filter plugins based on search term
         */
        filterPlugins(searchTerm, config) {
            const term = config.caseSensitive ? searchTerm : searchTerm.toLowerCase();

            let visibleCount = 0;

            this.pluginRows.forEach(row => {
                const matches = this.pluginMatchesFilter(row, term, config);

                if (matches || !term) {
                    row.style.display = '';
                    visibleCount++;
                } else {
                    row.style.display = 'none';
                }
            });

            // Dispatch custom event
            const event = new CustomEvent('abps:filter_changed', {
                detail: { searchTerm: term, visibleCount: visibleCount }
            });
            document.dispatchEvent(event);

            this.log(`Filter: "${term}", visible: ${visibleCount}`);
        }

        /**
         * Check if plugin matches filter criteria
         */
        pluginMatchesFilter(row, term, config) {
            if (!term) return true;

            const searchableFields = config.searchableFields;

            for (const field of searchableFields) {
                let value = '';

                switch (field) {
                    case 'name':
                        value = row.querySelector('.plugin-title strong')?.textContent || '';
                        break;
                    case 'slug':
                        value = row.dataset.slug || '';
                        break;
                    case 'description':
                        // Only get the visible description text, not hidden content
                        const descEl = row.querySelector('.plugin-description');
                        if (descEl) {
                            // Get only visible text by checking each text node
                            value = this.getVisibleText(descEl);
                        }
                        break;
                    case 'author':
                        const authorEl = row.querySelector('.plugin-author');
                        if (authorEl) {
                            // Get visible author text
                            value = this.getVisibleText(authorEl);
                        }
                        break;
                }

                if (!config.caseSensitive) {
                    value = value.toLowerCase();
                }

                if (value.includes(term)) {
                    return true;
                }
            }

            return false;
        }

        /**
         * Get only visible text from an element (excludes hidden elements)
         */
        getVisibleText(element) {
            let text = '';

            // Walk through all child nodes
            const walker = document.createTreeWalker(
                element,
                NodeFilter.SHOW_TEXT | NodeFilter.SHOW_ELEMENT,
                {
                    acceptNode: function(node) {
                        // If it's a text node, check if parent is visible
                        if (node.nodeType === Node.TEXT_NODE) {
                            const parent = node.parentElement;
                            if (parent) {
                                const style = window.getComputedStyle(parent);
                                // Only include if element is visible
                                if (style.display !== 'none' && style.visibility !== 'hidden' && style.opacity !== '0') {
                                    return NodeFilter.FILTER_ACCEPT;
                                }
                            }
                            return NodeFilter.FILTER_REJECT;
                        }
                        // For elements, check if they're hidden
                        if (node.nodeType === Node.ELEMENT_NODE) {
                            const style = window.getComputedStyle(node);
                            if (style.display === 'none' || style.visibility === 'hidden' || style.opacity === '0') {
                                return NodeFilter.FILTER_REJECT;
                            }
                        }
                        return NodeFilter.FILTER_SKIP;
                    }
                }
            );

            let node;
            while (node = walker.nextNode()) {
                if (node.nodeType === Node.TEXT_NODE) {
                    text += node.textContent;
                }
            }

            return text.trim();
        }

        /**
         * Revert link order to original
         */
        revertToOriginalOrder() {
            this.pluginRows.forEach(row => {
                const rowActions = row.querySelector('.row-actions');
                if (!rowActions) return;

                const actionSpans = Array.from(rowActions.querySelectorAll(':scope > span'));

                // Sort by original order
                actionSpans.sort((a, b) => {
                    const orderA = parseInt(a.dataset.abpsOriginalOrder);
                    const orderB = parseInt(b.dataset.abpsOriginalOrder);
                    return orderA - orderB;
                });

                // Clear and re-append
                rowActions.innerHTML = '';
                actionSpans.forEach((span, index) => {
                    if (index > 0) {
                        rowActions.appendChild(document.createTextNode(' | '));
                    }
                    rowActions.appendChild(span);
                });
            });
        }

        /**
         * Logging helper
         */
        log(...args) {
            if (this.config.get('debug.enabled')) {
                console.log('[ABPS Features]', ...args);
            }
        }
    }

    // Expose class
    window.ABPSFeaturesClass = ABPSFeatures;

})(window);
