<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;

class MeController extends Controller
{
    public function show(Request $request)
    {
        return response()->json($request->user() ?? abort(401));
    }

    public function update(Request $request)
    {
        $user = $request->user() ?? abort(401);

        $data = $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'avatar_url' => ['sometimes', 'nullable', 'string', 'max:500'],
            'fec_nac' => ['sometimes', 'nullable', 'date'],
            'altura_cm' => ['sometimes', 'nullable', 'integer', 'min:90', 'max:260'],
            'sexo' => ['sometimes', 'nullable', 'in:M,F'],
        ]);

        foreach ($data as $field => $value) {
            if (Schema::hasColumn('users', $field)) {
                $user->{$field} = $value;
            }
        }

        $user->save();

        return response()->json($user->fresh());
    }
}
