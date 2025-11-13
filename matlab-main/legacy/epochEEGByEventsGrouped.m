function epochedData = epochEEGByEventsGrouped(EEG, selectedConditions, timeWindow, groupByFields)
    % EPOCHEEGBYEVENTSGROUPED - Epoch EEG data using grouped condition labels
    %
    % This function works with simplified condition labels (e.g., 'G23_word')
    % rather than full event type strings, grouping multiple trials together.
    %
    % Inputs:
    %   EEG - EEG structure
    %   selectedConditions - Cell array of condition labels to epoch around
    %                        (e.g., {'G23_word', 'SG23_nonword'})
    %   timeWindow - [start, end] in seconds (e.g., [-0.2, 0.8])
    %   groupByFields - Fields used for grouping (default: {'Cond', 'Code'})
    %
    % Output:
    %   epochedData - Structure array containing:
    %     .eventType - Condition label
    %     .epochs - Cell array of epoch data matrices
    %     .numEpochs - Number of epochs
    %     .timeVector - Time vector for epochs
    %     .avgERP - Average ERP across epochs
    %     .stdERP - Standard deviation ERP
    %     .metrics - Quality metrics for this condition

    if nargin < 3
        timeWindow = [-0.2, 0.8]; % Default: 200ms pre, 800ms post
    end

    if nargin < 4
        groupByFields = {'Cond', 'Code'};
    end

    epochedData = struct();
    fs = EEG.srate;

    % Convert time window to samples
    preStim = round(abs(timeWindow(1)) * fs);
    postStim = round(timeWindow(2) * fs);
    epochLength = preStim + postStim + 1;

    % Create time vector
    timeVector = linspace(timeWindow(1), timeWindow(2), epochLength);

    fprintf('\nEpoching data by grouped conditions...\n');
    fprintf('  Time window: [%.2f, %.2f] seconds\n', timeWindow(1), timeWindow(2));
    fprintf('  Epoch length: %d samples\n', epochLength);
    fprintf('  Grouping by: %s\n', strjoin(groupByFields, ', '));

    for typeIdx = 1:length(selectedConditions)
        conditionLabel = selectedConditions{typeIdx};

        % Find all events matching this condition label
        eventIndices = [];
        for i = 1:length(EEG.event)
            % Parse this event's condition
            thisCondition = parseEventConditions(EEG.event(i), groupByFields);

            % Check if it matches the target condition
            if strcmp(thisCondition, conditionLabel)
                eventIndices(end+1) = i;
            end
        end

        fprintf('  Processing condition ''%s'': %d trials\n', conditionLabel, length(eventIndices));

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
        epochedData(typeIdx).eventType = conditionLabel;
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

            % Compute quality metrics
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
