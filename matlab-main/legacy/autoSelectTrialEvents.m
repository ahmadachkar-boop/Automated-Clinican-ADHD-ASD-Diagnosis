function selectedEventTypes = autoSelectTrialEvents(EEG, varargin)
% AUTOSELECTTRIALEVENTS Automatically filter trial events by condition codes
%
% This function is specifically designed to handle MFF files with complex
% event structures like EVNT_TRSP events containing condition codes.
%
% Usage:
%   selectedEventTypes = autoSelectTrialEvents(EEG)
%   selectedEventTypes = autoSelectTrialEvents(EEG, 'Name', Value, ...)
%
% Inputs:
%   EEG            - EEGLAB EEG structure with events
%
% Optional Name-Value Pairs:
%   'Pattern'      - Pattern to match in event types (default: 'EVNT_TRSP')
%   'Conditions'   - Cell array of condition codes to include
%                    (default: auto-detect all conditions)
%                    Example: {'SG23', 'SG45', 'SKG1', 'KG1', 'G23', 'G45'}
%   'FieldName'    - Event field to use (default: auto-detect from 'type', 'label', 'code')
%   'Display'      - Show summary table (default: true)
%
% Outputs:
%   selectedEventTypes - Cell array of filtered event type names
%
% Examples:
%   % Auto-select all EVNT_TRSP events
%   events = autoSelectTrialEvents(EEG);
%
%   % Select only specific conditions
%   events = autoSelectTrialEvents(EEG, 'Conditions', {'SKG1', 'KG1', 'SG23', 'SG45'});
%
%   % Select all events with 'G' prefix conditions
%   events = autoSelectTrialEvents(EEG, 'Pattern', 'EVNT_TRSP', 'Conditions', {'G23', 'G45'});

% Parse inputs
p = inputParser;
addRequired(p, 'EEG', @isstruct);
addParameter(p, 'Pattern', 'EVNT_TRSP', @(x) ischar(x) || iscellstr(x) || isstring(x));
addParameter(p, 'Conditions', {}, @(x) iscellstr(x) || isstring(x) || isempty(x));
addParameter(p, 'FieldName', '', @(x) ischar(x) || isstring(x));
addParameter(p, 'Display', true, @islogical);
parse(p, EEG, varargin{:});

pattern = p.Results.Pattern;
conditions = p.Results.Conditions;
fieldName = p.Results.FieldName;
displayResults = p.Results.Display;

fprintf('\n========================================\n');
fprintf('AUTO-SELECTING TRIAL EVENTS\n');
fprintf('========================================\n\n');

% Step 1: Determine which event field to use
if isempty(fieldName)
    fprintf('Step 1: Auto-detecting event field...\n');
    [~, eventFieldInfo] = getAvailableEventFields(EEG);
    if isempty(eventFieldInfo)
        error('No event fields found in EEG data');
    end

    % Use the field with the most unique markers
    [~, maxIdx] = max([eventFieldInfo.numUnique]);
    fieldName = eventFieldInfo(maxIdx).name;
    fprintf('  ✓ Using field: "%s" (%d unique markers)\n\n', fieldName, eventFieldInfo(maxIdx).numUnique);
else
    fprintf('Step 1: Using specified field "%s"\n\n', fieldName);
end

% Step 2: Extract all unique event types from the selected field
fprintf('Step 2: Extracting event types from "%s" field...\n', fieldName);
allEventTypes = {};
for i = 1:length(EEG.event)
    evt = EEG.event(i);

    % Get value from the specified field
    if isfield(evt, fieldName)
        eventValue = evt.(fieldName);
    else
        continue;
    end

    % Convert to string
    if isnumeric(eventValue)
        eventStr = num2str(eventValue);
    elseif iscell(eventValue)
        eventStr = eventValue{1};
    else
        eventStr = char(eventValue);
    end

    allEventTypes{end+1} = strtrim(eventStr);
end

uniqueEventTypes = unique(allEventTypes);
fprintf('  ✓ Found %d unique event types (out of %d total events)\n\n', ...
    length(uniqueEventTypes), length(EEG.event));

% Step 3: Filter by pattern
fprintf('Step 3: Filtering by pattern "%s"...\n', pattern);
patternMask = false(length(uniqueEventTypes), 1);
for i = 1:length(uniqueEventTypes)
    if contains(uniqueEventTypes{i}, pattern, 'IgnoreCase', true)
        patternMask(i) = true;
    end
end
patternFiltered = uniqueEventTypes(patternMask);
fprintf('  ✓ Matched %d event types containing "%s"\n\n', length(patternFiltered), pattern);

% Step 4: Extract condition codes from remaining events
fprintf('Step 4: Extracting condition codes...\n');
conditionCodes = {};
for i = 1:length(patternFiltered)
    eventType = patternFiltered{i};

    % Try to extract condition code
    % Pattern: EVNT_TRSP_?y_CONDITION_...
    % The condition is typically after the 3rd underscore
    parts = strsplit(eventType, '_');
    if length(parts) >= 4
        % The condition is usually the 4th part
        cond = parts{4};
        conditionCodes{end+1} = cond;
    end
end

uniqueConditions = unique(conditionCodes);
fprintf('  ✓ Found %d unique condition codes: %s\n\n', ...
    length(uniqueConditions), strjoin(uniqueConditions, ', '));

% Step 5: Filter by specified conditions (if any)
if isempty(conditions)
    % Use all found conditions
    selectedEventTypes = patternFiltered;
    fprintf('Step 5: Using all %d conditions (no filter specified)\n\n', length(uniqueConditions));
else
    fprintf('Step 5: Filtering by specified conditions...\n');
    fprintf('  Target conditions: %s\n', strjoin(conditions, ', '));

    conditionMask = false(length(patternFiltered), 1);
    for i = 1:length(patternFiltered)
        eventType = patternFiltered{i};
        for j = 1:length(conditions)
            if contains(eventType, conditions{j}, 'IgnoreCase', true)
                conditionMask(i) = true;
                break;
            end
        end
    end

    selectedEventTypes = patternFiltered(conditionMask);
    fprintf('  ✓ Matched %d event types with specified conditions\n\n', length(selectedEventTypes));
end

% Step 6: Count occurrences of each selected event type
fprintf('Step 6: Counting event occurrences...\n');
eventCounts = zeros(length(selectedEventTypes), 1);
for i = 1:length(selectedEventTypes)
    eventCounts(i) = sum(strcmp(allEventTypes, selectedEventTypes{i}));
end

% Display summary
fprintf('\n========================================\n');
fprintf('SELECTION SUMMARY\n');
fprintf('========================================\n');
fprintf('Total events in file:     %d\n', length(EEG.event));
fprintf('Unique event types:       %d\n', length(uniqueEventTypes));
fprintf('After pattern filter:     %d\n', length(patternFiltered));
fprintf('Final selected types:     %d\n', length(selectedEventTypes));
fprintf('Total selected events:    %d\n', sum(eventCounts));
fprintf('========================================\n\n');

% Display detailed table
if displayResults && ~isempty(selectedEventTypes)
    fprintf('SELECTED EVENT TYPES:\n');
    fprintf('%-60s %10s\n', 'Event Type', 'Count');
    fprintf('%s\n', repmat('-', 1, 72));

    % Sort by count (descending)
    [sortedCounts, sortIdx] = sort(eventCounts, 'descend');
    sortedTypes = selectedEventTypes(sortIdx);

    for i = 1:length(sortedTypes)
        % Extract condition code for display
        parts = strsplit(sortedTypes{i}, '_');
        if length(parts) >= 4
            cond = parts{4};
            fprintf('%-60s %10d  [%s]\n', sortedTypes{i}, sortedCounts(i), cond);
        else
            fprintf('%-60s %10d\n', sortedTypes{i}, sortedCounts(i));
        end
    end
    fprintf('\n');
end

end
