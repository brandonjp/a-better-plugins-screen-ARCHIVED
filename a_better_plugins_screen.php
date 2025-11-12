<?php
/*
Plugin Name: A Better Plugins Screen
Plugin URI: https://github.com/brandonjp/a-better-plugins-screen
GitHub Plugin URI: https://github.com/brandonjp/a-better-plugins-screen
Description: Enhances the WordPress plugins screen with intelligent link reordering, settings discovery, real-time filtering, and configuration options. Zero configuration required - works out of the box!
Version: 1.0.0
Author: Brandon Pfeiffer
Author URI: http://brandonjp.com
Requires at least: 5.0
Tested up to: 6.4
Requires PHP: 7.0

Text Domain: a-better-plugins-screen
Domain Path: /languages

License: GPL v3 or later
License URI: https://www.gnu.org/licenses/gpl-3.0.html
*/

// Exit if accessed directly
if (!defined('ABSPATH')) {
    exit;
}

// Define plugin constants
define('ABPS_VERSION', '1.0.0');
define('ABPS_PLUGIN_DIR', plugin_dir_path(__FILE__));
define('ABPS_PLUGIN_URL', plugin_dir_url(__FILE__));
define('ABPS_PLUGIN_FILE', __FILE__);

// Require Dependencies: https://github.com/afragen/wp-dependency-installer#description
require_once ABPS_PLUGIN_DIR . 'vendor/autoload.php';

add_action('plugins_loaded', function() {
    WP_Dependency_Installer::instance(ABPS_PLUGIN_DIR)->run();
});

/**
 * Main ABPS Class
 */
class A_Better_Plugins_Screen {

    /**
     * Instance of this class
     */
    private static $instance = null;

    /**
     * Get instance
     */
    public static function get_instance() {
        if (null === self::$instance) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    /**
     * Constructor
     */
    private function __construct() {
        add_action('admin_enqueue_scripts', array($this, 'enqueue_assets'));
        add_action('admin_init', array($this, 'check_compatibility'));
    }

    /**
     * Check WordPress and PHP compatibility
     */
    public function check_compatibility() {
        global $wp_version;

        // Check WordPress version
        if (version_compare($wp_version, '5.0', '<')) {
            add_action('admin_notices', array($this, 'admin_notice_wp_version'));
            return false;
        }

        // Check PHP version
        if (version_compare(PHP_VERSION, '7.0', '<')) {
            add_action('admin_notices', array($this, 'admin_notice_php_version'));
            return false;
        }

        return true;
    }

    /**
     * Admin notice for WordPress version
     */
    public function admin_notice_wp_version() {
        ?>
        <div class="notice notice-error">
            <p>
                <strong>A Better Plugins Screen:</strong>
                This plugin requires WordPress 5.0 or higher. Please update WordPress.
            </p>
        </div>
        <?php
    }

    /**
     * Admin notice for PHP version
     */
    public function admin_notice_php_version() {
        ?>
        <div class="notice notice-error">
            <p>
                <strong>A Better Plugins Screen:</strong>
                This plugin requires PHP 7.0 or higher. Please contact your hosting provider to upgrade PHP.
            </p>
        </div>
        <?php
    }

    /**
     * Enqueue assets only on plugins screen
     */
    public function enqueue_assets($hook) {
        // Only run on plugins page
        if ('plugins.php' !== $hook) {
            return;
        }

        // Enqueue CSS
        wp_enqueue_style(
            'abps-main-css',
            ABPS_PLUGIN_URL . 'assets/css/abps-main.css',
            array(),
            ABPS_VERSION
        );

        // Enqueue JavaScript files in correct order
        // 1. Configuration (no dependencies)
        wp_enqueue_script(
            'abps-config',
            ABPS_PLUGIN_URL . 'assets/js/abps-config.js',
            array(),
            ABPS_VERSION,
            true
        );

        // 2. Storage (no dependencies)
        wp_enqueue_script(
            'abps-storage',
            ABPS_PLUGIN_URL . 'assets/js/abps-storage.js',
            array(),
            ABPS_VERSION,
            true
        );

        // 3. Discovery (depends on config)
        wp_enqueue_script(
            'abps-discovery',
            ABPS_PLUGIN_URL . 'assets/js/abps-discovery.js',
            array('abps-config'),
            ABPS_VERSION,
            true
        );

        // 4. Features (depends on config, storage, discovery)
        wp_enqueue_script(
            'abps-features',
            ABPS_PLUGIN_URL . 'assets/js/abps-features.js',
            array('abps-config', 'abps-storage', 'abps-discovery'),
            ABPS_VERSION,
            true
        );

        // 5. UI (depends on config, storage, features)
        wp_enqueue_script(
            'abps-ui',
            ABPS_PLUGIN_URL . 'assets/js/abps-ui.js',
            array('abps-config', 'abps-storage', 'abps-features'),
            ABPS_VERSION,
            true
        );

        // 6. Main initialization (depends on all above)
        wp_enqueue_script(
            'abps-main',
            ABPS_PLUGIN_URL . 'assets/js/abps-main.js',
            array('abps-config', 'abps-storage', 'abps-discovery', 'abps-features', 'abps-ui'),
            ABPS_VERSION,
            true
        );

        // Pass data to JavaScript
        wp_localize_script('abps-main', 'abpsData', array(
            'version' => ABPS_VERSION,
            'pluginUrl' => ABPS_PLUGIN_URL,
            'ajaxUrl' => admin_url('admin-ajax.php'),
            'nonce' => wp_create_nonce('abps-nonce'),
            'strings' => array(
                'searchPlaceholder' => __('Search plugins...', 'a-better-plugins-screen'),
                'noSettingsFound' => __('No Settings Found', 'a-better-plugins-screen'),
                'settingsSaved' => __('Settings saved successfully!', 'a-better-plugins-screen'),
                'settingsReset' => __('Settings reset to defaults', 'a-better-plugins-screen'),
                'confirmReset' => __('Are you sure you want to reset all settings?', 'a-better-plugins-screen')
            )
        ));
    }
}

// Initialize the plugin
A_Better_Plugins_Screen::get_instance();

/**
 * Activation hook
 */
register_activation_hook(__FILE__, function() {
    // Set activation flag
    set_transient('abps_activated', true, 60);
});

/**
 * Display activation notice
 */
add_action('admin_notices', function() {
    if (get_transient('abps_activated')) {
        delete_transient('abps_activated');
        ?>
        <div class="notice notice-success is-dismissible">
            <p>
                <strong>⚡ A Better Plugins Screen</strong> is now active!
                Visit the <a href="<?php echo admin_url('plugins.php'); ?>">Plugins page</a>
                to see the improvements.
            </p>
        </div>
        <?php
    }
});

/**
 * Deactivation hook
 */
register_deactivation_hook(__FILE__, function() {
    // Clean up transients
    delete_transient('abps_activated');
});
