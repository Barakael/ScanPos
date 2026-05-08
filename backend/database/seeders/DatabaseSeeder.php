<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // Demo shop requires users (owner_id). Run UserSeeder first, then attach demo TRA shop.
        $this->call([
            UserSeeder::class,
            DemoShopSeeder::class,
            ProductSeeder::class,
        ]);
    }
}
