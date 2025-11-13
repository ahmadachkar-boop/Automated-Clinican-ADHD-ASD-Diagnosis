function selectedEventTypes = autoSelectTrialEventsGrouped(EEG, varargin)
% AUTOSELECTTRIALEVENTS GROUPED - Intelligently group trial events by condition
%
% This function groups events by experimental condition, ignoring trial-specific
% metadata like trial numbers, response times, and observation numbers.
%
% Usage:
%   selectedEventTypes = autoSelectTrialEventsGrouped(EEG)
%   selectedEventTypes = autoSelectTrialEventsGrouped(EEG, 'Name', Value, ...)
%
% Inputs:
%   EEG            - EEGLAB EEG structure with events
%
% Optional Name-Value Pairs:
%   'Pattern'      - Pattern to match in event types (default: 'EVNT_TRSP')
%   'Conditions'   - Cell array of condition codes to include
%                    (default: auto-detect all conditions)
%                    Example: {'SG23', 'SG45', 'SKG1', 'KG1', 'G23', 'G45'}
%   'GroupBy'      - Fields to use for grouping (default: {'Cond', 'Code'})
%                    Options: 'Cond', 'Code', 'Phon', 'Verb', 'Sylb', 'TskB'
%                    Example: {'Cond', 'Code', 'Verb'} groups by condition + word/nonword + verb status
%   'ExcludePractice' - Exclude practice trials (default: true)
%   'Display'      - Show summary table (default: true)
%
% Outputs:
%   selectedEventTypes - Cell array of grouped condition labels
%
% Examples:
%   % Basic grouping by condition and word status
%   events = autoSelectTrialEventsGrouped(EEG);
%
%   % Group by condition, word status, and verb
%   events = autoSelectTrialEventsGrouped(EEG, 'GroupBy', {'Cond', 'Code', 'Verb'});
%
%   % Select only specific conditions with phonological detail
%   events = autoSelectTrialEventsGrouped(EEG, 'Conditions', {'G23', 'G45'}, ...
%                                         'GroupBy', {'Cond', 'Code', 'Phon'});

% Parse inputs
p = inputParser;
addRequired(p, 'EEG', @isstruct);
addParameter(p, 'Pattern', 'EVNT_TRSP', @(x) ischar(x) || iscellstr(x) || isstring(x));
addParameter(p, 'Conditions', {}, @(x) iscellstr(x) || isstring(x) || isempty(x));
addParameter(p, 'GroupBy', {'Cond', 'Code'}, @iscellstr);
addParameter(p, 'ExcludePractice', true, @islogical);
addParameter(p, 'Display', true, @islogical);
parse(p, EEG, varargin{:});

pattern = p.Results.Pattern;
conditions = p.Results.Conditions;
groupByFields = p.Results.GroupBy;
excludePractice = p.Results.ExcludePractice;
displayResults = p.Results.Display;

fprintf('\n========================================\n');
fprintf('AUTO-SELECTING AND GROUPING TRIAL EVENTS\n');
fprintf('========================================\n\n');

% Step 1: Extract condition labels for all events
fprintf('Step 1: Parsing event conditions...\n');
fprintf('  Grouping by: %s\n', strjoin(groupByFields, ', '));

conditionLabels = {};
originalEventTypes = {};
eventIndices = [];

for i = 1:length(EEG.event)
    evt = EEG.event(i);

    % Check if this is a matching event type
    if isfield(evt, 'type')
        eventType = char(evt.type);

        if contains(eventType, pattern, 'IgnoreCase', true)
            % Parse the condition label
            condLabel = parseEventConditions(evt, groupByFields);

            if ~isempty(condLabel)
                conditionLabels{end+1} = condLabel;
                originalEventTypes{end+1} = eventType;
                eventIndices(end+1) = i;
            end
        end
    end
end

fprintf('  ✓ Parsed %d matching events\n\n', length(conditionLabels));

% Step 2: Exclude practice trials if requested
if excludePractice
    fprintf('Step 2: Filtering out practice trials...\n');

    % Practice trial patterns to exclude
    practicePatterns = {'Prac', 'PracSlow', '_a_', '_s_', '_w_', '_s1_'};

    keepMask = true(length(originalEventTypes), 1);
    for i = 1:length(originalEventTypes)
        for p = 1:length(practicePatterns)
            if contains(originalEventTypes{i}, practicePatterns{p}, 'IgnoreCase', true)
                keepMask(i) = false;
                break;
            end
        end
    end

    beforeCount = length(conditionLabels);
    conditionLabels = conditionLabels(keepMask);
    originalEventTypes = originalEventTypes(keepMask);
    eventIndices = eventIndices(keepMask);
    afterCount = length(conditionLabels);

    fprintf('  ✓ Excluded %d practice trials (%d remaining)\n\n', ...
        beforeCount - afterCount, afterCount);
else
    fprintf('Step 2: Including all events (practice not excluded)\n\n');
end

% Step 3: Get unique condition labels
fprintf('Step 3: Identifying unique conditions...\n');
uniqueConditions = unique(conditionLabels);
fprintf('  ✓ Found %d unique condition groups\n\n', length(uniqueConditions));

% Step 4: Filter by specified conditions (if any)
if ~isempty(conditions)
    fprintf('Step 4: Filtering by specified conditions...\n');
    fprintf('  Target conditions: %s\n', strjoin(conditions, ', '));

    keepMask = false(length(conditionLabels), 1);
    for i = 1:length(conditionLabels)
        for j = 1:length(conditions)
            if contains(conditionLabels{i}, conditions{j}, 'IgnoreCase', true)
                keepMask(i) = true;
                break;
            end
        end
    end

    beforeCount = length(conditionLabels);
    conditionLabels = conditionLabels(keepMask);
    originalEventTypes = originalEventTypes(keepMask);
    eventIndices = eventIndices(keepMask);
    afterCount = length(conditionLabels);

    uniqueConditions = unique(conditionLabels);

    fprintf('  ✓ Kept %d events in %d condition groups\n\n', ...
        afterCount, length(uniqueConditions));
else
    fprintf('Step 4: Using all conditions (no filter specified)\n\n');
end

% Step 5: Count trials per condition
fprintf('Step 5: Counting trials per condition...\n');
conditionCounts = zeros(length(uniqueConditions), 1);
for i = 1:length(uniqueConditions)
    conditionCounts(i) = sum(strcmp(conditionLabels, uniqueConditions{i}));
end

% Return the unique condition labels
selectedEventTypes = uniqueConditions;

% Display summary
fprintf('\n========================================\n');
fprintf('GROUPING SUMMARY\n');
fprintf('========================================\n');
fprintf('Total events in file:     %d\n', length(EEG.event));
fprintf('Matching pattern:         %d\n', length(conditionLabels));
fprintf('Unique condition groups:  %d\n', length(uniqueConditions));
fprintf('Total grouped events:     %d\n', length(conditionLabels));
fprintf('========================================\n\n');

% Display detailed table
if displayResults && ~isempty(selectedEventTypes)
    fprintf('CONDITION GROUPS:\n');
    fprintf('%-40s %10s %15s\n', 'Condition', 'Trials', 'Avg trials/group');
    fprintf('%s\n', repmat('-', 1, 70));

    % Sort by count (descending)
    [sortedCounts, sortIdx] = sort(conditionCounts, 'descend');
    sortedConditions = selectedEventTypes(sortIdx);

    totalTrials = sum(sortedCounts);
    avgTrials = mean(sortedCounts);

    for i = 1:length(sortedConditions)
        fprintf('%-40s %10d\n', sortedConditions{i}, sortedCounts(i));
    end

    fprintf('%s\n', repmat('-', 1, 70));
    fprintf('%-40s %10d %15.1f\n', 'TOTAL', totalTrials, avgTrials);
    fprintf('\n');

    % Show warnings for low trial counts
    lowCountThreshold = 10;
    lowCountConditions = sum(sortedCounts < lowCountThreshold);
    if lowCountConditions > 0
        fprintf('⚠ WARNING: %d condition(s) have fewer than %d trials\n', ...
            lowCountConditions, lowCountThreshold);
        fprintf('  Consider using broader grouping (fewer fields in GroupBy)\n\n');
    end
end

end
