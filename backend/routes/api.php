<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\ProductController;
use App\Http\Controllers\Api\SaleController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\SettingsController;
use App\Http\Controllers\Api\ShopController;
use App\Http\Controllers\Api\MyShopController;
use Illuminate\Support\Facades\Route;

// Public
Route::post('/login', [AuthController::class, 'login']);

// Authenticated (any role)
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);

    // POS — read products & lookup by barcode
    Route::get('/products', [ProductController::class, 'index']);
    Route::get('/products/{id}', [ProductController::class, 'show']);

    // POS — complete a sale (cashier+)
    Route::post('/sales', [SaleController::class, 'store']);
    Route::get('/sales', [SaleController::class, 'index']);
    Route::get('/sales/{id}', [SaleController::class, 'show']);

    // Dashboard
    Route::get('/dashboard', [DashboardController::class, 'index']);

    // Inventory management — owner / super_admin only
    Route::middleware('can:manage-inventory')->group(function () {
        Route::post('/products', [ProductController::class, 'store']);
        Route::put('/products/{id}', [ProductController::class, 'update']);
        Route::patch('/products/{id}', [ProductController::class, 'update']);
        Route::delete('/products/{id}', [ProductController::class, 'destroy']);
    });

    // User management — super_admin only
    Route::middleware('can:manage-users')->group(function () {
        Route::get('/users', [UserController::class, 'index']);
        Route::post('/users', [UserController::class, 'store']);
        Route::put('/users/{user}', [UserController::class, 'update']);
        Route::delete('/users/{user}', [UserController::class, 'destroy']);
    });

    // Settings — super_admin only
    Route::middleware('can:manage-settings')->group(function () {
        Route::get('/settings', [SettingsController::class, 'index']);
        Route::put('/settings', [SettingsController::class, 'update']);
    });

    // Shop management — super_admin only
    Route::middleware('can:manage-shops')->group(function () {
        Route::get('/shops', [ShopController::class, 'index']);
        Route::post('/shops', [ShopController::class, 'store']);
        Route::put('/shops/{shop}', [ShopController::class, 'update']);
        Route::delete('/shops/{shop}', [ShopController::class, 'destroy']);
    });

    // My shop — owner only
    Route::middleware('can:manage-my-shop')->group(function () {
        Route::get('/my-shop', [MyShopController::class, 'show']);
        Route::put('/my-shop', [MyShopController::class, 'update']);
        Route::get('/my-shop/branches', [MyShopController::class, 'branches']);
        Route::post('/my-shop/branches', [MyShopController::class, 'createBranch']);
        Route::put('/my-shop/branches/{branch}', [MyShopController::class, 'updateBranch']);
        Route::delete('/my-shop/branches/{branch}', [MyShopController::class, 'destroyBranch']);
        Route::get('/my-shop/staff', [MyShopController::class, 'staff']);
        Route::post('/my-shop/staff', [MyShopController::class, 'createStaff']);
        Route::put('/my-shop/staff/{user}', [MyShopController::class, 'updateStaff']);
        Route::delete('/my-shop/staff/{user}', [MyShopController::class, 'destroyStaff']);
    });
});
