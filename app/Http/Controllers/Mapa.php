<?php

namespace App\Http\Controllers;

use App\Models\Polideportivo;

class Mapa extends Controller
{
    public function mapa()
    {
        $polideportivo = Polideportivo::select('id','nombre','x','y','descripcion','precio_desde','url_foto')->get();

        $fields = $polideportivo->map(function($p){
            return [
                'id'    => $p->id,
                'name'  => $p->nombre,
                'x'     => (float) $p->x,
                'y'     => (float) $p->y,
                'description' => $p->descripcion,
                'price' => (int) ($p->precio_desde ?? 0),
                'photo' => $p->url_foto,
            ];
        })->values();

        $cards = $polideportivo->take(6)->map(function($p){
            return [
                'sub'      => 'Pichanga',
                'title'    => $p->nombre,
                'zona'     => $p->descripcion ? mb_strimwidth($p->descripcion,0,28,'…') : '',
                'modalidad'=> '6vs6',
                'hora'     => '9pm',
                'dur'      => '1 hora',
            ];
        })->values();

        return view('home', compact('fields','cards'));
    }
}
