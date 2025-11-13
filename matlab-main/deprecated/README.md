# Deprecated - FastICA Implementation

These files are deprecated and no longer used in the analysis pipeline.

## Background

FastICA was initially implemented as a faster alternative to runica for ICA-based artifact removal. However, it was abandoned for the following reasons:

1. **No speed improvement**: Expected 2-5x speedup but saw same or slower performance
2. **Convergence issues**: Failed to converge on 129-channel HD-EEG (stuck at delta ~0.99)
3. **User decision**: User requested to "keep runica for everything"

## Current Solution

**JuanAnalyzer uses**: `pop_runica` with PCA reduction (40 components)
- 3-5x faster than full 128-component ICA
- Reliable convergence
- Retains ~95% of variance

## Files in This Folder

- **fastica.m** - Full FastICA implementation (symmetric & deflation approaches)
- **runFastICA.m** - EEGLAB-compatible wrapper for FastICA
- **setupFastICA.m** - FastICA setup utility
- **test_fastica.m** - FastICA testing script
- **test_fastica_quick.m** - Quick FastICA test
- **benchmark_ica.m** - ICA speed benchmarking

## Status

❌ **Deprecated** - Do not use these files. They are kept for historical reference only.

If you need ICA speedup, use PCA reduction with runica instead:
```matlab
EEG = pop_runica(EEG, 'icatype', 'runica', 'extended', 1, 'pca', 40);
```

See `JuanAnalyzer/optimize_ica_performance.m` and `JuanAnalyzer/benchmark_ica_speed.m` for current optimization tools.
