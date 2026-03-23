<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Product extends Model
{
    protected $fillable = [
        'name',
        'barcode',
        'price',
        'stock',
        'category',
        'image',
        'low_stock_threshold',
        'shop_id',
    ];

    protected $casts = [
        'price' => 'float',
        'stock' => 'integer',
        'low_stock_threshold' => 'integer',
    ];

    public function saleItems()
    {
        return $this->hasMany(SaleItem::class);
    }
}
