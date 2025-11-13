function juananalyze(mffFilePath, varargin)
% JUANANALYZE - AI-Powered ERP Analysis with Universal Event Detection
%
% Comprehensive EEG/ERP analysis tool that:
%   ✓ Uses AI-only event detection (no heuristics)
%   ✓ Analyzes N400, N250, P600 ERP components
%   ✓ Performs frequency band analysis
%   ✓ Warns about bad channels but keeps them
%   ✓ Generates publication-ready visualizations
%
% Usage:
%   juananalyze(mffFilePath)
%   juananalyze(mffFilePath, 'APIKey', 'your-key')
%   juananalyze(mffFilePath, 'TimeWindow', [-0.2, 0.8])
%   juananalyze(mffFilePath, 'Provider', 'openai')
%
% Inputs:
%   mffFilePath - Path to EEG file (.mff, .set, etc.)
%
% Optional Name-Value Pairs:
%   'APIKey'      - Anthropic API key (or set ANTHROPIC_API_KEY env var)
%   'Provider'    - AI provider: 'claude' (default) or 'openai'
%   'TimeWindow'  - Epoch time window in seconds (default: [-0.2, 0.8])
%   'OutputDir'   - Output directory for results (default: 'juan_results')
%   'Preprocess'  - Apply preprocessing (default: true)
%
% Example:
%   juananalyze('/path/to/data.mff')
%   juananalyze('/path/to/data.mff', 'TimeWindow', [-0.5, 1.0])
%
% Outputs:
%   Results saved to OutputDir/filename/:
%     - ERP waveforms with N400/N250/P600 marked
%     - Topographic maps at key timepoints
%     - Frequency band power analysis
%     - Statistical summary
%     - Quality metrics report

    %% Parse inputs
    p = inputParser;
    addRequired(p, 'mffFilePath', @(x) ischar(x) || isstring(x));
    addParameter(p, 'APIKey', '', @ischar);
    addParameter(p, 'Provider', 'claude', @ischar);
    addParameter(p, 'TimeWindow', [-0.2, 0.8], @(x) isnumeric(x) && length(x)==2);
    addParameter(p, 'OutputDir', 'juan_results', @ischar);
    addParameter(p, 'Preprocess', true, @islogical);
    parse(p, mffFilePath, varargin{:});

    apiKey = p.Results.APIKey;
    provider = p.Results.Provider;
    timeWindow = p.Results.TimeWindow;
    outputDir = p.Results.OutputDir;
    doPreprocess = p.Results.Preprocess;

    %% Setup
    fprintf('\n');
    fprintf('========================================================\n');
    fprintf('  JUANANALYZE - AI-Powered ERP Analysis\n');
    fprintf('  Universal Event Detection + ERP Component Analysis\n');
    fprintf('========================================================\n\n');

    % Set API key if provided
    if ~isempty(apiKey)
        if strcmp(provider, 'claude')
            setenv('ANTHROPIC_API_KEY', apiKey);
        else
            setenv('OPENAI_API_KEY', apiKey);
        end
    end

    % Validate API key is set
    if strcmp(provider, 'claude')
        key = getenv('ANTHROPIC_API_KEY');
        if isempty(key)
            error('ANTHROPIC_API_KEY not set. Use setenv or pass as parameter.');
        end
    else
        key = getenv('OPENAI_API_KEY');
        if isempty(key)
            error('OPENAI_API_KEY not set. Use setenv or pass as parameter.');
        end
    end

    % Create output directory
    [~, filename, ~] = fileparts(mffFilePath);
    resultDir = fullfile(outputDir, filename);
    if ~exist(resultDir, 'dir')
        mkdir(resultDir);
    end

    %% Step 1: Load EEG data
    fprintf('[1/7] Loading EEG data...\n');
    if ~exist(mffFilePath, 'file') && ~exist(mffFilePath, 'dir')
        error('File not found: %s', mffFilePath);
    end

    try
        if exist('pop_mffimport', 'file') && (endsWith(mffFilePath, '.mff') || exist(mffFilePath, 'dir'))
            EEG = pop_mffimport(mffFilePath, {});
        else
            EEG = pop_loadset(mffFilePath);
        end
        fprintf('  ✓ Loaded: %d channels, %d events, %.1f seconds\n', ...
            EEG.nbchan, length(EEG.event), EEG.xmax);
    catch ME
        error('Failed to load file: %s', ME.message);
    end

    EEG_original = EEG;  % Keep original for comparison

    %% Step 2: Check for bad channels (warn but don't remove)
    fprintf('\n[2/7] Checking channel quality...\n');
    try
        % Compute channel statistics
        chanStats = zeros(EEG.nbchan, 1);
        for ch = 1:EEG.nbchan
            chanStats(ch) = kurtosis(EEG.data(ch, :));
        end

        % Identify bad channels (kurtosis > 5)
        badChans = find(abs(chanStats) > 5);

        if ~isempty(badChans)
            fprintf('  ⚠ WARNING: %d potentially bad channels detected:\n', length(badChans));
            for i = 1:length(badChans)
                if ~isempty(EEG.chanlocs) && length(EEG.chanlocs) >= badChans(i)
                    chanLabel = EEG.chanlocs(badChans(i)).labels;
                else
                    chanLabel = sprintf('Ch%d', badChans(i));
                end
                fprintf('     - %s (kurtosis: %.2f)\n', chanLabel, chanStats(badChans(i)));
            end
            fprintf('  ℹ These channels are KEPT in the analysis but flagged.\n');
        else
            fprintf('  ✓ All channels appear good (kurtosis < 5)\n');
        end
    catch ME
        fprintf('  ℹ Could not assess channel quality: %s\n', ME.message);
        badChans = [];
    end

    %% Step 3: AI-powered event detection
    fprintf('\n[3/7] Running AI-powered event detection...\n');
    fprintf('  🤖 Mode: AI-ONLY (no heuristic fallback)\n');
    fprintf('  🤖 Provider: %s\n\n', upper(provider));

    try
        % Use universal event selection with AI-ONLY mode
        [selectedEvents, structure, discovery] = autoSelectTrialEventsUniversal(EEG, ...
            'UseAI', 'always', ...
            'AIProvider', provider, ...
            'Display', true);

        if isempty(selectedEvents)
            error('No events selected by AI. Check your data or API configuration.');
        end

        fprintf('\n  ✓ AI successfully identified %d event types\n', length(selectedEvents));
    catch ME
        error('AI event detection failed: %s', ME.message);
    end

    %% Step 4: Preprocessing
    if doPreprocess
        fprintf('\n[4/7] Preprocessing EEG data...\n');
        try
            % Resample to 250 Hz
            fprintf('  - Resampling to 250 Hz...\n');
            EEG = pop_resample(EEG, 250);

            % High-pass filter (0.1 Hz for ERP analysis)
            fprintf('  - High-pass filtering (0.1 Hz)...\n');
            EEG = pop_eegfiltnew(EEG, 'locutoff', 0.1, 'plotfreqz', 0);

            % Low-pass filter (30 Hz for ERP analysis)
            fprintf('  - Low-pass filtering (30 Hz)...\n');
            EEG = pop_eegfiltnew(EEG, 'hicutoff', 30, 'plotfreqz', 0);

            % Re-reference to average
            fprintf('  - Re-referencing to average...\n');
            EEG = pop_reref(EEG, []);

            fprintf('  ✓ Preprocessing complete\n');
        catch ME
            warning('Preprocessing failed: %s. Using raw data.', ME.message);
        end
    else
        fprintf('\n[4/7] Skipping preprocessing (disabled)\n');
    end

    %% Step 5: Epoch and extract ERPs
    fprintf('\n[5/7] Extracting epochs and computing ERPs...\n');
    try
        epochedData = epochEEGByEventsUniversal(EEG, selectedEvents, timeWindow, ...
                                               structure, discovery, discovery.groupingFields);

        totalEpochs = sum([epochedData.numEpochs]);
        fprintf('  ✓ Extracted %d total epochs across %d conditions\n', ...
            totalEpochs, length(epochedData));
    catch ME
        error('Epoching failed: %s', ME.message);
    end

    %% Step 6: Analyze ERP components (N400, N250, P600)
    fprintf('\n[6/7] Analyzing ERP components...\n');
    fprintf('  Target components:\n');
    fprintf('    - N250: 200-300 ms (early lexical/semantic)\n');
    fprintf('    - N400: 300-500 ms (semantic processing)\n');
    fprintf('    - P600: 500-800 ms (syntactic reanalysis)\n\n');

    erpAnalysis = analyzeERPComponents(epochedData, timeWindow);

    %% Step 7: Frequency analysis
    fprintf('\n[7/7] Analyzing frequency bands...\n');
    freqAnalysis = analyzeFrequencyBands(EEG);

    %% Generate visualizations
    fprintf('\nGenerating visualizations...\n');
    generateVisualizations(epochedData, erpAnalysis, freqAnalysis, badChans, resultDir, timeWindow, EEG);

    %% Save results
    fprintf('\nSaving results...\n');
    results = struct();
    results.filename = filename;
    results.eventTypes = selectedEvents;
    results.epochedData = epochedData;
    results.erpAnalysis = erpAnalysis;
    results.freqAnalysis = freqAnalysis;
    results.badChannels = badChans;
    results.structure = structure;
    results.discovery = discovery;
    results.timeWindow = timeWindow;

    save(fullfile(resultDir, 'analysis_results.mat'), 'results');
    fprintf('  ✓ Results saved to: %s\n', resultDir);

    %% Print summary
    printSummary(results);

    fprintf('\n========================================================\n');
    fprintf('  ✓ ANALYSIS COMPLETE!\n');
    fprintf('  📁 Results: %s\n', resultDir);
    fprintf('========================================================\n\n');
end

%% Helper Functions

function erpAnalysis = analyzeERPComponents(epochedData, timeWindow)
    % Analyze N250, N400, P600 components

    fs = 250;  % Sampling rate after preprocessing
    timeVector = linspace(timeWindow(1), timeWindow(2), round((timeWindow(2)-timeWindow(1))*fs)+1);

    % Define time windows for each component (in seconds)
    n250Window = [0.2, 0.3];
    n400Window = [0.3, 0.5];
    p600Window = [0.5, 0.8];

    % Find indices for each window
    n250Idx = timeVector >= n250Window(1) & timeVector <= n250Window(2);
    n400Idx = timeVector >= n400Window(1) & timeVector <= n400Window(2);
    p600Idx = timeVector >= p600Window(1) & timeVector <= p600Window(2);

    erpAnalysis = struct();

    for i = 1:length(epochedData)
        condition = epochedData(i).eventType;
        erp = epochedData(i).avgERP;

        if isempty(erp) || epochedData(i).numEpochs == 0
            continue;
        end

        % Average across channels for global analysis
        % (In practice, you might want to focus on specific electrode sites)
        erpGlobal = mean(erp, 1);

        % Extract component amplitudes and latencies
        [n250Amp, n250Lat] = min(erpGlobal(n250Idx));
        n250LatTime = timeVector(n250Idx);
        n250LatTime = n250LatTime(n250Lat);

        [n400Amp, n400Lat] = min(erpGlobal(n400Idx));
        n400LatTime = timeVector(n400Idx);
        n400LatTime = n400LatTime(n400Lat);

        [p600Amp, p600Lat] = max(erpGlobal(p600Idx));
        p600LatTime = timeVector(p600Idx);
        p600LatTime = p600LatTime(p600Lat);

        erpAnalysis(i).condition = condition;
        erpAnalysis(i).n250.amplitude = n250Amp;
        erpAnalysis(i).n250.latency = n250LatTime;
        erpAnalysis(i).n400.amplitude = n400Amp;
        erpAnalysis(i).n400.latency = n400LatTime;
        erpAnalysis(i).p600.amplitude = p600Amp;
        erpAnalysis(i).p600.latency = p600LatTime;
        erpAnalysis(i).numEpochs = epochedData(i).numEpochs;

        fprintf('  %s (n=%d):\n', condition, epochedData(i).numEpochs);
        fprintf('    N250: %.2f μV @ %.0f ms\n', n250Amp, n250LatTime*1000);
        fprintf('    N400: %.2f μV @ %.0f ms\n', n400Amp, n400LatTime*1000);
        fprintf('    P600: %.2f μV @ %.0f ms\n', p600Amp, p600LatTime*1000);
    end
end

function freqAnalysis = analyzeFrequencyBands(EEG)
    % Analyze power in standard frequency bands

    fprintf('  Computing power spectral density...\n');

    % Frequency bands
    bands = struct();
    bands.delta = [0.5, 4];
    bands.theta = [4, 8];
    bands.alpha = [8, 13];
    bands.beta = [13, 30];
    bands.gamma = [30, 50];

    freqAnalysis = struct();

    try
        % Compute PSD using Welch's method
        [psd, freqs] = pwelch(EEG.data', [], [], [], EEG.srate);
        psd = psd';  % Channels x Frequencies

        bandNames = fieldnames(bands);
        for b = 1:length(bandNames)
            bandName = bandNames{b};
            bandRange = bands.(bandName);

            % Find frequency indices
            freqIdx = freqs >= bandRange(1) & freqs <= bandRange(2);

            % Compute mean power in band (across channels)
            bandPower = mean(psd(:, freqIdx), 2);  % Average across frequencies
            meanPower = mean(bandPower);  % Average across channels
            stdPower = std(bandPower);

            freqAnalysis.(bandName).meanPower = meanPower;
            freqAnalysis.(bandName).stdPower = stdPower;
            freqAnalysis.(bandName).channelPowers = bandPower;

            fprintf('    %s (%.1f-%.1f Hz): %.2f ± %.2f μV²/Hz\n', ...
                upper(bandName), bandRange(1), bandRange(2), meanPower, stdPower);
        end

        freqAnalysis.psd = psd;
        freqAnalysis.freqs = freqs;

        % Check if frequency bands are similar across channels
        fprintf('\n  Checking frequency consistency across channels...\n');
        for b = 1:length(bandNames)
            bandName = bandNames{b};
            cv = freqAnalysis.(bandName).stdPower / freqAnalysis.(bandName).meanPower;
            if cv < 0.5
                status = '✓ Consistent';
            else
                status = '⚠ Variable';
            end
            fprintf('    %s: %s (CV=%.2f)\n', upper(bandName), status, cv);
        end

    catch ME
        warning('Frequency analysis failed: %s', ME.message);
        freqAnalysis.error = ME.message;
    end
end

function generateVisualizations(epochedData, erpAnalysis, freqAnalysis, badChans, resultDir, timeWindow, EEG)
    % Generate comprehensive visualizations

    fprintf('  Creating figures...\n');

    %% Figure 1: ERP Waveforms with Component Markers
    fprintf('    - ERP waveforms with N250/N400/P600...\n');
    fig1 = figure('Position', [100, 100, 1400, 800], 'Visible', 'off');

    nConds = length(epochedData);
    nCols = ceil(sqrt(nConds));
    nRows = ceil(nConds / nCols);

    for i = 1:nConds
        subplot(nRows, nCols, i);

        if epochedData(i).numEpochs == 0
            continue;
        end

        % Plot global average ERP
        erp = mean(epochedData(i).avgERP, 1);
        timeVec = epochedData(i).timeVector;

        plot(timeVec * 1000, erp, 'LineWidth', 2, 'Color', [0.2, 0.4, 0.8]);
        hold on;

        % Mark component windows
        n250Win = [200, 300];
        n400Win = [300, 500];
        p600Win = [500, 800];

        yLim = ylim;

        % N250 window (green)
        patch([n250Win(1), n250Win(2), n250Win(2), n250Win(1)], ...
              [yLim(1), yLim(1), yLim(2), yLim(2)], ...
              [0.8, 1, 0.8], 'FaceAlpha', 0.2, 'EdgeColor', 'none');

        % N400 window (blue)
        patch([n400Win(1), n400Win(2), n400Win(2), n400Win(1)], ...
              [yLim(1), yLim(1), yLim(2), yLim(2)], ...
              [0.8, 0.9, 1], 'FaceAlpha', 0.2, 'EdgeColor', 'none');

        % P600 window (red)
        patch([p600Win(1), p600Win(2), p600Win(2), p600Win(1)], ...
              [yLim(1), yLim(1), yLim(2), yLim(2)], ...
              [1, 0.9, 0.9], 'FaceAlpha', 0.2, 'EdgeColor', 'none');

        % Re-plot ERP on top
        plot(timeVec * 1000, erp, 'LineWidth', 2, 'Color', [0.2, 0.4, 0.8]);

        % Mark peak latencies if available
        if i <= length(erpAnalysis)
            plot(erpAnalysis(i).n250.latency * 1000, erpAnalysis(i).n250.amplitude, ...
                'go', 'MarkerSize', 8, 'LineWidth', 2);
            plot(erpAnalysis(i).n400.latency * 1000, erpAnalysis(i).n400.amplitude, ...
                'bo', 'MarkerSize', 8, 'LineWidth', 2);
            plot(erpAnalysis(i).p600.latency * 1000, erpAnalysis(i).p600.amplitude, ...
                'ro', 'MarkerSize', 8, 'LineWidth', 2);
        end

        % Styling
        plot([0, 0], yLim, 'k--', 'LineWidth', 1);
        plot([timeVec(1)*1000, timeVec(end)*1000], [0, 0], 'k-', 'LineWidth', 0.5);

        xlabel('Time (ms)');
        ylabel('Amplitude (μV)');
        title(sprintf('%s (n=%d)', strrep(epochedData(i).eventType, '_', '\_'), ...
            epochedData(i).numEpochs));
        grid on;
        xlim([timeWindow(1)*1000, timeWindow(2)*1000]);
    end

    sgtitle('ERP Waveforms: N250 (green), N400 (blue), P600 (red)', 'FontSize', 14, 'FontWeight', 'bold');

    saveas(fig1, fullfile(resultDir, 'erp_waveforms.png'));
    close(fig1);

    %% Figure 2: Frequency Band Analysis
    fprintf('    - Frequency band power analysis...\n');
    fig2 = figure('Position', [100, 100, 1200, 600], 'Visible', 'off');

    subplot(1, 2, 1);
    if isfield(freqAnalysis, 'psd')
        % Plot PSD
        meanPSD = mean(freqAnalysis.psd, 1);
        semPSD = std(freqAnalysis.psd, 0, 1) / sqrt(size(freqAnalysis.psd, 1));

        plot(freqAnalysis.freqs, 10*log10(meanPSD), 'LineWidth', 2);
        hold on;
        fill([freqAnalysis.freqs; flipud(freqAnalysis.freqs)], ...
             [10*log10(meanPSD(:) + semPSD(:)); flipud(10*log10(meanPSD(:) - semPSD(:)))], ...
             [0.7, 0.7, 0.9], 'EdgeColor', 'none', 'FaceAlpha', 0.3);

        xlabel('Frequency (Hz)');
        ylabel('Power (dB)');
        title('Power Spectral Density');
        grid on;
        xlim([0.5, 50]);
    end

    subplot(1, 2, 2);
    if isfield(freqAnalysis, 'delta')
        % Bar plot of band powers
        bandNames = {'delta', 'theta', 'alpha', 'beta', 'gamma'};
        bandPowers = zeros(1, 5);
        bandStds = zeros(1, 5);

        for b = 1:5
            if isfield(freqAnalysis, bandNames{b})
                bandPowers(b) = freqAnalysis.(bandNames{b}).meanPower;
                bandStds(b) = freqAnalysis.(bandNames{b}).stdPower;
            end
        end

        bar(1:5, bandPowers, 'FaceColor', [0.3, 0.6, 0.9]);
        hold on;
        errorbar(1:5, bandPowers, bandStds, 'k.', 'LineWidth', 1.5);

        set(gca, 'XTick', 1:5, 'XTickLabel', {'Delta', 'Theta', 'Alpha', 'Beta', 'Gamma'});
        ylabel('Mean Power (μV²/Hz)');
        title('Frequency Band Power');
        grid on;
    end

    sgtitle('Frequency Analysis', 'FontSize', 14, 'FontWeight', 'bold');

    saveas(fig2, fullfile(resultDir, 'frequency_analysis.png'));
    close(fig2);

    %% Figure 3: Topographic maps at key timepoints
    fprintf('    - Topographic maps...\n');
    if ~isempty(EEG.chanlocs) && length(EEG.chanlocs) == size(epochedData(1).avgERP, 1)
        fig3 = figure('Position', [100, 100, 1400, 400], 'Visible', 'off');

        timepoints = [250, 400, 600];  % N250, N400, P600 timepoints (ms)

        for i = 1:min(3, length(epochedData))
            if epochedData(i).numEpochs == 0
                continue;
            end

            for t = 1:length(timepoints)
                subplot(min(3, length(epochedData)), length(timepoints), (i-1)*3 + t);

                % Find closest timepoint
                [~, tIdx] = min(abs(epochedData(i).timeVector * 1000 - timepoints(t)));
                topoData = epochedData(i).avgERP(:, tIdx);

                try
                    topoplot(topoData, EEG.chanlocs, 'maplimits', 'maxmin', 'electrodes', 'off');
                    title(sprintf('%s @ %d ms', strrep(epochedData(i).eventType, '_', '\_'), timepoints(t)));
                catch
                    text(0.5, 0.5, 'Topoplot unavailable', 'HorizontalAlignment', 'center');
                end
            end
        end

        sgtitle('Topographic Maps at Key Timepoints', 'FontSize', 14, 'FontWeight', 'bold');

        saveas(fig3, fullfile(resultDir, 'topographic_maps.png'));
        close(fig3);
    end

    fprintf('  ✓ Visualizations saved\n');
end

function printSummary(results)
    % Print comprehensive summary

    fprintf('\n========================================\n');
    fprintf('  ANALYSIS SUMMARY\n');
    fprintf('========================================\n\n');

    fprintf('File: %s\n', results.filename);
    fprintf('Event types detected: %d\n', length(results.eventTypes));
    fprintf('Total epochs: %d\n', sum([results.epochedData.numEpochs]));

    if ~isempty(results.badChannels)
        fprintf('Bad channels (kept): %d\n', length(results.badChannels));
    else
        fprintf('Bad channels: None\n');
    end

    fprintf('\nERP Components:\n');
    for i = 1:length(results.erpAnalysis)
        if results.erpAnalysis(i).numEpochs > 0
            fprintf('  %s:\n', results.erpAnalysis(i).condition);
            fprintf('    N250: %.2f μV @ %.0f ms\n', ...
                results.erpAnalysis(i).n250.amplitude, ...
                results.erpAnalysis(i).n250.latency * 1000);
            fprintf('    N400: %.2f μV @ %.0f ms\n', ...
                results.erpAnalysis(i).n400.amplitude, ...
                results.erpAnalysis(i).n400.latency * 1000);
            fprintf('    P600: %.2f μV @ %.0f ms\n', ...
                results.erpAnalysis(i).p600.amplitude, ...
                results.erpAnalysis(i).p600.latency * 1000);
        end
    end

    fprintf('\nFrequency Bands:\n');
    if isfield(results.freqAnalysis, 'delta')
        bandNames = {'delta', 'theta', 'alpha', 'beta', 'gamma'};
        for b = 1:length(bandNames)
            bandName = bandNames{b};
            if isfield(results.freqAnalysis, bandName)
                fprintf('  %s: %.2f ± %.2f μV²/Hz\n', ...
                    upper(bandName), ...
                    results.freqAnalysis.(bandName).meanPower, ...
                    results.freqAnalysis.(bandName).stdPower);
            end
        end
    end
end
