# JuanAnalyzer - AI-Powered ERP Analysis Tool

JuanAnalyzer is a MATLAB GUI application for automated EEG analysis with AI-powered event detection and ERP (Event-Related Potential) analysis.

## Main Files

### Application Files
- **JuanAnalyzer.m** - Main GUI application (App Designer)
- **launchJuanAnalyzer.m** - Launcher script to start the GUI
- **juananalyze.m** - Command-line version of the analyzer

## Core Functionality

### Event Detection & Analysis
- **discoverEventFields.m** - AI-powered event field discovery with heuristic fallback
- **autoSelectTrialEventsUniversal.m** - Universal event selection for different datasets
- **detectEEGEvents.m** - Detect events in EEG data
- **detectEventStructure.m** - Analyze event structure patterns
- **diagnoseEvents.m** - Diagnose event-related issues

### Event Processing
- **epochEEGByEventsUniversal.m** - Universal epoching function with practice trial filtering
- **parseEventUniversal.m** - Parse events from different formats
- **parseEventConditions.m** - Parse event conditions and grouping
- **filterEventsByPattern.m** - Filter events by pattern matching
- **getAvailableEventFields.m** - Get available event fields from EEG data

### AI Integration
- **callAIAnalysis.m** - Call Claude/OpenAI APIs for event analysis
- **buildFieldAnalysisPrompt.m** - Build prompts for AI field discovery

### Performance Optimization
- **optimize_ica_performance.m** - Diagnostic tool for ICA performance optimization
- **benchmark_ica_speed.m** - Benchmark different ICA configurations
- **startup_template.m** - Template for MATLAB startup.m to enable multi-threading

## Features

### Analysis Pipeline
1. **Data Loading** - Supports EEGLAB .set files
2. **Preprocessing**
   - Band-pass filtering (0.1-40 Hz)
   - Bad channel detection (kurtosis-based)
3. **ICA Artifact Removal**
   - PCA-reduced runica (40 components for speed)
   - ICLabel automatic artifact classification
   - 75% confidence threshold for artifact removal
4. **AI Event Discovery**
   - Automatic event field detection using Claude/OpenAI
   - Heuristic fallback with confidence scoring
   - Practice trial filtering
5. **Epoching** - Event-based segmentation (-200 to 800 ms)
6. **ERP Analysis**
   - N250, N400, P600 component analysis
   - Interactive waveform selection and comparison
7. **Frequency Analysis** - Power spectral density by band
8. **Topographic Maps** - Interactive time-slider visualization

### Visualizations
- **ERP Waveforms Tab** - Multi-select listbox for comparing events
- **Frequency Analysis Tab** - Band power analysis (delta, theta, alpha, beta, gamma)
- **Topographic Maps Tab** - Scalp voltage distributions with time slider
- **Summary Tab** - Processing summary and quality metrics

## Configuration

### AI Settings
Set your API keys as environment variables:
```bash
# For Claude (Anthropic)
export ANTHROPIC_API_KEY='your-api-key'

# For OpenAI
export OPENAI_API_KEY='your-api-key'
```

Edit `discoverEventFields.m` to choose AI provider:
- Line 105-109: Set `useAIMode` to 'always', 'fallback', or 'never'
- Line 112-117: Choose 'anthropic' or 'openai'

### ICA Optimization
For faster ICA on MacBook:
1. Run `optimize_ica_performance()` to check threading
2. Copy `startup_template.m` to `~/Documents/MATLAB/startup.m`
3. Restart MATLAB

Speedup achieved: 3-5x faster (4-6 min vs 15-30 min for 128 channels)

## Usage

### GUI Mode
```matlab
% Launch the GUI
launchJuanAnalyzer

% Or directly
JuanAnalyzer
```

### Command-Line Mode
```matlab
% Analyze a single file
results = juananalyze('path/to/eeg_data.set');

% With options
results = juananalyze('data.set', 'TimeWindow', [-0.2 0.8], 'ExcludePractice', true);
```

## Requirements

- MATLAB R2020a or later
- EEGLAB toolbox
- Signal Processing Toolbox
- Statistics Toolbox (optional, for advanced metrics)
- Internet connection (for AI event discovery)

## Key Parameters

### ICA Settings (JuanAnalyzer.m line 537)
- PCA reduction: 40 components (adjustable to 30-60)
- Extended ICA: enabled
- Artifact threshold: 75% confidence

### Event Detection (discoverEventFields.m)
- AI confidence vs heuristic confidence comparison
- Practice trial patterns: 'Practice', 'Prac', 'Training', etc.

### Epoching (epochEEGByEventsUniversal.m)
- Default window: -200 to 800 ms
- Baseline correction: -200 to 0 ms

## Support

For issues or questions, see the main repository documentation.

## Version History

See git commit history for detailed changes.
