<?php

namespace App\Providers;

use Illuminate\Support\Facades\Gate;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void {}

    public function boot(): void
    {
        // Only owner and super_admin can manage inventory
        Gate::define('manage-inventory', function ($user) {
            return in_array($user->role, ['owner', 'super_admin']);
        });

        // Only super_admin can manage users
        Gate::define('manage-users', function ($user) {
            return $user->role === 'super_admin';
        });

        // Only super_admin can manage all shops
        Gate::define('manage-shops', function ($user) {
            return $user->role === 'super_admin';
        });

        // Only owner can manage their own shop / branches / staff
        Gate::define('manage-my-shop', function ($user) {
            return $user->role === 'owner';
        });
    }
}
