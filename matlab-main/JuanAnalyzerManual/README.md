# JuanAnalyzer - Manual Version

This is the **manual event selection version** of JuanAnalyzer. Unlike the AI-powered version, this version allows you to manually select which event types to analyze.

## Key Differences from AI Version

### Removed Features:
- ❌ AI-powered event detection (Claude/OpenAI API)
- ❌ Automatic paradigm identification  
- ❌ AI field classification
- ❌ Practice trial detection
- ❌ API key requirements

### Added Features:
- ✅ **Manual event selection dialog**
- ✅ Shows all unique event types with trial counts
- ✅ Multi-select interface with Select All / Clear All
- ✅ No API keys required
- ✅ No AI dependencies

## Workflow

1. **Select EEG File** - Browse and load your .mff, .set, or .edf file
2. **Select Events** - 2-step process:
   - **Step 1:** Choose which fields to group by (e.g., mffkey_Cond, mffkey_Code)
   - **Step 2:** Select which resulting event types to analyze
3. **Start Analysis** - Run the full ERP analysis pipeline

## Event Selection (2-Step Process)

### Step 1: Select Grouping Fields
After loading your file, click "📋 Select Events" to see:
- All available event fields with unique value counts
- Auto-selects mffkey* fields by default
- Choose which fields define your conditions
- Example: Select `mffkey_Cond` + `mffkey_Code` to get "G23_valid", "SG23_invalid", etc.

### Step 2: Select Event Types
Based on your field selection:
- See all unique event combinations
- Number of trials for each event type
- Interactive multi-select listbox
- All events selected by default
- Can go back to change field selection

## Use Cases

Use the manual version when you:
- Don't have/want to use AI APIs
- Know exactly which events you want to analyze
- Want full control over event selection
- Have simple event structures
- Don't need automated practice trial detection

## Analysis Features

Same powerful analysis as the AI version:
- ✅ Automatic preprocessing (filtering, resampling, referencing)
- ✅ ICA artifact removal
- ✅ Bad channel detection
- ✅ ERP component analysis (N250, N400, P600)
- ✅ **Baseline-corrected frequency analysis**
- ✅ Topographic maps
- ✅ Per-condition breakdown

## Launch

```matlab
cd JuanAnalyzerManual
JuanAnalyzer
```

## Requirements

- MATLAB R2019b or later
- EEGLAB toolbox
- No AI API keys needed!
