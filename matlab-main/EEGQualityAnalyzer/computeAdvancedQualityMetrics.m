function metrics = computeAdvancedQualityMetrics(EEG_original, EEG_clean)
    % COMPUTEADVANCEDQUALITYMETRICS - Comprehensive EEG quality assessment
    %
    % Inputs:
    %   EEG_original - Original EEG structure before processing
    %   EEG_clean    - Cleaned EEG structure after processing
    %
    % Output:
    %   metrics - Structure containing quality scores and metrics

    metrics = struct();

    %% 1. CHANNEL QUALITY (0-25 points)
    original_nbchan = EEG_original.nbchan;
    clean_nbchan = EEG_clean.nbchan;
    chan_retention = clean_nbchan / original_nbchan;

    metrics.channels_original = original_nbchan;
    metrics.channels_clean = clean_nbchan;
    metrics.channels_removed = original_nbchan - clean_nbchan;
    metrics.channel_retention = chan_retention;

    % Scoring: >95% = 25pts, 90-95% = 20pts, 80-90% = 15pts, <80% = 10pts
    if chan_retention > 0.95
        metrics.channel_score = 25;
    elseif chan_retention > 0.90
        metrics.channel_score = 20;
    elseif chan_retention > 0.80
        metrics.channel_score = 15;
    else
        metrics.channel_score = 10;
    end

    %% 2. ARTIFACT CONTAMINATION (0-30 points)
    if isfield(EEG_clean, 'icaweights') && ~isempty(EEG_clean.icaweights)
        total_comps = size(EEG_original.icaweights, 1);
        remaining_comps = size(EEG_clean.icaweights, 1);
        artifact_comps = total_comps - remaining_comps;

        metrics.total_components = total_comps;
        metrics.artifact_components = artifact_comps;
        metrics.artifact_ratio = artifact_comps / total_comps;

        % Classify artifact types if ICLabel data available
        if isfield(EEG_original, 'etc') && isfield(EEG_original.etc, 'ic_classification')
            classifications = EEG_original.etc.ic_classification.ICLabel.classifications;

            % Count high-confidence artifacts by type
            metrics.eye_artifacts = sum(classifications(:,3) > 0.9);
            metrics.muscle_artifacts = sum(classifications(:,2) > 0.9);
            metrics.heart_artifacts = sum(classifications(:,4) > 0.9);
            metrics.line_noise = sum(classifications(:,5) > 0.9);
        else
            metrics.eye_artifacts = 0;
            metrics.muscle_artifacts = 0;
            metrics.heart_artifacts = 0;
            metrics.line_noise = 0;
        end

        % Scoring: <10% = 30pts, 10-20% = 25pts, 20-30% = 20pts, >30% = 10pts
        if metrics.artifact_ratio < 0.10
            metrics.artifact_score = 30;
        elseif metrics.artifact_ratio < 0.20
            metrics.artifact_score = 25;
        elseif metrics.artifact_ratio < 0.30
            metrics.artifact_score = 20;
        else
            metrics.artifact_score = 10;
        end
    else
        % No ICA performed
        metrics.total_components = 0;
        metrics.artifact_components = 0;
        metrics.artifact_ratio = 0;
        metrics.artifact_score = 15; % Partial credit
    end

    %% 3. SIGNAL-TO-NOISE RATIO (0-25 points)
    % Calculate SNR from clean data
    signal_data = EEG_clean.data(:, :);

    % Remove baseline for better SNR estimation
    signal_data = signal_data - mean(signal_data, 2);

    % Calculate variance-based SNR
    signal_power = var(signal_data(:));
    metrics.signal_variance = signal_power;
    metrics.snr_db = 10 * log10(signal_power);

    % Calculate kurtosis (should be close to 3 for clean data)
    signal_kurt = kurtosis(signal_data(:));
    metrics.kurtosis = signal_kurt;

    % Scoring based on SNR
    if metrics.snr_db > 20
        metrics.signal_score = 25;
    elseif metrics.snr_db > 15
        metrics.signal_score = 20;
    elseif metrics.snr_db > 10
        metrics.signal_score = 15;
    else
        metrics.signal_score = 10;
    end

    %% 4. SPECTRAL QUALITY (0-20 points)
    % Analyze frequency spectrum
    try
        % Use first channel for spectral analysis (or average)
        sample_data = mean(EEG_clean.data, 1);
        fs = EEG_clean.srate;

        % Compute PSD using Welch's method
        [psd, freqs] = pwelch(sample_data, hamming(fs*2), fs, fs*2, fs);

        % Find peaks in canonical bands
        delta_idx = freqs >= 0.5 & freqs <= 4;
        theta_idx = freqs >= 4 & freqs <= 8;
        alpha_idx = freqs >= 8 & freqs <= 13;
        beta_idx = freqs >= 13 & freqs <= 30;
        gamma_idx = freqs >= 30 & freqs <= 50;

        metrics.delta_power = mean(psd(delta_idx));
        metrics.theta_power = mean(psd(theta_idx));
        metrics.alpha_power = mean(psd(alpha_idx));
        metrics.beta_power = mean(psd(beta_idx));
        metrics.gamma_power = mean(psd(gamma_idx));

        % Total power
        total_power = sum(psd);

        % Relative band powers
        metrics.delta_relative = metrics.delta_power / total_power;
        metrics.theta_relative = metrics.theta_power / total_power;
        metrics.alpha_relative = metrics.alpha_power / total_power;
        metrics.beta_relative = metrics.beta_power / total_power;
        metrics.gamma_relative = metrics.gamma_power / total_power;

        % Check for line noise contamination (should be minimal at 60Hz)
        hz60_idx = freqs >= 58 & freqs <= 62;
        line_noise_power = mean(psd(hz60_idx));
        metrics.line_noise_power = line_noise_power;
        metrics.line_noise_ratio = line_noise_power / total_power;

        % Quality score based on spectral features
        spectral_score = 20;

        % Penalize if excessive line noise
        if metrics.line_noise_ratio > 0.1
            spectral_score = spectral_score - 5;
        end

        % Reward if clear alpha peak (healthy resting EEG)
        if metrics.alpha_relative > 0.2
            spectral_score = min(20, spectral_score + 2);
        end

        % Penalize if excessive high-frequency noise
        if metrics.gamma_relative > 0.3
            spectral_score = spectral_score - 3;
        end

        metrics.spectral_score = max(0, spectral_score);

        % Store PSD for visualization
        metrics.psd = psd;
        metrics.psd_freqs = freqs;

    catch ME
        % If spectral analysis fails
        metrics.spectral_score = 10;
        metrics.alpha_power = 0;
        warning('Spectral analysis failed: %s', ME.message);
    end

    %% 5. OVERALL QUALITY SCORE (0-100)
    metrics.total_score = round(metrics.channel_score + metrics.artifact_score + ...
                                metrics.signal_score + metrics.spectral_score);

    % Ensure score is within 0-100
    metrics.total_score = max(0, min(100, metrics.total_score));

    %% 6. QUALITY CLASSIFICATION
    % Thresholds for clinical use
    if metrics.total_score >= 75
        metrics.quality_level = 'Excellent';
        metrics.is_clean = true;
    elseif metrics.total_score >= 60
        metrics.quality_level = 'Good';
        metrics.is_clean = true;
    elseif metrics.total_score >= 45
        metrics.quality_level = 'Fair';
        metrics.is_clean = false;
    else
        metrics.quality_level = 'Poor';
        metrics.is_clean = false;
    end

    %% 7. DOMINANT NOISE SOURCES
    noise_sources = {};

    if metrics.channels_removed > original_nbchan * 0.15
        noise_sources{end+1} = 'Excessive bad channels';
    end

    if metrics.artifact_ratio > 0.25
        noise_sources{end+1} = 'High artifact contamination';
    end

    if metrics.eye_artifacts > 3
        noise_sources{end+1} = 'Eye movement artifacts';
    end

    if metrics.muscle_artifacts > 5
        noise_sources{end+1} = 'Muscle tension artifacts';
    end

    if metrics.line_noise_ratio > 0.05
        noise_sources{end+1} = 'Electrical line noise';
    end

    if metrics.snr_db < 12
        noise_sources{end+1} = 'Low signal-to-noise ratio';
    end

    metrics.noise_sources = noise_sources;

    %% 8. RECOMMENDATIONS
    recommendations = {};

    if ~metrics.is_clean
        recommendations{end+1} = 'Recording quality insufficient for reliable analysis';

        if metrics.channels_removed > original_nbchan * 0.15
            recommendations{end+1} = 'Check electrode impedances before recording';
        end

        if metrics.artifact_ratio > 0.3
            recommendations{end+1} = 'Instruct patient to minimize movement and stay relaxed';
        end

        if metrics.eye_artifacts > 5
            recommendations{end+1} = 'Consider eyes-closed protocol to reduce eye artifacts';
        end
    else
        recommendations{end+1} = 'Data quality acceptable for clinical interpretation';
    end

    metrics.recommendations = recommendations;

    %% 9. RECORDING METADATA
    metrics.duration = EEG_clean.xmax; % Duration in seconds

end
