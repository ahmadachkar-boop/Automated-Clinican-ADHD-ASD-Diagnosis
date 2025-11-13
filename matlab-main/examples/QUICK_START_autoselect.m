%% QUICK START: UNIVERSAL Automatic Event Selection and Epoching
%
% This script uses the UNIVERSAL auto-detection system that works with
% ANY dataset format - no manual configuration required!
%
% Features:
%   ✓ Auto-detects event structure (brackets, fields, delimiters, codes)
%   ✓ Auto-discovers available fields and grouping variables
%   ✓ Auto-excludes trial-specific metadata (trial#, response time, etc.)
%   ✓ Optional AI-powered analysis for intelligent field classification
%   ✓ Works with your current data AND any future datasets
%
% Just update the file path below and run this script!

clear; clc;

%% ========== CONFIGURATION (EDIT THIS SECTION) ==========

% 1. Set your MFF file path (or any EEGLAB-compatible format)
mffFilePath = 'path/to/your/file.mff';  % <-- CHANGE THIS

% 2. Choose which conditions to include (or leave empty for ALL)
% Examples:
%   {} - Include ALL conditions (auto-detect)
%   {'SG23', 'SG45', 'SKG1', 'KG1'} - Only these conditions
%   {'G23', 'G45'} - Only G-type conditions
conditionsToInclude = {};  % <-- CHANGE THIS if you want specific conditions

% 3. Set epoching time window (in seconds)
epochTimeWindow = [-0.2, 0.8];  % 200ms before to 800ms after event

% 4. Choose whether to preprocess data first
doPreprocessing = false;  % Set to true to enable filtering

% 5. Advanced: Override auto-detected grouping fields (usually not needed)
%    Leave empty {} to use automatic detection
%    Example: {'Cond', 'Code', 'Verb'} to group by these specific fields
overrideGroupBy = {};  % <-- Usually leave this empty!

% 6. 🤖 AI-POWERED ANALYSIS (Optional - requires API key)
%    AI provides intelligent field classification for ambiguous cases
%    Options:
%      'auto'   - Use AI only when heuristic confidence < 70% (default)
%      'always' - Always use AI for enhanced analysis
%      'never'  - Never use AI (heuristics only, free and fast)
useAI = 'auto';  % <-- Set to 'always' to always use AI, 'never' to disable

% 7. AI Provider (if using AI)
%    Options: 'claude' (default) or 'openai'
%    Requires environment variable:
%      - For Claude: setenv('ANTHROPIC_API_KEY', 'your-key')
%      - For OpenAI: setenv('OPENAI_API_KEY', 'your-key')
aiProvider = 'claude';  % <-- Change to 'openai' if preferred

%% ========== SCRIPT STARTS HERE (NO NEED TO EDIT BELOW) ==========

fprintf('\n');
fprintf('====================================================\n');
fprintf('  UNIVERSAL AUTOMATIC EVENT SELECTION\n');
fprintf('====================================================\n\n');

%% Step 1: Load MFF file
fprintf('[Step 1/5] Loading data file...\n');
fprintf('  File: %s\n', mffFilePath);

if ~exist(mffFilePath, 'file') && ~exist(mffFilePath, 'dir')
    error('File not found: %s\nPlease update the mffFilePath variable at the top of this script.', mffFilePath);
end

try
    % Try MFF import first
    if exist('pop_mffimport', 'file') && (endsWith(mffFilePath, '.mff') || exist(mffFilePath, 'dir'))
        % Pass empty cell array {} to automatically import all event types without GUI prompt
        EEG = pop_mffimport(mffFilePath, {});
    else
        % Fallback to generic EEGLAB load
        EEG = pop_loadset(mffFilePath);
    end
    fprintf('  ✓ Loaded: %d channels, %d events, %.1f seconds\n\n', ...
        EEG.nbchan, length(EEG.event), EEG.xmax);
catch ME
    error('Failed to load file: %s', ME.message);
end

%% Step 2: Universal auto-selection (detects format automatically)
fprintf('[Step 2/5] Running universal auto-detection...\n');
if strcmp(useAI, 'always')
    fprintf('  🤖 AI mode: ALWAYS (enhanced analysis)\n');
elseif strcmp(useAI, 'auto')
    fprintf('  🤖 AI mode: AUTO (triggered for low confidence cases)\n');
else
    fprintf('  🤖 AI mode: NEVER (heuristics only)\n');
end
fprintf('\n');

% Build options
selectOptions = {};
if ~isempty(conditionsToInclude)
    selectOptions = [selectOptions, 'Conditions', {conditionsToInclude}];
end
if ~isempty(overrideGroupBy)
    selectOptions = [selectOptions, 'GroupBy', {overrideGroupBy}];
end

% Add AI parameters
selectOptions = [selectOptions, 'UseAI', useAI, 'AIProvider', aiProvider];

% Call universal auto-selection (with AI if enabled)
[selectedEvents, structure, discovery] = autoSelectTrialEventsUniversal(EEG, selectOptions{:});

if isempty(selectedEvents)
    error('No events selected! Check your data or conditions.');
end

fprintf('✓ Selected %d condition groups\n\n', length(selectedEvents));

%% Step 3: Preprocess (optional)
if doPreprocessing
    fprintf('[Step 3/5] Preprocessing data...\n');
    fprintf('  Resampling to 250 Hz...\n');
    EEG = pop_resample(EEG, 250);

    fprintf('  High-pass filtering at 0.5 Hz...\n');
    EEG = pop_eegfiltnew(EEG, 'locutoff', 0.5);

    fprintf('  Low-pass filtering at 50 Hz...\n');
    EEG = pop_eegfiltnew(EEG, 'hicutoff', 50);

    fprintf('  Re-referencing to average...\n');
    EEG = pop_reref(EEG, []);

    fprintf('  ✓ Preprocessing complete\n\n');
else
    fprintf('[Step 3/5] Skipping preprocessing (disabled)\n\n');
end

%% Step 4: Universal epoching
fprintf('[Step 4/5] Epoching with universal system...\n');

try
    % Use universal epoching (passes structure and discovery info)
    epochedData = epochEEGByEventsUniversal(EEG, selectedEvents, epochTimeWindow, ...
                                           structure, discovery, discovery.groupingFields);
catch ME
    error('Epoching failed: %s', ME.message);
end

%% Step 5: Display results
fprintf('[Step 5/5] Results summary:\n');
fprintf('====================================================\n');

totalEpochs = 0;
for i = 1:length(epochedData)
    ed = epochedData(i);
    totalEpochs = totalEpochs + ed.numEpochs;

    % Extract condition code
    parts = strsplit(ed.eventType, '_');
    if length(parts) >= 4
        condition = parts{4};
    else
        condition = '?';
    end

    fprintf('%2d. %-40s [%s] n=%3d', i, ed.eventType, condition, ed.numEpochs);

    if isfield(ed, 'metrics') && isfield(ed.metrics, 'mean_snr_db')
        fprintf('  SNR=%.1fdB', ed.metrics.mean_snr_db);
    end
    fprintf('\n');
end

fprintf('====================================================\n');
fprintf('Total event types: %d\n', length(epochedData));
fprintf('Total epochs: %d\n', totalEpochs);
fprintf('====================================================\n\n');

%% Plot example ERP
fprintf('Plotting example ERP...\n');

if ~isempty(epochedData) && ~isempty(epochedData(1).avgERP)
    ed = epochedData(1);  % Plot first event type

    figure('Name', sprintf('Auto-Epoched ERP: %s', ed.eventType), ...
           'NumberTitle', 'off', 'Position', [100, 100, 1000, 600]);

    % Determine number of channels to plot
    numChans = min(9, size(ed.avgERP, 1));
    rows = ceil(sqrt(numChans));
    cols = ceil(numChans / rows);

    for ch = 1:numChans
        subplot(rows, cols, ch);
        hold on;

        % Get data
        erpWave = ed.avgERP(ch, :);
        stdWave = ed.stdERP(ch, :);
        timeVec = ed.timeVector;

        % Plot shaded error region
        fill([timeVec, fliplr(timeVec)], ...
             [erpWave + stdWave, fliplr(erpWave - stdWave)], ...
             [0.7 0.85 1], 'EdgeColor', 'none', 'FaceAlpha', 0.3);

        % Plot ERP line
        plot(timeVec, erpWave, 'b', 'LineWidth', 2);

        % Reference lines
        plot([timeVec(1), timeVec(end)], [0, 0], 'k--', 'LineWidth', 0.5);
        plot([0, 0], ylim, 'r--', 'LineWidth', 0.5);

        % Labels
        xlabel('Time (s)');
        ylabel('µV');

        if ch <= length(EEG.chanlocs)
            title(EEG.chanlocs(ch).labels);
        else
            title(sprintf('Ch %d', ch));
        end

        grid on;
        box on;
        hold off;
    end

    sgtitle(sprintf('ERP: %s (n=%d epochs)', ed.eventType, ed.numEpochs), ...
            'Interpreter', 'none', 'FontSize', 12, 'FontWeight', 'bold');

    fprintf('  ✓ Figure created\n\n');
else
    fprintf('  ! No data to plot\n\n');
end

%% Save results (optional)
fprintf('====================================================\n');
fprintf('Saving results...\n');

% Create output directory
outputDir = 'auto_epoch_results';
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

% Save MAT file
[~, fileName, ~] = fileparts(mffFilePath);
outputFile = fullfile(outputDir, sprintf('%s_epoched.mat', fileName));
save(outputFile, 'epochedData', 'selectedEvents', 'epochTimeWindow', 'EEG');
fprintf('  ✓ Saved: %s\n', outputFile);

% Save figure
if exist('ed', 'var')
    figFile = fullfile(outputDir, sprintf('%s_erp.png', fileName));
    saveas(gcf, figFile);
    fprintf('  ✓ Saved: %s\n', figFile);
end

fprintf('====================================================\n');
fprintf('\n✓ ALL DONE!\n\n');

fprintf('====================================================\n');
fprintf('DETECTION SUMMARY (for your records):\n');
fprintf('====================================================\n');
fprintf('Event format detected: %s\n', upper(structure.format));
fprintf('Detection confidence: %.0f%%\n', structure.confidence * 100);
fprintf('Fields discovered: %d\n', length(discovery.fields));
fprintf('Grouping fields used: %s\n', strjoin(discovery.groupingFields, ', '));
fprintf('Trial-specific fields excluded: %s\n', strjoin(discovery.excludeFields, ', '));
fprintf('====================================================\n\n');

fprintf('Next steps:\n');
fprintf('  1. Check the results in: %s/\n', outputDir);
fprintf('  2. This same script will work with OTHER datasets!\n');
fprintf('  3. Adjust conditions at top if you want to filter specific ones\n');
fprintf('  4. Use ''overrideGroupBy'' if you want different grouping\n\n');

fprintf('💡 TIP: This universal system automatically adapts to:\n');
fprintf('   - Bracket notation: [key: value, ...]\n');
fprintf('   - Direct fields: EEG.event.condition, etc.\n');
fprintf('   - Delimiter format: STIM_cond_type_trial\n');
fprintf('   - Simple codes: S1, S2, DIN1, etc.\n\n');
