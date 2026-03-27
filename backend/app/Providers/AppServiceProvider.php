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

        // Only super_admin can manage users / view all users
        Gate::define('manage-users', function ($user) {
            return $user->role === 'super_admin';
        });

        // Only super_admin can register / manage shops
        Gate::define('manage-shops', function ($user) {
            return $user->role === 'super_admin';
        });

        // Owner manages their own branches
        Gate::define('manage-branch', function ($user) {
            return $user->role === 'owner';
        });

        // Owner manages their own staff (cashiers)
        Gate::define('manage-staff', function ($user) {
            return $user->role === 'owner';
        });

        // Owner can view/edit their own shop settings
        Gate::define('manage-settings', function ($user) {
            return $user->role === 'owner';
        });

        // super_admin can manage subscriptions / assign plans
        Gate::define('manage-subscriptions', function ($user) {
            return $user->role === 'super_admin';
        });

        // owner can view their own subscription
        Gate::define('view-subscription', function ($user) {
            return in_array($user->role, ['owner', 'super_admin']);
        });
    }
}
