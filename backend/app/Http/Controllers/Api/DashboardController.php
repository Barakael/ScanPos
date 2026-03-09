<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Models\Sale;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    public function index()
    {
        $today = today();

        // Today's totals
        $todaySales = Sale::whereDate('created_at', $today)->get();
        $todayTotal        = $todaySales->sum('total');
        $todayTransactions = $todaySales->count();

        // Low-stock products
        $lowStock = Product::whereColumn('stock', '<=', 'low_stock_threshold')
            ->orderBy('stock')
            ->get();

        // Category breakdown  (sum of stock per category)
        $categoryStock = Product::select('category', DB::raw('SUM(stock) as total_stock'))
            ->groupBy('category')
            ->get();

        // Last 7 days daily totals
        $weeklySales = Sale::select(
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
            'total_products'     => Product::count(),
            'low_stock_count'    => $lowStock->count(),
            'low_stock_items'    => $lowStock,
            'category_stock'     => $categoryStock,
            'weekly_sales'       => $weeklySales,
        ]);
    }
}
