# Resting State Analyzer

Automated resting state EEG analysis tool for continuous segment extraction and condition comparison (e.g., eyes open vs eyes closed).

## Overview

RestingStateAnalyzer is specifically designed for resting state EEG analysis where recordings contain **start-end marker pairs** that define continuous segments of different conditions, rather than time-locked events for ERP analysis.

## Key Features

### 🎯 Start-End Marker Pair Selection
- Two-step workflow to define marker pairs
- Each condition defined by a start marker and end marker
- Supports multiple conditions in a single recording
- Example: `Eyes_Open_Start` → `Eyes_Open_End` labeled as "EyesOpen"

### 🔬 Automated Processing Pipeline
1. **Loading** - Supports .mff, .set, .edf formats
2. **Filtering** - 250Hz resample, 0.5-50Hz bandpass, 60Hz notch filter
3. **Artifact Detection** - Multi-method bad channel detection (kurtosis, probability, spectrum, correlation)
4. **ICA** - Independent component analysis with PCA reduction to 40 components
5. **Signal Cleaning** - ICLabel artifact removal at 75% confidence threshold
6. **Segment Extraction** - Continuous data extraction between start-end markers
7. **Quality Evaluation** - 100-point comprehensive quality scoring
8. **Band Power Analysis** - Spectral analysis for each condition

### 📊 Resting State Metrics
- **Frequency Bands**: Delta (1-4 Hz), Theta (4-8 Hz), Alpha (8-13 Hz), Beta (13-30 Hz), Gamma (30-50 Hz)
- **Absolute Power**: Power spectral density in µV²
- **Relative Power**: Percentage of total power per band
- **Condition Comparison**: Statistical comparison between conditions

### 📈 Visualizations
- **Relative Band Powers**: Grouped bar chart comparing all conditions
- **Absolute Band Powers**: Log-scale grouped bar chart
- **Power Differences**: Difference plot for two-condition comparisons
- **Segment Statistics**: Duration, counts, and dominant bands per condition

## How to Use

### Launch the Application

```matlab
cd matlab-main/RestingStateAnalyzer
RestingStateAnalyzer
```

### Workflow

#### 1. Select EEG File
- Click **"Select EEG File"**
- Choose your .mff, .set, or .edf file
- File info will be displayed once loaded

#### 2. Define Start-End Marker Pairs
- Click **"Select Start/End Markers"**
- **Step 1**: Select event field (usually 'type')
- **Step 2**: Define marker pairs:
  - Select **Start Marker** from dropdown
  - Select **End Marker** from dropdown
  - Enter **Condition Label** (e.g., "EyesOpen")
  - Click **"Add Pair"** to save
  - Repeat for additional conditions (e.g., "EyesClosed")
  - Click **"OK"** when done

#### 3. Start Analysis
- Click **"Start Analysis"**
- Processing takes 2-5 minutes depending on file size
- Progress is shown with 8 processing stages

#### 4. View Results
Results are organized into 4 tabs:

**Quality Assessment Tab:**
- Signal-to-noise ratio
- Spectral quality
- Bad channel information
- Artifact removal statistics

**Condition Comparison Tab:**
- Relative band power comparison (bar charts)
- Absolute band power comparison (log scale)
- Band power differences (if 2 conditions)
- Segment statistics summary

**Epoch Analysis Tab:**
- Quality score timeline
- Segment-level analysis

**Summary Report Tab:**
- Comprehensive text report
- Export options

## Example Use Case: Eyes Open vs Eyes Closed

### Recording Structure
Your EEG file contains alternating segments:
```
[ Eyes_Open_Start ... continuous EEG ... Eyes_Open_End ]
[ Eyes_Closed_Start ... continuous EEG ... Eyes_Closed_End ]
[ Eyes_Open_Start ... continuous EEG ... Eyes_Open_End ]
[ Eyes_Closed_Start ... continuous EEG ... Eyes_Closed_End ]
...
```

### Setup
1. Load your resting state EEG file
2. Select markers:
   - Pair 1: Start=`Eyes_Open_Start`, End=`Eyes_Open_End`, Label=`EyesOpen`
   - Pair 2: Start=`Eyes_Closed_Start`, End=`Eyes_Closed_End`, Label=`EyesClosed`
3. Click OK and Start Analysis

### Expected Results
- **Alpha Suppression**: Higher alpha power with eyes closed
- **Beta Activity**: May increase with eyes open (alertness)
- **Condition Comparison**: Shows relative differences between states
- **Clinical Indicators**: Alpha/Theta ratio per condition

## File Formats

### Supported Input Formats
- **.mff** - EGI (Electrical Geodesics, Inc.) format
- **.set** - EEGLAB dataset format
- **.edf** - European Data Format

### Requirements
- EEGLAB must be in MATLAB path
- Required EEGLAB plugins:
  - `mffimport` (for .mff files)
  - `ICLabel` (for artifact classification)

## Output

### Metrics Computed
- **Per Condition**:
  - Number of segments
  - Total duration
  - Mean segment duration
  - Absolute power per band (mean, std, median)
  - Relative power per band (mean, std, median)
  - Dominant frequency band

- **Comparison** (if 2 conditions):
  - Relative power difference per band
  - Absolute power difference per band
  - Statistical significance indicators

### Export Options
- Full analysis report (text format)
- Processed EEG data
- Quality metrics
- Band power statistics

## Differences from EEGQualityAnalyzer

| Feature | EEGQualityAnalyzer | RestingStateAnalyzer |
|---------|-------------------|---------------------|
| **Purpose** | Event-related potentials (ERPs) | Resting state analysis |
| **Event Type** | Time-locked events | Start-end marker pairs |
| **Segmentation** | Epochs around events | Continuous segments between markers |
| **Analysis** | ERP waveforms, quality metrics | Band power comparison |
| **Typical Use** | N400, P600, N250 components | Eyes open/closed, resting states |
| **Output** | ERP visualizations | Band power comparisons |

## Technical Details

### Preprocessing Pipeline
- **Resampling**: 250 Hz (for computational efficiency)
- **High-pass**: 0.5 Hz (removes DC drift)
- **Low-pass**: 50 Hz (removes high-frequency noise)
- **Notch**: 60 Hz (removes line noise)

### Bad Channel Detection
Four independent methods:
1. **Kurtosis**: Detects non-normal distributions
2. **Probability**: Identifies outlier channels
3. **Spectrum**: Finds channels with abnormal frequency content
4. **Correlation**: Detects channels uncorrelated with neighbors

Channels are flagged but **not removed** - preserved for clinical review.

### ICA Configuration
- **PCA Reduction**: To 40 components for speed
- **Algorithm**: Infomax ICA
- **Artifact Classification**: ICLabel at 75% confidence
- **Removed Components**: Eye, muscle, heart, line noise

### Spectral Analysis
- **Method**: Welch's power spectral density
- **Window**: 2 seconds (or segment length if shorter)
- **Overlap**: 50%
- **FFT**: Adaptive (minimum 256 points)

## Troubleshooting

### No Segments Extracted
- Check marker spelling matches exactly
- Verify start markers occur before end markers
- Ensure no overlapping segments (start-start-end pattern)
- Check event field selection (should contain marker strings)

### Quality Score Low
- File may have excessive artifacts
- Bad channels detected - review channel list
- Consider manually cleaning data before analysis
- Check recording setup (impedances, grounding)

### Visualization Errors
- Ensure MATLAB version is R2020a or later
- Check that all functions are in MATLAB path
- Verify EEG data structure is valid

## Requirements

- MATLAB R2020a or later
- EEGLAB (latest version recommended)
- Signal Processing Toolbox
- Statistics and Machine Learning Toolbox (optional)

## Citation

If you use RestingStateAnalyzer in your research, please cite the parent EEGQualityAnalyzer project and note the resting state modifications.

## Support

For issues, questions, or feature requests:
1. Check this documentation
2. Review EEGLAB documentation for format-specific issues
3. Verify marker definitions match your recording structure

## Version History

- **v1.0** (2025) - Initial release
  - Start-end marker pair selection
  - Continuous segment extraction
  - Band power analysis
  - Condition comparison visualizations
