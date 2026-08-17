<?php

return [
    // Binaries are invoked without a shell. Set absolute paths in production
    // when ffmpeg is not available in the PHP-FPM PATH.
    'ffmpeg_binary' => env('MEDIA_FFMPEG_BINARY', 'ffmpeg'),
    'ffprobe_binary' => env('MEDIA_FFPROBE_BINARY', 'ffprobe'),
    'clip_max_output_bytes' => (int) env('PROFILE_CLIP_MAX_OUTPUT_BYTES', 1331 * 1024),
    'clip_transcode_timeout_seconds' => (int) env('PROFILE_CLIP_TRANSCODE_TIMEOUT_SECONDS', 45),
];
