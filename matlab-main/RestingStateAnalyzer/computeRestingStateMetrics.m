function metrics = computeRestingStateMetrics(segmentData)
    % Compute resting state metrics including band powers for each condition
    % Analyzes differences between conditions (e.g., eyes open vs closed)
    %
    % Input:
    %   segmentData - Structure array from extractRestingSegments
    %
    % Output:
    %   metrics - Structure with band power analysis per condition

    fprintf('\n=== Computing Resting State Metrics ===\n');

    if isempty(segmentData)
        warning('No segment data provided');
        metrics = struct();
        return;
    end

    % Define frequency bands (conservative definitions for resting state)
    bands = struct();
    bands.delta = [2 4];    % Narrower delta (excludes very slow oscillations 1-2 Hz)
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

    % Process each condition
    for condIdx = 1:length(conditions)
        cond = conditions{condIdx};
        fprintf('\nProcessing condition: %s\n', cond);

        % Get all segments for this condition
        condMask = strcmp({segmentData.condition}, cond);
        condSegments = segmentData(condMask);

        fprintf('  Found %d segments\n', length(condSegments));

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

        % Storage for per-channel band powers (for topographic maps)
        % Format: perChannelPowers.bandName = [nChannels x nSegments]
        perChannelPowers = struct();
        for b = 1:length(bandNames)
            perChannelPowers.(bandNames{b}) = [];
        end

        % Process each segment
        for segIdx = 1:length(condSegments)
            seg = condSegments(segIdx);

            % Detrend data to remove any residual linear drift
            detrendedData = detrend(seg.data', 'linear')';

            % Compute PSD using pwelch
            % Average across channels for overall analysis
            windowLength = min(seg.srate * 2, size(detrendedData, 2));  % 2-second window
            noverlap = floor(windowLength / 2);
            nfft = max(512, 2^nextpow2(windowLength));  % Higher NFFT for better frequency resolution

            % Compute PSD for each channel and average
            psdSum = zeros(nfft/2 + 1, 1);
            psdPerChannel = zeros(seg.nbchan, nfft/2 + 1);  % Store per-channel PSDs

            for ch = 1:seg.nbchan
                [psd, freqs] = pwelch(detrendedData(ch, :), windowLength, noverlap, nfft, seg.srate);
                psdPerChannel(ch, :) = psd;
                psdSum = psdSum + psd;
            end
            psdAvg = psdSum / seg.nbchan;

            % Compute total power in analysis range (1-50 Hz) to exclude low-frequency drift
            analysisRange = freqs >= 1 & freqs <= 50;
            totalPower = trapz(freqs(analysisRange), psdAvg(analysisRange));

            % Compute band powers (averaged across channels)
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

            % Compute per-channel band powers for topographic maps
            segPerChannelBandPowers = struct();
            for b = 1:length(bandNames)
                bandName = bandNames{b};
                bandRange = bands.(bandName);
                freqIdx = freqs >= bandRange(1) & freqs <= bandRange(2);

                % Compute band power for each channel
                channelBandPowers = zeros(seg.nbchan, 1);
                for ch = 1:seg.nbchan
                    channelBandPowers(ch) = trapz(freqs(freqIdx), psdPerChannel(ch, freqIdx));
                end
                segPerChannelBandPowers.(bandName) = channelBandPowers;
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

            % Store per-channel band powers for this segment
            for b = 1:length(bandNames)
                bandName = bandNames{b};
                if isempty(perChannelPowers.(bandName))
                    perChannelPowers.(bandName) = segPerChannelBandPowers.(bandName);
                else
                    perChannelPowers.(bandName) = [perChannelPowers.(bandName), segPerChannelBandPowers.(bandName)];
                end
            end
        end

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

        % Store per-channel band powers (for topographic maps)
        % Format: perChannel.bandName = [nChannels x nSegments]
        condMetrics.perChannel = struct();
        for b = 1:length(bandNames)
            bandName = bandNames{b};
            condMetrics.perChannel.(bandName) = perChannelPowers.(bandName);
        end

        fprintf('  Per-channel data: %d channels x %d segments\n', ...
            size(perChannelPowers.(bandNames{1}), 1), ...
            size(perChannelPowers.(bandNames{1}), 2));

        % Store in metrics
        metrics.(cond) = condMetrics;

        % Print summary
        fprintf('  Band Powers (Relative %%):   <signal-to-noise ratio>')
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

    fprintf('\n=== Resting State Analysis Complete ===\n');
end
