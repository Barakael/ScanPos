<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Shop;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class ShopController extends Controller
{
    public function index()
    {
        $shops = Shop::with('owner:id,name,email')
            ->withCount([
                'branches',
                'users as staff_count' => fn ($q) => $q->where('role', 'cashier'),
            ])
            ->latest()
            ->get();

        return response()->json($shops);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name'           => 'required|string|max:255',
            'address'        => 'nullable|string|max:500',
            'phone'          => 'nullable|string|max:50',
            'email'          => 'nullable|email|max:255',
            'owner_name'     => 'required|string|max:255',
            'owner_email'    => 'required|email|unique:users,email',
            'owner_password' => 'required|string|min:8',
        ]);

        return DB::transaction(function () use ($data) {
            // 1 — create the owner user (shop_id is assigned after shop creation)
            $owner = User::create([
                'name'     => $data['owner_name'],
                'email'    => $data['owner_email'],
                'password' => Hash::make($data['owner_password']),
                'role'     => 'owner',
            ]);

            // 2 — create the shop
            $shop = Shop::create([
                'name'     => $data['name'],
                'address'  => $data['address'] ?? null,
                'phone'    => $data['phone'] ?? null,
                'email'    => $data['email'] ?? null,
                'owner_id' => $owner->id,
            ]);

            // 3 — link the owner user back to the shop
            $owner->update(['shop_id' => $shop->id]);

            $shop->load('owner:id,name,email');
            $shop->loadCount(['branches', 'users as staff_count' => fn ($q) => $q->where('role', 'cashier')]);

            return response()->json($shop, 201);
        });
    }

    public function update(Request $request, Shop $shop)
    {
        $data = $request->validate([
            'name'    => 'sometimes|string|max:255',
            'address' => 'nullable|string|max:500',
            'phone'   => 'nullable|string|max:50',
            'email'   => 'nullable|email|max:255',
        ]);

        $shop->update($data);

        return response()->json($shop->fresh()->load('owner:id,name,email'));
    }

    public function destroy(Shop $shop)
    {
        $shop->delete();

        return response()->json(['message' => 'Shop deleted.']);
    }
}
