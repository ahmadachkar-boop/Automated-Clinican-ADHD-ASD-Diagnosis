# MATLAB EEG Analysis Tools

A comprehensive suite of MATLAB tools for EEG analysis, including AI-powered ERP analysis and clinical quality assessment.

![MATLAB](https://img.shields.io/badge/MATLAB-R2018b+-orange)
![EEGLAB](https://img.shields.io/badge/EEGLAB-required-blue)

## 📁 Repository Organization

### Main Tools

#### 🧠 **JuanAnalyzer/**
AI-powered Event-Related Potential (ERP) analysis tool
- Automated AI event detection (Claude/OpenAI)
- N250, N400, P600 component analysis
- Interactive topographic maps
- Frequency band analysis
- Practice trial filtering

**Launch**: `launchJuanAnalyzer`

[📖 Full Documentation](JuanAnalyzer/README.md)

#### 🏥 **EEGQualityAnalyzer/**
Clinical EEG quality assessment tool
- Automated preprocessing pipeline
- Quality scoring (0-100)
- Clinical visualizations
- PDF report generation
- ICLabel artifact classification

**Launch**: `launchEEGAnalyzer`

[📖 Full Documentation](EEGQualityAnalyzer/README.md)

### Supporting Folders

#### 📚 **examples/**
Example scripts and quick start guides
- Quick start for auto event selection
- Example epoching workflows
- General usage demonstrations

[📖 Examples Documentation](examples/README.md)

#### 🗄️ **legacy/**
Older event selection methods (superseded but kept for compatibility)
- Original event selection variants
- Basic epoching functions
- Not actively maintained

[📖 Legacy Documentation](legacy/README.md)

#### ⚠️ **deprecated/**
Deprecated FastICA implementation (not recommended)
- FastICA files (abandoned due to performance issues)
- Old ICA benchmarking tools
- Kept for historical reference only

[📖 Deprecated Documentation](deprecated/README.md)

## 🚀 Quick Start

### Prerequisites

1. **MATLAB** R2018b or later
2. **EEGLAB** toolbox ([download](https://sccn.ucsd.edu/eeglab/))
3. **ICLabel** plugin (install via EEGLAB Plugin Manager)
4. **Signal Processing Toolbox**

### Installation

```matlab
% Clone or download this repository
cd /path/to/matlab

% Add main folder to MATLAB path
addpath('/path/to/matlab');
```

### Launch Tools

```matlab
% AI-powered ERP Analysis
launchJuanAnalyzer

% Clinical Quality Assessment
launchEEGAnalyzer
```

## 🎯 Which Tool Should I Use?

| Use Case | Tool | Features |
|----------|------|----------|
| **ERP research** | JuanAnalyzer | AI event detection, ERP components, topomaps |
| **Clinical assessment** | EEGQualityAnalyzer | Quality scoring, artifact removal, PDF reports |
| **Quick data check** | EEGQualityAnalyzer | Fast automated pipeline |
| **Custom analysis** | examples/ | Modify example scripts for your needs |

## 📊 Supported File Formats

Both tools support:
- `.set` (EEGLAB)
- `.edf` (European Data Format)
- `.mff` (EGI)
- `.fif` (MNE Python)

## 🔧 Key Features

### JuanAnalyzer
- ✅ AI-powered event field discovery (Claude API or OpenAI)
- ✅ Automatic practice trial exclusion
- ✅ Interactive event and time selection
- ✅ PCA-accelerated ICA (3-5x faster)
- ✅ 75% artifact removal threshold
- ✅ Real-time topographic visualization

### EEGQualityAnalyzer
- ✅ Hands-free automated pipeline
- ✅ Multi-dimensional quality scoring
- ✅ Bad channel detection and interpolation
- ✅ ICLabel-based artifact classification
- ✅ Clinical visualizations (topoplots, PSDs)
- ✅ PDF report export

## 🤖 AI Integration (JuanAnalyzer)

JuanAnalyzer uses AI for intelligent event field discovery:

```matlab
% Set your API key (choose one):
setenv('ANTHROPIC_API_KEY', 'your-claude-key');
% or
setenv('OPENAI_API_KEY', 'your-openai-key');

% Launch - AI detection runs automatically
launchJuanAnalyzer
```

Edit `JuanAnalyzer/discoverEventFields.m` to configure:
- AI provider (Claude or OpenAI)
- Confidence thresholds
- Fallback behavior

## 📈 Performance Optimization

### ICA Speedup (3-5x faster)

JuanAnalyzer uses PCA reduction by default:
```matlab
% 128 channels → 40 ICA components
% Retains ~95% variance
% Runtime: 4-6 min instead of 15-30 min
```

Enable multi-threading for additional speedup:
```matlab
maxNumCompThreads('automatic');
```

See `JuanAnalyzer/optimize_ica_performance.m` for diagnostics.

## 📖 Documentation

Each folder contains a README with detailed documentation:
- [JuanAnalyzer Documentation](JuanAnalyzer/README.md)
- [EEGQualityAnalyzer Documentation](EEGQualityAnalyzer/README.md)
- [Examples Documentation](examples/README.md)
- [Legacy Code Documentation](legacy/README.md)

## 🐛 Troubleshooting

### "Method not defined for class"
```matlab
% Make sure you're launching from the root directory or use full path:
run('/path/to/matlab/launchJuanAnalyzer.m')
```

### "EEGLAB not found"
```matlab
% Add EEGLAB to path before launching:
addpath('/path/to/eeglab');
eeglab nogui;
```

### Slow ICA
```matlab
% Run the optimizer:
cd JuanAnalyzer
optimize_ica_performance()
```

## 📝 Notes

- **JuanAnalyzer** is designed for research ERP analysis with AI integration
- **EEGQualityAnalyzer** is designed for clinical quality assessment
- Both tools use separate preprocessing pipelines optimized for their purposes
- Legacy and deprecated folders are kept for reference but not recommended for new projects

## 🔄 Recent Changes

- Organized repository into logical folders
- Removed unused event detection helpers
- Added comprehensive documentation
- Created convenience launchers for both tools
- Fixed topographic map rendering issues
- Reduced artifact threshold to 75%
- Added PCA-accelerated ICA

## 📄 License

See individual tool folders for licensing information.

## 🤝 Contributing

This is a research/clinical tool. Contributions and bug reports welcome.
