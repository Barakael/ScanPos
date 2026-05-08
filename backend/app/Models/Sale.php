<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Sale extends Model
{
    protected $fillable = [
        'shop_id',
        'cashier_id',
        'subtotal',
        'tax',
        'total',
        'payment_method',
        'serial_number',
        'znr',
        'uin',
        'verification_code',
        'customer_name',
        'customer_phone',
        'customer_address',
        'customer_id_type',
        'customer_id',
        'total_excl_tax',
        'total_tax',
        'amount_tendered',
        'cash_change',
        'tax_rate_used',
    ];

    /** @var list<string> */
    protected $hidden = [
        'cash_change',
    ];

    protected $casts = [
        'subtotal'        => 'float',
        'tax'             => 'float',
        'total'           => 'float',
        'total_excl_tax'  => 'float',
        'total_tax'       => 'float',
        'amount_tendered' => 'float',
        'cash_change'     => 'float',
        'tax_rate_used'   => 'float',
    ];

    protected $appends = [
        'change',
    ];

    /** Alias for API consumers expecting key `change`. */
    public function getChangeAttribute(): ?float
    {
        return $this->attributes['cash_change'] !== null
            ? (float) $this->attributes['cash_change']
            : null;
    }

    public function shop()
    {
        return $this->belongsTo(Shop::class);
    }

    public function cashier()
    {
        return $this->belongsTo(User::class, 'cashier_id');
    }

    public function items()
    {
        return $this->hasMany(SaleItem::class);
    }
}
