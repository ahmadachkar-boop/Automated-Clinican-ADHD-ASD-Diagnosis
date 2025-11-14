function clinical = computeClinicalMetrics(EEG_clean)
    % COMPUTECLINICALMETRICS - Compute clinical diagnostic markers from EEG
    %
    % Input:
    %   EEG_clean - Cleaned EEG structure
    %
    % Output:
    %   clinical - Structure containing:
    %     .theta_beta_ratio - Theta/beta ratio per channel
    %     .band_powers - Power in each frequency band per channel
    %     .frontal_theta_beta - Average theta/beta at frontal electrodes
    %     .hemispheric_asymmetry - Left vs right hemisphere metrics
    %     .clinical_markers_a - Clinical indicators (type A)
    %     .clinical_markers_b - Clinical indicators (type B)

    clinical = struct();

    fprintf('Computing clinical diagnostic metrics...\n');

    %% 1. COMPUTE BAND POWERS FOR ALL CHANNELS
    fs = EEG_clean.srate;
    n_channels = EEG_clean.nbchan;

    % Initialize band power arrays
    delta_power = zeros(1, n_channels);  % 0.5-4 Hz
    theta_power = zeros(1, n_channels);  % 4-8 Hz
    alpha_power = zeros(1, n_channels);  % 8-13 Hz
    beta_power = zeros(1, n_channels);   % 13-30 Hz
    gamma_power = zeros(1, n_channels);  % 30-50 Hz

    fprintf('  Computing frequency band powers for %d channels...\n', n_channels);

    for ch = 1:n_channels
        try
            % Get channel data
            channel_data = EEG_clean.data(ch, :);

            % Compute PSD using Welch's method
            [pxx, f] = pwelch(channel_data, hamming(fs*2), fs, fs*2, fs);

            % Extract power in each band
            delta_idx = f >= 0.5 & f <= 4;
            theta_idx = f >= 4 & f <= 8;
            alpha_idx = f >= 8 & f <= 13;
            beta_idx = f >= 13 & f <= 30;
            gamma_idx = f >= 30 & f <= 50;

            delta_power(ch) = mean(pxx(delta_idx));
            theta_power(ch) = mean(pxx(theta_idx));
            alpha_power(ch) = mean(pxx(alpha_idx));
            beta_power(ch) = mean(pxx(beta_idx));
            gamma_power(ch) = mean(pxx(gamma_idx));

        catch
            % Mark as NaN if computation fails
            delta_power(ch) = NaN;
            theta_power(ch) = NaN;
            alpha_power(ch) = NaN;
            beta_power(ch) = NaN;
            gamma_power(ch) = NaN;
        end
    end

    % Convert to microvolts squared
    delta_power = delta_power * 1e12;
    theta_power = theta_power * 1e12;
    alpha_power = alpha_power * 1e12;
    beta_power = beta_power * 1e12;
    gamma_power = gamma_power * 1e12;

    % Store band powers
    clinical.band_powers = struct(...
        'delta', delta_power, ...
        'theta', theta_power, ...
        'alpha', alpha_power, ...
        'beta', beta_power, ...
        'gamma', gamma_power);

    %% 2. COMPUTE THETA/BETA RATIO
    fprintf('  Computing theta/beta ratios...\n');

    % Avoid division by zero
    beta_power_safe = beta_power;
    beta_power_safe(beta_power_safe == 0) = eps;

    theta_beta_ratio = theta_power ./ beta_power_safe;
    clinical.theta_beta_ratio = theta_beta_ratio;

    %% 3. FRONTAL ELECTRODE ANALYSIS
    fprintf('  Analyzing frontal regions...\n');

    % Try to find frontal electrodes by name
    frontal_indices = [];
    frontal_names = {};

    if isfield(EEG_clean, 'chanlocs') && ~isempty(EEG_clean.chanlocs)
        % Look for common frontal electrode labels
        frontal_labels = {'Fz', 'F3', 'F4', 'Fp1', 'Fp2', 'F7', 'F8', 'AFz', 'AF3', 'AF4'};

        for i = 1:length(EEG_clean.chanlocs)
            if ~isempty(EEG_clean.chanlocs(i).labels)
                label = EEG_clean.chanlocs(i).labels;
                if any(strcmpi(frontal_labels, label))
                    frontal_indices(end+1) = i;
                    frontal_names{end+1} = label;
                end
            end
        end
    end

    % If no frontal electrodes found by name, use first 20% of channels
    if isempty(frontal_indices)
        frontal_indices = 1:max(1, round(n_channels * 0.2));
        frontal_names = arrayfun(@(x) sprintf('Ch%d', x), frontal_indices, 'UniformOutput', false);
        fprintf('    Warning: Using first %d channels as frontal approximation\n', length(frontal_indices));
    else
        fprintf('    Found %d frontal electrodes: %s\n', length(frontal_indices), strjoin(frontal_names, ', '));
    end

    clinical.frontal_indices = frontal_indices;
    clinical.frontal_names = frontal_names;

    % Compute average frontal theta/beta ratio
    frontal_theta_beta = theta_beta_ratio(frontal_indices);
    clinical.frontal_theta_beta_mean = mean(frontal_theta_beta(~isnan(frontal_theta_beta)));
    clinical.frontal_theta_beta_values = frontal_theta_beta;

    % Try to find Fz specifically (most diagnostic)
    fz_idx = [];
    if ~isempty(frontal_names)
        fz_idx = find(strcmpi(frontal_names, 'Fz'), 1);
        if ~isempty(fz_idx)
            clinical.fz_theta_beta = frontal_theta_beta(fz_idx);
            fprintf('    Fz theta/beta ratio: %.2f\n', clinical.fz_theta_beta);
        end
    end

    if isempty(fz_idx)
        clinical.fz_theta_beta = clinical.frontal_theta_beta_mean;
        fprintf('    Fz not found, using frontal average: %.2f\n', clinical.fz_theta_beta);
    end

    %% 4. HEMISPHERIC ASYMMETRY ANALYSIS
    fprintf('  Computing hemispheric asymmetry...\n');

    % Try to identify left and right hemisphere electrodes
    left_indices = [];
    right_indices = [];

    if isfield(EEG_clean, 'chanlocs') && ~isempty(EEG_clean.chanlocs) && ...
       isfield(EEG_clean.chanlocs, 'X')

        for i = 1:length(EEG_clean.chanlocs)
            if ~isempty(EEG_clean.chanlocs(i).Y)
                y_coord = EEG_clean.chanlocs(i).Y;
                % Y coordinate: positive = left, negative = right in standard orientation
                if y_coord > 0.1  % Left hemisphere
                    left_indices(end+1) = i;
                elseif y_coord < -0.1  % Right hemisphere
                    right_indices(end+1) = i;
                end
            end
        end
    end

    % If coordinate-based detection failed, use odd/even electrodes
    if isempty(left_indices) || isempty(right_indices)
        left_indices = 1:2:n_channels;  % Odd channels
        right_indices = 2:2:n_channels; % Even channels
        fprintf('    Warning: Using odd/even channels for hemispheric analysis\n');
    else
        fprintf('    Found %d left and %d right hemisphere electrodes\n', ...
            length(left_indices), length(right_indices));
    end

    clinical.left_indices = left_indices;
    clinical.right_indices = right_indices;

    % Compute hemispheric asymmetry for each band
    % Asymmetry Index: (Left - Right) / (Left + Right)
    for band = {'delta', 'theta', 'alpha', 'beta', 'gamma'}
        band_name = band{1};
        band_power = clinical.band_powers.(band_name);

        left_power = mean(band_power(left_indices), 'omitnan');
        right_power = mean(band_power(right_indices), 'omitnan');

        % Asymmetry index
        if (left_power + right_power) > 0
            asymmetry = (left_power - right_power) / (left_power + right_power);
        else
            asymmetry = 0;
        end

        clinical.hemispheric_asymmetry.(band_name) = struct(...
            'left_power', left_power, ...
            'right_power', right_power, ...
            'asymmetry_index', asymmetry);
    end

    %% 5. CLINICAL DIAGNOSTIC MARKERS (TYPE A)
    fprintf('  Evaluating clinical markers (type A)...\n');

    % Threshold values from literature (Snyder & Hall, 2006; Arns et al., 2013)
    threshold_high = 3.0;  % >3.0 indicates elevated
    threshold_low = 2.5;   % <2.5 normal

    % Frontal theta/beta evaluation
    if clinical.fz_theta_beta > threshold_high
        frontal_status = 'HIGH';
        frontal_flag = true;
    elseif clinical.fz_theta_beta > threshold_low
        frontal_status = 'ELEVATED';
        frontal_flag = true;
    else
        frontal_status = 'NORMAL';
        frontal_flag = false;
    end

    % Frontal theta power (relative to other bands)
    total_frontal_power = mean(delta_power(frontal_indices)) + ...
                          mean(theta_power(frontal_indices)) + ...
                          mean(alpha_power(frontal_indices)) + ...
                          mean(beta_power(frontal_indices)) + ...
                          mean(gamma_power(frontal_indices));

    frontal_theta_relative = mean(theta_power(frontal_indices)) / total_frontal_power;

    % Excess frontal theta (>30% is elevated)
    if frontal_theta_relative > 0.30
        theta_excess_status = 'HIGH';
        theta_excess_flag = true;
    else
        theta_excess_status = 'NORMAL';
        theta_excess_flag = false;
    end

    % Beta power deficiency
    frontal_beta_relative = mean(beta_power(frontal_indices)) / total_frontal_power;
    if frontal_beta_relative < 0.15
        beta_deficit_status = 'LOW';
        beta_deficit_flag = true;
    else
        beta_deficit_status = 'NORMAL';
        beta_deficit_flag = false;
    end

    clinical.clinical_markers_a = struct(...
        'theta_beta_ratio', clinical.fz_theta_beta, ...
        'theta_beta_status', frontal_status, ...
        'theta_beta_flag', frontal_flag, ...
        'frontal_theta_relative', frontal_theta_relative * 100, ...
        'theta_excess_status', theta_excess_status, ...
        'theta_excess_flag', theta_excess_flag, ...
        'frontal_beta_relative', frontal_beta_relative * 100, ...
        'beta_deficit_status', beta_deficit_status, ...
        'beta_deficit_flag', beta_deficit_flag);

    % Overall pattern likelihood (0-100%)
    pattern_score = 0;
    if frontal_flag
        pattern_score = pattern_score + 40;  % Theta/beta ratio most important
    end
    if theta_excess_flag
        pattern_score = pattern_score + 30;
    end
    if beta_deficit_flag
        pattern_score = pattern_score + 30;
    end

    clinical.clinical_markers_a.pattern_likelihood = min(100, pattern_score);

    fprintf('    Type A Pattern Likelihood: %d%%\n', clinical.clinical_markers_a.pattern_likelihood);

    %% 6. CLINICAL DIAGNOSTIC MARKERS (TYPE B)
    fprintf('  Evaluating clinical markers (type B)...\n');

    % Excess gamma (Wang et al., 2013)
    mean_gamma = mean(gamma_power, 'omitnan');
    gamma_relative = mean_gamma / mean([delta_power; theta_power; alpha_power; beta_power; gamma_power], 'all', 'omitnan');

    if gamma_relative > 0.20
        gamma_status = 'HIGH';
        gamma_flag = true;
    else
        gamma_status = 'NORMAL';
        gamma_flag = false;
    end

    % Reduced interhemispheric coherence (approximated by asymmetry)
    % High asymmetry suggests poor interhemispheric communication
    mean_asymmetry = mean(abs([...
        clinical.hemispheric_asymmetry.delta.asymmetry_index, ...
        clinical.hemispheric_asymmetry.theta.asymmetry_index, ...
        clinical.hemispheric_asymmetry.alpha.asymmetry_index]));

    if mean_asymmetry > 0.3
        coherence_status = 'REDUCED';
        coherence_flag = true;
    else
        coherence_status = 'NORMAL';
        coherence_flag = false;
    end

    clinical.clinical_markers_b = struct(...
        'gamma_power_relative', gamma_relative * 100, ...
        'gamma_status', gamma_status, ...
        'gamma_flag', gamma_flag, ...
        'hemispheric_asymmetry', mean_asymmetry, ...
        'coherence_status', coherence_status, ...
        'coherence_flag', coherence_flag);

    % Overall type B pattern likelihood
    pattern_score_b = 0;
    if gamma_flag
        pattern_score_b = pattern_score_b + 50;
    end
    if coherence_flag
        pattern_score_b = pattern_score_b + 50;
    end

    clinical.clinical_markers_b.pattern_likelihood = min(100, pattern_score_b);

    fprintf('    Type B Pattern Likelihood: %d%%\n', clinical.clinical_markers_b.pattern_likelihood);

    fprintf('✓ Clinical metrics computed\n\n');
end
