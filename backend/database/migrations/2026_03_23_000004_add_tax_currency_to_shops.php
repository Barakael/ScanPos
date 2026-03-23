<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('shops', function (Blueprint $table) {
            $table->decimal('tax_rate', 5, 2)->default(18)->after('email');
            $table->string('currency', 10)->default('TZS')->after('tax_rate');
        });
    }

    public function down(): void
    {
        Schema::table('shops', function (Blueprint $table) {
            $table->dropColumn(['tax_rate', 'currency']);
        });
    }
};
