<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Plan;
use Illuminate\Http\Request;

class PlanController extends Controller
{
    /** GET /api/plans — list active plans (all authenticated users) */
    public function index()
    {
        return response()->json(Plan::where('is_active', true)->orderBy('price')->get());
    }
}
