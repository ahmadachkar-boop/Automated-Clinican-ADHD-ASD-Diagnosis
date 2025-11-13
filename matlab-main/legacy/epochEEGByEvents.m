function epochedData = epochEEGByEvents(EEG, selectedEventTypes, timeWindow)
    % EPOCHEEGBYEVENTS - Epoch EEG data around selected event types
    %
    % Inputs:
    %   EEG - EEG structure
    %   selectedEventTypes - Cell array of event types to epoch around
    %   timeWindow - [start, end] in seconds (e.g., [-0.2, 0.8])
    %
    % Output:
    %   epochedData - Structure containing:
    %     .eventType - Event type name
    %     .epochs - Cell array of epoch data matrices
    %     .numEpochs - Number of epochs
    %     .timeVector - Time vector for epochs
    %     .metrics - Quality metrics for this event type

    if nargin < 3
        timeWindow = [-0.2, 0.8]; % Default: 200ms pre, 800ms post
    end

    epochedData = struct();
    fs = EEG.srate;

    % Convert time window to samples
    preStim = round(abs(timeWindow(1)) * fs);
    postStim = round(timeWindow(2) * fs);
    epochLength = preStim + postStim + 1;

    % Create time vector
    timeVector = linspace(timeWindow(1), timeWindow(2), epochLength);

    fprintf('\nEpoching data around events...\n');
    fprintf('  Time window: [%.2f, %.2f] seconds\n', timeWindow(1), timeWindow(2));
    fprintf('  Epoch length: %d samples\n', epochLength);

    for typeIdx = 1:length(selectedEventTypes)
        eventType = selectedEventTypes{typeIdx};

        % Find events of this type
        eventIndices = [];
        for i = 1:length(EEG.event)
            % Try different field names
            event_label = '';
            if isfield(EEG.event, 'type') && ~isempty(EEG.event(i).type)
                val = EEG.event(i).type;
                if isnumeric(val)
                    event_label = num2str(val);
                else
                    event_label = char(val);
                end
            elseif isfield(EEG.event, 'code') && ~isempty(EEG.event(i).code)
                val = EEG.event(i).code;
                if isnumeric(val)
                    event_label = num2str(val);
                else
                    event_label = char(val);
                end
            end

            if strcmp(event_label, eventType)
                eventIndices(end+1) = i;
            end
        end

        fprintf('  Processing event type ''%s'': %d occurrences\n', eventType, length(eventIndices));

        % Extract epochs
        epochs = {};
        validEpochCount = 0;

        for i = 1:length(eventIndices)
            eventIdx = eventIndices(i);

            % Get event latency (in samples)
            if isfield(EEG.event, 'latency')
                eventSample = round(EEG.event(eventIdx).latency);
            else
                warning('Event %d has no latency field, skipping', eventIdx);
                continue;
            end

            % Check if epoch is within data bounds
            startSample = eventSample - preStim;
            endSample = eventSample + postStim;

            if startSample < 1 || endSample > size(EEG.data, 2)
                % Skip epochs that extend beyond data boundaries
                continue;
            end

            % Extract epoch data (all channels)
            epochData = EEG.data(:, startSample:endSample);

            % Baseline correction (subtract mean of pre-stimulus period)
            if preStim > 0
                baselineMean = mean(epochData(:, 1:preStim), 2);
                epochData = epochData - baselineMean;
            end

            epochs{end+1} = epochData;
            validEpochCount = validEpochCount + 1;
        end

        % Store epoch data
        epochedData(typeIdx).eventType = eventType;
        epochedData(typeIdx).epochs = epochs;
        epochedData(typeIdx).numEpochs = validEpochCount;
        epochedData(typeIdx).timeVector = timeVector;

        fprintf('    Extracted %d valid epochs\n', validEpochCount);

        % Compute average ERP (Event-Related Potential)
        if validEpochCount > 0
            % Stack all epochs into 3D matrix: channels x samples x epochs
            epochMatrix = cat(3, epochs{:});

            % Compute mean across epochs
            avgERP = mean(epochMatrix, 3);

            epochedData(typeIdx).avgERP = avgERP;
            epochedData(typeIdx).stdERP = std(epochMatrix, 0, 3);

            % Compute simple quality metrics
            epochedData(typeIdx).metrics = computeEpochMetrics(epochMatrix, EEG);
        else
            epochedData(typeIdx).avgERP = [];
            epochedData(typeIdx).stdERP = [];
            epochedData(typeIdx).metrics = struct();
        end
    end

    fprintf('✓ Epoching complete\n\n');
end


function metrics = computeEpochMetrics(epochMatrix, EEG)
    % Compute basic quality metrics for epoched data
    % epochMatrix: channels x samples x epochs

    metrics = struct();

    % Average across epochs
    avgData = mean(epochMatrix, 3);

    % Signal-to-noise ratio (trial-to-trial consistency)
    signal = var(mean(epochMatrix, 3), 0, 2);  % Variance of average
    noise = mean(var(epochMatrix, 0, 3), 2);   % Average variance across trials
    snr = signal ./ (noise + eps);
    metrics.mean_snr_db = 10 * log10(mean(snr));

    % Peak-to-peak amplitude
    p2p = max(avgData, [], 2) - min(avgData, [], 2);
    metrics.mean_p2p_amplitude = mean(p2p);

    % Number of epochs
    metrics.num_epochs = size(epochMatrix, 3);

    % Rejected epochs (would need more sophisticated rejection)
    % For now, count epochs with excessive amplitude
    threshold = 100; % microvolts
    bad_epochs = 0;
    for ep = 1:size(epochMatrix, 3)
        if max(abs(epochMatrix(:, :, ep)), [], 'all') > threshold
            bad_epochs = bad_epochs + 1;
        end
    end
    metrics.bad_epochs = bad_epochs;
    metrics.good_epochs = metrics.num_epochs - bad_epochs;
    metrics.rejection_rate = bad_epochs / metrics.num_epochs;
end
