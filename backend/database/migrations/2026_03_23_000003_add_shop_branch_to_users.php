<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            // Plain nullable columns — no FK constraints to avoid circular dependency
            $table->unsignedBigInteger('shop_id')->nullable()->after('role');
            $table->unsignedBigInteger('branch_id')->nullable()->after('shop_id');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['shop_id', 'branch_id']);
        });
    }
};
