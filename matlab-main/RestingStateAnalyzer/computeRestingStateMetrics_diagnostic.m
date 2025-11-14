function metrics = computeRestingStateMetrics_diagnostic(segmentData)
    % DIAGNOSTIC VERSION - Shows PSD plots and detailed frequency analysis
    % This helps identify why delta is so high

    fprintf('\n=== DIAGNOSTIC: Computing Resting State Metrics ===\n');

    if isempty(segmentData)
        warning('No segment data provided');
        metrics = struct();
        return;
    end

    % Define frequency bands
    bands = struct();
    bands.delta = [1 4];
    bands.theta = [4 8];
    bands.alpha = [8 13];
    bands.beta = [13 30];
    bands.gamma = [30 50];

    bandNames = {'delta', 'theta', 'alpha', 'beta', 'gamma'};

    % Get unique conditions
    conditions = unique({segmentData.condition});
    fprintf('Analyzing %d conditions: %s\n', length(conditions), strjoin(conditions, ', '));

    % Initialize metrics structure
    metrics = struct();
    metrics.conditions = conditions;
    metrics.bands = bands;
    metrics.bandNames = bandNames;

    % Create diagnostic figure
    diagFig = figure('Name', 'Diagnostic PSD Analysis', 'Position', [100 100 1400 800]);

    % Process each condition
    for condIdx = 1:length(conditions)
        cond = conditions{condIdx};
        fprintf('\n=== DIAGNOSTIC: Processing condition: %s ===\n', cond);

        % Get all segments for this condition
        condMask = strcmp({segmentData.condition}, cond);
        condSegments = segmentData(condMask);

        fprintf('  Found %d segments\n', length(condSegments));

        % Storage for PSDs
        allPSDs = [];
        allFreqs = [];

        % Initialize storage for this condition
        condMetrics = struct();
        condMetrics.numSegments = length(condSegments);
        condMetrics.totalDuration = sum([condSegments.duration]);
        condMetrics.meanDuration = mean([condSegments.duration]);

        % Storage for band powers across segments
        allAbsolutePowers = struct();
        allRelativePowers = struct();
        for b = 1:length(bandNames)
            allAbsolutePowers.(bandNames{b}) = [];
            allRelativePowers.(bandNames{b}) = [];
        end

        % Process each segment
        for segIdx = 1:length(condSegments)
            seg = condSegments(segIdx);

            % Detrend data to remove slow drifts
            detrendedData = detrend(seg.data', 'linear')';

            % Compute PSD using pwelch
            windowLength = min(seg.srate * 2, size(detrendedData, 2));  % 2-second window
            noverlap = floor(windowLength / 2);
            nfft = max(512, 2^nextpow2(windowLength));  % Increased NFFT for better frequency resolution

            % Compute PSD for each channel and average
            psdSum = zeros(nfft/2 + 1, 1);
            for ch = 1:seg.nbchan
                [psd, freqs] = pwelch(detrendedData(ch, :), windowLength, noverlap, nfft, seg.srate);
                psdSum = psdSum + psd;
            end
            psdAvg = psdSum / seg.nbchan;

            % Store for averaging
            if isempty(allPSDs)
                allPSDs = psdAvg;
                allFreqs = freqs;
            else
                allPSDs(:, end+1) = psdAvg;
            end

            % Compute total power in analysis range (1-50 Hz)
            analysisRange = freqs >= 1 & freqs <= 50;
            totalPower = trapz(freqs(analysisRange), psdAvg(analysisRange));

            % DIAGNOSTIC: Check power in sub-bands
            if segIdx == 1
                fprintf('\n  DIAGNOSTIC - First segment frequency breakdown:\n');
                freqRanges = [0.5 1; 1 2; 2 4; 4 8; 8 13; 13 30; 30 50];
                freqLabels = {'0.5-1 Hz', '1-2 Hz', '2-4 Hz', '4-8 Hz', '8-13 Hz', '13-30 Hz', '30-50 Hz'};
                for fr = 1:size(freqRanges, 1)
                    fIdx = freqs >= freqRanges(fr, 1) & freqs <= freqRanges(fr, 2);
                    power = trapz(freqs(fIdx), psdAvg(fIdx));
                    pct = (power / totalPower) * 100;
                    fprintf('    %s: %.2f%%\n', freqLabels{fr}, pct);
                end
            end

            % Compute band powers
            segBandPowers = struct();

            for b = 1:length(bandNames)
                bandName = bandNames{b};
                bandRange = bands.(bandName);

                % Find frequency indices for this band
                freqIdx = freqs >= bandRange(1) & freqs <= bandRange(2);

                % Integrate power in this band (absolute power)
                bandPower = trapz(freqs(freqIdx), psdAvg(freqIdx));
                segBandPowers.(bandName) = bandPower;
            end

            % Compute relative powers for this segment
            for b = 1:length(bandNames)
                bandName = bandNames{b};
                absolutePower = segBandPowers.(bandName);
                relativePower = (absolutePower / totalPower) * 100;  % Percentage

                % Store
                allAbsolutePowers.(bandName)(end+1) = absolutePower;
                allRelativePowers.(bandName)(end+1) = relativePower;
            end
        end

        % Average PSD across all segments for this condition
        meanPSD = mean(allPSDs, 2);

        % Plot PSD
        subplot(2, length(conditions), condIdx);
        semilogy(allFreqs, meanPSD, 'LineWidth', 2);
        hold on;

        % Highlight frequency bands
        ylims = ylim;
        colors = {[0.8 0.2 0.2], [0.2 0.8 0.2], [0.2 0.2 0.8], [0.8 0.8 0.2], [0.8 0.2 0.8]};
        for b = 1:length(bandNames)
            bandRange = bands.(bandNames{b});
            patch([bandRange(1) bandRange(2) bandRange(2) bandRange(1)], ...
                  [ylims(1) ylims(1) ylims(2) ylims(2)], ...
                  colors{b}, 'FaceAlpha', 0.2, 'EdgeColor', 'none');
        end

        xlabel('Frequency (Hz)');
        ylabel('Power Spectral Density (µV²/Hz)');
        title(sprintf('%s - Mean PSD', cond));
        xlim([0 50]);
        grid on;
        legend({'PSD', 'Delta', 'Theta', 'Alpha', 'Beta', 'Gamma'}, 'Location', 'best');

        % Plot relative band powers
        subplot(2, length(conditions), length(conditions) + condIdx);
        relPowers = zeros(1, length(bandNames));
        for b = 1:length(bandNames)
            relPowers(b) = mean(allRelativePowers.(bandNames{b}));
        end
        bar(relPowers);
        set(gca, 'XTickLabel', cellfun(@upper, bandNames, 'UniformOutput', false));
        ylabel('Relative Power (%)');
        title(sprintf('%s - Band Powers', cond));
        grid on;
        ylim([0 max(relPowers)*1.2]);

        % Compute statistics across segments for this condition
        condMetrics.absolute = struct();
        condMetrics.relative = struct();

        for b = 1:length(bandNames)
            bandName = bandNames{b};

            % Absolute power statistics
            condMetrics.absolute.(bandName) = struct();
            condMetrics.absolute.(bandName).mean = mean(allAbsolutePowers.(bandName));
            condMetrics.absolute.(bandName).std = std(allAbsolutePowers.(bandName));
            condMetrics.absolute.(bandName).median = median(allAbsolutePowers.(bandName));

            % Relative power statistics
            condMetrics.relative.(bandName) = struct();
            condMetrics.relative.(bandName).mean = mean(allRelativePowers.(bandName));
            condMetrics.relative.(bandName).std = std(allRelativePowers.(bandName));
            condMetrics.relative.(bandName).median = median(allRelativePowers.(bandName));
        end

        % Store in metrics
        metrics.(cond) = condMetrics;

        % Print summary
        fprintf('\n  Band Powers (Relative %%):\n');
        for b = 1:length(bandNames)
            bandName = bandNames{b};
            fprintf('    %s: %.2f%% ± %.2f%%\n', ...
                upper(bandName), ...
                condMetrics.relative.(bandName).mean, ...
                condMetrics.relative.(bandName).std);
        end
    end

    % Compute condition comparisons if we have exactly 2 conditions
    if length(conditions) == 2
        fprintf('\n=== Comparing Conditions: %s vs %s ===\n', conditions{1}, conditions{2});

        cond1 = conditions{1};
        cond2 = conditions{2};

        metrics.comparison = struct();
        metrics.comparison.condition1 = cond1;
        metrics.comparison.condition2 = cond2;

        for b = 1:length(bandNames)
            bandName = bandNames{b};

            % Relative power difference (cond1 - cond2)
            rel1 = metrics.(cond1).relative.(bandName).mean;
            rel2 = metrics.(cond2).relative.(bandName).mean;
            relDiff = rel1 - rel2;

            % Absolute power difference
            abs1 = metrics.(cond1).absolute.(bandName).mean;
            abs2 = metrics.(cond2).absolute.(bandName).mean;
            absDiff = abs1 - abs2;

            metrics.comparison.(bandName) = struct();
            metrics.comparison.(bandName).relativeDiff = relDiff;
            metrics.comparison.(bandName).absoluteDiff = absDiff;

            fprintf('  %s: %.2f%% (%s) vs %.2f%% (%s) → Diff: %+.2f%%\n', ...
                upper(bandName), rel1, cond1, rel2, cond2, relDiff);
        end
    end

    fprintf('\n=== DIAGNOSTIC Analysis Complete ===\n');
    fprintf('CHECK THE DIAGNOSTIC FIGURE for PSD plots!\n\n');
end
