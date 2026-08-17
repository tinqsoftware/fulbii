<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;
use App\Models\User;
use App\Models\Club;
use App\Models\ClubUser;
use App\Models\Polideportivo;
use App\Models\Cancha;
use App\Models\GroupPichanga;
use App\Models\GroupPichangaParticipant;
use App\Models\GroupPichangaRating;
use App\Models\Calificacion;
use App\Models\UserProfileClip;

class DatabaseSeeder extends Seeder
{
    /**
     * Intentionally does not load disposable demo content.
     *
     * Use `php artisan db:seed --class=DemoDataSeeder` only in a local or
     * testing environment and only after explicitly enabling demo seeding.
     */
    public function run(): void
    {
        // Keep a normal `php artisan db:seed` harmless for a real database.
    }

    /**
     * Seed the application's disposable demo data.
     */
    public function runDemo(): void
    {
        if (!app()->environment(['local', 'testing']) || !config('demo_seeding.enabled', false)) {
            throw new \RuntimeException(
                'El seeder de demo está bloqueado. Solo se permite en local/testing con DEMO_SEEDING_ENABLED=true.'
            );
        }

        // 1. Limpieza de tablas preservando tokens activos de usuario y cuentas principales
        DB::statement('SET FOREIGN_KEY_CHECKS=0;');

        // Preservamos los IDs de usuarios con sesiones activas para no cerrarles la sesión
        $activeUserIds = [];
        if (Schema::hasTable('personal_access_tokens')) {
            $activeUserIds = DB::table('personal_access_tokens')->pluck('tokenable_id')->toArray();
        }
        
        $currentUsers = User::whereIn('id', $activeUserIds)
            ->orWhere('nick', 'enriquericci')
            ->orWhere('email', 'like', '%apple%')
            ->orWhere('email', 'like', '%ricci%')
            ->get();
            
        $preservedUserIds = $currentUsers->pluck('id')->toArray();

        // Truncamos las tablas principales para limpiar la plataforma
        if (Schema::hasTable('polideportivo')) Polideportivo::truncate();
        if (Schema::hasTable('cancha')) Cancha::truncate();
        if (Schema::hasTable('group_pichangas')) GroupPichanga::truncate();
        if (Schema::hasTable('group_pichanga_participants')) GroupPichangaParticipant::truncate();
        if (Schema::hasTable('group_pichanga_ratings')) GroupPichangaRating::truncate();
        if (Schema::hasTable('calificaciones')) Calificacion::truncate();
        if (Schema::hasTable('user_profile_clips')) UserProfileClip::truncate();
        if (Schema::hasTable('clubs')) Club::truncate();
        if (Schema::hasTable('club_user')) ClubUser::truncate();
        if (Schema::hasTable('user_favorite_fields')) DB::table('user_favorite_fields')->truncate();
        if (Schema::hasTable('group_pichanga_posts')) DB::table('group_pichanga_posts')->truncate();
        if (Schema::hasTable('group_pichanga_comments')) DB::table('group_pichanga_comments')->truncate();

        // Borramos usuarios que no estén preservados
        if (!empty($preservedUserIds)) {
            User::whereNotIn('id', $preservedUserIds)->delete();
        } else {
            User::truncate();
        }

        // 2. Crear Usuarios de prueba con perfiles completos
        $nicks = [
            'piero_gol', 'carlos_10', 'luis_crack', 'juan_arquero', 'diego_9', 'mateo_mid', 
            'leo_messi', 'cr7_goat', 'sandro_def', 'marcos_c', 'adriano_p', 'felipe_g', 
            'paco_t', 'hugo_h', 'santi_s', 'seba_v', 'lucas_d', 'thiago_m', 'lolo_c', 'lucho_r',
            'gonza_peru', 'renzo_10', 'andres_cap', 'jorge_pichanga', 'fabricio_crack', 'valentin_mid',
            'nicolas_zurda', 'sebas_9', 'mathias_portero', 'esteban_def', 'bruno_poli', 'matias_chile',
            'alvaro_lima', 'rodrigo_fut', 'gabo_gol', 'samuel_tiki', 'joaquin_p', 'dante_fc', 'ignacio_10', 'mateo_10'
        ];

        $avatars = [
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80',
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=300&q=80',
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=300&q=80',
            'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?auto=format&fit=crop&w=300&q=80',
            'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&w=300&q=80',
        ];

        foreach ($nicks as $idx => $nick) {
            User::create([
                'name' => Str::title(str_replace('_', ' ', $nick)),
                'email' => "$nick@fulbii.pe",
                'email_verified_at' => now(),
                'password' => bcrypt('password'),
                'nick' => $nick,
                'sexo' => rand(0, 1) ? 'M' : 'F',
                'altura_cm' => rand(165, 192),
                'avatar_url' => $avatars[$idx % count($avatars)],
                'fec_nac' => rand(1990, 2005) . '-' . str_pad(rand(1, 12), 2, '0', STR_PAD_LEFT) . '-' . str_pad(rand(1, 28), 2, '0', STR_PAD_LEFT),
            ]);
        }

        $allUsers = User::all();

        // 3. Crear 1200 Polideportivos en todo Lima con coordenadas x(lat), y(lng) reales
        $distritosData = [
            ['id' => 1, 'nombre' => 'Miraflores', 'lat' => -12.122, 'lng' => -77.030],
            ['id' => 2, 'nombre' => 'San Isidro', 'lat' => -12.097, 'lng' => -77.036],
            ['id' => 3, 'nombre' => 'Santiago de Surco', 'lat' => -12.140, 'lng' => -76.985],
            ['id' => 4, 'nombre' => 'La Molina', 'lat' => -12.078, 'lng' => -76.945],
            ['id' => 5, 'nombre' => 'Barranco', 'lat' => -12.147, 'lng' => -77.021],
            ['id' => 6, 'nombre' => 'San Borja', 'lat' => -12.107, 'lng' => -76.998],
            ['id' => 7, 'nombre' => 'Lince', 'lat' => -12.083, 'lng' => -77.035],
            ['id' => 8, 'nombre' => 'Jesús María', 'lat' => -12.074, 'lng' => -77.046],
            ['id' => 9, 'nombre' => 'San Miguel', 'lat' => -12.077, 'lng' => -77.087],
            ['id' => 10, 'nombre' => 'Los Olivos', 'lat' => -11.975, 'lng' => -77.070],
            ['id' => 11, 'nombre' => 'Chorrillos', 'lat' => -12.170, 'lng' => -77.018],
            ['id' => 12, 'nombre' => 'Surquillo', 'lat' => -12.113, 'lng' => -77.021],
            ['id' => 13, 'nombre' => 'Magdalena del Mar', 'lat' => -12.090, 'lng' => -77.070],
            ['id' => 14, 'nombre' => 'Pueblo Libre', 'lat' => -12.076, 'lng' => -77.062],
            ['id' => 15, 'nombre' => 'La Victoria', 'lat' => -12.068, 'lng' => -77.018],
            ['id' => 16, 'nombre' => 'Ate', 'lat' => -12.025, 'lng' => -76.915],
            ['id' => 17, 'nombre' => 'San Juan de Lurigancho', 'lat' => -11.980, 'lng' => -76.990],
            ['id' => 18, 'nombre' => 'Comas', 'lat' => -11.935, 'lng' => -77.050],
            ['id' => 19, 'nombre' => 'Villa El Salvador', 'lat' => -12.215, 'lng' => -76.940],
            ['id' => 20, 'nombre' => 'Carabayllo', 'lat' => -11.890, 'lng' => -77.030],
        ];

        $calles = [
            'Av. Larco', 'Av. Arequipa', 'Av. Javier Prado', 'Av. Salaverry', 'Av. Brasil',
            'Av. La Marina', 'Av. Angamos', 'Av. Benavides', 'Av. El Corregidor', 'Av. Primavera',
            'Jr. Bolognesi', 'Av. Sucre', 'Av. Túpac Amaru', 'Av. Universitaria', 'Av. Próceres',
            'Av. Defensores del Morro', 'Av. El Sol', 'Av. Huaylas', 'Av. Nicolás de Piérola'
        ];

        $fieldPhotos = [
            'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?auto=format&fit=crop&w=800&q=80',
            'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?auto=format&fit=crop&w=800&q=80',
            'https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&w=800&q=80',
            'https://images.unsplash.com/photo-1551958219-acbc608c6377?auto=format&fit=crop&w=800&q=80',
            'https://images.unsplash.com/photo-1489945052260-4f21c5e22984?auto=format&fit=crop&w=800&q=80'
        ];

        $polideportivos = [];
        $hasPrecioDesdeNum = Schema::hasColumn('polideportivo', 'precio_desde_num');

        for ($i = 1; $i <= 1200; $i++) {
            $dist = $distritosData[array_rand($distritosData)];
            $calle = $calles[array_rand($calles)];
            $numero = rand(100, 3900);

            // Variación aleatoria de ±0.015 grados (~1.5 km) alrededor del centro del distrito
            $lat = $dist['lat'] + (rand(-150, 150) / 10000);
            $lng = $dist['lng'] + (rand(-150, 150) / 10000);
            $precio = rand(60, 190);

            $row = [
                'nombre' => "Complejo Deportivo " . $dist['nombre'] . " #" . rand(1, 99),
                'direccion' => "$calle $numero, " . $dist['nombre'] . ", Lima",
                'x' => (string) round($lat, 6),
                'y' => (string) round($lng, 6),
                'descripcion' => "Complejo con césped sintético de alta calidad, iluminación LED nocturna, vestuarios y estacionamiento privado.",
                'precio_desde' => "S/ $precio",
                'celular' => '9' . rand(10000000, 99999999),
                'wsp' => '1', // Flag boolean '1' o '0' para wsp varchar(2)
                'id_distrito' => $dist['id'],
                'url_foto' => $fieldPhotos[$i % count($fieldPhotos)],
                'created_at' => now(),
                'updated_at' => now(),
            ];

            if ($hasPrecioDesdeNum) {
                $row['precio_desde_num'] = $precio;
            }

            $polideportivos[] = $row;
        }

        // Insertar por lotes de 100
        foreach (array_chunk($polideportivos, 100) as $chunk) {
            DB::table('polideportivo')->insert($chunk);
        }

        $polideportivoIds = DB::table('polideportivo')->pluck('id')->toArray();

        // 4. Crear 1500 Canchas distribuidas en los 1200 polideportivos
        $canchas = [];
        $superficies = ['sintetico', 'losa', 'artificial'];
        $formatos = [
            '6v6' => 6,
            '7v7' => 7,
            '9v9' => 9,
        ];

        $hasTipoSuperficie = Schema::hasColumn('cancha', 'tipo_superficie');
        $hasFormatoVs = Schema::hasColumn('cancha', 'formato_vs');
        $hasEquiposVs = Schema::hasColumn('cancha', 'equiposvs');

        for ($i = 1; $i <= 1500; $i++) {
            $formatKey = array_rand($formatos);
            // Aseguramos que los primeros 1200 cubran cada polideportivo, luego repartimos el resto
            $poliId = ($i <= 1200) ? $polideportivoIds[$i - 1] : $polideportivoIds[array_rand($polideportivoIds)];

            $row = [
                'id_polideportivo' => $poliId,
                'nombre' => "Cancha " . (($i % 4) + 1),
                'created_at' => now(),
                'updated_at' => now(),
            ];

            if ($hasTipoSuperficie) {
                $row['tipo_superficie'] = $superficies[array_rand($superficies)];
            }
            if ($hasFormatoVs) {
                $row['formato_vs'] = $formatKey;
            }
            if ($hasEquiposVs) {
                $row['equiposvs'] = (string) $formatos[$formatKey];
            }

            $canchas[] = $row;
        }

        foreach (array_chunk($canchas, 100) as $chunk) {
            DB::table('cancha')->insert($chunk);
        }

        $canchaIds = DB::table('cancha')->pluck('id')->toArray();

        // 5. Crear Clubs / Grupos de Pichanga
        $clubNames = [
            'Los Galácticos FC', 'Pichangueros del Sur', 'Hijos del Balón', 'Amigos del Barrio', 
            'La Naranja Mecánica', 'Tiki Taka FC', 'Real Alcoholicos', 'Dep. Calichines',
            'Full Vasos', 'Pichangueros de Surco', 'Los Legendarios', 'La Redonda FC',
            'Deportivo Lima', 'Cazadores de Goles', 'La Cantera FC'
        ];

        $clubs = collect();
        foreach ($clubNames as $name) {
            $clubs->push(Club::create([
                'nombre' => $name,
                'slug' => Str::slug($name) . '-' . rand(10, 99),
                'descripcion' => "Grupo oficial para organizar las pichangas de $name. ¡Todos bienvenidos a jugar!",
                'estado' => 1,
                'is_visible' => true,
                'link_join_enabled' => true,
                'auto_reminder_enabled' => true,
            ]));
        }

        // Asignar admins e integrantes a los clubes
        foreach ($clubs as $club) {
            $admin = $allUsers->random();
            ClubUser::create([
                'club_id' => $club->id,
                'user_id' => $admin->id,
                'rol' => 'admin',
                'estado' => 1,
            ]);

            $members = $allUsers->where('id', '!=', $admin->id)->random(rand(10, 20));
            foreach ($members as $member) {
                ClubUser::create([
                    'club_id' => $club->id,
                    'user_id' => $member->id,
                    'rol' => 'miembro',
                    'estado' => 1,
                ]);
            }
        }

        // 6. Crear Pichangas (Futuras/Pendientes y Pasadas/Terminadas)
        $pichangas = collect();
        
        // 50 Pichangas Pendientes (Futuras)
        for ($i = 1; $i <= 50; $i++) {
            $club = $clubs->random();
            $creatorId = ClubUser::where('club_id', $club->id)->first()->user_id ?? $allUsers->random()->id;
            
            $pichangas->push(GroupPichanga::create([
                'club_id' => $club->id,
                'created_by_user_id' => $creatorId,
                'title' => "Pichanga " . $club->nombre . " #" . rand(10, 99),
                'description' => "Pichanga confirmada, favor llegar 10 min antes.",
                'starts_at' => now()->addDays(rand(1, 14))->setHour(rand(18, 22))->setMinute(0),
                'duration_minutes' => 60,
                'field_id' => $polideportivoIds[array_rand($polideportivoIds)],
                'cancha_id' => $canchaIds[array_rand($canchaIds)],
                'players_per_team' => rand(5, 7),
                'team_count' => 2,
                'capacity' => rand(10, 14),
                'is_open' => true,
                'allow_external_requests' => true,
                'status' => 'confirmed',
            ]));
        }

        // 80 Pichangas Pasadas (Terminadas / Completed)
        for ($i = 1; $i <= 80; $i++) {
            $club = $clubs->random();
            $creatorId = ClubUser::where('club_id', $club->id)->first()->user_id ?? $allUsers->random()->id;

            $pichangas->push(GroupPichanga::create([
                'club_id' => $club->id,
                'created_by_user_id' => $creatorId,
                'title' => "Partido " . $club->nombre . " #" . rand(1, 9),
                'description' => "Gran partido con tercer tiempo incluido.",
                'starts_at' => now()->subDays(rand(1, 30))->setHour(rand(18, 22))->setMinute(0),
                'duration_minutes' => 60,
                'field_id' => $polideportivoIds[array_rand($polideportivoIds)],
                'cancha_id' => $canchaIds[array_rand($canchaIds)],
                'players_per_team' => rand(5, 7),
                'team_count' => 2,
                'capacity' => rand(10, 14),
                'is_open' => false,
                'allow_external_requests' => false,
                'status' => 'completed',
            ]));
        }

        // 7. Registrar Participantes garantizando estrictamente entre 2 y 10 pichangas por usuario
        foreach ($allUsers as $user) {
            // Asignamos un número aleatorio entre 3 y 9 pichangas por usuario
            $targetCount = rand(3, 9);
            $selectedPichangas = $pichangas->random(min($targetCount, $pichangas->count()));

            foreach ($selectedPichangas as $pichanga) {
                $alreadyIn = GroupPichangaParticipant::where('pichanga_id', $pichanga->id)
                    ->where('user_id', $user->id)
                    ->exists();

                if (!$alreadyIn) {
                    GroupPichangaParticipant::create([
                        'pichanga_id' => $pichanga->id,
                        'user_id' => $user->id,
                        'status' => 'confirmed',
                        'origin' => 'member',
                        'confirmed_at' => $pichanga->starts_at->copy()->subDays(2),
                        'created_at' => $pichanga->starts_at->copy()->subDays(2),
                        'updated_at' => $pichanga->starts_at->copy()->subDays(2),
                    ]);

                    // Si la pichanga ya terminó (status = completed), registramos calificaciones entre los participantes
                    if ($pichanga->status === 'completed') {
                        $rater = $allUsers->where('id', '!=', $user->id)->random();

                        $fisico = rand(30, 50) / 10.0;
                        $arquero = rand(10, 50) / 10.0;
                        $delantero = rand(20, 50) / 10.0;
                        $mediocampo = rand(25, 50) / 10.0;
                        $defensa = rand(20, 50) / 10.0;

                        // Rating de la pichanga específica
                        GroupPichangaRating::create([
                            'pichanga_id' => $pichanga->id,
                            'rater_user_id' => $rater->id,
                            'rated_user_id' => $user->id,
                            'fisico' => $fisico,
                            'arquero' => $arquero,
                            'delantero' => $delantero,
                            'mediocampo' => $mediocampo,
                            'defensa' => $defensa,
                            'created_at' => $pichanga->starts_at->copy()->addHours(2),
                            'updated_at' => $pichanga->starts_at->copy()->addHours(2),
                        ]);

                        // Rating general de calificaciones
                        Calificacion::create([
                            'club_id' => $pichanga->club_id,
                            'user_calificador_id' => $rater->id,
                            'user_calificado_id' => $user->id,
                            'fisico' => $fisico,
                            'arquero' => $arquero,
                            'delantero' => $delantero,
                            'mediocampo' => $mediocampo,
                            'defensa' => $defensa,
                            'created_at' => $pichanga->starts_at->copy()->addHours(2),
                            'updated_at' => $pichanga->starts_at->copy()->addHours(2),
                        ]);
                    }
                }
            }
        }

        // 8. Crear Clips de perfil de usuario
        $clipTitles = [
            '¡Golazo de tiro libre directo!',
            'Tapadón abajo al ángulo',
            'Caño magistral en el medio',
            'Rabona en el último minuto',
            'Jugada individual y definición'
        ];

        $videoUrls = [
            'https://assets.mixkit.co/videos/preview/mixkit-playing-soccer-in-a-field-41558-large.mp4',
            'https://assets.mixkit.co/videos/preview/mixkit-game-of-soccer-41559-large.mp4'
        ];

        $clipUsers = $allUsers->random(min(15, $allUsers->count()));
        foreach ($clipUsers as $u) {
            for ($c = 1; $c <= rand(1, 3); $c++) {
                UserProfileClip::create([
                    'user_id' => $u->id,
                    'title' => $clipTitles[array_rand($clipTitles)],
                    'duration_ms' => rand(5000, 12000),
                    'width' => 720,
                    'height' => 1280,
                    'has_audio' => true,
                    'file_size_bytes' => rand(600000, 1500000),
                    'sort_order' => $c,
                    'mp4_url' => $videoUrls[array_rand($videoUrls)],
                ]);
            }
        }

        // 9. Crear Polideportivos Favoritos para los usuarios
        if (Schema::hasTable('user_favorite_fields')) {
            foreach ($allUsers->random(min(20, $allUsers->count())) as $favUser) {
                $favPolis = array_rand(array_flip($polideportivoIds), rand(2, 4));
                foreach ((array)$favPolis as $favPoliId) {
                    DB::table('user_favorite_fields')->insertOrIgnore([
                        'user_id' => $favUser->id,
                        'polideportivo_id' => $favPoliId,
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);
                }
            }
        }

        DB::statement('SET FOREIGN_KEY_CHECKS=1;');
    }
}
