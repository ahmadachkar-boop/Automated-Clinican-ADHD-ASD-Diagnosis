# Examples & Quick Start Scripts

Example scripts demonstrating how to use the EEG analysis tools.

## Files

- **QUICK_START_autoselect.m** - Quick start guide for automatic event selection
- **example_autoEpoch.m** - Example of automatic epoching
- **example_usage.m** - General usage examples for various tools

## Usage

These scripts demonstrate:
- Loading EEG data
- Running automatic event detection
- Epoching by events
- Computing ERPs
- Generating visualizations

You can run these scripts directly to see how the tools work, or copy/modify them for your own analysis pipelines.

## Note

These examples may use legacy functions. For the most up-to-date methods, see:
- **JuanAnalyzer/** - Modern AI-powered ERP analysis with universal event selection
- **EEGQualityAnalyzer/** - Clinical quality assessment tool

## Getting Started

1. Make sure EEGLAB is installed and in your path
2. Load an example EEG file or use your own data
3. Run one of the example scripts
4. Modify the parameters for your specific needs

For full-featured analysis with GUI:
```matlab
launchJuanAnalyzer      % AI-powered ERP analysis
launchEEGAnalyzer       % Clinical quality assessment
```
