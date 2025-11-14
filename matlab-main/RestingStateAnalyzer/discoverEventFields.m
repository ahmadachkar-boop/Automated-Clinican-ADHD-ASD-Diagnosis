function discovery = discoverEventFields(EEG, structure, varargin)
% DISCOVEREVENTFIELDS - Automatically discover and analyze event fields
%
% This function scans all events to find available fields, their values,
% and automatically determines which fields are good for grouping conditions
% vs which are trial-specific metadata.
%
% Inputs:
%   EEG - EEGLAB EEG structure
%   structure - Output from detectEventStructure()
%
% Optional Name-Value Pairs:
%   'UseAI' - Use AI for intelligent analysis ('auto', 'always', 'never')
%             'auto' = use AI only if heuristic confidence < 0.7 (default)
%             'always' = always use AI
%             'never' = never use AI (heuristics only)
%   'AIProvider' - AI provider to use ('claude' or 'openai', default: 'claude')
%
% Outputs:
%   discovery - Struct containing:
%     .fields - Cell array of field names
%     .fieldStats - Statistics for each field
%     .groupingFields - Recommended fields for grouping
%     .excludeFields - Fields to exclude (trial-specific)
%     .practicePatterns - Auto-detected practice trial patterns
%     .valueMappings - Auto-detected value mappings (e.g., y->word)
%     .confidence - Confidence in classification (0-1)
%     .usedAI - Boolean indicating if AI was used

    % Parse optional inputs
    p = inputParser;
    addParameter(p, 'UseAI', 'auto', @ischar);
    addParameter(p, 'AIProvider', 'claude', @ischar);
    parse(p, varargin{:});

    useAIMode = p.Results.UseAI;
    aiProvider = p.Results.AIProvider;

    discovery = struct();
    discovery.fields = {};
    discovery.fieldStats = struct();
    discovery.groupingFields = {};
    discovery.excludeFields = {};
    discovery.practicePatterns = {};
    discovery.valueMappings = struct();

    fprintf('=== AUTO-DISCOVERING EVENT FIELDS ===\n');
    fprintf('Analyzing %d events...\n', length(EEG.event));

    % Sample events for analysis (use more if dataset is small)
    if length(EEG.event) <= 500
        sampleSize = length(EEG.event);
    else
        sampleSize = min(500, length(EEG.event));
    end
    sampleIndices = round(linspace(1, length(EEG.event), sampleSize));

    % Parse events based on detected format
    allFieldData = struct();
    eventSamples = {};  % Collect actual event structures for AI

    for i = sampleIndices
        evt = EEG.event(i);

        if ~isfield(evt, 'type')
            continue;
        end

        % Collect first 30 events as samples for AI (diverse sample)
        if length(eventSamples) < 30
            eventSamples{end+1} = evt;
        end

        eventType = char(evt.type);

        % Extract fields based on format
        switch structure.format
            case 'bracket'
                fields = parseBracketFields(eventType);

            case 'fields'
                fields = parseStructFields(evt);

            case 'delimiter'
                fields = parseDelimiterFields(eventType);

            case 'simple'
                % Simple codes don't have subfields
                fields = struct('type', eventType);

            otherwise
                % Try bracket format as fallback
                fields = parseBracketFields(eventType);
                if isempty(fieldnames(fields))
                    fields = parseStructFields(evt);
                end
        end

        % Store values for each field
        fieldNames = fieldnames(fields);
        for f = 1:length(fieldNames)
            fieldName = fieldNames{f};
            fieldValue = fields.(fieldName);

            if ~isfield(allFieldData, fieldName)
                allFieldData.(fieldName) = {};
            end

            allFieldData.(fieldName){end+1} = fieldValue;
        end
    end

    % Analyze each field
    fprintf('\nField Analysis:\n');
    fprintf('%-20s %12s %12s %20s\n', 'Field', 'Unique Vals', 'Cardinality', 'Classification');
    fprintf('%s\n', repmat('-', 1, 70));

    fieldNames = fieldnames(allFieldData);
    discovery.fields = fieldNames;

    for f = 1:length(fieldNames)
        fieldName = fieldNames{f};
        values = allFieldData.(fieldName);

        % Compute statistics
        uniqueValues = unique(values);
        numUnique = length(uniqueValues);
        cardinality = numUnique / length(values);  % Ratio of unique to total

        % Store stats
        discovery.fieldStats.(fieldName) = struct();
        discovery.fieldStats.(fieldName).uniqueValues = uniqueValues;
        discovery.fieldStats.(fieldName).numUnique = numUnique;
        discovery.fieldStats.(fieldName).cardinality = cardinality;
        discovery.fieldStats.(fieldName).sampleValues = values(1:min(5, length(values)));

        % Classify field
        % Low cardinality (< 0.3) = good for grouping
        % High cardinality (> 0.7) = trial-specific, exclude
        % Medium cardinality = optional grouping

        if cardinality < 0.3 && numUnique >= 2 && numUnique <= 20
            classification = '✓ CONDITION';
            discovery.groupingFields{end+1} = fieldName;
        elseif cardinality > 0.7 || numUnique > 50
            classification = '✗ TRIAL-SPECIFIC';
            discovery.excludeFields{end+1} = fieldName;
        else
            classification = '? OPTIONAL';
        end

        % Special handling for common field names
        fieldLower = lower(fieldName);

        % Exclude EEG metadata fields (never use for grouping)
        metadataPatterns = {'description', 'classid', 'label', 'sourcedevice', 'name', ...
                           'tracktype', 'begintime', 'endtime', 'relativebegintime', ...
                           'age', 'exp', 'hand', 'sex', 'subj', 'backup', 'urevent'};
        isMetadata = false;
        for mp = 1:length(metadataPatterns)
            if contains(fieldLower, metadataPatterns{mp})
                isMetadata = true;
                break;
            end
        end

        if isMetadata
            classification = '✗ METADATA';
            if ~ismember(fieldName, discovery.excludeFields)
                discovery.excludeFields{end+1} = fieldName;
            end
            % Remove from grouping if it was added
            discovery.groupingFields = discovery.groupingFields(~strcmp(discovery.groupingFields, fieldName));
            fprintf('%-20s %12d %11.2f%% %20s\n', ...
                fieldName, numUnique, cardinality * 100, classification);
            continue;
        end

        % Trial-specific patterns
        if contains(fieldLower, {'trial', 'trl', 'obs', 'rep', 'response', 'rt', 'time', 'cel', 'latency'})
            classification = '✗ TRIAL-SPECIFIC';
            if ~ismember(fieldName, discovery.excludeFields)
                discovery.excludeFields{end+1} = fieldName;
            end
            % Remove from grouping if it was added
            discovery.groupingFields = discovery.groupingFields(~strcmp(discovery.groupingFields, fieldName));
        end

        % Condition-specific patterns (but exclude 'code' without mffkey prefix - that's EEG metadata)
        if contains(fieldLower, {'cond', 'condition', 'stim', 'stimulus', 'task'}) && cardinality < 0.5
            if ~ismember(fieldName, discovery.groupingFields) && numUnique >= 2
                classification = '✓ CONDITION';
                discovery.groupingFields{end+1} = fieldName;
            end
        end

        fprintf('%-20s %12d %11.2f%% %20s\n', ...
            fieldName, numUnique, cardinality * 100, classification);

        % Detect practice trial patterns
        if contains(fieldLower, {'practice', 'prac', 'training', 'train'})
            for v = 1:length(uniqueValues)
                val = uniqueValues{v};
                if ~isempty(val) && ~strcmp(val, '?') && ~strcmp(val, '0')
                    discovery.practicePatterns{end+1} = val;
                end
            end
        end

        % Detect common value mappings
        if ismember(fieldName, discovery.groupingFields)
            discovery.valueMappings.(fieldName) = detectValueMappings(uniqueValues, fieldName);
        end
    end

    fprintf('%s\n\n', repmat('-', 1, 70));

    % Prioritize grouping fields (put most important first)
    discovery.groupingFields = prioritizeGroupingFields(discovery.groupingFields, discovery.fieldStats);

    % Auto-detect additional practice patterns
    % More specific patterns to avoid false positives
    discovery.practicePatterns = [discovery.practicePatterns, ...
        {'Prac', 'PracSlow', 'Practice', 'Training', 'practice', 'training', ...
         'a_Practice', 's_Practice', 'w_Practice', 's1_Practice', ...
         '1_Practice', '2_Practice', '3_Practice'}];
    discovery.practicePatterns = unique(discovery.practicePatterns);

    % Calculate heuristic confidence
    heuristicConfidence = calculateHeuristicConfidence(discovery);
    discovery.confidence = heuristicConfidence;
    discovery.usedAI = false;

    % Display heuristic recommendations
    fprintf('Heuristic Recommendations:\n');
    fprintf('  Group by: %s\n', strjoin(discovery.groupingFields, ', '));
    fprintf('  Exclude: %s\n', strjoin(discovery.excludeFields, ', '));
    if ~isempty(discovery.practicePatterns)
        fprintf('  Practice patterns: %s\n', strjoin(discovery.practicePatterns(1:min(5, end)), ', '));
    end
    fprintf('  Confidence: %.0f%%\n', heuristicConfidence * 100);

    % Decide whether to use AI
    useAI = false;
    if strcmp(useAIMode, 'always')
        useAI = true;
        fprintf('  → AI analysis requested (mode: always)\n');
    elseif strcmp(useAIMode, 'auto')
        if heuristicConfidence < 0.7
            useAI = true;
            fprintf('  → Low confidence detected. Using AI analysis...\n');
        elseif length(discovery.groupingFields) > 3
            useAI = true;
            fprintf('  → Many grouping fields detected. Using AI to refine...\n');
        end
    end

    fprintf('======================================\n\n');

    % AI Integration
    if useAI
        try
            % Call AI analysis with event samples for enhanced context
            aiAnalysis = callAIAnalysis(discovery.fieldStats, structure, aiProvider, eventSamples);

            % Merge AI recommendations with heuristic results
            fprintf('=== AI ANALYSIS RESULTS ===\n');

            % Show experimental paradigm identification
            if isfield(aiAnalysis, 'experimental_paradigm')
                fprintf('\nExperimental Paradigm Identified:\n');
                fprintf('  Type: %s\n', aiAnalysis.experimental_paradigm.type);
                fprintf('  Description: %s\n', aiAnalysis.experimental_paradigm.description);
                if isfield(aiAnalysis.experimental_paradigm, 'key_manipulations')
                    fprintf('  Key manipulations: %s\n', strjoin(aiAnalysis.experimental_paradigm.key_manipulations, ', '));
                end
            end

            % Show practice trial patterns
            if isfield(aiAnalysis, 'practice_trial_patterns') && ~isempty(aiAnalysis.practice_trial_patterns)
                fprintf('\nPractice Trials Detected by AI:\n');

                patterns = aiAnalysis.practice_trial_patterns;
                numAdded = 0;

                for i = 1:length(patterns)
                    try
                        ptp = patterns(i);

                        % Validate and extract pattern string
                        if ~isfield(ptp, 'pattern')
                            continue;
                        end

                        patternStr = char(ptp.pattern);
                        patternStr = strtrim(patternStr);

                        % Skip invalid patterns
                        if isempty(patternStr) || strcmp(patternStr, '""') || strcmp(patternStr, '''''')
                            continue;
                        end

                        % Extract field and reasoning
                        fieldStr = '';
                        if isfield(ptp, 'field')
                            fieldStr = char(ptp.field);
                        end

                        reasoningStr = '';
                        if isfield(ptp, 'reasoning')
                            reasoningStr = char(ptp.reasoning);
                            if length(reasoningStr) > 80
                                reasoningStr = [reasoningStr(1:77) '...'];
                            end
                        end

                        fprintf('  Pattern "%s" in field "%s": %s\n', ...
                            patternStr, fieldStr, reasoningStr);

                        % Add valid pattern
                        discovery.practicePatterns{end+1} = patternStr;
                        numAdded = numAdded + 1;

                    catch ME
                        warning('Error processing practice pattern %d: %s', i, ME.message);
                        continue;
                    end
                end

                discovery.practicePatterns = unique(discovery.practicePatterns);
                fprintf('  → %d practice patterns added to exclusion list\n', numAdded);
            end

            % Show condition recommendations
            if isfield(aiAnalysis, 'condition_recommendations')
                fprintf('\nCondition Recommendations:\n');
                if isfield(aiAnalysis.condition_recommendations, 'include')
                    fprintf('  Include: %s\n', strjoin(aiAnalysis.condition_recommendations.include, ', '));
                end
                if isfield(aiAnalysis.condition_recommendations, 'exclude')
                    fprintf('  Exclude: %s\n', strjoin(aiAnalysis.condition_recommendations.exclude, ', '));
                end
                if isfield(aiAnalysis.condition_recommendations, 'primary_comparisons')
                    fprintf('  Recommended Comparisons:\n');
                    for i = 1:length(aiAnalysis.condition_recommendations.primary_comparisons)
                        comp = aiAnalysis.condition_recommendations.primary_comparisons(i);
                        fprintf('    %s vs %s (ERP: %s)\n', ...
                            comp.condition_a, comp.condition_b, comp.erp_component);
                    end
                end
            end

            fprintf('\nField Classification:\n');
            fprintf('  Heuristic grouping: %s\n', strjoin(discovery.groupingFields, ', '));
            fprintf('  AI grouping:        %s\n', strjoin(aiAnalysis.grouping_fields, ', '));

            % Decide whether to use AI recommendations
            % When mode is 'always', always use AI regardless of confidence
            % Otherwise, only use AI if confidence is higher than heuristic
            if strcmp(useAIMode, 'always')
                fprintf('  ✓ Using AI recommendations (mode: always)\n');
                discovery.groupingFields = aiAnalysis.grouping_fields;
                discovery.excludeFields = union(discovery.excludeFields, aiAnalysis.exclude_fields);
                discovery.confidence = aiAnalysis.confidence;
                discovery.usedAI = true;
                discovery.aiAnalysis = aiAnalysis;

                % Apply AI value mappings if available
                if isfield(aiAnalysis, 'value_mappings')
                    mappingFields = fieldnames(aiAnalysis.value_mappings);
                    for i = 1:length(mappingFields)
                        fieldName = mappingFields{i};
                        discovery.valueMappings.(fieldName) = aiAnalysis.value_mappings.(fieldName);
                    end
                end
            elseif aiAnalysis.confidence >= heuristicConfidence
                fprintf('✓ Using AI recommendations (higher confidence)\n');
                discovery.groupingFields = aiAnalysis.grouping_fields;
                discovery.excludeFields = union(discovery.excludeFields, aiAnalysis.exclude_fields);
                discovery.confidence = aiAnalysis.confidence;
                discovery.usedAI = true;
                discovery.aiAnalysis = aiAnalysis;

                % Apply AI value mappings if available
                if isfield(aiAnalysis, 'value_mappings')
                    mappingFields = fieldnames(aiAnalysis.value_mappings);
                    for i = 1:length(mappingFields)
                        fieldName = mappingFields{i};
                        discovery.valueMappings.(fieldName) = aiAnalysis.value_mappings.(fieldName);
                    end
                end
            else
                fprintf('ℹ AI confidence (%.0f%%) lower than heuristic (%.0f%%). Keeping heuristic results.\n', ...
                        aiAnalysis.confidence * 100, heuristicConfidence * 100);
                discovery.aiAnalysis = aiAnalysis;  % Store for reference
            end

            fprintf('======================================\n\n');

        catch ME
            warning('AI analysis failed: %s', ME.message);
            fprintf('Continuing with heuristic results.\n\n');
        end
    end

    % Final recommendations
    fprintf('=== FINAL RECOMMENDATIONS ===\n');
    fprintf('Group by: %s\n', strjoin(discovery.groupingFields, ', '));
    fprintf('Exclude: %s\n', strjoin(discovery.excludeFields, ', '));
    fprintf('Confidence: %.0f%%\n', discovery.confidence * 100);
    if discovery.usedAI
        fprintf('Source: AI-enhanced analysis (%s)\n', aiProvider);
    else
        fprintf('Source: Heuristic analysis\n');
    end
    fprintf('======================================\n\n');
end


function confidence = calculateHeuristicConfidence(discovery)
    % Calculate confidence score for heuristic classification

    % Base confidence
    confidence = 0.5;

    % Boost if we found clear grouping fields
    if ~isempty(discovery.groupingFields)
        confidence = confidence + 0.2;
    end

    % Boost if grouping fields have good cardinality (2-3 fields is ideal)
    numGrouping = length(discovery.groupingFields);
    if numGrouping >= 2 && numGrouping <= 3
        confidence = confidence + 0.2;
    elseif numGrouping > 3
        confidence = confidence - 0.1;  % Too many = less confident
    end

    % Boost if we excluded trial-specific fields
    if ~isempty(discovery.excludeFields)
        confidence = confidence + 0.1;
    end

    % Cap at 0-1
    confidence = max(0, min(1, confidence));
end


function fields = parseBracketFields(eventType)
    % Parse bracket notation: [key: value, ...]
    fields = struct();

    if contains(eventType, '[') && contains(eventType, ']')
        startIdx = strfind(eventType, '[');
        endIdx = strfind(eventType, ']');
        if ~isempty(startIdx) && ~isempty(endIdx)
            bracketContent = eventType(startIdx(1)+1:endIdx(1)-1);

            pairs = strsplit(bracketContent, ',');
            for i = 1:length(pairs)
                pair = strtrim(pairs{i});
                colonIdx = strfind(pair, ':');
                if ~isempty(colonIdx)
                    key = strtrim(pair(1:colonIdx(1)-1));
                    value = strtrim(pair(colonIdx(1)+1:end));

                    % Clean up key names
                    key = regexprep(key, '[^a-zA-Z0-9]', '');

                    if ~isempty(key)
                        fields.(key) = value;
                    end
                end
            end
        end
    end
end


function fields = parseStructFields(evt)
    % Parse EEG.event fields directly
    fields = struct();

    basicFields = {'type', 'latency', 'duration', 'urevent', 'epoch'};
    eventFields = fieldnames(evt);

    for i = 1:length(eventFields)
        fieldName = eventFields{i};
        if ~ismember(fieldName, basicFields)
            value = evt.(fieldName);
            if ischar(value) || isstring(value)
                fields.(fieldName) = char(value);
            elseif isnumeric(value)
                fields.(fieldName) = num2str(value);
            end
        end
    end
end


function fields = parseDelimiterFields(eventType)
    % Parse delimiter-separated format: prefix_field1_field2_...
    fields = struct();

    % Try underscore first
    if contains(eventType, '_')
        parts = strsplit(eventType, '_');
    elseif contains(eventType, '-')
        parts = strsplit(eventType, '-');
    else
        return;
    end

    % Create generic field names
    for i = 1:length(parts)
        fieldName = sprintf('field%d', i);
        fields.(fieldName) = parts{i};
    end
end


function mappings = detectValueMappings(uniqueValues, fieldName)
    % Auto-detect common value mappings
    mappings = struct();

    fieldLower = lower(fieldName);

    for i = 1:length(uniqueValues)
        val = uniqueValues{i};
        if isempty(val)
            continue;
        end

        % Common boolean mappings
        if strcmp(val, 'y') || strcmp(val, 'Y')
            if contains(fieldLower, {'word', 'code', 'lex'})
                mappings.y = 'word';
            elseif contains(fieldLower, {'verb'})
                mappings.y = 'verb';
            else
                mappings.y = 'yes';
            end
        elseif strcmp(val, 'n') || strcmp(val, 'N')
            if contains(fieldLower, {'word', 'code', 'lex'})
                mappings.n = 'nonword';
            elseif contains(fieldLower, {'verb'})
                mappings.n = 'nonverb';
            else
                mappings.n = 'no';
            end
        end

        % Numeric boolean - prefix with 'n' to make valid field names
        if strcmp(val, '1')
            mappings.n1 = 'yes';
        elseif strcmp(val, '0')
            mappings.n0 = 'no';
        end
    end
end


function prioritized = prioritizeGroupingFields(fields, stats)
    % Prioritize fields for grouping (condition fields first, then modifiers)

    if isempty(fields)
        prioritized = {};
        return;
    end

    priorities = zeros(length(fields), 1);

    for i = 1:length(fields)
        fieldName = fields{i};
        fieldLower = lower(fieldName);

        % SUPER HIGH PRIORITY: mffkey fields (experimental variables)
        isMffkey = startsWith(fieldLower, 'mffkey_');

        % Highest priority: mffkey condition fields
        if isMffkey && contains(fieldLower, {'cond', 'condition'})
            priorities(i) = 150;
        % Very high priority: mffkey code/word fields
        elseif isMffkey && contains(fieldLower, {'code', 'word', 'lex'})
            priorities(i) = 140;
        % High priority: other mffkey experimental variables
        elseif isMffkey && contains(fieldLower, {'verb', 'phon', 'sylb', 'freq', 'task'})
            priorities(i) = 130;
        % Medium-high: any other mffkey field (experimental)
        elseif isMffkey
            priorities(i) = 110;
        % Medium: non-mffkey condition fields
        elseif contains(fieldLower, {'cond', 'condition', 'stim', 'stimulus'})
            priorities(i) = 100;
        % Lower: code/word fields without mffkey prefix
        elseif contains(fieldLower, {'code', 'word', 'lex', 'status'})
            priorities(i) = 80;
        % Low: modifier fields
        elseif contains(fieldLower, {'verb', 'phon', 'sylb', 'freq'})
            priorities(i) = 70;
        % Very low: task/type fields (often metadata)
        elseif contains(fieldLower, {'task', 'type', 'category'})
            priorities(i) = 60;
        % Lowest: everything else
        else
            priorities(i) = 50;
        end

        % Bonus for low cardinality (more discriminative)
        if isfield(stats, fieldName)
            cardinality = stats.(fieldName).cardinality;
            priorities(i) = priorities(i) + (1 - cardinality) * 10;
        end
    end

    % Sort by priority (descending), then alphabetically for consistency
    % First, sort alphabetically
    [sortedFields, alphaIdx] = sort(fields);
    sortedPriorities = priorities(alphaIdx);

    % Then sort by priority (MATLAB's sort is stable, preserves alphabetical order)
    [~, priorityIdx] = sort(sortedPriorities, 'descend');
    prioritized = sortedFields(priorityIdx);

    % Get the sorted priorities for limit checking
    finalPriorities = sortedPriorities(priorityIdx);

    % Limit to top 2-3 fields by default (avoid over-fragmentation)
    % Keep top 2 if both are high priority (>120), otherwise top 3
    if length(prioritized) > 2
        if finalPriorities(1) > 120 && finalPriorities(2) > 120
            % Keep just the top 2 high-priority mffkey fields
            prioritized = prioritized(1:2);
        elseif length(prioritized) > 3
            % Otherwise limit to top 3
            prioritized = prioritized(1:3);
        end
    end
end
