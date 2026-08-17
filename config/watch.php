<?php

return [
    'create_per_minute' => (int) env('WATCH_SESSION_CREATE_PER_MINUTE', 6),
    'sample_batches_per_minute' => (int) env('WATCH_SAMPLE_BATCHES_PER_MINUTE', 12),
    'event_batches_per_minute' => (int) env('WATCH_EVENT_BATCHES_PER_MINUTE', 20),
    'max_samples_per_batch' => (int) env('WATCH_MAX_SAMPLES_PER_BATCH', 500),
    'max_samples_per_session' => (int) env('WATCH_MAX_SAMPLES_PER_SESSION', 10000),
    'retention_days' => (int) env('WATCH_RETENTION_DAYS', 30),
];
