<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Sale extends Model
{
    protected $fillable = [
        'cashier_id',
        'subtotal',
        'tax',
        'total',
        'payment_method',
    ];

    protected $casts = [
        'subtotal' => 'float',
        'tax'      => 'float',
        'total'    => 'float',
    ];

    public function cashier()
    {
        return $this->belongsTo(User::class, 'cashier_id');
    }

    public function items()
    {
        return $this->hasMany(SaleItem::class);
    }
}
