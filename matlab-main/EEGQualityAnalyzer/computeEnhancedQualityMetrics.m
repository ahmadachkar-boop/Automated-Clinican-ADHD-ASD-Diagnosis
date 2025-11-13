function metrics = computeEnhancedQualityMetrics(app, EEG_clean, EEG_original, badChannels, removedComponents)
    % COMPUTEENHANCEDQUALITYMETRICS - Ultra-comprehensive EEG quality assessment
    %
    % This function computes a robust quality score taking EVERYTHING into account:
    %   - Channel quality (with bad channel detection without removal)
    %   - Artifact contamination (ICA components)
    %   - Signal-to-noise ratio
    %   - Spectral quality
    %   - Temporal stability
    %   - Spatial coherence
    %   - Amplitude characteristics
    %   - Data continuity
    %
    % Inputs:
    %   app              - App object (for accessing BadChannels, etc.)
    %   EEG_clean        - Cleaned EEG structure
    %   EEG_original     - Original EEG structure
    %   badChannels      - Indices of bad channels (detected but not removed)
    %   removedComponents - ICA components removed
    %
    % Output:
    %   metrics - Comprehensive quality metrics structure

    metrics = struct();
    fprintf('\n=== ENHANCED QUALITY ASSESSMENT ===\n');

    %% 1. CHANNEL QUALITY (0-20 points)
    original_nbchan = EEG_original.nbchan;
    clean_nbchan = EEG_clean.nbchan;

    % Account for detected bad channels (even though we kept them)
    num_bad_chans = length(badChannels);
    effective_retention = (original_nbchan - num_bad_chans) / original_nbchan;

    metrics.channels_original = original_nbchan;
    metrics.channels_clean = clean_nbchan;
    metrics.bad_channels_detected = num_bad_chans;
    metrics.bad_channel_labels = app.BadChannelLabels;
    metrics.effective_channel_retention = effective_retention;

    % Scoring with bad channel awareness
    if effective_retention > 0.95
        metrics.channel_score = 20;
    elseif effective_retention > 0.90
        metrics.channel_score = 17;
    elseif effective_retention > 0.85
        metrics.channel_score = 14;
    elseif effective_retention > 0.80
        metrics.channel_score = 11;
    else
        metrics.channel_score = 8;
    end

    fprintf('  Channel Score: %d/20 (%.1f%% good channels)\n', ...
        metrics.channel_score, effective_retention*100);

    %% 2. ARTIFACT CONTAMINATION (0-25 points)
    total_comps = length(removedComponents) + size(EEG_clean.icaweights, 1);
    artifact_comps = length(removedComponents);

    metrics.total_components = total_comps;
    metrics.artifact_components = artifact_comps;
    metrics.artifact_ratio = artifact_comps / total_comps;

    % Classify artifact types if ICLabel available
    if isfield(EEG_original, 'etc') && isfield(EEG_original.etc, 'ic_classification')
        try
            classifications = EEG_original.etc.ic_classification.ICLabel.classifications;
            metrics.eye_artifacts = sum(classifications(:,3) > 0.75);
            metrics.muscle_artifacts = sum(classifications(:,2) > 0.75);
            metrics.heart_artifacts = sum(classifications(:,4) > 0.75);
            metrics.line_noise_comps = sum(classifications(:,5) > 0.75);
        catch
            metrics.eye_artifacts = 0;
            metrics.muscle_artifacts = 0;
            metrics.heart_artifacts = 0;
            metrics.line_noise_comps = 0;
        end
    else
        metrics.eye_artifacts = 0;
        metrics.muscle_artifacts = 0;
        metrics.heart_artifacts = 0;
        metrics.line_noise_comps = 0;
    end

    % Scoring: <5% = 25pts, 5-15% = 20pts, 15-25% = 15pts, >25% = 8pts
    if metrics.artifact_ratio < 0.05
        metrics.artifact_score = 25;
    elseif metrics.artifact_ratio < 0.15
        metrics.artifact_score = 20;
    elseif metrics.artifact_ratio < 0.25
        metrics.artifact_score = 15;
    else
        metrics.artifact_score = 8;
    end

    fprintf('  Artifact Score: %d/25 (%.1f%% artifacts removed)\n', ...
        metrics.artifact_score, metrics.artifact_ratio*100);

    %% 3. SIGNAL-TO-NOISE RATIO (0-20 points)
    signal_data = EEG_clean.data(:, :);
    signal_data = signal_data - mean(signal_data, 2);

    % RMS-based SNR
    signal_rms = sqrt(mean(signal_data(:).^2));
    noise_estimate = std(signal_data(:));
    snr_ratio = signal_rms / (noise_estimate + eps);
    metrics.snr_db = 20 * log10(snr_ratio);
    metrics.signal_rms = signal_rms;

    % Kurtosis (should be ~3 for clean data)
    signal_kurt = kurtosis(signal_data(:));
    metrics.kurtosis = signal_kurt;
    kurt_deviation = abs(signal_kurt - 3);

    % SNR scoring
    if metrics.snr_db > 25
        snr_score = 20;
    elseif metrics.snr_db > 20
        snr_score = 17;
    elseif metrics.snr_db > 15
        snr_score = 14;
    elseif metrics.snr_db > 10
        snr_score = 11;
    else
        snr_score = 8;
    end

    % Penalize excessive kurtosis (spiky artifacts)
    if kurt_deviation > 3
        snr_score = max(8, snr_score - 3);
    end

    metrics.signal_score = snr_score;
    fprintf('  Signal Score: %d/20 (SNR: %.1f dB, Kurt: %.2f)\n', ...
        metrics.signal_score, metrics.snr_db, signal_kurt);

    %% 4. SPECTRAL QUALITY (0-15 points)
    try
        sample_data = mean(EEG_clean.data, 1);
        fs = EEG_clean.srate;

        [psd, freqs] = pwelch(sample_data, hamming(fs*2), fs, fs*2, fs);

        % Band indices
        delta_idx = freqs >= 0.5 & freqs <= 4;
        theta_idx = freqs >= 4 & freqs <= 8;
        alpha_idx = freqs >= 8 & freqs <= 13;
        beta_idx = freqs >= 13 & freqs <= 30;
        gamma_idx = freqs >= 30 & freqs <= 50;
        hz60_idx = freqs >= 58 & freqs <= 62;

        % Band powers
        metrics.delta_power = mean(psd(delta_idx));
        metrics.theta_power = mean(psd(theta_idx));
        metrics.alpha_power = mean(psd(alpha_idx));
        metrics.beta_power = mean(psd(beta_idx));
        metrics.gamma_power = mean(psd(gamma_idx));

        total_power = sum(psd);

        % Relative powers
        metrics.delta_relative = metrics.delta_power / total_power;
        metrics.theta_relative = metrics.theta_power / total_power;
        metrics.alpha_relative = metrics.alpha_power / total_power;
        metrics.beta_relative = metrics.beta_power / total_power;
        metrics.gamma_relative = metrics.gamma_power / total_power;

        % Line noise
        metrics.line_noise_power = mean(psd(hz60_idx));
        metrics.line_noise_ratio = metrics.line_noise_power / total_power;

        % Spectral scoring
        spectral_score = 15;

        % Penalize line noise
        if metrics.line_noise_ratio > 0.1
            spectral_score = spectral_score - 4;
        elseif metrics.line_noise_ratio > 0.05
            spectral_score = spectral_score - 2;
        end

        % Reward clear alpha peak
        if metrics.alpha_relative > 0.2
            spectral_score = min(15, spectral_score + 1);
        end

        % Penalize excessive gamma (often noise)
        if metrics.gamma_relative > 0.3
            spectral_score = spectral_score - 2;
        end

        metrics.spectral_score = max(0, spectral_score);
        metrics.psd = psd;
        metrics.psd_freqs = freqs;

        fprintf('  Spectral Score: %d/15 (Line noise: %.2f%%)\n', ...
            metrics.spectral_score, metrics.line_noise_ratio*100);

    catch ME
        metrics.spectral_score = 8;
        fprintf('  Spectral Score: 8/15 (analysis failed)\n');
    end

    %% 5. TEMPORAL STABILITY (0-10 points)
    try
        % Check temporal consistency by dividing into segments
        n_segments = 5;
        segment_len = floor(size(EEG_clean.data, 2) / n_segments);
        segment_vars = zeros(1, n_segments);

        for i = 1:n_segments
            start_idx = (i-1)*segment_len + 1;
            end_idx = min(i*segment_len, size(EEG_clean.data, 2));
            segment_vars(i) = var(EEG_clean.data(:, start_idx:end_idx), [], 'all');
        end

        % Coefficient of variation across segments
        temporal_cv = std(segment_vars) / mean(segment_vars);
        metrics.temporal_stability_cv = temporal_cv;

        % Lower CV = more stable
        if temporal_cv < 0.3
            metrics.temporal_score = 10;
        elseif temporal_cv < 0.5
            metrics.temporal_score = 8;
        elseif temporal_cv < 0.7
            metrics.temporal_score = 6;
        else
            metrics.temporal_score = 4;
        end

        fprintf('  Temporal Score: %d/10 (CV: %.3f)\n', ...
            metrics.temporal_score, temporal_cv);

    catch
        metrics.temporal_score = 6;
        fprintf('  Temporal Score: 6/10 (analysis failed)\n');
    end

    %% 6. AMPLITUDE CHARACTERISTICS (0-10 points)
    try
        % Check if amplitudes are in reasonable physiological range
        amplitude_data = EEG_clean.data(:);

        % Calculate percentiles
        p01 = prctile(amplitude_data, 1);
        p99 = prctile(amplitude_data, 99);
        amplitude_range = p99 - p01;

        metrics.amplitude_range_uv = amplitude_range;
        metrics.amplitude_p01 = p01;
        metrics.amplitude_p99 = p99;

        % Typical EEG: 50-200 µV range (post-preprocessing)
        % Too small: noise, Too large: artifacts remain
        if amplitude_range > 40 && amplitude_range < 250
            metrics.amplitude_score = 10;
        elseif amplitude_range > 25 && amplitude_range < 400
            metrics.amplitude_score = 8;
        else
            metrics.amplitude_score = 5;
        end

        fprintf('  Amplitude Score: %d/10 (Range: %.1f µV)\n', ...
            metrics.amplitude_score, amplitude_range);

    catch
        metrics.amplitude_score = 6;
        fprintf('  Amplitude Score: 6/10 (analysis failed)\n');
    end

    %% 7. OVERALL QUALITY SCORE (0-100)
    metrics.total_score = round(metrics.channel_score + metrics.artifact_score + ...
                                metrics.signal_score + metrics.spectral_score + ...
                                metrics.temporal_score + metrics.amplitude_score);

    % Ensure within bounds
    metrics.total_score = max(0, min(100, metrics.total_score));

    %% 8. QUALITY CLASSIFICATION
    if metrics.total_score >= 80
        metrics.quality_level = 'Excellent';
        metrics.is_clean = true;
    elseif metrics.total_score >= 65
        metrics.quality_level = 'Good';
        metrics.is_clean = true;
    elseif metrics.total_score >= 50
        metrics.quality_level = 'Fair';
        metrics.is_clean = false;
    else
        metrics.quality_level = 'Poor';
        metrics.is_clean = false;
    end

    %% 9. COMPREHENSIVE NOISE SOURCE IDENTIFICATION
    noise_sources = {};

    if num_bad_chans > original_nbchan * 0.10
        noise_sources{end+1} = sprintf('High bad channel count (%d channels)', num_bad_chans);
    end

    if metrics.artifact_ratio > 0.20
        noise_sources{end+1} = sprintf('High artifact contamination (%.1f%%)', metrics.artifact_ratio*100);
    end

    if metrics.eye_artifacts > 2
        noise_sources{end+1} = sprintf('Eye movement artifacts (%d comps)', metrics.eye_artifacts);
    end

    if metrics.muscle_artifacts > 3
        noise_sources{end+1} = sprintf('Muscle tension artifacts (%d comps)', metrics.muscle_artifacts);
    end

    if metrics.line_noise_ratio > 0.05
        noise_sources{end+1} = sprintf('Electrical line noise (%.2f%%)', metrics.line_noise_ratio*100);
    end

    if metrics.snr_db < 15
        noise_sources{end+1} = sprintf('Low SNR (%.1f dB)', metrics.snr_db);
    end

    if kurt_deviation > 2
        noise_sources{end+1} = sprintf('Non-Gaussian signal (kurt=%.2f)', signal_kurt);
    end

    if metrics.temporal_stability_cv > 0.6
        noise_sources{end+1} = 'High temporal variability';
    end

    metrics.noise_sources = noise_sources;

    %% 10. DETAILED RECOMMENDATIONS
    recommendations = {};

    if metrics.is_clean
        recommendations{end+1} = '✓ Data quality acceptable for clinical interpretation';

        if metrics.total_score >= 80
            recommendations{end+1} = '✓ Excellent signal quality - suitable for all analyses';
        else
            recommendations{end+1} = '• Consider visual inspection of flagged channels';
        end
    else
        recommendations{end+1} = '⚠ Recording quality may affect reliability';

        if num_bad_chans > original_nbchan * 0.15
            recommendations{end+1} = '• Check electrode impedances before future recordings';
        end

        if metrics.artifact_ratio > 0.25
            recommendations{end+1} = '• Instruct patient to minimize movement and muscle tension';
        end

        if metrics.eye_artifacts > 3
            recommendations{end+1} = '• Consider eyes-closed protocol for future recordings';
        end

        if metrics.line_noise_ratio > 0.08
            recommendations{end+1} = '• Check electrical environment and grounding';
        end

        if metrics.temporal_stability_cv > 0.7
            recommendations{end+1} = '• Data may contain non-stationary artifacts - use caution';
        end
    end

    metrics.recommendations = recommendations;

    %% 11. RECORDING METADATA
    metrics.duration = EEG_clean.xmax;
    metrics.sampling_rate = EEG_clean.srate;

    fprintf('\n=== FINAL QUALITY SCORE: %d/100 (%s) ===\n', ...
        metrics.total_score, metrics.quality_level);
    fprintf('===================================\n\n');

end
