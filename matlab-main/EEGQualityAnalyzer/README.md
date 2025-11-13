# EEG Quality Analyzer

Clinical EEG quality assessment tool with automated analysis and reporting.

## Main Files

- **EEGQualityAnalyzer.m** - Main GUI application (App Designer)
- **launchEEGAnalyzer.m** - Launcher script

## Analysis Functions

- **computeAdvancedQualityMetrics.m** - Advanced quality metrics computation
- **computeClinicalMetrics.m** - Clinical metrics (alpha asymmetry, power ratios, etc.)

## Visualization Functions

- **generateClinicalVisualizations.m** - Clinical visualizations (topoplots, spectra)
- **generateEEGVisualizations.m** - General EEG visualizations
- **visualizeEEGWithMarkers.m** - Visualize EEG with event markers
- **quickViewEEG.m** - Quick preview of EEG data

## Features

- Automated preprocessing pipeline
- Bad channel detection
- ICA artifact removal with ICLabel
- Clinical metrics computation
- Quality assessment scoring
- PDF report generation
- Event detection and visualization

## Usage

From MATLAB root directory:
```matlab
launchEEGAnalyzer
```

Or add to path and launch:
```matlab
addpath('path/to/matlab/EEGQualityAnalyzer');
launchEEGAnalyzer
```

## Supported Formats

- .set (EEGLAB)
- .edf (EDF/EDF+)
- .fif (MNE)
- .mff (EGI)

## Requirements

- MATLAB R2018b or later
- EEGLAB toolbox
- ICLabel plugin (for ICA classification)
- Signal Processing Toolbox
