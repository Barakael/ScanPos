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

        // super_admin and owner can manage settings
        Gate::define('manage-settings', function ($user) {
            return in_array($user->role, ['super_admin', 'owner']);
        });
    }
}
