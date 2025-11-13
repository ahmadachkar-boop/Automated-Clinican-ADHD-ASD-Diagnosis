function epochedData = epochEEGByMarkerPairs(EEG, epochDefinitions)
    % EPOCHEEGBYMARKERPAIRS - Epoch EEG data between marker pairs
    %
    % Input:
    %   EEG - EEGLAB EEG structure
    %   epochDefinitions - Cell array of structs with fields:
    %                      .startMarker, .endMarker, .name
    %
    % Output:
    %   epochedData - Array of structs (one per epoch type) with fields:
    %                 .eventType, .epochs, .numEpochs, .avgERP, .stdERP,
    %                 .timeVector, .metrics

    epochedData = [];

    if isempty(epochDefinitions)
        return;
    end

    events = EEG.event;

    fprintf('Extracting marker-pair epochs...\n');

    % Process each epoch definition
    for d = 1:length(epochDefinitions)
        def = epochDefinitions{d};

        fprintf('  Processing: %s (%s → %s)\n', def.name, def.startMarker, def.endMarker);

        % Find all start and end marker latencies
        startLatencies = [];
        endLatencies = [];

        for i = 1:length(events)
            % Check if this is a start marker
            eventType = getEventType(events(i));

            if strcmp(eventType, def.startMarker)
                if isfield(events, 'latency') && ~isempty(events(i).latency)
                    startLatencies(end+1) = events(i).latency;
                end
            elseif strcmp(eventType, def.endMarker)
                if isfield(events, 'latency') && ~isempty(events(i).latency)
                    endLatencies(end+1) = events(i).latency;
                end
            end
        end

        fprintf('    Found %d start markers and %d end markers\n', ...
            length(startLatencies), length(endLatencies));

        % Match start and end markers (find pairs)
        epochPairs = findMarkerPairs(startLatencies, endLatencies);

        if isempty(epochPairs)
            fprintf('    Warning: No valid marker pairs found\n');
            continue;
        end

        fprintf('    Matched %d epoch pairs\n', size(epochPairs, 1));

        % Extract epoch data for each pair
        epochs = cell(size(epochPairs, 1), 1);
        epochLengths = zeros(size(epochPairs, 1), 1);

        for e = 1:size(epochPairs, 1)
            startSample = round(epochPairs(e, 1));  % Ensure integer
            endSample = round(epochPairs(e, 2));    % Ensure integer

            % Ensure indices are within bounds
            startSample = max(1, startSample);
            endSample = min(EEG.pnts, endSample);

            % Extract data
            epochData = EEG.data(:, startSample:endSample);
            epochs{e} = epochData;
            epochLengths(e) = size(epochData, 2);
        end

        % Find common length (minimum) for averaging
        minLength = round(min(epochLengths));  % Ensure integer
        maxLength = round(max(epochLengths));  % Ensure integer

        fprintf('    Epoch lengths: min=%.3fs, max=%.3fs, mean=%.3fs\n', ...
            minLength/EEG.srate, maxLength/EEG.srate, mean(epochLengths)/EEG.srate);

        % Truncate all epochs to minimum length for averaging
        epochMatrix = zeros(EEG.nbchan, minLength, length(epochs));
        for e = 1:length(epochs)
            epochMatrix(:, :, e) = epochs{e}(:, 1:minLength);
        end

        % Compute average and std
        avgERP = mean(epochMatrix, 3);
        stdERP = std(epochMatrix, [], 3);

        % Create time vector (relative to start marker)
        timeVector = (0:minLength-1) / EEG.srate;

        % Compute metrics
        metrics = struct();
        metrics.num_epochs = length(epochs);
        metrics.good_epochs = length(epochs); % All are good (already cleaned data)

        % SNR per channel (ratio of signal power to noise estimate)
        signalPower = mean(avgERP.^2, 2);
        noisePower = mean(stdERP.^2, 2);
        snr_linear = signalPower ./ (noisePower + eps);
        snr_db = 10 * log10(snr_linear + eps);
        metrics.mean_snr_db = mean(snr_db);

        % Peak-to-peak amplitude
        p2p_amp = max(avgERP, [], 2) - min(avgERP, [], 2);
        metrics.mean_p2p_amplitude = mean(p2p_amp);

        % Store results
        result = struct();
        result.eventType = def.name;
        result.epochs = epochs;
        result.numEpochs = length(epochs);
        result.avgERP = avgERP;
        result.stdERP = stdERP;
        result.timeVector = timeVector;
        result.metrics = metrics;
        result.epochLengths = epochLengths;

        epochedData = [epochedData; result];
    end

    fprintf('✓ Marker-pair epoching complete\n\n');
end

function eventType = getEventType(event)
    % Extract event type from event structure
    type_fields = {'type', 'code', 'label', 'name'};
    eventType = '';

    for f = 1:length(type_fields)
        field = type_fields{f};
        if isfield(event, field) && ~isempty(event.(field))
            value = event.(field);
            if ischar(value)
                eventType = value;
                return;
            elseif isnumeric(value)
                eventType = num2str(value);
                return;
            end
        end
    end
end

function pairs = findMarkerPairs(startLatencies, endLatencies)
    % Find matching pairs of start and end markers
    % Each start marker is matched with the next end marker that comes after it

    pairs = [];

    usedEndIdx = false(size(endLatencies));

    for i = 1:length(startLatencies)
        startLat = startLatencies(i);

        % Find the next end marker after this start
        validEnds = endLatencies > startLat & ~usedEndIdx;

        if any(validEnds)
            % Get the first valid end marker
            validEndLatencies = endLatencies(validEnds);
            [minEndLat, ~] = min(validEndLatencies);

            % Find index in original array
            endIdx = find(endLatencies == minEndLat & ~usedEndIdx, 1, 'first');

            % Add pair
            pairs(end+1, :) = [startLat, endLatencies(endIdx)];

            % Mark this end as used
            usedEndIdx(endIdx) = true;
        end
    end
end
