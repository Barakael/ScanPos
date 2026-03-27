<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ActivityLog;
use App\Models\Product;
use App\Models\Sale;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SaleController extends Controller
{
    // GET /api/sales?date=2026-03-09  OR  GET /api/sales (last 30 days)
    public function index(Request $request)
    {
        $query = Sale::with(['items', 'cashier:id,name'])
            ->orderByDesc('created_at');

        // Scope by shop: super_admin sees all, others see only their shop's sales
        $user = $request->user();
        if ($user->role !== 'super_admin' && $user->shop_id) {
            $cashierIds = User::where('shop_id', $user->shop_id)->pluck('id');
            $query->whereIn('cashier_id', $cashierIds);
        }

        if ($request->filled('date')) {
            $query->whereDate('created_at', $request->date);
        } else {
            $query->where('created_at', '>=', now()->subDays(30));
        }

        return response()->json($query->get());
    }

    // POST /api/sales
    // body: { payment_method, items: [{product_id, quantity}] }
    public function store(Request $request)
    {
        $request->validate([
            'payment_method'       => 'required|in:cash,card,mobile',
            'items'                => 'required|array|min:1',
            'items.*.product_id'   => 'required|exists:products,id',
            'items.*.quantity'     => 'required|integer|min:1',
        ]);

        $sale = DB::transaction(function () use ($request) {
            $subtotal  = 0;
            $saleItems = [];

            foreach ($request->items as $item) {
                /** @var Product $product */
                $product = Product::lockForUpdate()->findOrFail($item['product_id']);

                if ($product->stock < $item['quantity']) {
                    abort(422, "Insufficient stock for [{$product->name}]. Available: {$product->stock}");
                }

                $lineTotal  = $product->price * $item['quantity'];
                $subtotal  += $lineTotal;

                $product->decrement('stock', $item['quantity']);

                $saleItems[] = [
                    'product_id'   => $product->id,
                    'product_name' => $product->name,
                    'unit_price'   => $product->price,
                    'quantity'     => $item['quantity'],
                ];
            }

            // Tax is 18% inclusive — already contained in the price, not added on top
            $total = round($subtotal, 2);

            $sale = Sale::create([
                'cashier_id'     => $request->user()->id,
                'subtotal'       => round($subtotal, 2),
                'tax'            => 0,
                'total'          => $total,
                'payment_method' => $request->payment_method,
            ]);

            $sale->items()->createMany($saleItems);

            ActivityLog::record(
                'sale_created',
                "Sale #{$sale->id} · total {$sale->total} via {$request->payment_method} by {$request->user()->name}",
                $request->user()->id,
                $request->ip()
            );

            return $sale;
        });

        return response()->json(
            $sale->load(['items', 'cashier:id,name']),
            201
        );
    }

    public function show(string $id)
    {
        return response()->json(
            Sale::with(['items', 'cashier:id,name'])->findOrFail($id)
        );
    }

    // Not used — sales are immutable
    public function update(Request $request, string $id) { abort(405); }
    public function destroy(string $id) { abort(405); }
}
