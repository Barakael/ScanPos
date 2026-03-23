<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Models\Sale;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    public function index(Request $request)
    {
        $user   = $request->user();
        $shopId = $user->shop_id;
        $today  = today();

        // For owner: aggregate across all branches of their shop (same shop_id)
        // For cashier: scoped to their own branch via cashier_id lookup
        $salesQuery = Sale::whereHas('cashier', fn($q) => $q->where('shop_id', $shopId));

        $todaySales        = (clone $salesQuery)->whereDate('created_at', $today)->get();
        $todayTotal        = $todaySales->sum('total');
        $todayTransactions = $todaySales->count();

        $productQuery = Product::where('shop_id', $shopId);

        // Low-stock products
        $lowStock = (clone $productQuery)
            ->whereColumn('stock', '<=', 'low_stock_threshold')
            ->orderBy('stock')
            ->get();

        // Category breakdown
        $categoryStock = (clone $productQuery)
            ->select('category', DB::raw('SUM(stock) as total_stock'))
            ->groupBy('category')
            ->get();

        // Last 7 days daily totals
        $weeklySales = (clone $salesQuery)
            ->select(
                DB::raw('DATE(created_at) as date'),
                DB::raw('SUM(total) as total'),
                DB::raw('COUNT(*) as transactions')
            )
            ->where('created_at', '>=', now()->subDays(6)->startOfDay())
            ->groupBy(DB::raw('DATE(created_at)'))
            ->orderBy('date')
            ->get();

        return response()->json([
            'today_total'        => $todayTotal,
            'today_transactions' => $todayTransactions,
            'total_products'     => (clone $productQuery)->count(),
            'low_stock_count'    => $lowStock->count(),
            'low_stock_items'    => $lowStock,
            'category_stock'     => $categoryStock,
            'weekly_sales'       => $weeklySales,
        ]);
    }
}
