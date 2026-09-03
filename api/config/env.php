<?php
// api/config/env.php

class Env {
    private static $env = [];

    public static function load($path = null) {
        if ($path === null) {
            $path = dirname(__DIR__) . '/.env';
        }

        if (!file_exists($path)) {
            return;
        }

        $lines = file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        foreach ($lines as $line) {
            $line = trim($line);
            if (empty($line) || $line[0] === '#') {
                continue;
            }

            if (strpos($line, '=') !== false) {
                list($name, $value) = explode('=', $line, 2);
                $name = trim($name);
                $value = trim($value);
                // Remove quotes
                $value = trim($value, '"\'');
                self::$env[$name] = $value;
                putenv("$name=$value");
                $_ENV[$name] = $value;
                $_SERVER[$name] = $value;
            }
        }
    }

    public static function get($key, $default = null) {
        if (isset(self::$env[$key])) {
            return self::$env[$key];
        }
        $val = getenv($key);
        return $val !== false ? $val : $default;
    }
}

// Auto-load on include
Env::load();
