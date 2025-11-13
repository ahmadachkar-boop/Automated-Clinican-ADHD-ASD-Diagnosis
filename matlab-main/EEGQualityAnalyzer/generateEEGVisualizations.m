function generateEEGVisualizations(EEG_clean, metrics, topoAx, psdAx, signalAx)
    % GENERATEEEGVISUALIZATIONS - Create clinical-friendly EEG visualizations
    %
    % Inputs:
    %   EEG_clean - Cleaned EEG structure
    %   metrics   - Quality metrics structure
    %   topoAx    - UIAxes for topographic map
    %   psdAx     - UIAxes for power spectral density
    %   signalAx  - UIAxes for signal traces

    %% 1. TOPOGRAPHIC POWER MAP
    try
        % Create interpolated topographic map with REAL alpha power
        cla(topoAx);
        hold(topoAx, 'on');

        % Compute REAL alpha power (8-13 Hz) for each channel
        alpha_power = zeros(1, EEG_clean.nbchan);

        for ch = 1:EEG_clean.nbchan
            % Get channel data
            channel_data = EEG_clean.data(ch, :);

            % Compute power spectral density for this channel
            fs = EEG_clean.srate;
            try
                [pxx, f] = pwelch(channel_data, hamming(fs*2), fs, fs*2, fs);

                % Extract alpha band power (8-13 Hz)
                alpha_idx = f >= 8 & f <= 13;
                alpha_power(ch) = mean(pxx(alpha_idx));
            catch
                alpha_power(ch) = NaN; % Mark as missing if calculation fails
            end
        end

        % Convert to microvolts squared
        alpha_power = alpha_power * 1e12;

        % Get electrode positions
        elec_x = [];
        elec_y = [];
        valid_power = [];

        % Try to get REAL electrode positions from EEG structure
        if isfield(EEG_clean, 'chanlocs') && ~isempty(EEG_clean.chanlocs) && ...
           isfield(EEG_clean.chanlocs, 'X') && isfield(EEG_clean.chanlocs, 'Y')

            for ch = 1:EEG_clean.nbchan
                if ~isempty(EEG_clean.chanlocs(ch).X) && ~isempty(EEG_clean.chanlocs(ch).Y) && ...
                   ~isnan(alpha_power(ch))
                    % Convert 3D coordinates to 2D projection
                    X = EEG_clean.chanlocs(ch).X;
                    Y = EEG_clean.chanlocs(ch).Y;
                    Z = EEG_clean.chanlocs(ch).Z;

                    % Simple azimuthal projection
                    if ~isempty(Z) && Z ~= 0
                        % Project onto 2D circle
                        radius = sqrt(X^2 + Y^2 + Z^2);
                        if radius > 0
                            % Normalize and project
                            proj_x = Y / radius;
                            proj_y = X / radius;

                            elec_x(end+1) = proj_x;
                            elec_y(end+1) = proj_y;
                            valid_power(end+1) = alpha_power(ch);
                        end
                    end
                end
            end
            use_real_positions = length(elec_x) >= 3;
        else
            use_real_positions = false;
        end

        % If no real positions, create generic circular arrangement
        if ~use_real_positions
            n_elecs = length(alpha_power);
            elec_angles = linspace(0, 2*pi, n_elecs+1);
            elec_angles = elec_angles(1:end-1);
            elec_radii = 0.6 * ones(1, n_elecs);

            elec_x = elec_radii .* cos(elec_angles);
            elec_y = elec_radii .* sin(elec_angles);
            valid_power = alpha_power;
            valid_power(isnan(valid_power)) = mean(valid_power(~isnan(valid_power)));
        end

        % Create 2D interpolation grid for smooth topographic map
        if length(elec_x) >= 3
            % Create fine grid
            grid_res = 100;
            [xi, yi] = meshgrid(linspace(-1.2, 1.2, grid_res), linspace(-1.2, 1.2, grid_res));

            % Interpolate alpha power across the grid
            try
                % Use scattered interpolant for smooth interpolation
                F = scatteredInterpolant(elec_x(:), elec_y(:), valid_power(:), 'natural', 'linear');
                zi = F(xi, yi);

                % Mask to only show inside head (circular region)
                head_mask = sqrt(xi.^2 + yi.^2) <= 1.0;
                zi(~head_mask) = NaN;

                % Create smooth contour plot
                contourf(topoAx, xi, yi, zi, 20, 'LineStyle', 'none');

                % Overlay electrode positions as small black dots
                scatter(topoAx, elec_x, elec_y, 30, 'k', 'filled', 'MarkerEdgeColor', 'w', 'LineWidth', 0.5);

                % Add status text
                if use_real_positions
                    status_text = 'Real Alpha Power Distribution';
                    status_color = [0.2 0.6 0.2];
                else
                    status_text = 'Real Alpha Power (Approx. Positions)';
                    status_color = [0.8 0.6 0.2];
                end

            catch ME
                % Fallback: simple scattered plot if interpolation fails
                warning('Interpolation failed: %s. Using scatter plot.', ME.message);
                scatter(topoAx, elec_x, elec_y, 200, valid_power, 'filled', ...
                    'MarkerEdgeColor', 'k', 'LineWidth', 1);

                if use_real_positions
                    status_text = 'Real Alpha Power (No Interpolation)';
                    status_color = [0.6 0.6 0.2];
                else
                    status_text = 'Real Alpha Power (Generic Positions)';
                    status_color = [0.8 0.6 0.2];
                end
            end
        else
            % Not enough electrodes
            text(topoAx, 0, 0, 'Insufficient electrode data', ...
                'HorizontalAlignment', 'center', 'FontSize', 12);
            status_text = 'Insufficient Data';
            status_color = [0.8 0.3 0.2];
        end

        % Draw head outline ON TOP of everything
        theta = linspace(0, 2*pi, 100);
        x_head = cos(theta);
        y_head = sin(theta);
        plot(topoAx, x_head, y_head, 'k', 'LineWidth', 2.5);

        % Nose
        nose_x = [0.15, 0, -0.15];
        nose_y = [1, 1.15, 1];
        plot(topoAx, nose_x, nose_y, 'k', 'LineWidth', 2.5);

        % Ears
        ear_theta = linspace(-pi/2, pi/2, 20);
        ear_r = 0.1;
        % Left ear
        ear_x_left = -1 + ear_r * cos(ear_theta + pi);
        ear_y_left = ear_r * sin(ear_theta + pi);
        plot(topoAx, ear_x_left, ear_y_left, 'k', 'LineWidth', 2.5);
        % Right ear
        ear_x_right = 1 + ear_r * cos(ear_theta);
        ear_y_right = ear_r * sin(ear_theta);
        plot(topoAx, ear_x_right, ear_y_right, 'k', 'LineWidth', 2.5);

        % Add status text
        text(topoAx, 0, -1.35, status_text, ...
            'HorizontalAlignment', 'center', 'FontSize', 9, ...
            'Color', status_color, 'FontWeight', 'bold');

        % Colormap and colorbar
        colormap(topoAx, 'jet');
        c = colorbar(topoAx);
        c.Label.String = 'Alpha Power (µV²)';
        c.Label.FontSize = 10;

        % Formatting
        axis(topoAx, 'equal');
        topoAx.XLim = [-1.4 1.4];
        topoAx.YLim = [-1.4 1.5];
        topoAx.XTick = [];
        topoAx.YTick = [];
        topoAx.Box = 'off';
        title(topoAx, 'Alpha Band Power (8-13 Hz)', 'FontSize', 12, 'FontWeight', 'bold');

        hold(topoAx, 'off');

    catch ME
        warning('Failed to create topographic map: %s', ME.message);
        cla(topoAx);
        text(topoAx, 0.5, 0.5, 'Topographic visualization unavailable', ...
            'Units', 'normalized', 'HorizontalAlignment', 'center');
    end

    %% 2. POWER SPECTRAL DENSITY
    try
        cla(psdAx);
        hold(psdAx, 'on');

        if isfield(metrics, 'psd') && isfield(metrics, 'psd_freqs')
            % Use computed PSD
            freqs = metrics.psd_freqs;
            psd = 10*log10(metrics.psd); % Convert to dB
        else
            % Compute PSD on the fly
            sample_data = mean(EEG_clean.data, 1);
            fs = EEG_clean.srate;
            [psd_raw, freqs] = pwelch(sample_data, hamming(fs*2), fs, fs*2, fs);
            psd = 10*log10(psd_raw);
        end

        % Only plot up to 50 Hz
        freq_idx = freqs <= 50;
        freqs_plot = freqs(freq_idx);
        psd_plot = psd(freq_idx);

        % Define frequency bands with colors
        bands = struct();
        bands.names = {'Delta', 'Theta', 'Alpha', 'Beta', 'Gamma'};
        bands.ranges = [0.5 4; 4 8; 8 13; 13 30; 30 50];
        bands.colors = [0.9 0.7 0.7; 0.9 0.9 0.6; 0.6 0.9 0.6; 0.7 0.8 0.9; 0.9 0.7 0.9];
        alpha_level = 0.15;

        % Get y-axis baseline for shading
        y_min = min(psd_plot) - 5;

        % Highlight frequency bands BEFORE plotting main line
        for i = 1:length(bands.names)
            f_low = bands.ranges(i, 1);
            f_high = bands.ranges(i, 2);
            color = bands.colors(i, :);

            % Find indices in this band
            band_idx = freqs_plot >= f_low & freqs_plot <= f_high;

            if sum(band_idx) > 1  % Need at least 2 points
                freqs_band = freqs_plot(band_idx);
                psd_band = psd_plot(band_idx);

                % Ensure row vectors for proper concatenation
                freqs_band = freqs_band(:)';
                psd_band = psd_band(:)';

                % Create polygon for fill: [left_to_right, right_to_left]
                x_fill = [freqs_band, fliplr(freqs_band)];
                y_fill = [psd_band, ones(1, length(freqs_band)) * y_min];

                % Draw filled area
                fill(psdAx, x_fill, y_fill, color, ...
                    'FaceAlpha', alpha_level, 'EdgeColor', 'none');
            end
        end

        % Plot main PSD line on top
        plot(psdAx, freqs_plot, psd_plot, 'LineWidth', 2, 'Color', [0.2 0.4 0.8]);

        % Formatting
        xlabel(psdAx, 'Frequency (Hz)', 'FontSize', 11);
        ylabel(psdAx, 'Power (dB)', 'FontSize', 11);
        title(psdAx, 'Power Spectral Density', 'FontSize', 12, 'FontWeight', 'bold');
        grid(psdAx, 'on');
        xlim(psdAx, [0 50]);

        % Add legend
        legend(psdAx, {'Delta (0.5-4 Hz)', 'Theta (4-8 Hz)', 'Alpha (8-13 Hz)', ...
                'Beta (13-30 Hz)', 'Gamma (30-50 Hz)', 'PSD'}, ...
                'Location', 'northeast', 'FontSize', 8);

        hold(psdAx, 'off');

    catch ME
        warning('Failed to create PSD plot: %s', ME.message);
        cla(psdAx);
        text(psdAx, 0.5, 0.5, 'PSD visualization unavailable', ...
            'Units', 'normalized', 'HorizontalAlignment', 'center');
    end

    %% 3. SIGNAL QUALITY COMPARISON
    try
        cla(signalAx);
        hold(signalAx, 'on');

        % Get sample of clean data
        fs = EEG_clean.srate;
        duration = 3; % Show 3 seconds
        n_samples = min(duration * fs, size(EEG_clean.data, 2));

        t = (0:n_samples-1) / fs;

        % Select representative channel (prefer Cz, Pz, or middle channel)
        if EEG_clean.nbchan > 0
            % Try to find Cz or central channel
            chan_idx = round(EEG_clean.nbchan / 2);
            if isfield(EEG_clean, 'chanlocs') && ~isempty(EEG_clean.chanlocs)
                cz_idx = find(strcmpi({EEG_clean.chanlocs.labels}, 'Cz'), 1);
                if ~isempty(cz_idx)
                    chan_idx = cz_idx;
                end
            end

            % Get signal
            signal = EEG_clean.data(chan_idx, 1:n_samples);

            % Normalize for display
            signal = signal - mean(signal);
            signal = signal / std(signal);

            % Plot
            plot(signalAx, t, signal, 'Color', [0.2 0.6 0.4], 'LineWidth', 1.2);

            % Add info about quality
            if isfield(metrics, 'is_clean') && metrics.is_clean
                quality_text = sprintf('Clean Signal (Quality: %s)', metrics.quality_level);
                text_color = [0.2 0.6 0.3];
            else
                quality_text = sprintf('Noisy Signal (Quality: %s)', metrics.quality_level);
                text_color = [0.8 0.4 0.2];
            end

            % Add text annotation
            ylims = ylim(signalAx);
            text(signalAx, t(end)*0.98, ylims(2)*0.9, quality_text, ...
                'HorizontalAlignment', 'right', 'FontSize', 10, ...
                'Color', text_color, 'FontWeight', 'bold', ...
                'BackgroundColor', [1 1 1 0.7]);

            % Formatting
            xlabel(signalAx, 'Time (s)', 'FontSize', 11);
            ylabel(signalAx, 'Normalized Amplitude', 'FontSize', 11);
            title(signalAx, 'Representative EEG Signal', 'FontSize', 12, 'FontWeight', 'bold');
            grid(signalAx, 'on');
            xlim(signalAx, [0 t(end)]);

        else
            text(signalAx, 0.5, 0.5, 'No channels available', 'HorizontalAlignment', 'center');
        end

        hold(signalAx, 'off');

    catch ME
        warning('Failed to create signal plot: %s', ME.message);
        cla(signalAx);
        text(signalAx, 0.5, 0.5, 'Visualization unavailable', 'HorizontalAlignment', 'center');
    end

end
