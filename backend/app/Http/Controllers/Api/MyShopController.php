<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Branch;
use App\Models\Shop;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class MyShopController extends Controller
{
    /** Resolve the authenticated owner's shop, or abort 404. */
    private function ownerShop(Request $request): Shop
    {
        $shop = Shop::where('owner_id', $request->user()->id)->first();

        if (! $shop) {
            abort(404, 'No shop is linked to your account. Contact a super admin.');
        }

        return $shop;
    }

    // ─── Shop Overview ────────────────────────────────────────────────────────

    public function show(Request $request)
    {
        $shop = $this->ownerShop($request);
        $shop->loadCount([
            'branches',
            'users as staff_count' => fn ($q) => $q->where('role', 'cashier'),
        ]);

        return response()->json($shop);
    }

    public function update(Request $request)
    {
        $shop = $this->ownerShop($request);

        $data = $request->validate([
            'name'    => 'sometimes|string|max:255',
            'address' => 'nullable|string|max:500',
            'phone'   => 'nullable|string|max:50',
            'email'   => 'nullable|email|max:255',
        ]);

        $shop->update($data);

        return response()->json($shop->fresh());
    }

    // ─── Branches ─────────────────────────────────────────────────────────────

    public function branches(Request $request)
    {
        $shop = $this->ownerShop($request);

        return response()->json(
            $shop->branches()->withCount('staff')->latest()->get()
        );
    }

    public function createBranch(Request $request)
    {
        $shop = $this->ownerShop($request);

        $data = $request->validate([
            'name'    => 'required|string|max:255',
            'address' => 'nullable|string|max:500',
            'phone'   => 'nullable|string|max:50',
        ]);

        $branch = $shop->branches()->create($data);

        return response()->json($branch->loadCount('staff'), 201);
    }

    public function updateBranch(Request $request, Branch $branch)
    {
        $shop = $this->ownerShop($request);

        if ($branch->shop_id !== $shop->id) {
            abort(404);
        }

        $data = $request->validate([
            'name'    => 'sometimes|string|max:255',
            'address' => 'nullable|string|max:500',
            'phone'   => 'nullable|string|max:50',
        ]);

        $branch->update($data);

        return response()->json($branch->fresh()->loadCount('staff'));
    }

    public function destroyBranch(Request $request, Branch $branch)
    {
        $shop = $this->ownerShop($request);

        if ($branch->shop_id !== $shop->id) {
            abort(404);
        }

        $branch->delete();

        return response()->json(['message' => 'Branch deleted.']);
    }

    // ─── Staff (Cashiers) ─────────────────────────────────────────────────────

    public function staff(Request $request)
    {
        $shop = $this->ownerShop($request);

        $staff = User::where('shop_id', $shop->id)
            ->where('role', 'cashier')
            ->with('branch:id,name')
            ->select('id', 'name', 'email', 'role', 'shop_id', 'branch_id', 'created_at')
            ->latest()
            ->get();

        return response()->json($staff);
    }

    public function createStaff(Request $request)
    {
        $shop = $this->ownerShop($request);

        $data = $request->validate([
            'name'      => 'required|string|max:255',
            'email'     => 'required|email|unique:users,email',
            'password'  => 'required|string|min:8',
            'branch_id' => 'nullable|integer',
        ]);

        // Ensure the selected branch belongs to this shop
        if (! empty($data['branch_id'])) {
            $branch = Branch::find($data['branch_id']);
            if (! $branch || $branch->shop_id !== $shop->id) {
                return response()->json(['message' => 'Invalid branch selected.'], 422);
            }
        }

        $user = User::create([
            'name'      => $data['name'],
            'email'     => $data['email'],
            'password'  => Hash::make($data['password']),
            'role'      => 'cashier',
            'shop_id'   => $shop->id,
            'branch_id' => $data['branch_id'] ?? null,
        ]);

        return response()->json(
            $user->load('branch:id,name')->only('id', 'name', 'email', 'role', 'shop_id', 'branch_id', 'created_at'),
            201
        );
    }

    public function updateStaff(Request $request, User $user)
    {
        $shop = $this->ownerShop($request);

        if ($user->shop_id !== $shop->id || $user->role !== 'cashier') {
            abort(404);
        }

        $data = $request->validate([
            'name'      => 'sometimes|string|max:255',
            'email'     => ['sometimes', 'email', Rule::unique('users')->ignore($user->id)],
            'password'  => 'sometimes|string|min:8',
            'branch_id' => 'nullable|integer',
        ]);

        if (isset($data['branch_id']) && $data['branch_id'] !== null) {
            $branch = Branch::find($data['branch_id']);
            if (! $branch || $branch->shop_id !== $shop->id) {
                return response()->json(['message' => 'Invalid branch selected.'], 422);
            }
        }

        if (isset($data['password'])) {
            $data['password'] = Hash::make($data['password']);
        }

        $user->update($data);

        return response()->json(
            $user->fresh()->load('branch:id,name')->only('id', 'name', 'email', 'role', 'shop_id', 'branch_id', 'created_at')
        );
    }

    public function destroyStaff(Request $request, User $user)
    {
        $shop = $this->ownerShop($request);

        if ($user->shop_id !== $shop->id || $user->role !== 'cashier') {
            abort(404);
        }

        $user->delete();

        return response()->json(['message' => 'Staff member removed.']);
    }
}
