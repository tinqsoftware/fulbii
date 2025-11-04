<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Auth;
use Http;
use Session;
use DB;
use DatePeriod;
use DateTime;
use DateInterval;
use PDF;

//modelos
use App\Models\Cancha;
use App\Models\Distritos;
use App\Models\Equipos;
use App\Models\Evento;
use App\Models\EventoUsuarios;
use App\Models\Formacion;
use App\Models\Goles;
use App\Models\HistorialCalificacion;
use App\Models\HorarioAtencion;
use App\Models\Pais;
use App\Models\Perfil;
use App\Models\Pichanga;
use App\Models\Polideportivo;
use App\Models\Posicion;
use App\Models\Provincia;
use App\Models\Region;
use App\Models\ServicioPolideportivo;
use App\Models\ServicioPolideportivoDetalle;
use App\Models\UserPerfil;
use App\Models\User;


class Mapa extends Controller
{

    public function mapa(){
        $polideportivo = Polideportivo::all();

        return view('mapa.mapa', compact('polideportivo'));
    }

   
}
