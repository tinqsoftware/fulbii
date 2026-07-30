import 'dart:io';
import 'dart:math';

import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import 'package:path_provider/path_provider.dart';

class ClipProcessingResult {
  ClipProcessingResult({
    required this.file,
    required this.width,
    required this.height,
    required this.fileSizeBytes,
    required this.durationMs,
    required this.hasAudio,
  });

  final File file;
  final int width;
  final int height;
  final int fileSizeBytes;
  final int durationMs;
  final bool hasAudio;
}

class ClipProcessingService {
  static const int clipDurationMs = 7000;
  static const int preferredMinBytes = 512 * 1024;
  static const int preferredMaxBytes = 1024 * 1024;
  static const int acceptedMaxBytes = 1331 * 1024;

  Future<ClipProcessingResult> processVerticalSevenSecond({
    required File sourceFile,
    required Duration startAt,
  }) async {
    final sourceHasAudio = await _hasAudioTrack(sourceFile.path);
    if (!sourceHasAudio) {
      throw Exception(
        'El video no tiene pista de audio. Selecciona un video con audio.',
      );
    }

    final tempDir = await getTemporaryDirectory();
    final outputBase =
        '${tempDir.path}/clip_${DateTime.now().millisecondsSinceEpoch}';

    final attempts = <({int width, int height, int videoKbps, int audioKbps})>[
      (width: 720, height: 1280, videoKbps: 900, audioKbps: 64),
      (width: 640, height: 1138, videoKbps: 760, audioKbps: 56),
      (width: 540, height: 960, videoKbps: 620, audioKbps: 48),
      (width: 480, height: 854, videoKbps: 520, audioKbps: 40),
    ];

    File? bestPreferred;
    int bestPreferredSize = 0;
    ({int width, int height}) bestPreferredDims = (width: 480, height: 854);

    File? bestFallback;
    int bestFallbackSize = 0;
    ({int width, int height}) bestFallbackDims = (width: 480, height: 854);

    for (var i = 0; i < attempts.length; i++) {
      final preset = attempts[i];
      final outputPath = '${outputBase}_$i.mp4';
      await _runTranscode(
        sourcePath: sourceFile.path,
        outputPath: outputPath,
        startAtSeconds: startAt.inMilliseconds / 1000,
        width: preset.width,
        height: preset.height,
        videoKbps: preset.videoKbps,
        audioKbps: preset.audioKbps,
      );

      final outputFile = File(outputPath);
      if (!await outputFile.exists()) {
        continue;
      }
      final size = await outputFile.length();
      final hasAudio = await _hasAudioTrack(outputPath);
      if (!hasAudio) {
        continue;
      }

      if (size >= preferredMinBytes && size <= preferredMaxBytes) {
        return ClipProcessingResult(
          file: outputFile,
          width: preset.width,
          height: preset.height,
          fileSizeBytes: size,
          durationMs: clipDurationMs,
          hasAudio: hasAudio,
        );
      }

      if (size <= preferredMaxBytes && size > bestPreferredSize) {
        bestPreferred = outputFile;
        bestPreferredSize = size;
        bestPreferredDims = (width: preset.width, height: preset.height);
      }

      if (size <= acceptedMaxBytes && size > bestFallbackSize) {
        bestFallback = outputFile;
        bestFallbackSize = size;
        bestFallbackDims = (width: preset.width, height: preset.height);
      }
    }

    if (bestPreferred != null) {
      return ClipProcessingResult(
        file: bestPreferred,
        width: bestPreferredDims.width,
        height: bestPreferredDims.height,
        fileSizeBytes: bestPreferredSize,
        durationMs: clipDurationMs,
        hasAudio: true,
      );
    }

    if (bestFallback != null) {
      return ClipProcessingResult(
        file: bestFallback,
        width: bestFallbackDims.width,
        height: bestFallbackDims.height,
        fileSizeBytes: bestFallbackSize,
        durationMs: clipDurationMs,
        hasAudio: true,
      );
    }

    throw Exception(
      'No se pudo optimizar el clip al peso máximo permitido (1.3MB). '
      'Prueba otro tramo o un video fuente más liviano.',
    );
  }

  Future<void> _runTranscode({
    required String sourcePath,
    required String outputPath,
    required double startAtSeconds,
    required int width,
    required int height,
    required int videoKbps,
    required int audioKbps,
  }) async {
    final escapedInput = _escapePath(sourcePath);
    final escapedOutput = _escapePath(outputPath);
    final safeStart = max(0, startAtSeconds);
    final cropFilter =
        'crop='
        "'if(gte(iw/ih,9/16),ih*9/16,iw):if(gte(iw/ih,9/16),ih,iw*16/9)'"
        ',scale=$width:$height:flags=lanczos'
        ',fps=24,format=yuv420p';

    final cmd =
        '-y '
        '-ss ${safeStart.toStringAsFixed(3)} '
        '-t 7 '
        '-i $escapedInput '
        '-map 0:v:0 -map 0:a? '
        '-vf "$cropFilter" '
        '-c:v libx264 -profile:v baseline -level 3.1 -preset veryfast '
        '-b:v ${videoKbps}k -maxrate ${(videoKbps * 1.25).round()}k -bufsize ${(videoKbps * 2).round()}k '
        '-c:a aac -ac 1 -ar 32000 -b:a ${audioKbps}k '
        '-movflags +faststart '
        '-shortest '
        '$escapedOutput';

    final session = await FFmpegKit.execute(cmd);
    final returnCode = await session.getReturnCode();
    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getAllLogsAsString();
      throw Exception('Falló procesamiento de clip. ffmpeg: $logs');
    }
  }

  String _escapePath(String value) {
    final escaped = value.replaceAll("'", "'\\''");
    return "'$escaped'";
  }

  Future<bool> _hasAudioTrack(String path) async {
    final session = await FFprobeKit.getMediaInformation(path);
    final info = session.getMediaInformation();
    final streams = info?.getStreams() ?? [];
    for (final stream in streams) {
      final streamMap = stream.getAllProperties() ?? const <String, dynamic>{};
      if ((streamMap['codec_type'] ?? '').toString().toLowerCase() == 'audio') {
        return true;
      }
    }
    return false;
  }
}
