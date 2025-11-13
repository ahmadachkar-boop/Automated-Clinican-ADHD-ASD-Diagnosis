function [selectedEventTypes, structure, discovery] = autoSelectTrialEventsUniversal(EEG, varargin)
% AUTOSELECTTRIALEVENTSUNIVERSAL - Universal automatic event selection
%
% This function automatically detects event structure, discovers fields,
% and intelligently groups trial events by condition. Works with ANY
% dataset format with zero user configuration required.
%
% Usage:
%   selectedEvents = autoSelectTrialEventsUniversal(EEG)
%   [selectedEvents, structure, discovery] = autoSelectTrialEventsUniversal(EEG, ...)
%
% Inputs:
%   EEG - EEGLAB EEG structure with events
%
% Optional Name-Value Pairs:
%   'Conditions'   - Cell array of condition codes to include (default: all)
%   'GroupBy'      - Override auto-detected grouping fields
%   'ExcludePractice' - Exclude practice trials (default: true)
%   'Display'      - Show summary table (default: true)
%   'UseAI'        - Use AI analysis ('auto', 'always', 'never', default: 'auto')
%   'AIProvider'   - AI provider ('claude' or 'openai', default: 'claude')
%
% Outputs:
%   selectedEventTypes - Cell array of grouped condition labels
%   structure - Detected event structure information
%   discovery - Discovered field information
%
% Examples:
%   % Basic usage (AI auto-enabled for low confidence)
%   selectedEvents = autoSelectTrialEventsUniversal(EEG);
%
%   % Always use AI
%   selectedEvents = autoSelectTrialEventsUniversal(EEG, 'UseAI', 'always');
%
%   % Never use AI (heuristics only)
%   selectedEvents = autoSelectTrialEventsUniversal(EEG, 'UseAI', 'never');
%
%   % Use OpenAI instead of Claude
%   selectedEvents = autoSelectTrialEventsUniversal(EEG, 'AIProvider', 'openai');

    % Parse inputs
    p = inputParser;
    addRequired(p, 'EEG', @isstruct);
    addParameter(p, 'Conditions', {}, @(x) iscellstr(x) || isstring(x) || isempty(x));
    addParameter(p, 'GroupBy', {}, @(x) iscellstr(x) || isempty(x));
    addParameter(p, 'ExcludePractice', true, @islogical);
    addParameter(p, 'Display', true, @islogical);
    addParameter(p, 'UseAI', 'auto', @ischar);
    addParameter(p, 'AIProvider', 'claude', @ischar);
    parse(p, EEG, varargin{:});

    conditions = p.Results.Conditions;
    groupByOverride = p.Results.GroupBy;
    excludePractice = p.Results.ExcludePractice;
    displayResults = p.Results.Display;
    useAI = p.Results.UseAI;
    aiProvider = p.Results.AIProvider;

    fprintf('\n========================================\n');
    fprintf('UNIVERSAL AUTO-EVENT SELECTION\n');
    fprintf('========================================\n\n');

    %% PHASE 1: Auto-detect event structure
    structure = detectEventStructure(EEG);

    if strcmp(structure.format, 'unknown') || structure.confidence < 0.3
        warning('Could not confidently detect event structure. Trying bracket format...');
        structure.format = 'bracket';
        structure.eventPattern = 'EVNT_TRSP';  % Fallback for your data
    end

    %% PHASE 2: Discover and analyze fields (with optional AI)
    discovery = discoverEventFields(EEG, structure, 'UseAI', useAI, 'AIProvider', aiProvider);

    if isempty(discovery.groupingFields)
        warning('No grouping fields auto-detected. Events may not have structured metadata.');
        % Fallback: group by raw event type
        structure.format = 'simple';
    end

    % Override grouping fields if specified
    if ~isempty(groupByOverride)
        fprintf('Note: Overriding auto-detected grouping fields\n');
        fprintf('  Auto-detected: %s\n', strjoin(discovery.groupingFields, ', '));
        fprintf('  User override: %s\n', strjoin(groupByOverride, ', '));
        groupByFields = groupByOverride;
        % Update discovery structure so override persists to epoching stage
        discovery.groupingFields = groupByFields;
    else
        groupByFields = discovery.groupingFields;
    end

    fprintf('\n========================================\n');
    fprintf('PARSING AND GROUPING EVENTS\n');
    fprintf('========================================\n');
    fprintf('Format: %s\n', structure.format);
    fprintf('Grouping by: %s\n', strjoin(groupByFields, ', '));
    fprintf('Note: Grouping fields sorted alphabetically for consistency\n');
    if excludePractice
        fprintf('Excluding practice: yes\n');
    end
    fprintf('----------------------------------------\n\n');

    %% PHASE 3: Parse all events and extract condition labels
    fprintf('Step 1: Parsing events...\n');

    conditionLabels = {};
    originalEventTypes = {};
    eventIndices = [];
    skippedGeneric = 0;
    skippedEmpty = 0;
    skippedPattern = 0;

    for i = 1:length(EEG.event)
        evt = EEG.event(i);

        if ~isfield(evt, 'type')
            continue;
        end

        eventType = char(evt.type);

        % Check if event matches pattern (if one was detected)
        if ~isempty(structure.eventPattern)
            if ~contains(eventType, structure.eventPattern, 'IgnoreCase', true)
                skippedPattern = skippedPattern + 1;
                continue;
            end
        end

        % Parse the event to get condition label
        condLabel = parseEventUniversal(evt, structure, discovery, groupByFields);

        % Skip empty labels
        if isempty(condLabel)
            skippedEmpty = skippedEmpty + 1;
            continue;
        end

        % Skip events with generic labels (events without proper condition info)
        % Generic labels are single-word labels that match common event types
        genericLabels = {'STIM', 'EVNT', 'TRIG', 'TRIGGER', 'STIMULUS', 'EVENT', 'DIN', 'RESP', 'RESPONSE'};
        isGeneric = false;
        for g = 1:length(genericLabels)
            if strcmpi(condLabel, genericLabels{g})
                isGeneric = true;
                break;
            end
        end

        if isGeneric
            skippedGeneric = skippedGeneric + 1;
            continue;
        end

        % Valid condition label - add it
        conditionLabels{end+1} = condLabel;
        originalEventTypes{end+1} = condLabel;  % Store parsed label, not raw event.type
        eventIndices(end+1) = i;
    end

    fprintf('  ✓ Parsed %d matching events\n', length(conditionLabels));
    if skippedPattern > 0
        fprintf('  ℹ Skipped %d events (pattern mismatch)\n', skippedPattern);
    end
    if skippedGeneric > 0
        fprintf('  ℹ Skipped %d events (generic labels without condition info)\n', skippedGeneric);
    end
    if skippedEmpty > 0
        fprintf('  ℹ Skipped %d events (no parseable condition info)\n', skippedEmpty);
    end

    if isempty(conditionLabels)
        error('No events could be parsed! Check your data or try manual configuration.');
    end

    % Show examples of parsed event names for verification
    fprintf('  Example event names (first 5 unique):\n');
    uniqueExamples = unique(originalEventTypes, 'stable');
    numExamples = min(5, length(uniqueExamples));
    for i = 1:numExamples
        fprintf('    - %s\n', uniqueExamples{i});
    end

    %% PHASE 4: Exclude practice trials
    if excludePractice && ~isempty(discovery.practicePatterns)
        fprintf('\nStep 2: Excluding practice trials...\n');
        fprintf('  Practice patterns to exclude: %s\n', strjoin(discovery.practicePatterns, ', '));

        keepMask = true(length(originalEventTypes), 1);
        excludedCount = 0;

        for i = 1:length(originalEventTypes)
            for p = 1:length(discovery.practicePatterns)
                if contains(originalEventTypes{i}, discovery.practicePatterns{p}, 'IgnoreCase', true)
                    keepMask(i) = false;
                    excludedCount = excludedCount + 1;

                    % Log first 10 exclusions for visibility
                    if excludedCount <= 10
                        fprintf('    [PRACTICE] Excluding event "%s" (matches pattern: "%s")\n', ...
                            conditionLabels{i}, discovery.practicePatterns{p});
                    end
                    break;
                end
            end
        end

        beforeCount = length(conditionLabels);
        conditionLabels = conditionLabels(keepMask);
        originalEventTypes = originalEventTypes(keepMask);
        eventIndices = eventIndices(keepMask);
        afterCount = length(conditionLabels);

        if excludedCount > 10
            fprintf('    ... and %d more practice trials\n', excludedCount - 10);
        end
        fprintf('  ✓ Excluded %d practice trials (%d remaining)\n', ...
            beforeCount - afterCount, afterCount);
    else
        fprintf('\nStep 2: Skipping practice exclusion\n');
    end

    %% PHASE 5: Get unique conditions
    fprintf('\nStep 3: Identifying unique conditions...\n');
    uniqueConditions = unique(conditionLabels);
    fprintf('  ✓ Found %d unique condition groups\n', length(uniqueConditions));

    %% PHASE 6: Apply AI condition recommendations (if available)
    if isfield(discovery, 'aiAnalysis') && isfield(discovery.aiAnalysis, 'condition_recommendations')
        fprintf('\nStep 4: Applying AI condition recommendations...\n');
        recommendations = discovery.aiAnalysis.condition_recommendations;

        % Get include/exclude lists
        includeConditions = {};
        excludeConditions = {};

        if isfield(recommendations, 'include') && ~isempty(recommendations.include)
            includeConditions = recommendations.include;
            if ~iscell(includeConditions)
                includeConditions = {includeConditions};
            end
            fprintf('  AI recommends INCLUDING: %s\n', strjoin(includeConditions, ', '));
        end

        if isfield(recommendations, 'exclude') && ~isempty(recommendations.exclude)
            excludeConditions = recommendations.exclude;
            if ~iscell(excludeConditions)
                excludeConditions = {excludeConditions};
            end
            fprintf('  AI recommends EXCLUDING: %s\n', strjoin(excludeConditions, ', '));
        end

        % Apply filtering
        if ~isempty(includeConditions) || ~isempty(excludeConditions)
            keepMask = true(length(conditionLabels), 1);
            excludedByAI = 0;
            keptByAI = 0;

            for i = 1:length(conditionLabels)
                condLabel = conditionLabels{i};
                shouldKeep = true;

                % Check exclude list first (takes priority)
                if ~isempty(excludeConditions)
                    for e = 1:length(excludeConditions)
                        if contains(condLabel, excludeConditions{e}, 'IgnoreCase', true)
                            shouldKeep = false;
                            excludedByAI = excludedByAI + 1;
                            fprintf('    [EXCLUDE] Event "%s" matches AI exclusion: "%s"\n', ...
                                condLabel, excludeConditions{e});
                            break;
                        end
                    end
                end

                % If not excluded and include list exists, must match include list
                if shouldKeep && ~isempty(includeConditions)
                    matchesInclude = false;
                    for inc = 1:length(includeConditions)
                        if contains(condLabel, includeConditions{inc}, 'IgnoreCase', true)
                            matchesInclude = true;
                            keptByAI = keptByAI + 1;
                            fprintf('    [INCLUDE] Event "%s" matches AI inclusion: "%s"\n', ...
                                condLabel, includeConditions{inc});
                            break;
                        end
                    end
                    shouldKeep = matchesInclude;

                    if ~matchesInclude
                        fprintf('    [EXCLUDE] Event "%s" does not match any AI inclusion criteria\n', ...
                            condLabel);
                    end
                end

                keepMask(i) = shouldKeep;
            end

            beforeCount = length(conditionLabels);
            conditionLabels = conditionLabels(keepMask);
            originalEventTypes = originalEventTypes(keepMask);
            eventIndices = eventIndices(keepMask);
            afterCount = length(conditionLabels);

            uniqueConditions = unique(conditionLabels);

            fprintf('  ✓ AI filtering: excluded %d, kept %d events (%d total remaining)\n', ...
                excludedByAI, keptByAI, afterCount);
        else
            fprintf('  ℹ No AI include/exclude criteria specified\n');
        end

    %% PHASE 6b: Filter by user-specified conditions (if no AI filtering was applied)
    elseif ~isempty(conditions)
        fprintf('\nStep 4: Filtering by user-specified conditions...\n');
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

        fprintf('  ✓ Kept %d events in %d condition groups\n', ...
            afterCount, length(uniqueConditions));
    else
        fprintf('\nStep 4: Using all detected conditions\n');
    end

    %% PHASE 7: Count trials per condition
    fprintf('\nStep 5: Counting trials per condition...\n');
    conditionCounts = zeros(length(uniqueConditions), 1);
    for i = 1:length(uniqueConditions)
        conditionCounts(i) = sum(strcmp(conditionLabels, uniqueConditions{i}));
    end

    % Return the unique condition labels
    selectedEventTypes = uniqueConditions;

    % Create mapping from condition labels to original event types
    % This preserves the original event names for display purposes
    originalEventTypeMap = containers.Map();
    for i = 1:length(uniqueConditions)
        % Find first occurrence of this condition label
        idx = find(strcmp(conditionLabels, uniqueConditions{i}), 1, 'first');
        if ~isempty(idx)
            originalEventTypeMap(uniqueConditions{i}) = originalEventTypes{idx};
        end
    end

    % Store mapping in discovery structure for later use
    discovery.originalEventTypeMap = originalEventTypeMap;

    %% Display summary
    fprintf('\n========================================\n');
    fprintf('SELECTION SUMMARY\n');
    fprintf('========================================\n');
    fprintf('Total events in file:     %d\n', length(EEG.event));
    fprintf('Matching events:          %d\n', length(conditionLabels));
    fprintf('Unique condition groups:  %d\n', length(uniqueConditions));

    % Show filtering pipeline
    if excludePractice && ~isempty(discovery.practicePatterns)
        fprintf('\nFiltering Pipeline:\n');
        fprintf('  ✓ Practice trials excluded: %d patterns used\n', length(discovery.practicePatterns));
    end

    if isfield(discovery, 'aiAnalysis') && isfield(discovery.aiAnalysis, 'condition_recommendations')
        fprintf('  ✓ AI condition filtering applied\n');
        if isfield(discovery.aiAnalysis.condition_recommendations, 'include') && ...
           ~isempty(discovery.aiAnalysis.condition_recommendations.include)
            fprintf('    Include list: %d criteria\n', length(discovery.aiAnalysis.condition_recommendations.include));
        end
        if isfield(discovery.aiAnalysis.condition_recommendations, 'exclude') && ...
           ~isempty(discovery.aiAnalysis.condition_recommendations.exclude)
            fprintf('    Exclude list: %d criteria\n', length(discovery.aiAnalysis.condition_recommendations.exclude));
        end
    end

    if isfield(discovery, 'usedAI') && discovery.usedAI
        fprintf('  ✓ AI-powered event analysis enabled\n');
    end

    fprintf('========================================\n\n');

    % Display detailed table
    if displayResults && ~isempty(selectedEventTypes)
        fprintf('CONDITION GROUPS:\n');
        fprintf('%-40s %10s\n', 'Condition', 'Trials');
        fprintf('%s\n', repmat('-', 1, 55));

        % Sort by count (descending)
        [sortedCounts, sortIdx] = sort(conditionCounts, 'descend');
        sortedConditions = selectedEventTypes(sortIdx);

        totalTrials = sum(sortedCounts);
        avgTrials = mean(sortedCounts);

        for i = 1:length(sortedConditions)
            fprintf('%-40s %10d\n', sortedConditions{i}, sortedCounts(i));
        end

        fprintf('%s\n', repmat('-', 1, 55));
        fprintf('%-40s %10d\n', 'TOTAL', totalTrials);
        fprintf('%-40s %10.1f\n', 'AVERAGE per condition', avgTrials);
        fprintf('\n');

        % Show warnings
        lowCountThreshold = 10;
        lowCountConditions = sum(sortedCounts < lowCountThreshold);
        if lowCountConditions > 0
            fprintf('⚠ WARNING: %d condition(s) have fewer than %d trials\n', ...
                lowCountConditions, lowCountThreshold);
            fprintf('  Consider using broader grouping (fewer fields)\n\n');
        end

        % Show quality metrics
        fprintf('Quality Metrics:\n');
        fprintf('  Format detection confidence: %.0f%%\n', structure.confidence * 100);
        fprintf('  Fields discovered: %d\n', length(discovery.fields));
        fprintf('  Grouping fields used: %d\n', length(groupByFields));
        fprintf('  Average trials per condition: %.1f\n', avgTrials);
        fprintf('  Min trials: %d | Max trials: %d\n', min(sortedCounts), max(sortedCounts));
        fprintf('\n');
    end
end
