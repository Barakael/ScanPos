<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Branch extends Model
{
    protected $fillable = ['shop_id', 'name', 'address', 'phone'];

    public function shop()
    {
        return $this->belongsTo(Shop::class);
    }

    public function staff()
    {
        return $this->hasMany(User::class, 'branch_id');
    }
}
