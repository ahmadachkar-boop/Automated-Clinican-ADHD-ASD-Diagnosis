# Quick Start Guide - EEG Quality Analyzer

Get started with the EEG Quality Analyzer in 3 simple steps!

## 🚀 Installation (One-Time Setup)

### Prerequisites
1. Install MATLAB R2018b or later
2. Install EEGLAB: https://sccn.ucsd.edu/eeglab/
3. Install ICLabel plugin from EEGLAB Plugin Manager

### Setup
```matlab
% Add EEGLAB to path
addpath('/path/to/eeglab');
eeglab nogui;

% Add EEG Quality Analyzer to path
addpath('/path/to/matlab');
```

## 🎯 Usage (3 Steps)

### Step 1: Launch
```matlab
launchEEGAnalyzer()
```

### Step 2: Upload
- Click "Browse Files" or drag & drop your EEG file
- Supported formats: `.edf`, `.set`, `.fif`, `.mff`

### Step 3: Analyze
- Click "Start Analysis"
- Wait 5-20 minutes (automatic processing)
- Review quality score and visualizations

## 📊 Results

### Quality Score Interpretation
- **75-100** (Excellent): ✅ Ready for analysis
- **60-74** (Good): ✅ Acceptable quality
- **45-59** (Fair): ⚠️ Use with caution
- **0-44** (Poor): ❌ Consider re-recording

### What You See
1. **Topographic Map**: Spatial distribution of brain activity
2. **Power Spectrum**: Frequency content (Delta, Theta, Alpha, Beta, Gamma)
3. **Signal Trace**: Sample of cleaned EEG signal

## 📄 Export Report
Click "Export Report" to save a PDF with:
- Quality score and classification
- All visualizations
- Detailed metrics

## 🆘 Troubleshooting

### "EEGLAB not found"
```matlab
addpath('/path/to/eeglab');
eeglab nogui;
```

### "ICLabel plugin not found"
1. Open EEGLAB: `eeglab`
2. File → Manage EEGLAB Extensions → Install ICLabel

### Processing too slow
- Normal for large files (can take 20-30 minutes)
- ICA computation is CPU-intensive
- Close other applications to free up RAM

## 📚 Need More Help?
- See `README.md` for comprehensive documentation
- See `example_usage.m` for advanced usage examples
- Check EEGLAB tutorials: https://sccn.ucsd.edu/wiki/EEGLAB

---

**Ready to analyze your first EEG?**
```matlab
launchEEGAnalyzer()
```
