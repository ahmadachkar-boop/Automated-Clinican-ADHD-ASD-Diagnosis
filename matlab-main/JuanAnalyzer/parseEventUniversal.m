function conditionLabel = parseEventUniversal(eventStruct, structure, discovery, groupingFields)
% PARSEEVENTUNIVERSAL - Universal event parser that works with any format
%
% This function parses events using automatically detected structure and
% field information, making it work with any dataset format.
%
% Inputs:
%   eventStruct - Event structure from EEG.event
%   structure - Output from detectEventStructure()
%   discovery - Output from discoverEventFields()
%   groupingFields - (Optional) Override auto-detected grouping fields
%
% Outputs:
%   conditionLabel - String label for this condition (e.g., 'G23_word')

    if nargin < 4 || isempty(groupingFields)
        groupingFields = discovery.groupingFields;
    end

    % Initialize empty label
    conditionLabel = '';

    if ~isfield(eventStruct, 'type')
        return;
    end

    eventType = char(eventStruct.type);

    % Parse fields based on detected format
    switch structure.format
        case 'bracket'
            fields = parseBracketFormat(eventType);

        case 'fields'
            fields = parseFieldFormat(eventStruct);

        case 'delimiter'
            fields = parseDelimiterFormat(eventType);

        case 'simple'
            % Simple codes: use the code itself as the label
            conditionLabel = eventType;
            return;

        otherwise
            % Fallback: try bracket format first, then fields
            fields = parseBracketFormat(eventType);
            if isempty(fieldnames(fields))
                fields = parseFieldFormat(eventStruct);
            end
    end

    if isempty(fieldnames(fields))
        return;
    end

    % Build condition label from grouping fields
    labelParts = {};

    for f = 1:length(groupingFields)
        fieldName = groupingFields{f};

        if isfield(fields, fieldName)
            value = fields.(fieldName);

            % Apply value mappings if available
            if isfield(discovery.valueMappings, fieldName)
                mappings = discovery.valueMappings.(fieldName);

                % Direct string mappings (y, n, Y, N)
                if isfield(mappings, value)
                    value = mappings.(value);
                % Numeric mappings (need prefix 'n' for valid field names)
                elseif strcmp(value, '1') && isfield(mappings, 'n1')
                    value = mappings.n1;
                elseif strcmp(value, '0') && isfield(mappings, 'n0')
                    value = mappings.n0;
                end
            end

            % Skip missing data indicators
            if ~strcmp(value, '?') && ~strcmp(value, '0') && ~strcmp(value, '') && ~strcmp(value, 'NA')
                labelParts{end+1} = value;
            end
        end
    end

    % Combine parts with underscore
    if ~isempty(labelParts)
        conditionLabel = strjoin(labelParts, '_');
    end
end


function fields = parseBracketFormat(eventType)
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

                    % Clean up key names (remove special chars)
                    key = regexprep(key, '[^a-zA-Z0-9]', '');

                    if ~isempty(key)
                        fields.(key) = value;
                    end
                end
            end
        end
    end
end


function fields = parseFieldFormat(eventStruct)
    % Parse EEG.event fields directly
    fields = struct();

    % Skip basic EEGLAB fields
    basicFields = {'type', 'latency', 'duration', 'urevent', 'epoch'};
    eventFields = fieldnames(eventStruct);

    for i = 1:length(eventFields)
        fieldName = eventFields{i};
        if ~ismember(fieldName, basicFields)
            value = eventStruct.(fieldName);

            % Convert to string
            if ischar(value) || isstring(value)
                fields.(fieldName) = char(value);
            elseif isnumeric(value)
                fields.(fieldName) = num2str(value);
            else
                % Try to convert other types
                try
                    fields.(fieldName) = char(value);
                catch
                    fields.(fieldName) = '';
                end
            end
        end
    end
end


function fields = parseDelimiterFormat(eventType)
    % Parse delimiter-separated values: prefix_field1_field2_...
    fields = struct();

    % Try underscore first, then dash
    if contains(eventType, '_')
        parts = strsplit(eventType, '_');
        delimiter = '_';
    elseif contains(eventType, '-')
        parts = strsplit(eventType, '-');
        delimiter = '-';
    else
        return;
    end

    % Heuristic: first part is often a prefix (STIM, EVENT, etc.)
    % Skip it if it's all uppercase or matches common prefixes
    startIdx = 1;
    if length(parts) > 1
        firstPart = parts{1};
        if strcmp(firstPart, upper(firstPart)) || ...
           ismember(lower(firstPart), {'stim', 'event', 'trigger', 'trial'})
            startIdx = 2;
        end
    end

    % Create fields with generic names
    fieldIdx = 1;
    for i = startIdx:length(parts)
        fieldName = sprintf('field%d', fieldIdx);
        fields.(fieldName) = parts{i};
        fieldIdx = fieldIdx + 1;
    end

    % If we only got one field, use the whole string
    if fieldIdx == 2 && length(parts) == 1
        fields.field1 = eventType;
    end
end
