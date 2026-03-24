<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS, PUT, DELETE');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Simple test endpoint
if ($_SERVER['REQUEST_METHOD'] == 'GET' && $_SERVER['REQUEST_URI'] == '/') {
    echo json_encode(['message' => 'Tera POS API Server is running!']);
    exit();
}

// Mock login endpoint
if ($_SERVER['REQUEST_METHOD'] == 'POST' && $_SERVER['REQUEST_URI'] == '/api/login') {
    $input = json_decode(file_get_contents('php://input'), true);
    
    // Always return success for testing
    echo json_encode([
        'token' => 'mock_jwt_token_' . time(),
        'user' => [
            'id' => 1,
            'firstName' => 'Test',
            'lastName' => 'User',
            'email' => $input['email'] ?? 'test@example.com',
            'phone' => '+1234567890',
            'roleName' => 'admin',
            'companyId' => null
        ]
    ]);
    exit();
}

// Mock register endpoint  
if ($_SERVER['REQUEST_METHOD'] == 'POST' && $_SERVER['REQUEST_URI'] == '/api/register') {
    $input = json_decode(file_get_contents('php://input'), true);
    
    echo json_encode([
        'token' => 'mock_jwt_token_' . time(),
        'user' => [
            'id' => 2,
            'firstName' => $input['firstName'] ?? 'New',
            'lastName' => $input['lastName'] ?? 'User',
            'email' => $input['email'] ?? 'new@example.com',
            'phone' => $input['phone'] ?? '+1234567891',
            'roleName' => $input['roleName'] ?? 'user',
            'companyId' => $input['companyId'] ?? null
        ]
    ]);
    exit();
}

// Mock me endpoint
if ($_SERVER['REQUEST_METHOD'] == 'GET' && $_SERVER['REQUEST_URI'] == '/api/me') {
    echo json_encode([
        'id' => 1,
        'firstName' => 'Test',
        'lastName' => 'User',
        'email' => 'test@example.com',
        'phone' => '+1234567890',
        'roleName' => 'admin',
        'companyId' => null
    ]);
    exit();
}

// 404 for other routes
http_response_code(404);
echo json_encode(['error' => 'Endpoint not found']);
?>
