<?php

use App\Http\Controllers\Api\ActivityLogController;
use App\Http\Controllers\Api\AdminReportsController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BpmReportController;
use App\Http\Controllers\Api\BranchController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\PlanController;
use App\Http\Controllers\Api\ProductController;
use App\Http\Controllers\Api\SaleController;
use App\Http\Controllers\Api\ShopController;
use App\Http\Controllers\Api\StaffController;
use App\Http\Controllers\Api\SubscriptionController;
use App\Http\Controllers\Api\SubscriptionPaymentController;
use App\Http\Controllers\Api\UserController;
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

    // Categories — readable by all staff, writable by owner/super_admin
    Route::get('/categories', [CategoryController::class, 'index']);

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

        // Category CRUD
        Route::post('/categories', [CategoryController::class, 'store']);
        Route::delete('/categories/{id}', [CategoryController::class, 'destroy']);
    });

    // User management — super_admin only
    Route::middleware('can:manage-users')->group(function () {
        Route::get('/users', [UserController::class, 'index']);
        Route::put('/users/{user}', [UserController::class, 'update']);
        Route::delete('/users/{user}', [UserController::class, 'destroy']);
        // Activity logs & admin reports (super_admin only, reuse manage-users gate)
        Route::get('/activity-logs', [ActivityLogController::class, 'index']);
        Route::get('/admin/reports', [AdminReportsController::class, 'index']);
    });

    // Shop management — super_admin
    Route::middleware('can:manage-shops')->group(function () {
        Route::get('/shops', [ShopController::class, 'index']);
        Route::post('/shops', [ShopController::class, 'store']);
        Route::get('/shops/{shop}', [ShopController::class, 'show']);
        Route::put('/shops/{shop}', [ShopController::class, 'update']);
        Route::delete('/shops/{shop}', [ShopController::class, 'destroy']);
    });

    // Branch management — owner
    Route::middleware('can:manage-branch')->group(function () {
        Route::get('/branches', [BranchController::class, 'index']);
        Route::post('/branches', [BranchController::class, 'store']);
        Route::put('/branches/{branch}', [BranchController::class, 'update']);
        Route::delete('/branches/{branch}', [BranchController::class, 'destroy']);
    });

    // Staff management — owner
    Route::middleware('can:manage-staff')->group(function () {
        Route::get('/staff', [StaffController::class, 'index']);
        Route::post('/staff', [StaffController::class, 'store']);
        Route::put('/staff/{user}', [StaffController::class, 'update']);
        Route::delete('/staff/{user}', [StaffController::class, 'destroy']);
    });

    // Shop settings — owner (edit own shop)
    Route::middleware('can:manage-settings')->group(function () {
        Route::get('/settings', [ShopController::class, 'showOwnerShop']);
        Route::put('/settings', [ShopController::class, 'updateOwnerShop']);
    });

    // Plans — visible to all authenticated users
    Route::get('/plans', [PlanController::class, 'index']);

    // Subscriptions — owner can view their own; super_admin can view all + assign
    Route::middleware('can:view-subscription')->group(function () {
        Route::get('/subscriptions', [SubscriptionController::class, 'index']);
        Route::get('/subscription-payments', [SubscriptionPaymentController::class, 'index']);
    });

    // Subscription management — super_admin only
    Route::middleware('can:manage-subscriptions')->group(function () {
        Route::post('/subscriptions', [SubscriptionController::class, 'store']);
        Route::put('/subscription-payments/{id}/mark-paid', [SubscriptionPaymentController::class, 'markPaid']);
    });
});

// BPM system reports — authenticated via BPM_API_KEY (Authorization: Bearer <key>)
Route::middleware('bpm.apikey')->group(function () {
    Route::get('/bpm/overview',       [BpmReportController::class, 'overview']);
    Route::get('/bpm/report/weekly',  [BpmReportController::class, 'weekly']);
    Route::get('/bpm/report/monthly', [BpmReportController::class, 'monthly']);
});
