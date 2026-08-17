<?php

namespace App\Services;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;
use Symfony\Component\Process\Process;

class MediaSanitizer
{
    /** Decodes and writes a new JPEG, discarding uploaded containers and metadata. */
    public function reencodeImage(UploadedFile $file, string $directory, string $field): string
    {
        $contents = @file_get_contents($file->getRealPath());
        $details = $contents === false ? false : @getimagesizefromstring($contents);
        $mime = is_array($details) ? ($details['mime'] ?? null) : null;
        $create = match ($mime) {
            'image/jpeg' => 'imagecreatefromjpeg',
            'image/png' => 'imagecreatefrompng',
            'image/webp' => 'imagecreatefromwebp',
            default => null,
        };

        if ($create === null || !function_exists($create) || !function_exists('imagejpeg')) {
            throw ValidationException::withMessages([$field => ['La imagen debe ser JPG, PNG o WebP válido.']]);
        }

        $image = @$create($file->getRealPath());
        if ($image === false) {
            throw ValidationException::withMessages([$field => ['No se pudo procesar la imagen subida.']]);
        }

        $temporary = null;
        try {
            $temporary = tempnam(sys_get_temp_dir(), 'fulbii-image-');
            if ($temporary === false || !imagejpeg($image, $temporary, 88)) {
                throw ValidationException::withMessages([$field => ['No se pudo normalizar la imagen subida.']]);
            }

            $path = trim($directory, '/') . '/' . Str::uuid() . '.jpg';
            Storage::disk('public')->put($path, File::get($temporary));

            return $path;
        } finally {
            imagedestroy($image);
            if (is_string($temporary) && is_file($temporary)) {
                @unlink($temporary);
            }
        }
    }

    /** @return array{path:string,width:int,height:int,duration_ms:int,file_size_bytes:int} */
    public function transcodeProfileClip(UploadedFile $file, int $userId): array
    {
        $input = $file->getRealPath();
        if (!is_string($input) || !is_file($input)) {
            throw ValidationException::withMessages(['clip' => ['No se pudo leer el clip subido.']]);
        }

        $metadata = $this->probe($input);
        $width = (int) ($metadata['width'] ?? 0);
        $height = (int) ($metadata['height'] ?? 0);
        $duration = (float) ($metadata['duration'] ?? 0);
        if ($width < 64 || $height < 64 || $height <= $width || $width > 2048 || $height > 2048 || $duration < 7 || $duration > 20 || empty($metadata['has_audio'])) {
            throw ValidationException::withMessages(['clip' => ['El clip debe ser vertical, tener audio y durar entre 7 y 20 segundos.']]);
        }

        $temporaryDir = storage_path('app/media-transcodes');
        File::ensureDirectoryExists($temporaryDir, 0700, true);
        $output = $temporaryDir . '/' . Str::uuid() . '.mp4';

        try {
            $process = new Process([
                (string) config('media.ffmpeg_binary', 'ffmpeg'), '-y', '-v', 'error', '-i', $input,
                '-map', '0:v:0', '-map', '0:a:0', '-t', '7',
                '-c:v', 'libx264', '-preset', 'veryfast', '-pix_fmt', 'yuv420p',
                '-b:v', '1100k', '-maxrate', '1100k', '-bufsize', '2200k',
                '-c:a', 'aac', '-b:a', '96k', '-movflags', '+faststart', $output,
            ]);
            $process->setTimeout(max(10, (int) config('media.clip_transcode_timeout_seconds', 45)));
            $process->run();
            if (!$process->isSuccessful() || !is_file($output)) {
                throw ValidationException::withMessages(['clip' => ['No se pudo procesar el clip. Intenta con otro archivo MP4.']]);
            }

            $outputMetadata = $this->probe($output);
            $size = filesize($output) ?: 0;
            if (($outputMetadata['width'] ?? 0) < 1 || empty($outputMetadata['has_audio']) || $size > (int) config('media.clip_max_output_bytes')) {
                throw ValidationException::withMessages(['clip' => ['El clip procesado supera los límites permitidos.']]);
            }

            $path = "profile_clips/{$userId}/" . Str::uuid() . '.mp4';
            Storage::disk('public')->put($path, File::get($output));

            return [
                'path' => $path,
                'width' => (int) $outputMetadata['width'],
                'height' => (int) $outputMetadata['height'],
                'duration_ms' => 7000,
                'file_size_bytes' => (int) $size,
            ];
        } finally {
            if (is_file($output)) {
                @unlink($output);
            }
        }
    }

    /** @return array{width:int,height:int,duration:float,has_audio:bool} */
    private function probe(string $path): array
    {
        $process = new Process([
            (string) config('media.ffprobe_binary', 'ffprobe'), '-v', 'error', '-show_entries',
            'format=duration:stream=codec_type,width,height', '-of', 'json', $path,
        ]);
        $process->setTimeout(10);
        $process->run();
        $payload = $process->isSuccessful() ? json_decode($process->getOutput(), true) : null;
        $streams = is_array($payload['streams'] ?? null) ? $payload['streams'] : [];
        $video = collect($streams)->first(fn (array $stream) => ($stream['codec_type'] ?? null) === 'video') ?? [];

        return [
            'width' => (int) ($video['width'] ?? 0),
            'height' => (int) ($video['height'] ?? 0),
            'duration' => (float) ($payload['format']['duration'] ?? 0),
            'has_audio' => collect($streams)->contains(fn (array $stream) => ($stream['codec_type'] ?? null) === 'audio'),
        ];
    }
}
