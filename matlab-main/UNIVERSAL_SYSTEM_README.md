# 🌍 Universal Event Selection System

## What Is This?

The Universal Event Selection System **automatically detects and adapts to ANY EEG event format** - no manual configuration required!

### ✨ Key Features

- **✓ Zero Configuration**: Works out-of-the-box with any dataset
- **✓ Auto-Detection**: Automatically identifies event structure and format
- **✓ Smart Grouping**: Separates trial-specific metadata from condition variables
- **✓ Format Agnostic**: Supports 4+ different event formats
- **✓ Backward Compatible**: Your old scripts still work!

---

## 🚀 Quick Start

### Basic Usage (Recommended)

Just update your file path and run:

```matlab
% Load your data
mffFilePath = 'path/to/your/data.mff';
EEG = pop_mffimport(mffFilePath);

% Universal auto-selection (one line!)
selectedEvents = autoSelectTrialEventsUniversal(EEG);

% Epoch using universal system
epochedData = epochEEGByEventsUniversal(EEG, selectedEvents, [-0.2, 0.8]);
```

**That's it!** The system automatically:
1. Detects your event format (bracket, fields, delimiters, or simple codes)
2. Discovers all available fields
3. Determines which fields are conditions vs trial-specific
4. Groups events intelligently
5. Excludes practice trials

---

## 📊 Supported Event Formats

### Format 1: **Bracket Notation** (Your Current Data)
```
'EVNT_TRSP_...[cel#: 3, obs#: 1, Cond: G23, Code: y, Phon: 3, ...]'
```
**Detected**: ✓ Automatically parses key-value pairs from brackets
**Output**: `'G23_word'`, `'SG23_nonword'`, etc.

---

### Format 2: **Direct Fields** (Common in many systems)
```matlab
EEG.event(1).type = 'Stimulus'
EEG.event(1).condition = 'G23'
EEG.event(1).word_type = 'word'
EEG.event(1).trial_num = 5
```
**Detected**: ✓ Reads fields directly from event structure
**Output**: `'G23_word'`

---

### Format 3: **Delimiter-Separated** (Custom setups)
```
'STIM_G23_word_trial5'
'trigger_cond1_go_rep3'
```
**Detected**: ✓ Splits on underscores/dashes, excludes trial info
**Output**: `'G23_word'`, `'cond1_go'`

---

### Format 4: **Simple Codes** (Biosemi, BrainVision)
```
'S  1', 'S  2', 'S 10', 'DIN1'
```
**Detected**: ✓ Uses codes as-is for grouping
**Output**: `'S1'`, `'S2'`, `'S10'`, `'DIN1'`

---

## 🧠 How It Works (Under the Hood)

### Phase 1: **Auto-Detection**
```matlab
structure = detectEventStructure(EEG);
```
- Samples 100 events to identify format
- Looks for patterns: brackets, rich fields, delimiters, simple codes
- Returns detected format + confidence score

**Example Output**:
```
Format detection:
  Bracket format:    95% (95/100 events)
  Rich fields:       12% (12/100 events)
  Delimiter format:  0% (0/100 events)
  Simple codes:      5% (5/100 events)
✓ Detected format: BRACKET (95% confidence)
✓ Event pattern: "EVNT_TRSP"
```

---

### Phase 2: **Field Discovery**
```matlab
discovery = discoverEventFields(EEG, structure);
```
- Parses all events to extract fields
- Analyzes cardinality (uniqueness ratio)
- Classifies fields as:
  - **Condition fields** (low cardinality, good for grouping)
  - **Trial-specific** (high cardinality, exclude from grouping)
  - **Optional** (medium cardinality)

**Example Output**:
```
Field Analysis:
Field                Unique Vals  Cardinality  Classification
----------------------------------------------------------------------
cel                           14       93.33%  ✗ TRIAL-SPECIFIC
obs                            3       20.00%  ✗ TRIAL-SPECIFIC
Cond                           8        5.33%  ✓ CONDITION
Code                           2        1.33%  ✓ CONDITION
Phon                           5        3.33%  ✓ CONDITION
Verb                           2        1.33%  ✓ CONDITION
trl                           50       96.67%  ✗ TRIAL-SPECIFIC
rtim                         261      100.00%  ✗ TRIAL-SPECIFIC

Recommendations:
  Group by: Cond, Code
  Exclude: cel, obs, trl, rtim
```

**How Classification Works**:
- **Cardinality < 30%** → Condition field (repeated across trials)
- **Cardinality > 70%** → Trial-specific (unique per trial)
- **Common patterns** → Automatic detection:
  - `trial`, `trl`, `obs`, `rt`, `response` → Always trial-specific
  - `cond`, `stim`, `task`, `type` → Always condition

---

### Phase 3: **Universal Parsing**
```matlab
condLabel = parseEventUniversal(evt, structure, discovery);
```
- Parses events using detected format
- Extracts only grouping fields
- Applies value mappings (e.g., `y` → `word`)
- Skips missing data (`?`, `0`, `NA`)

**Example**:
```
Input:  'EVNT_TRSP_...[cel#: 3, Cond: G23, Code: y, trl: 18, ...]'
Extract: Cond='G23', Code='y'
Map:     Code 'y' → 'word'
Output:  'G23_word'
```

---

### Phase 4: **Intelligent Grouping**
```matlab
selectedEvents = autoSelectTrialEventsUniversal(EEG);
```
- Groups events by condition labels
- Excludes practice trials automatically
- Returns unique condition groups

**Example**:
```
Before grouping: 261 unique event strings
After grouping:  6 condition groups

G23_word:        38 trials
SG23_nonword:    35 trials
G45_word:        37 trials
...
```

---

## 🎛️ Advanced Options

### Override Grouping Fields
```matlab
selectedEvents = autoSelectTrialEventsUniversal(EEG, ...
    'GroupBy', {'Cond', 'Code', 'Verb'});
```
Use this if auto-detection picks the wrong fields.

---

### Filter Specific Conditions
```matlab
selectedEvents = autoSelectTrialEventsUniversal(EEG, ...
    'Conditions', {'G23', 'G45'});
```
Only include events matching these patterns.

---

### Include Practice Trials
```matlab
selectedEvents = autoSelectTrialEventsUniversal(EEG, ...
    'ExcludePractice', false);
```
Keep practice trials in the analysis.

---

## 📦 What Gets Saved

When you run `QUICK_START_autoselect.m`, you get:

### 1. **epochedData** (MAT file)
```matlab
epochedData(1).eventType = 'G23_word'
epochedData(1).numEpochs = 38
epochedData(1).avgERP = [256×256 double]  % Averaged ERP
epochedData(1).metrics.mean_snr_db = 23.4
```

### 2. **structure** (Detection results)
```matlab
structure.format = 'bracket'
structure.confidence = 0.95
structure.eventPattern = 'EVNT_TRSP'
```

### 3. **discovery** (Field analysis)
```matlab
discovery.fields = {'cel', 'obs', 'Cond', 'Code', ...}
discovery.groupingFields = {'Cond', 'Code'}
discovery.excludeFields = {'cel', 'obs', 'trl', 'rtim'}
discovery.valueMappings.Code.y = 'word'
```

---

## 🔧 Troubleshooting

### "No events could be parsed!"
**Cause**: Auto-detection failed to identify structure
**Fix**: Check your events with:
```matlab
EEG.event(1)  % Inspect first event
```

### "Only 1 condition found" (should be more)
**Cause**: Auto-detected wrong grouping fields
**Fix**: Override with correct fields:
```matlab
selectedEvents = autoSelectTrialEventsUniversal(EEG, ...
    'GroupBy', {'YourField1', 'YourField2'});
```

### "Too many condition groups" (over-fragmentation)
**Cause**: Including trial-specific fields in grouping
**Fix**: Use fewer grouping fields:
```matlab
selectedEvents = autoSelectTrialEventsUniversal(EEG, ...
    'GroupBy', {'Cond'});  % Just condition, not code
```

---

## 🆚 Comparison: Old vs New

### Old System (Dataset-Specific)
```matlab
% ❌ Hardcoded pattern
pattern = 'EVNT_TRSP';

% ❌ Hardcoded bracket parsing
if contains(eventType, '[') && contains(eventType, ']')
    % Parse brackets...
end

% ❌ Hardcoded field names
groupByFields = {'Cond', 'Code'};

% ❌ Hardcoded value mappings
if strcmp(value, 'y')
    value = 'word';
end
```
**Result**: Only works with your specific dataset format

---

### New System (Universal)
```matlab
% ✓ Auto-detects format
structure = detectEventStructure(EEG);

% ✓ Auto-discovers fields
discovery = discoverEventFields(EEG, structure);

% ✓ Auto-determines grouping
groupByFields = discovery.groupingFields;

% ✓ Auto-maps values
mappings = discovery.valueMappings;
```
**Result**: Works with ANY dataset format!

---

## 📝 File Structure

### Core Universal Functions (NEW)
- `detectEventStructure.m` - Format detection
- `discoverEventFields.m` - Field discovery and analysis
- `parseEventUniversal.m` - Universal event parser
- `autoSelectTrialEventsUniversal.m` - Universal selection
- `epochEEGByEventsUniversal.m` - Universal epoching

### Original Functions (UNCHANGED - Still work!)
- `autoSelectTrialEventsGrouped.m` - Original grouped selection
- `parseEventConditions.m` - Original parser
- `epochEEGByEventsGrouped.m` - Original epoching

### Main Scripts
- `QUICK_START_autoselect.m` - **UPDATED** to use universal system

---

## 🎯 Real-World Examples

### Example 1: Your Current Data (Bracket Format)
```matlab
% Event: 'EVNT_TRSP_...[Cond: G23, Code: y, ...]'
selectedEvents = autoSelectTrialEventsUniversal(EEG);
% Output: {'G23_word', 'SG23_nonword', ...}
```

### Example 2: BrainVision Data (Simple Codes)
```matlab
% Events: 'S  1', 'S  2', 'S 10'
selectedEvents = autoSelectTrialEventsUniversal(EEG);
% Output: {'S1', 'S2', 'S10'}
```

### Example 3: Custom Fields
```matlab
% EEG.event(1).condition = 'go'
% EEG.event(1).stimulus = 'left'
selectedEvents = autoSelectTrialEventsUniversal(EEG);
% Output: {'go_left', 'go_right', 'nogo_left', ...}
```

### Example 4: Delimiter Format
```matlab
% Event: 'STIM_cond1_word_trial5'
selectedEvents = autoSelectTrialEventsUniversal(EEG);
% Output: {'cond1_word', 'cond2_word', ...}
```

---

## 💡 Tips & Best Practices

### 1. **Trust the Auto-Detection**
The system is designed to work automatically. Let it analyze your data first before overriding.

### 2. **Check the Summary**
Always look at the field analysis output to understand what was detected:
```
Field Analysis:
Field                Unique Vals  Cardinality  Classification
----------------------------------------------------------------------
```

### 3. **Start Broad, Then Narrow**
Begin with auto-detected grouping. If you get too few conditions, add more fields. If too many, use fewer.

### 4. **Save Detection Results**
```matlab
save('myDataset_detection.mat', 'structure', 'discovery');
```
Load them later to skip detection phase.

### 5. **Test with Small Data First**
If you have a huge dataset, test on a subset first to verify grouping.

---

## 🚀 Future Compatibility

This system is designed to handle:
- **New event formats** you haven't encountered yet
- **Different EEG systems** (Biosemi, BrainVision, ANT, etc.)
- **Custom experimental paradigms**
- **Multi-site data** with varying conventions

Just run the same script - it adapts automatically! 🎉

---

## 📞 Need Help?

Check these in order:
1. Look at auto-detection output (it tells you what it found)
2. Inspect your events: `EEG.event(1)`
3. Override grouping if needed: `'GroupBy', {'field1', 'field2'}`
4. Check the troubleshooting section above

---

## 🎉 Summary

**Before**: Hardcoded for one specific dataset format
**After**: Automatically adapts to ANY format

**Your workflow now**:
1. Load data
2. Run `autoSelectTrialEventsUniversal(EEG)`
3. Done!

No configuration. No manual field specification. No format-specific code. Just works! ✨
