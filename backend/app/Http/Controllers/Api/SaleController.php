<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ActivityLog;
use App\Models\Product;
use App\Models\Sale;
use App\Models\Shop;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SaleController extends Controller
{
    // GET /api/sales?date=2026-03-09  OR  GET /api/sales (last 30 days)
    public function index(Request $request)
    {
        $query = Sale::with(['items', 'cashier:id,name', 'shop'])
            ->orderByDesc('created_at');

        $user = $request->user();
        if ($user->role !== 'super_admin' && $user->shop_id) {
            $query->where('shop_id', $user->shop_id);
        }

        if ($request->filled('date')) {
            $query->whereDate('created_at', $request->date);
        } else {
            $query->where('created_at', '>=', now()->subDays(30));
        }

        return response()->json($query->get());
    }

    // POST /api/sales
    public function store(Request $request)
    {
        $request->validate([
            'payment_method'       => 'required|in:cash,card,mobile',
            'items'                => 'required|array|min:1',
            'items.*.product_id'   => 'required|exists:products,id',
            'items.*.quantity'     => 'required|integer|min:1',
            'customer_name'        => 'required|string|max:255',
            'customer_phone'       => 'required|string|max:64',
            'customer_address'     => 'required|string|max:255',
            'customer_id_type'     => 'nullable|string|max:64',
            'customer_id'          => 'nullable|string|max:128',
            'amount_tendered'      => 'required|numeric|min:0',
        ]);

        $sale = DB::transaction(function () use ($request) {
            $user = $request->user();
            if (! $user->shop_id) {
                abort(422, 'User is not assigned to a shop.');
            }

            /** @var Shop $shop */
            $shop = Shop::where('id', $user->shop_id)->lockForUpdate()->firstOrFail();

            $subtotal  = 0;
            $saleItems = [];

            foreach ($request->items as $item) {
                /** @var Product $product */
                $product = Product::lockForUpdate()->findOrFail($item['product_id']);

                if ($product->stock < $item['quantity']) {
                    abort(422, "Insufficient stock for [{$product->name}]. Available: {$product->stock}");
                }

                $lineTotal = $product->price * $item['quantity'];
                $subtotal += $lineTotal;

                $product->decrement('stock', $item['quantity']);

                $saleItems[] = [
                    'product_id'   => $product->id,
                    'product_name' => $product->name,
                    'unit_price'   => $product->price,
                    'quantity'     => $item['quantity'],
                ];
            }

            $total = round($subtotal, 2);

            $rate    = (float) ($shop->tax_rate ?? 18);
            $divisor = 1 + ($rate / 100);
            $totalExclTax = round($total / $divisor, 2);
            $totalTax     = round($total - $totalExclTax, 2);

            $amountTendered = round((float) $request->amount_tendered, 2);

            if ($request->payment_method === 'cash' && $amountTendered < $total) {
                abort(422, 'Amount tendered must be at least the sale total.');
            }

            if (in_array($request->payment_method, ['card', 'mobile'], true)) {
                $amountTendered = $total;
            }

            $cashChange = round(max(0, $amountTendered - $total), 2);

            $shop->receipt_counter = ((int) $shop->receipt_counter) + 1;
            $shop->save();

            $prefix        = $shop->serial_prefix ?: 'DEM';
            $serialNumber  = sprintf('%s-%s-%04d', $prefix, now()->format('Ym'), $shop->receipt_counter);
            $znr           = $serialNumber.'/Z';
            $uinSuffix     = preg_replace('/\D/', '', sprintf('%.6f', microtime(true)));
            $uin           = $serialNumber.$uinSuffix;
            $verification = strtoupper(substr(sha1($serialNumber.'|'.uniqid('', true)), 0, 12));

            $sale = Sale::create([
                'shop_id'             => $shop->id,
                'cashier_id'          => $user->id,
                'subtotal'            => round($subtotal, 2),
                'tax'                 => $totalTax,
                'total'               => $total,
                'payment_method'      => $request->payment_method,
                'serial_number'       => $serialNumber,
                'znr'                 => $znr,
                'uin'                 => $uin,
                'verification_code'   => $verification,
                'customer_name'       => $request->customer_name,
                'customer_phone'      => $request->customer_phone,
                'customer_address'    => $request->customer_address,
                'customer_id_type'    => $request->customer_id_type,
                'customer_id'         => $request->customer_id,
                'total_excl_tax'      => $totalExclTax,
                'total_tax'           => $totalTax,
                'amount_tendered'     => $amountTendered,
                'cash_change'         => $cashChange,
                'tax_rate_used'       => $rate,
            ]);

            $sale->items()->createMany($saleItems);

            ActivityLog::record(
                'sale_created',
                "Sale #{$sale->id} · {$serialNumber} · total {$sale->total} via {$request->payment_method} by {$user->name}",
                $user->id,
                $request->ip()
            );

            return $sale;
        });

        return response()->json(
            $sale->load(['items', 'cashier:id,name', 'shop']),
            201
        );
    }

    public function show(string $id)
    {
        return response()->json(
            Sale::with(['items', 'cashier:id,name', 'shop'])->findOrFail($id)
        );
    }

    public function update(Request $request, string $id) { abort(405); }
    public function destroy(string $id) { abort(405); }
}
