---
name: performance-profiling
description: >-
  Profiles and optimizes QR decoding speed, custom QR rendering latency, isolate worker offloading,
  memory footprint, and startup performance.
---

# Performance Profiling & Optimization Skill

Use this skill when optimizing scanning pipelines, batch QR generation, custom canvas rendering, and startup latency.

## Performance Budgets

1. **Single QR Decode Latency (from image buffer)**: `< 25 ms` on desktop/modern mobile CPU via background isolate processing.
2. **Custom QR Matrix + Canvas Render Time**: `< 16 ms` (`60 FPS` interactive customization preview).
3. **Batch Generation Throughput**: `>= 50 QR codes/second` in background isolate workers without blocking the UI thread.
4. **Verification**: Run automated benchmark tests in `test/performance/` to assert latency and throughput thresholds.
