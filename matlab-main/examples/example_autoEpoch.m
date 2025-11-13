% EXAMPLE: Automatically Select and Epoch Trial Events
%
% This script demonstrates how to automatically filter and epoch around
% specific trial events (like EVNT_TRSP with condition codes) without
% manually selecting from 1000+ event types.

%% Load your MFF file
% Replace with your actual file path
mffFile = 'your_file.mff';

fprintf('Loading MFF file: %s\n', mffFile);
EEG = pop_mffimport(mffFile);
fprintf('Loaded EEG data: %d channels, %d events, %.1f seconds\n', ...
    EEG.nbchan, length(EEG.event), EEG.xmax);

%% Method 1: Auto-select ALL EVNT_TRSP events
fprintf('\n=== METHOD 1: Select ALL EVNT_TRSP events ===\n');
selectedEvents1 = autoSelectTrialEvents(EEG);

%% Method 2: Auto-select only specific conditions
fprintf('\n=== METHOD 2: Select specific conditions only ===\n');
% Specify the exact condition codes you want
conditions = {'SG23', 'SG45', 'SKG1', 'KG1', 'G23', 'G45'};
selectedEvents2 = autoSelectTrialEvents(EEG, 'Conditions', conditions);

%% Method 3: Select only "G" conditions (exclude "S" and "K" prefixes)
fprintf('\n=== METHOD 3: Select only G-conditions ===\n');
gConditions = {'G23', 'G45'};
selectedEvents3 = autoSelectTrialEvents(EEG, 'Conditions', gConditions);

%% Method 4: Select only "S" and "K" prefixed conditions
fprintf('\n=== METHOD 4: Select S and K conditions ===\n');
skConditions = {'SG23', 'SG45', 'SKG1', 'KG1'};
selectedEvents4 = autoSelectTrialEvents(EEG, 'Conditions', skConditions);

%% Now epoch the data around selected events
fprintf('\n=== EPOCHING DATA ===\n');

% Use the selected events from Method 2 (or choose any method above)
selectedEvents = selectedEvents2;

% Define time window around events (in seconds)
timeWindow = [-0.2, 0.8];  % 200ms before to 800ms after event

% Epoch the data
fprintf('Epoching around %d event types...\n', length(selectedEvents));
epochedData = epochEEGByEvents(EEG, selectedEvents, timeWindow);

%% Display results
fprintf('\n=== EPOCHING RESULTS ===\n');
for i = 1:length(epochedData)
    ed = epochedData(i);
    fprintf('Event: %s\n', ed.eventType);
    fprintf('  Epochs: %d\n', ed.numEpochs);
    fprintf('  Avg ERP size: [%d channels x %d timepoints]\n', ...
        size(ed.avgERP, 1), size(ed.avgERP, 2));

    if isfield(ed, 'metrics')
        fprintf('  SNR: %.2f dB\n', ed.metrics.snr_db);
        fprintf('  Peak-to-peak: %.2f µV\n', ed.metrics.peak_to_peak_uv);
    end
    fprintf('\n');
end

%% Plot ERP for first event type
if ~isempty(epochedData) && ~isempty(epochedData(1).avgERP)
    ed = epochedData(1);

    fprintf('Plotting ERP for: %s\n', ed.eventType);

    figure('Name', sprintf('ERP: %s', ed.eventType), 'NumberTitle', 'off');

    % Plot first 4 channels
    numChansToPlot = min(4, size(ed.avgERP, 1));

    for ch = 1:numChansToPlot
        subplot(2, 2, ch);
        hold on;

        % Plot ERP with shaded error
        erpWave = ed.avgERP(ch, :);
        stdWave = ed.stdERP(ch, :);
        timeVec = ed.timeVector;

        % Shaded error region
        fill([timeVec, fliplr(timeVec)], ...
             [erpWave + stdWave, fliplr(erpWave - stdWave)], ...
             [0.8 0.9 1], 'EdgeColor', 'none', 'FaceAlpha', 0.5);

        % ERP line
        plot(timeVec, erpWave, 'b', 'LineWidth', 2);

        % Zero lines
        plot([timeVec(1), timeVec(end)], [0, 0], 'k--', 'LineWidth', 0.5);
        plot([0, 0], ylim, 'r--', 'LineWidth', 0.5);

        xlabel('Time (s)');
        ylabel('Amplitude (µV)');

        if ch <= length(EEG.chanlocs)
            title(sprintf('Channel: %s', EEG.chanlocs(ch).labels));
        else
            title(sprintf('Channel %d', ch));
        end

        grid on;
        hold off;
    end

    sgtitle(sprintf('Event-Related Potential: %s (n=%d)', ed.eventType, ed.numEpochs));
end

%% Save results (optional)
% Uncomment to save
% save('epoched_results.mat', 'epochedData', 'selectedEvents', 'timeWindow');
% fprintf('Results saved to: epoched_results.mat\n');

fprintf('\n=== DONE ===\n');
