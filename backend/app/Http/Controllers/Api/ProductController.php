<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\Request;

class ProductController extends Controller
{
    // GET /api/products?barcode=xxx  OR  GET /api/products
    public function index(Request $request)
    {
        $shopId = $request->user()->shop_id;

        if ($request->filled('barcode')) {
            $product = Product::where('shop_id', $shopId)
                ->where('barcode', $request->barcode)
                ->first();
            if (! $product) {
                return response()->json(['message' => 'Product not found.'], 404);
            }
            return response()->json($product);
        }

        return response()->json(
            Product::where('shop_id', $shopId)->orderBy('name')->get()
        );
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name'                => 'required|string|max:255',
            'barcode'             => 'required|string|unique:products,barcode',
            'price'               => 'required|numeric|min:0',
            'stock'               => 'required|integer|min:0',
            'category'            => 'required|string|max:100',
            'image'               => 'nullable|string',
            'low_stock_threshold' => 'nullable|integer|min:0',
        ]);

        $data['shop_id'] = $request->user()->shop_id;

        $product = Product::create($data);

        return response()->json($product, 201);
    }

    public function show(Request $request, string $id)
    {
        $product = Product::where('shop_id', $request->user()->shop_id)
            ->findOrFail($id);

        return response()->json($product);
    }

    public function update(Request $request, string $id)
    {
        $product = Product::where('shop_id', $request->user()->shop_id)
            ->findOrFail($id);

        $data = $request->validate([
            'name'                => 'sometimes|string|max:255',
            'barcode'             => 'sometimes|string|unique:products,barcode,' . $product->id,
            'price'               => 'sometimes|numeric|min:0',
            'stock'               => 'sometimes|integer|min:0',
            'category'            => 'sometimes|string|max:100',
            'image'               => 'nullable|string',
            'low_stock_threshold' => 'nullable|integer|min:0',
        ]);

        $product->update($data);

        return response()->json($product);
    }

    public function destroy(Request $request, string $id)
    {
        Product::where('shop_id', $request->user()->shop_id)
            ->findOrFail($id)
            ->delete();

        return response()->json(['message' => 'Product deleted.']);
    }
}
