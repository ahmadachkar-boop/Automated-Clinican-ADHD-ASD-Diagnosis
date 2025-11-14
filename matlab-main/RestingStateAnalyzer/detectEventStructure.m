function structure = detectEventStructure(EEG)
% DETECTEVENTSTRUCTURE - Automatically detect how events are structured
%
% This function analyzes EEG.event to determine the format:
%   - 'bracket': Events use [key: value] notation in type string
%   - 'fields': Events use EEG.event fields directly
%   - 'delimiter': Events use delimiter-separated values (e.g., 'cond_G23_word')
%   - 'simple': Events are simple codes (e.g., 'S  1', 'DIN1')
%
% Inputs:
%   EEG - EEGLAB EEG structure
%
% Outputs:
%   structure - Struct containing:
%     .format - Detected format type
%     .confidence - Confidence score (0-1)
%     .eventPattern - Detected event pattern to match
%     .sampleEvent - Representative event string
%     .numEvents - Total events analyzed

    structure = struct();
    structure.format = 'unknown';
    structure.confidence = 0;
    structure.eventPattern = '';
    structure.sampleEvent = '';
    structure.numEvents = length(EEG.event);

    if structure.numEvents == 0
        warning('No events found in EEG structure');
        return;
    end

    fprintf('\n=== AUTO-DETECTING EVENT STRUCTURE ===\n');
    fprintf('Analyzing %d events...\n', structure.numEvents);

    % Sample up to 100 events for analysis
    sampleSize = min(100, structure.numEvents);
    sampleIndices = round(linspace(1, structure.numEvents, sampleSize));

    % Count format indicators
    bracketCount = 0;
    richFieldsCount = 0;
    delimiterCount = 0;
    simpleCount = 0;

    for i = sampleIndices
        evt = EEG.event(i);

        if ~isfield(evt, 'type')
            continue;
        end

        eventType = char(evt.type);

        % Check for bracket format: [key: value, ...]
        if contains(eventType, '[') && contains(eventType, ']')
            bracketIdx = strfind(eventType, '[');
            if ~isempty(bracketIdx)
                bracketContent = eventType(bracketIdx(1):end);
                % Check if it looks like key: value pairs
                if contains(bracketContent, ':') && contains(bracketContent, ',')
                    bracketCount = bracketCount + 1;
                    if isempty(structure.sampleEvent)
                        structure.sampleEvent = eventType;
                    end
                end
            end
        end

        % Check for rich fields in event structure
        eventFields = fieldnames(evt);
        % Look for fields beyond basic EEGLAB fields (type, latency, duration, urevent)
        basicFields = {'type', 'latency', 'duration', 'urevent'};
        extraFields = setdiff(eventFields, basicFields);
        if length(extraFields) >= 2  % At least 2 extra fields suggests rich structure
            richFieldsCount = richFieldsCount + 1;
        end

        % Check for delimiter-based format
        if contains(eventType, '_') || contains(eventType, '-')
            parts = strsplit(eventType, {'_', '-'});
            if length(parts) >= 3  % At least 3 parts suggests structured format
                delimiterCount = delimiterCount + 1;
            end
        end

        % Check for simple code format
        if length(eventType) <= 10 && ~contains(eventType, '_') && ~contains(eventType, '[')
            simpleCount = simpleCount + 1;
        end
    end

    % Determine format based on counts
    totalSampled = length(sampleIndices);

    bracketRatio = bracketCount / totalSampled;
    fieldsRatio = richFieldsCount / totalSampled;
    delimiterRatio = delimiterCount / totalSampled;
    simpleRatio = simpleCount / totalSampled;

    fprintf('  Format detection:\n');
    fprintf('    Bracket format:    %.0f%% (%d/%d events)\n', bracketRatio*100, bracketCount, totalSampled);
    fprintf('    Rich fields:       %.0f%% (%d/%d events)\n', fieldsRatio*100, richFieldsCount, totalSampled);
    fprintf('    Delimiter format:  %.0f%% (%d/%d events)\n', delimiterRatio*100, delimiterCount, totalSampled);
    fprintf('    Simple codes:      %.0f%% (%d/%d events)\n', simpleRatio*100, simpleCount, totalSampled);

    % Choose format with highest ratio
    [maxRatio, maxIdx] = max([bracketRatio, fieldsRatio, delimiterRatio, simpleRatio]);

    formatNames = {'bracket', 'fields', 'delimiter', 'simple'};
    structure.format = formatNames{maxIdx};
    structure.confidence = maxRatio;

    % Auto-detect event pattern (common prefix in event types)
    if structure.confidence > 0.3
        structure.eventPattern = detectEventPattern(EEG, sampleIndices);
    end

    fprintf('  ✓ Detected format: %s (%.0f%% confidence)\n', upper(structure.format), structure.confidence * 100);
    if ~isempty(structure.eventPattern)
        fprintf('  ✓ Event pattern: "%s"\n', structure.eventPattern);
    end
    fprintf('======================================\n\n');
end


function pattern = detectEventPattern(EEG, sampleIndices)
    % Find common prefix/pattern in event type strings

    patterns = {};
    for i = sampleIndices
        if isfield(EEG.event(i), 'type')
            eventType = char(EEG.event(i).type);
            patterns{end+1} = eventType;
        end
    end

    if isempty(patterns)
        pattern = '';
        return;
    end

    % Find common prefix
    firstEvent = patterns{1};

    % Try to find a common prefix (up to first underscore or space)
    tokens = regexp(firstEvent, '[_\s\[]', 'split', 'once');
    if ~isempty(tokens)
        candidatePattern = tokens{1};

        % Check if this prefix appears in most events
        matchCount = 0;
        for i = 1:length(patterns)
            if startsWith(patterns{i}, candidatePattern, 'IgnoreCase', true)
                matchCount = matchCount + 1;
            end
        end

        if matchCount / length(patterns) > 0.5
            pattern = candidatePattern;
            return;
        end
    end

    % If no common prefix, look for common keywords
    keywords = {'EVNT', 'TRSP', 'STIM', 'Stimulus', 'Trigger', 'DIN', 'Event'};
    for k = 1:length(keywords)
        matchCount = 0;
        for i = 1:length(patterns)
            if contains(patterns{i}, keywords{k}, 'IgnoreCase', true)
                matchCount = matchCount + 1;
            end
        end

        if matchCount / length(patterns) > 0.5
            pattern = keywords{k};
            return;
        end
    end

    % Default: no specific pattern required
    pattern = '';
end
