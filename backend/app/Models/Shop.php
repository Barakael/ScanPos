<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Shop extends Model
{
    protected $fillable = [
        'name', 'owner_id', 'address', 'phone', 'email', 'tax_rate', 'currency',
    ];

    protected $casts = [
        'tax_rate' => 'float',
        'owner_id' => 'integer',
    ];

    /** The shop owner */
    public function owner()
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    /** Branches of this shop (shop records that have this shop as parent via users/branches model) */
    public function branches()
    {
        return $this->hasMany(Branch::class);
    }

    /** All staff (users) assigned to this shop */
    public function staff()
    {
        return $this->hasMany(User::class);
    }

    /** Products belonging to this shop */
    public function products()
    {
        return $this->hasMany(Product::class);
    }
}
