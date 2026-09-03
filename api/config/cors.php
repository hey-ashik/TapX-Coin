<?php
// api/config/cors.php

require_once __DIR__ . '/env.php';

function handleCors() {
    $origin = isset($_SERVER['HTTP_ORIGIN']) ? $_SERVER['HTTP_ORIGIN'] : '*';
    header("Access-Control-Allow-Origin: $origin");
    header("Access-Control-Allow-Credentials: true");
    header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
    header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, X-Session-Token");

    if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        http_response_code(200);
        exit(0);
    }
}

function jsonResponse($data, $statusCode = 200) {
    http_response_code($statusCode);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode($data, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    exit;
}

function jsonError($message, $statusCode = 400, $errors = null) {
    $response = [
        'success' => false,
        'message' => $message,
    ];
    if ($errors !== null) {
        $response['errors'] = $errors;
    }
    jsonResponse($response, $statusCode);
}

function jsonSuccess($data = [], $message = 'Success', $statusCode = 200) {
    $response = [
        'success' => true,
        'message' => $message,
        'data' => $data,
    ];
    jsonResponse($response, $statusCode);
}

function getJsonInput() {
    $raw = file_get_contents('php://input');
    if (empty($raw)) {
        return $_POST;
    }
    $decoded = json_decode($raw, true);
    return is_array($decoded) ? $decoded : $_POST;
}

function getBearerToken() {
    $headers = [];
    if (function_exists('getallheaders')) {
        $headers = getallheaders();
    } elseif (function_exists('apache_request_headers')) {
        $headers = apache_request_headers();
    }

    if (!empty($headers)) {
        foreach ($headers as $key => $val) {
            if (strtolower($key) === 'authorization') {
                if (preg_match('/Bearer\s(\S+)/i', $val, $matches)) {
                    return $matches[1];
                }
            }
        }
    }

    if (isset($_SERVER['HTTP_AUTHORIZATION'])) {
        if (preg_match('/Bearer\s(\S+)/i', $_SERVER['HTTP_AUTHORIZATION'], $matches)) {
            return $matches[1];
        }
    }

    if (isset($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) {
        if (preg_match('/Bearer\s(\S+)/i', $_SERVER['REDIRECT_HTTP_AUTHORIZATION'], $matches)) {
            return $matches[1];
        }
    }

    if (isset($_GET['token'])) {
        return $_GET['token'];
    }

    return null;
}

// Invoke CORS immediately
handleCors();
