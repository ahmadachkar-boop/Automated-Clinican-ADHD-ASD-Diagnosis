# EEG Quality Analyzer

A hands-free graphical application for clinicians to automatically evaluate and visualize EEG data quality.

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![MATLAB](https://img.shields.io/badge/MATLAB-R2018b+-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## 🎯 Overview

The **EEG Quality Analyzer** is a clinical-grade tool designed for healthcare professionals to quickly assess the quality of EEG recordings without requiring technical expertise in signal processing. The system automatically:

- Processes raw EEG data through a validated preprocessing pipeline
- Detects and removes artifacts (eye blinks, muscle noise, electrical interference)
- Computes comprehensive quality scores (0-100)
- Generates intuitive visualizations for clinical interpretation
- Provides clear recommendations for data quality

## ✨ Key Features

### 🔄 Automated Pipeline
- **No manual intervention required** - Upload file and go
- Automatic filtering (high-pass, low-pass, notch)
- Bad channel detection and interpolation
- Independent Component Analysis (ICA) for artifact removal
- ICLabel-based automatic artifact classification

### 📊 Comprehensive Quality Assessment
- **Multi-dimensional scoring** (0-100 scale):
  - Channel retention (25 points)
  - Artifact contamination (30 points)
  - Signal-to-noise ratio (25 points)
  - Spectral quality (20 points)
- Classification: Excellent (75+), Good (60-74), Fair (45-59), Poor (<45)

### 🎨 Clinical Visualizations
- **Topographic power maps** - Spatial distribution of brain activity
- **Power spectral density** - Frequency content analysis with band highlighting
- **Signal quality traces** - Representative cleaned signal samples

### 📄 Export Capability
- Generate PDF reports for clinical documentation
- Include quality scores, metrics, and visualizations
- Ready for electronic health record (EHR) integration

## 📋 Requirements

### Software Requirements
- **MATLAB** R2018b or later (R2020a+ recommended)
- **EEGLAB** toolbox (latest version recommended)
- **ICLabel** EEGLAB plugin
- Signal Processing Toolbox (MATLAB)

### Supported File Formats
- `.edf` - European Data Format
- `.set` - EEGLAB dataset
- `.fif` - Neuromag FIF format
- `.mff` - EGI MFF format

### Hardware Requirements
- Minimum 8GB RAM (16GB recommended for large datasets)
- Multi-core processor recommended for ICA computation
- Display resolution: 1920x1080 or higher

## 🚀 Installation

### 1. Install MATLAB
Download and install MATLAB from [MathWorks](https://www.mathworks.com/products/matlab.html).

### 2. Install EEGLAB
```matlab
% Download EEGLAB from https://sccn.ucsd.edu/eeglab/
% Extract to a folder, then add to MATLAB path:
addpath('/path/to/eeglab');
eeglab;
```

### 3. Install ICLabel Plugin
```matlab
% Within EEGLAB:
% File > Manage EEGLAB Extensions > ICLabel
% Or download from: https://github.com/sccn/ICLabel
```

### 4. Download EEG Quality Analyzer
```bash
git clone https://github.com/yourusername/matlab.git
cd matlab
```

### 5. Add to MATLAB Path
```matlab
addpath('/path/to/matlab');
```

## 🎮 Usage

### Quick Start

#### Launch the Application
```matlab
launchEEGAnalyzer()
```

#### Complete Workflow
1. **Upload EEG File**
   - Click "Browse Files" or drag & drop your EEG file
   - Supported formats: .edf, .set, .fif, .mff
   - File info (duration, channels) displays automatically

2. **Start Processing**
   - Click "Start Analysis"
   - Watch progress bar (6 automated stages)
   - Processing time: 5-20 minutes depending on data size

3. **Review Results**
   - Quality score (0-100) displayed prominently
   - ✅ Green checkmark = sufficient quality (≥60)
   - ⚠️ Warning symbol = insufficient quality (<60)
   - View topographic maps, spectral plots, signal traces

4. **Export Report** (optional)
   - Click "Export Report" to save PDF
   - Contains all metrics and visualizations
   - Ready for clinical documentation

### Processing Stages

The application performs 6 automated stages:

1. **Loading Data** (0-15%)
   - Imports EEG file
   - Validates format and structure

2. **Filtering & Preprocessing** (16-33%)
   - Resamples to 250 Hz
   - High-pass filter: 0.5 Hz
   - Low-pass filter: 50 Hz
   - Notch filter: 60 Hz (line noise)
   - Average reference

3. **Detecting Artifacts** (34-50%)
   - Bad channel detection (kurtosis-based)
   - Independent Component Analysis (ICA)
   - ICLabel component classification

4. **Cleaning Signal** (51-67%)
   - Remove artifact components (>90% confidence):
     - Eye movements/blinks
     - Muscle artifacts
     - Heartbeat
     - Line noise
     - Channel noise

5. **Evaluating Quality** (68-83%)
   - Compute quality score (0-100)
   - Analyze spectral features
   - Calculate SNR
   - Identify noise sources

6. **Rendering Visualizations** (84-100%)
   - Generate topographic maps
   - Create spectral plots
   - Render signal traces

## 📈 Quality Metrics Explained

### Overall Score (0-100)
Composite of four components:

#### 1. Channel Quality (0-25 points)
- **Metric**: Percentage of channels retained after bad channel rejection
- **Scoring**:
  - >95% retained → 25 points
  - 90-95% retained → 20 points
  - 80-90% retained → 15 points
  - <80% retained → 10 points

#### 2. Artifact Contamination (0-30 points)
- **Metric**: Percentage of ICA components classified as artifacts
- **Scoring**:
  - <10% artifacts → 30 points
  - 10-20% artifacts → 25 points
  - 20-30% artifacts → 20 points
  - >30% artifacts → 10 points

#### 3. Signal-to-Noise Ratio (0-25 points)
- **Metric**: SNR in decibels (dB)
- **Scoring**:
  - >20 dB → 25 points
  - 15-20 dB → 20 points
  - 10-15 dB → 15 points
  - <10 dB → 10 points

#### 4. Spectral Quality (0-20 points)
- **Metric**: Frequency spectrum characteristics
- **Factors**:
  - Line noise contamination
  - Alpha peak prominence
  - High-frequency noise

### Quality Classifications

| Score | Level | Clinical Interpretation |
|-------|-------|------------------------|
| 75-100 | Excellent | High-quality recording, reliable for all analyses |
| 60-74 | Good | Acceptable quality, suitable for clinical interpretation |
| 45-59 | Fair | Marginal quality, interpret with caution |
| 0-44 | Poor | Insufficient quality, consider re-recording |

## 🏥 Clinical Use Cases

### Resting-State EEG Analysis
- **Application**: Baseline brain activity assessment
- **What to look for**:
  - Alpha activity (8-13 Hz) in posterior regions
  - Symmetric power distribution
  - Minimal artifact contamination

### Pre-Surgical Evaluation
- **Application**: Epilepsy surgery planning
- **What to look for**:
  - Clean signal from all electrode sites
  - High SNR for seizure detection
  - Minimal channel loss

### Research Studies
- **Application**: Group-level statistical analysis
- **What to look for**:
  - Consistent quality across participants
  - Sufficient data duration
  - Low artifact burden

## 🛠️ Advanced Configuration

### Customizing Processing Parameters

You can modify preprocessing parameters by editing `EEGQualityAnalyzer.m` (line 456-459):

```matlab
% In the processEEG function:
params.resample_rate = 250;    % Hz
params.hp_cutoff = 0.5;        % Hz (high-pass)
params.lp_cutoff = 50;         % Hz (low-pass)
params.notch_freq = 60;        % Hz (line noise, use 50 for Europe)
```

### Adjusting Quality Thresholds

Modify quality thresholds in `computeAdvancedQualityMetrics.m`:

```matlab
% Example: More lenient channel retention scoring
if chan_retention > 0.90  % Changed from 0.95
    metrics.channel_score = 25;
```

### ICLabel Artifact Thresholds

Adjust confidence thresholds (line 491):

```matlab
% Format: [Brain; Muscle; Eye; Heart; LineNoise; ChanNoise; Other]
% [min max] - flag if probability in range
EEG = pop_icflag(EEG, [
    0 0;      % Brain (don't flag)
    0.9 1;    % Muscle (flag if >90%)
    0.9 1;    % Eye (flag if >90%)
    0.9 1;    % Heart (flag if >90%)
    0.9 1;    % Line noise (flag if >90%)
    0.9 1;    % Channel noise (flag if >90%)
    0 0]);    % Other (don't flag)
```

## 📊 Understanding Visualizations

**All visualizations display REAL data from your EEG recording** - no simulated or artificial data is used.

### 1. Topographic Power Map (REAL DATA - INTERPOLATED)
- **What it shows**: Smooth, interpolated spatial distribution of alpha band (8-13 Hz) power across the entire scalp
- **Data source**:
  - Computes power spectral density for each channel individually using Welch's method
  - Extracts mean power in 8-13 Hz range
  - Uses real electrode positions from your montage (when available)
  - Interpolates power values across 100x100 grid using scattered interpolation
  - Creates smooth contour map covering the entire head surface
  - Small black dots show actual electrode locations
  - Label indicates: "Real Alpha Power Distribution" or "Real Alpha Power (Approx. Positions)"
- **Interpretation**:
  - Smooth color gradients show interpolated power distribution across scalp
  - Warmer colors (red/yellow) = higher actual alpha power
  - Cooler colors (blue/green) = lower actual alpha power
  - Posterior dominance of alpha is typical in healthy resting-state
  - Values shown in µV² (microvolts squared)
  - Black dots indicate actual measurement locations
- **Note**: Interpolation provides publication-quality visualization. If channel locations are missing, generic circular positions are used, but **power values are always real**

### 2. Power Spectral Density - PSD (REAL DATA)
- **What it shows**: Actual power across frequency spectrum (0-50 Hz) from your EEG
- **Data source**:
  - Computed using Welch's method on cleaned EEG data
  - Shows average power across all channels
  - Colored bands highlight standard frequency ranges
- **Interpretation**:
  - Delta (0.5-4 Hz): Deep sleep, artifacts
  - Theta (4-8 Hz): Drowsiness, meditation
  - Alpha (8-13 Hz): Relaxed wakefulness, eyes closed
  - Beta (13-30 Hz): Active thinking, alertness
  - Gamma (30-50 Hz): Cognitive processing, artifacts
  - Sharp peak at 60 Hz = line noise contamination

### 3. Representative Signal Trace (REAL DATA)
- **What it shows**: Actual 3-second sample of cleaned EEG signal from a representative channel
- **Data source**:
  - Attempts to use Cz electrode if available
  - Falls back to middle channel otherwise
  - Normalized for display (mean=0, std=1)
- **Interpretation**:
  - Smooth oscillations = good quality
  - Sharp spikes = possible residual artifacts
  - Flat signal = bad channel or equipment issue

## 🔍 Troubleshooting

### Common Issues

#### "EEGLAB not found" Error
**Solution**:
```matlab
addpath('/path/to/eeglab');
eeglab nogui;
```

#### "ICLabel plugin not found" Warning
**Solution**:
1. Open EEGLAB: `eeglab`
2. File → Manage EEGLAB Extensions
3. Install "ICLabel"
4. Restart MATLAB

#### Processing Takes Very Long (>30 min)
**Cause**: ICA computation on high-density EEG (>64 channels)
**Solutions**:
- Use computer with more RAM
- Reduce data length to 5-10 minutes
- Consider downsampling more aggressively

#### Poor Quality Score Despite Clean-Looking Data
**Possible reasons**:
- Short recording duration (<60 seconds)
- Many channels rejected due to high impedance
- High artifact burden requiring many ICA components removed
- Review individual metric scores for specifics

#### Application Crashes During ICA
**Solutions**:
- Ensure sufficient RAM (16GB+ recommended)
- Close other applications
- Reduce data length
- Update EEGLAB to latest version

#### ICLabel MEX Compilation Warning (Performance Issue)
**Warning Message**: `"ICLabel: defaulting to uncompiled matlab code (about 80x slower)"`

**What it means**: ICLabel's C++ MEX files failed to compile, causing it to fall back to slower MATLAB code. Processing will still work but take significantly longer.

**Solutions**:
1. **Install Xcode Command Line Tools** (macOS):
   ```bash
   xcode-select --install
   ```

2. **Verify MATLAB compiler**:
   ```matlab
   mex -setup C++
   ```

3. **Manually compile ICLabel MEX files**:
   ```matlab
   % Navigate to ICLabel directory
   cd('~/Library/Application Support/MathWorks/MATLAB Add-Ons/Collections/EEGLAB/plugins/ICLabel1.7/matconvnet')
   % Run compilation
   vl_compilenn
   ```

4. **Alternative**: Live with slower performance (processing will take 5-20 min instead of seconds for ICLabel step)

5. **Contact ICLabel support**: If compilation continues to fail, email Luca Pion-Tonachini at lpionton@ucsd.edu with your system details

**Note**: This warning does not affect accuracy, only processing speed.

#### EEGLAB Path Warning (Repeated Messages)
**Warning Message**: `"Path Warning: It appears that you have added the path to all of the subfolders to EEGLAB"`

**What it means**: All EEGLAB subfolders were added to MATLAB path, which may cause conflicts.

**Solution**:
1. Remove all EEGLAB paths:
   ```matlab
   rmpath(genpath('/path/to/eeglab'));
   ```

2. Go to EEGLAB folder and run:
   ```matlab
   cd /path/to/eeglab
   eeglab
   ```

   EEGLAB will automatically add only the necessary paths.

3. Save the path for future sessions:
   ```matlab
   savepath
   ```

## 📚 Background & Methods

### Preprocessing Pipeline
Based on established EEG preprocessing best practices:
- Makoto's preprocessing pipeline (UCSD)
- Jas et al. (2017) - "Autoreject" methodology
- Pion-Tonachini et al. (2019) - ICLabel

### Quality Metrics
Adapted from:
- Delorme et al. (2012) - EEGLAB methods
- Bigdely-Shamlo et al. (2015) - EEG quality assessment
- PREP pipeline (Bigdely-Shamlo et al., 2015)

### References
1. Delorme, A., & Makeig, S. (2004). EEGLAB: an open source toolbox for analysis of single-trial EEG dynamics. *Journal of Neuroscience Methods*, 134(1), 9-21.

2. Pion-Tonachini, L., Kreutz-Delgado, K., & Makeig, S. (2019). ICLabel: An automated electroencephalographic independent component classifier, dataset, and website. *NeuroImage*, 198, 181-197.

3. Bigdely-Shamlo, N., et al. (2015). The PREP pipeline: standardized preprocessing for large-scale EEG analysis. *Frontiers in Neuroinformatics*, 9, 16.

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👨‍⚕️ Clinical Disclaimer

This software is intended for research and clinical decision support purposes only. It should not be used as the sole basis for clinical diagnosis or treatment decisions. Always consult with qualified healthcare professionals and follow institutional protocols.

## 📧 Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Email: [your-email@domain.com]
- Documentation: [link to docs]

## 🙏 Acknowledgments

- SCCN/UCSD for EEGLAB framework
- ICLabel team for automated component classification
- MATLAB community for GUI development resources

---

**Version**: 1.0.0
**Last Updated**: October 31, 2025
**Authors**: Ahmad Achkar
**Institution**: [Your Institution]
