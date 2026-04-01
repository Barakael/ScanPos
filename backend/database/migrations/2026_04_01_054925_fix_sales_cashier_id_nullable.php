<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('sales', function (Blueprint $table) {
            $table->dropForeign(['cashier_id']);
            $table->foreignId('cashier_id')->nullable()->change();
            $table->foreign('cashier_id')->references('id')->on('users')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('sales', function (Blueprint $table) {
            $table->dropForeign(['cashier_id']);
            $table->foreignId('cashier_id')->nullable(false)->change();
            $table->foreign('cashier_id')->references('id')->on('users')->restrictOnDelete();
        });
    }
};
