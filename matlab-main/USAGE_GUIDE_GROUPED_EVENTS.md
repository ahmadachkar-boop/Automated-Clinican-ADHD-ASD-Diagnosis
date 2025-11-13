# Event Grouping Fix - Usage Guide

## The Problem (What Was Happening Before)

Your data had **261 "unique" event types**, but each one only had **n=1 trial**. This happened because:

- Event names included trial-specific metadata (trial number, response time, observation number)
- Each individual trial was treated as its own unique event type
- You can't compute meaningful ERPs from single trials - you need averaging across multiple trials

**Example of over-fragmented events:**
```
EVNT_TRSP___?_y_G23_3_1_5_Session1_y_?___3_1___1__0_0____18_   (n=1)
EVNT_TRSP___?_y_G23_3_1_7_Session1_n_?___3_1___2__0_0____20_   (n=1)
EVNT_TRSP___?_y_G23_3_1_38_Session1_y_?___3_1___4__0_0____51_  (n=1)
```

These should all be grouped as: **`G23_word`** with **n=~15-20 trials**

## The Solution (What Happens Now)

New functions intelligently **group trials by experimental condition**, ignoring trial-specific details:

1. **`parseEventConditions.m`** - Extracts meaningful condition info from complex event strings
2. **`autoSelectTrialEventsGrouped.m`** - Groups events by experimental condition
3. **`epochEEGByEventsGrouped.m`** - Epochs data using grouped conditions

## Quick Start

The updated `QUICK_START_autoselect.m` now uses intelligent grouping by default:

```matlab
% Just run this - it now groups events automatically!
QUICK_START_autoselect
```

**Expected Results:**
- ~6-10 condition groups (not 261!)
- ~20-40 trials per condition
- Meaningful ERPs you can actually analyze

## Grouping Options

### Basic Grouping (Default)
Groups by **Condition + Word Status**:

```matlab
% Groups: G23_word, G23_nonword, SG23_nonword, etc.
events = autoSelectTrialEventsGrouped(EEG);
```

### Detailed Grouping
Add phonological and verb features:

```matlab
% Groups: G23_word_3_verb, G23_word_3_nonverb, etc.
events = autoSelectTrialEventsGrouped(EEG, ...
    'GroupBy', {'Cond', 'Code', 'Phon', 'Verb'});
```

### Condition-Specific Analysis
Focus on specific conditions:

```matlab
% Only analyze word conditions
events = autoSelectTrialEventsGrouped(EEG, ...
    'Conditions', {'G23', 'G45', 'KG1'});
```

## Grouping Field Options

| Field | Description | Example Values |
|-------|-------------|----------------|
| `Cond` | Main experimental condition | `G23`, `SG23`, `SKG1`, `KG1` |
| `Code` | Word vs non-word | `word`, `nonword` |
| `Phon` | Phonological features | `2`, `3`, `4`, `5` |
| `Verb` | Verb status | `verb`, `nonverb` |
| `Sylb` | Syllable count | `1`, `2` |
| `TskB` | Task block | `Session1`, `Session2` |

## Advanced Examples

### Compare Words vs Non-Words
```matlab
% Separate word and non-word conditions
events = autoSelectTrialEventsGrouped(EEG, ...
    'GroupBy', {'Code', 'Phon'});
% Results: word_3, word_4, nonword_3, nonword_4, etc.
```

### Phonological Analysis
```matlab
% Group by phonological features only
events = autoSelectTrialEventsGrouped(EEG, ...
    'GroupBy', {'Phon', 'Verb'});
% Results: 3_verb, 3_nonverb, 4_verb, 4_nonverb, etc.
```

### Session Comparison
```matlab
% Keep session information
events = autoSelectTrialEventsGrouped(EEG, ...
    'GroupBy', {'Cond', 'Code', 'TskB'}, ...
    'ExcludePractice', false);
% Results: G23_word_Session1, G23_word_Session2, etc.
```

## Understanding Your Data

### Practice Trials
These are automatically excluded by default:
- Conditions: `a`, `s`, `s1`, `w`
- Tasks: `Prac`, `PracSlow`

To include them:
```matlab
events = autoSelectTrialEventsGrouped(EEG, 'ExcludePractice', false);
```

### Main Experimental Conditions

**Word Conditions** (Code: y):
- `G23`, `G45` - Words with different features
- `KG1` - Another word type

**Non-Word Conditions** (Code: n):
- `SG23`, `SG45` - Non-words matching G23/G45
- `SKG1` - Non-word matching KG1

## Troubleshooting

### "Too many conditions with low trial counts"
**Problem:** Still getting fragmented groups (e.g., 50 groups with n=2-5 each)

**Solution:** Use fewer grouping fields:
```matlab
% Instead of this (too specific):
events = autoSelectTrialEventsGrouped(EEG, ...
    'GroupBy', {'Cond', 'Code', 'Phon', 'Verb', 'Sylb'});

% Use this (broader groups):
events = autoSelectTrialEventsGrouped(EEG, ...
    'GroupBy', {'Cond', 'Code'});
```

### "No events selected"
**Problem:** Condition names don't match

**Solution:** Check available conditions:
```matlab
% See what conditions exist
events = autoSelectTrialEventsGrouped(EEG, 'Display', true);
% Then use exact names from the output
```

## Complete Analysis Example

```matlab
clear; clc;

% 1. Load your MFF file
mffFilePath = 'path/to/your/file.mff';
EEG = pop_mffimport(mffFilePath);

% 2. Auto-select and group events
selectedEvents = autoSelectTrialEventsGrouped(EEG, ...
    'GroupBy', {'Cond', 'Code'}, ...
    'ExcludePractice', true);

% 3. Epoch the data
epochTimeWindow = [-0.2, 0.8];
epochedData = epochEEGByEventsGrouped(EEG, selectedEvents, epochTimeWindow);

% 4. Check results
for i = 1:length(epochedData)
    fprintf('%s: n=%d, SNR=%.1f dB\n', ...
        epochedData(i).eventType, ...
        epochedData(i).numEpochs, ...
        epochedData(i).metrics.mean_snr_db);
end

% 5. Plot an ERP
figure;
plot(epochedData(1).timeVector, epochedData(1).avgERP(1,:));
xlabel('Time (s)');
ylabel('µV');
title(sprintf('%s (n=%d)', epochedData(1).eventType, epochedData(1).numEpochs));
```

## What Changed in the Code

### Before (Problematic):
```matlab
% Would return 261 unique event strings, each appearing once
events = autoSelectTrialEvents(EEG);
% Result: n=1 for everything!
```

### After (Fixed):
```matlab
% Returns ~8 condition labels, each appearing 20-40 times
events = autoSelectTrialEventsGrouped(EEG);
% Result: Proper trial counts for statistical analysis!
```

## Why This Matters

**With n=1 per "event":**
- ❌ No trial averaging
- ❌ No SNR calculation
- ❌ No statistical comparisons
- ❌ Can't see ERP components

**With proper grouping (n=20-40):**
- ✅ Clean averaged ERPs
- ✅ Reliable SNR metrics
- ✅ Statistical power for comparisons
- ✅ Can identify ERP components (N400, P600, etc.)

---

## Need Help?

If you're unsure what grouping strategy to use:

1. Start with default (Condition + Code)
2. Check the trial counts in the output
3. Aim for 15-30 trials per condition minimum
4. Add more grouping fields only if scientifically necessary

**Goal:** Balance between experimental detail and statistical power!
