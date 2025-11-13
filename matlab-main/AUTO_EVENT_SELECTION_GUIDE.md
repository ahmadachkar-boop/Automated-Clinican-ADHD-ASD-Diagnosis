# Automatic Event Selection Guide

## Problem

When working with MFF files containing complex event structures (like EVNT_TRSP events with condition codes), you may have 1000+ unique event types. Manually selecting specific event types for epoching is tedious and error-prone.

## Solution

Three new tools have been added to automatically filter and select events:

1. **`autoSelectTrialEvents.m`** - Standalone function for automatic event selection
2. **`filterEventsByPattern.m`** - General-purpose event filtering utility
3. **Enhanced `detectEEGEvents.m`** - Now supports built-in filtering

---

## Quick Start

### Method 1: Using autoSelectTrialEvents (Recommended)

This is the easiest method for your specific use case with EVNT_TRSP events.

```matlab
% Load your MFF file
EEG = pop_mffimport('your_file.mff');

% Auto-select ALL EVNT_TRSP events
selectedEvents = autoSelectTrialEvents(EEG);

% Or select only specific conditions
conditions = {'SG23', 'SG45', 'SKG1', 'KG1', 'G23', 'G45'};
selectedEvents = autoSelectTrialEvents(EEG, 'Conditions', conditions);

% Now epoch around selected events
timeWindow = [-0.2, 0.8];  % 200ms before to 800ms after
epochedData = epochEEGByEvents(EEG, selectedEvents, timeWindow);
```

### Method 2: Using detectEEGEvents with Filters

Use this to integrate filtering directly into event detection.

```matlab
% Load EEG
EEG = pop_mffimport('your_file.mff');

% Detect events with automatic filtering
eventInfo = detectEEGEvents(EEG, 'type', ...
    'FilterPattern', 'EVNT_TRSP', ...
    'FilterConditions', {'SG23', 'SKG1', 'KG1'});

% eventInfo.eventTypes now contains only filtered events
selectedEvents = eventInfo.eventTypes;

% Epoch the data
epochedData = epochEEGByEvents(EEG, selectedEvents, [-0.2, 0.8]);
```

### Method 3: Using filterEventsByPattern

Use this for custom filtering scenarios.

```matlab
% Load EEG
EEG = pop_mffimport('your_file.mff');

% First get all event types
eventInfo = detectEEGEvents(EEG, 'type');
allEventTypes = eventInfo.eventTypes;

% Apply custom filtering
selectedEvents = filterEventsByPattern(allEventTypes, ...
    'Pattern', 'EVNT_TRSP', ...
    'Conditions', {'SG23', 'SKG1'}, ...
    'MatchAny', false);  % Require BOTH pattern AND condition match

% Epoch the data
epochedData = epochEEGByEvents(EEG, selectedEvents, [-0.2, 0.8]);
```

---

## Detailed Usage

### autoSelectTrialEvents

**Purpose:** Automatically select trial events (like EVNT_TRSP) based on condition codes.

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `EEG` | struct | (required) | EEGLAB EEG structure |
| `'Pattern'` | string | `'EVNT_TRSP'` | Event type pattern to match |
| `'Conditions'` | cell array | `{}` (all) | Specific condition codes |
| `'FieldName'` | string | auto-detect | Event field to use |
| `'Display'` | logical | `true` | Show summary table |

**Examples:**

```matlab
% Select ALL EVNT_TRSP events
events = autoSelectTrialEvents(EEG);

% Select only specific conditions
events = autoSelectTrialEvents(EEG, 'Conditions', {'SG23', 'SKG1', 'KG1'});

% Select from specific event field
events = autoSelectTrialEvents(EEG, 'FieldName', 'label');

% Quiet mode (no display)
events = autoSelectTrialEvents(EEG, 'Display', false);
```

**Output:**

Returns a cell array of selected event type strings, e.g.:
```matlab
{
    'EVNT_TRSP_?y_SG23_3_1_...'
    'EVNT_TRSP_?y_SG45_4_1_...'
    'EVNT_TRSP_?n_SKG1_0_0_...'
    ...
}
```

---

### filterEventsByPattern

**Purpose:** General-purpose event filtering with pattern and condition matching.

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `eventTypes` | cell array | (required) | Event types or event struct |
| `'Pattern'` | string/cell | `'EVNT_TRSP'` | Pattern(s) to match |
| `'Conditions'` | cell array | `{}` | Condition codes to match |
| `'MatchAny'` | logical | `true` | Match ANY vs ALL criteria |
| `'CaseSensitive'` | logical | `false` | Case-sensitive matching |

**Examples:**

```matlab
% Basic pattern matching
events = filterEventsByPattern(eventTypes, 'Pattern', 'EVNT_TRSP');

% Multiple patterns
events = filterEventsByPattern(eventTypes, 'Pattern', {'EVNT_TRSP', 'EVNT_bgin'});

% Condition filtering only
events = filterEventsByPattern(eventTypes, 'Conditions', {'SG23', 'G45'});

% Pattern AND condition (both must match)
events = filterEventsByPattern(eventTypes, ...
    'Pattern', 'EVNT_TRSP', ...
    'Conditions', {'SG23'}, ...
    'MatchAny', false);
```

---

### detectEEGEvents (Enhanced)

**Purpose:** Detect events with optional automatic filtering.

**New Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `'FilterPattern'` | string | `''` | Pattern to filter by |
| `'FilterConditions'` | cell array | `{}` | Conditions to filter by |

**Examples:**

```matlab
% Standard detection (no filter)
eventInfo = detectEEGEvents(EEG);

% With pattern filter
eventInfo = detectEEGEvents(EEG, 'type', 'FilterPattern', 'EVNT_TRSP');

% With condition filter
eventInfo = detectEEGEvents(EEG, 'type', ...
    'FilterConditions', {'SG23', 'SKG1', 'KG1'});

% With both filters
eventInfo = detectEEGEvents(EEG, 'type', ...
    'FilterPattern', 'EVNT_TRSP', ...
    'FilterConditions', {'SG23', 'SKG1'});
```

**Output Fields (new):**

- `.filterApplied` - Boolean indicating if filter was used
- `.numFiltered` - Number of events after filtering

---

## Complete Workflow Example

```matlab
%% 1. Load MFF file
fprintf('Loading MFF file...\n');
EEG = pop_mffimport('path/to/your/file.mff');

%% 2. Auto-select trial events
fprintf('Auto-selecting trial events...\n');
selectedEvents = autoSelectTrialEvents(EEG, ...
    'Conditions', {'SG23', 'SG45', 'SKG1', 'KG1', 'G23', 'G45'});

%% 3. Preprocess data (optional)
fprintf('Preprocessing...\n');
EEG = pop_resample(EEG, 250);
EEG = pop_eegfiltnew(EEG, 'locutoff', 0.5);
EEG = pop_eegfiltnew(EEG, 'hicutoff', 50);
EEG = pop_reref(EEG, []);

%% 4. Epoch around selected events
fprintf('Epoching data...\n');
timeWindow = [-0.2, 0.8];  % 200ms pre to 800ms post
epochedData = epochEEGByEvents(EEG, selectedEvents, timeWindow);

%% 5. Display results
for i = 1:length(epochedData)
    ed = epochedData(i);
    fprintf('\nEvent: %s\n', ed.eventType);
    fprintf('  Epochs: %d\n', ed.numEpochs);
    fprintf('  ERP size: [%d x %d]\n', size(ed.avgERP));

    if isfield(ed, 'metrics')
        fprintf('  SNR: %.2f dB\n', ed.metrics.snr_db);
        fprintf('  P2P: %.2f µV\n', ed.metrics.peak_to_peak_uv);
    end
end

%% 6. Plot ERPs
if ~isempty(epochedData)
    figure;
    for i = 1:min(4, length(epochedData))
        subplot(2, 2, i);
        ed = epochedData(i);
        plot(ed.timeVector, ed.avgERP(1, :), 'LineWidth', 2);
        xlabel('Time (s)');
        ylabel('Amplitude (µV)');
        title(ed.eventType, 'Interpreter', 'none');
        grid on;
    end
end

%% 7. Save results
save('epoched_results.mat', 'epochedData', 'selectedEvents', 'timeWindow');
fprintf('Results saved!\n');
```

---

## Understanding Event Structure

Your events have this structure:

```
EVNT_TRSP_?y_G23_3_1_44_Session1_y?3_1___5__0_0____57
          ↑  ↑↑↑
          │  └── Condition code (G23, SG45, SKG1, etc.)
          └───── Response info
```

The condition codes you mentioned:
- **SG23, SG45** - "S" prefix conditions
- **SKG1** - "SK" prefix condition
- **KG1** - "K" prefix condition
- **G23, G45** - "G" prefix conditions

The tools automatically extract and filter by these condition codes.

---

## Condition Code Patterns

Based on your data, here are common filtering scenarios:

### Select ALL conditions
```matlab
selectedEvents = autoSelectTrialEvents(EEG);
```

### Select only "G" conditions (no prefix)
```matlab
selectedEvents = autoSelectTrialEvents(EEG, 'Conditions', {'G23', 'G45'});
```

### Select only "S" prefix conditions
```matlab
selectedEvents = autoSelectTrialEvents(EEG, 'Conditions', {'SG23', 'SG45'});
```

### Select only "K" conditions
```matlab
selectedEvents = autoSelectTrialEvents(EEG, 'Conditions', {'KG1', 'SKG1'});
```

### Select all "G" variations (G, SG, SKG, KG)
```matlab
% Include all conditions with "G23" or "G45" anywhere in name
selectedEvents = autoSelectTrialEvents(EEG, 'Conditions', {'G23', 'G45'});
% This will match: G23, SG23, KG23, SKG23, etc.
```

---

## Troubleshooting

### Problem: No events selected

**Check 1:** Verify events exist
```matlab
fprintf('Total events: %d\n', length(EEG.event));
```

**Check 2:** See available event types
```matlab
eventInfo = detectEEGEvents(EEG);
fprintf('Unique event types: %d\n', length(eventInfo.eventTypes));
eventInfo.eventTypes(1:10)  % Show first 10
```

**Check 3:** Check event field
```matlab
eventFields = getAvailableEventFields(EEG);
for i = 1:length(eventFields)
    fprintf('%s: %d unique markers\n', eventFields(i).name, eventFields(i).numUnique);
end
```

### Problem: Wrong events selected

**Solution:** Be more specific with conditions
```matlab
% Instead of this (too broad):
events = autoSelectTrialEvents(EEG, 'Conditions', {'G'});

% Do this (specific codes):
events = autoSelectTrialEvents(EEG, 'Conditions', {'G23', 'G45'});
```

### Problem: Too many event types still

**Solution:** Combine pattern AND condition filters
```matlab
% Require BOTH EVNT_TRSP pattern AND specific condition
events = filterEventsByPattern(allEvents, ...
    'Pattern', 'EVNT_TRSP', ...
    'Conditions', {'SG23'}, ...
    'MatchAny', false);  % Both must match
```

---

## Files Created

1. **autoSelectTrialEvents.m** - Main automatic selection function
2. **filterEventsByPattern.m** - General filtering utility
3. **detectEEGEvents.m** - Enhanced with filtering support
4. **example_autoEpoch.m** - Complete working example

---

## See Also

- `epochEEGByEvents.m` - Epoch data around events
- `getAvailableEventFields.m` - List event fields
- `diagnoseEvents.m` - Debug MFF import issues

---

## Questions?

If you have issues or need custom filtering logic, you can modify the functions or create custom filters:

```matlab
% Custom filter example
allEvents = detectEEGEvents(EEG).eventTypes;
customFilter = cellfun(@(x) contains(x, 'TRSP') && contains(x, 'G'), allEvents);
selectedEvents = allEvents(customFilter);
```
