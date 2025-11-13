function epochedData = epochEEGByEventsUniversal(EEG, selectedConditions, timeWindow, structure, discovery, groupByFields)
% EPOCHEEGBYEVENTSUNIVERSAL - Universal epoching that works with any format
%
% This function epochs EEG data using condition labels extracted by the
% universal parsing system. Works with any event format automatically.
%
% Inputs:
%   EEG - EEGLAB EEG structure
%   selectedConditions - Cell array of condition labels to epoch
%   timeWindow - [start, end] in seconds (e.g., [-0.2, 0.8])
%   structure - Output from detectEventStructure() (optional)
%   discovery - Output from discoverEventFields() (optional)
%   groupByFields - Fields used for grouping (optional)
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

    % Handle optional arguments
    if nargin < 3
        timeWindow = [-0.2, 0.8];
    end

    % If structure/discovery not provided, auto-detect
    if nargin < 4 || isempty(structure)
        fprintf('Auto-detecting event structure...\n');
        structure = detectEventStructure(EEG);
    end

    if nargin < 5 || isempty(discovery)
        fprintf('Auto-discovering event fields...\n');
        discovery = discoverEventFields(EEG, structure);
    end

    if nargin < 6 || isempty(groupByFields)
        groupByFields = discovery.groupingFields;
    end

    epochedData = struct();
    fs = EEG.srate;

    % Convert time window to samples
    preStim = round(abs(timeWindow(1)) * fs);
    postStim = round(timeWindow(2) * fs);
    epochLength = preStim + postStim + 1;

    % Create time vector
    timeVector = linspace(timeWindow(1), timeWindow(2), epochLength);

    fprintf('\n========================================\n');
    fprintf('UNIVERSAL EPOCHING\n');
    fprintf('========================================\n');
    fprintf('Time window: [%.2f, %.2f] seconds\n', timeWindow(1), timeWindow(2));
    fprintf('Epoch length: %d samples\n', epochLength);
    fprintf('Format: %s\n', structure.format);
    fprintf('Grouping by: %s\n', strjoin(groupByFields, ', '));

    % Double-check: Filter out any practice trials that might have slipped through
    practicePatterns = {'Practice', 'practice', 'Prac', 'Training', 'training'};
    originalCount = length(selectedConditions);
    keepMask = true(length(selectedConditions), 1);
    for i = 1:length(selectedConditions)
        for p = 1:length(practicePatterns)
            if contains(selectedConditions{i}, practicePatterns{p}, 'IgnoreCase', true)
                keepMask(i) = false;
                break;
            end
        end
    end
    selectedConditions = selectedConditions(keepMask);
    if originalCount ~= length(selectedConditions)
        fprintf('Filtered out %d practice conditions\n', originalCount - length(selectedConditions));
    end

    fprintf('----------------------------------------\n\n');

    for typeIdx = 1:length(selectedConditions)
        conditionLabel = selectedConditions{typeIdx};

        fprintf('Processing condition "%s"...\n', conditionLabel);

        % Find all events matching this condition label
        eventIndices = [];
        for i = 1:length(EEG.event)
            % Parse this event's condition using universal parser
            thisCondition = parseEventUniversal(EEG.event(i), structure, discovery, groupByFields);

            % Check if it matches the target condition
            if strcmp(thisCondition, conditionLabel)
                eventIndices(end+1) = i;
            end
        end

        fprintf('  Found %d matching events\n', length(eventIndices));

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

        fprintf('  Extracted %d valid epochs\n', validEpochCount);

        % Store epoch data
        epochedData(typeIdx).eventType = conditionLabel;

        % Store original event type (before AI modification) if available
        if isfield(discovery, 'originalEventTypeMap') && discovery.originalEventTypeMap.isKey(conditionLabel)
            epochedData(typeIdx).originalEventType = discovery.originalEventTypeMap(conditionLabel);
        else
            epochedData(typeIdx).originalEventType = conditionLabel;  % Fallback to condition label
        end

        epochedData(typeIdx).epochs = epochs;
        epochedData(typeIdx).numEpochs = validEpochCount;
        epochedData(typeIdx).timeVector = timeVector;

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

            fprintf('  ✓ Averaged ERP computed (SNR: %.1f dB)\n', ...
                epochedData(typeIdx).metrics.mean_snr_db);
        else
            epochedData(typeIdx).avgERP = [];
            epochedData(typeIdx).stdERP = [];
            epochedData(typeIdx).metrics = struct();
            fprintf('  ⚠ No valid epochs extracted\n');
        end

        fprintf('\n');
    end

    fprintf('========================================\n');
    fprintf('✓ EPOCHING COMPLETE\n');
    fprintf('========================================\n');
    fprintf('Conditions processed: %d\n', length(selectedConditions));
    totalEpochs = sum([epochedData.numEpochs]);
    fprintf('Total epochs extracted: %d\n', totalEpochs);
    fprintf('Average per condition: %.1f\n', totalEpochs / length(selectedConditions));
    fprintf('========================================\n\n');
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

    % Rejected epochs (based on amplitude threshold)
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
