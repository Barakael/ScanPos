<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Shop;
use App\Models\Subscription;
use App\Models\SubscriptionPayment;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class BpmReportController extends Controller
{
    /**
     * GET /api/bpm/overview
     *
     * General snapshot used by the BPM system to monitor the platform at a glance:
     * - Shops: total registered, added this week, added this month
     * - Subscriptions: active total, payments paid this week / this month,
     *   corresponding revenue, and overdue pending invoices
     */
    public function overview(): JsonResponse
    {
        $now        = now();
        $weekStart  = $now->copy()->startOfIsoWeek();
        $monthStart = $now->copy()->startOfMonth();

        return response()->json([
            'shops' => [
                'total'            => Shop::count(),
                'added_this_week'  => Shop::where('created_at', '>=', $weekStart)->count(),
                'added_this_month' => Shop::where('created_at', '>=', $monthStart)->count(),
            ],
            'subscriptions' => [
                'active_total'          => Subscription::where('status', 'active')->count(),
                'paid_this_week'        => SubscriptionPayment::where('status', 'paid')
                                            ->where('paid_at', '>=', $weekStart)
                                            ->count(),
                'paid_this_month'       => SubscriptionPayment::where('status', 'paid')
                                            ->where('paid_at', '>=', $monthStart)
                                            ->count(),
                'revenue_this_week'     => (float) SubscriptionPayment::where('status', 'paid')
                                            ->where('paid_at', '>=', $weekStart)
                                            ->sum('amount'),
                'revenue_this_month'    => (float) SubscriptionPayment::where('status', 'paid')
                                            ->where('paid_at', '>=', $monthStart)
                                            ->sum('amount'),
                'pending_overdue'       => SubscriptionPayment::where('status', 'pending')
                                            ->where('due_date', '<', today())
                                            ->count(),
            ],
            'generated_at' => $now->toIso8601String(),
        ]);
    }

    /**
     * GET /api/bpm/report/weekly?weeks=12
     *
     * Weekly breakdown for the last N ISO weeks (default 12, max 52).
     * Each period shows: new shops registered, paid subscription payments,
     * and total subscription revenue collected.
     */
    public function weekly(Request $request): JsonResponse
    {
        $weeks = min((int) $request->input('weeks', 12), 52);
        $from  = now()->subWeeks($weeks - 1)->startOfIsoWeek();

        // New shops per ISO week  (%x = ISO year, %v = ISO week 01-53)
        $shopRows = Shop::select(
                DB::raw("DATE_FORMAT(created_at, '%x-%v') AS period"),
                DB::raw('COUNT(*) AS new_shops')
            )
            ->where('created_at', '>=', $from)
            ->groupBy('period')
            ->orderBy('period')
            ->pluck('new_shops', 'period');

        // Paid subscription payments per ISO week
        $paymentRows = SubscriptionPayment::select(
                DB::raw("DATE_FORMAT(paid_at, '%x-%v') AS period"),
                DB::raw('COUNT(*) AS paid_count'),
                DB::raw('SUM(amount) AS revenue')
            )
            ->where('status', 'paid')
            ->where('paid_at', '>=', $from)
            ->groupBy('period')
            ->orderBy('period')
            ->get()
            ->keyBy('period');

        // Build a contiguous list of all ISO week periods
        $periods = [];
        $cursor  = $from->copy();

        while ($cursor->lte(now())) {
            // PHP 'o' = ISO year, 'W' = ISO week number (01-53), matches MySQL %x-%v
            $key = $cursor->format('o-W');

            $periods[] = [
                'period'               => $key,
                'new_shops'            => (int)   ($shopRows[$key]              ?? 0),
                'paid_subscriptions'   => (int)   ($paymentRows[$key]?->paid_count ?? 0),
                'subscription_revenue' => (float) ($paymentRows[$key]?->revenue    ?? 0),
            ];

            $cursor->addWeek();
        }

        return response()->json([
            'period_type' => 'weekly',
            'periods'     => $periods,
        ]);
    }

    /**
     * GET /api/bpm/report/monthly?months=12
     *
     * Monthly breakdown for the last N months (default 12, max 24).
     * Each period shows: new shops registered, paid subscription payments,
     * and total subscription revenue collected.
     */
    public function monthly(Request $request): JsonResponse
    {
        $months = min((int) $request->input('months', 12), 24);
        $from   = now()->subMonths($months - 1)->startOfMonth();

        // New shops per calendar month
        $shopRows = Shop::select(
                DB::raw("DATE_FORMAT(created_at, '%Y-%m') AS period"),
                DB::raw('COUNT(*) AS new_shops')
            )
            ->where('created_at', '>=', $from)
            ->groupBy('period')
            ->orderBy('period')
            ->pluck('new_shops', 'period');

        // Paid subscription payments per calendar month
        $paymentRows = SubscriptionPayment::select(
                DB::raw("DATE_FORMAT(paid_at, '%Y-%m') AS period"),
                DB::raw('COUNT(*) AS paid_count'),
                DB::raw('SUM(amount) AS revenue')
            )
            ->where('status', 'paid')
            ->where('paid_at', '>=', $from)
            ->groupBy('period')
            ->orderBy('period')
            ->get()
            ->keyBy('period');

        // Build a contiguous list of all calendar month periods
        $periods = [];
        $cursor  = $from->copy();

        while ($cursor->lte(now())) {
            $key = $cursor->format('Y-m');

            $periods[] = [
                'period'               => $key,
                'new_shops'            => (int)   ($shopRows[$key]              ?? 0),
                'paid_subscriptions'   => (int)   ($paymentRows[$key]?->paid_count ?? 0),
                'subscription_revenue' => (float) ($paymentRows[$key]?->revenue    ?? 0),
            ];

            $cursor->addMonth();
        }

        return response()->json([
            'period_type' => 'monthly',
            'periods'     => $periods,
        ]);
    }
}
