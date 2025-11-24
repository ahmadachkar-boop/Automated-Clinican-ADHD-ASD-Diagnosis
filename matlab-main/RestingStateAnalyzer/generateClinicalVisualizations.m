function generateClinicalVisualizations(EEG_clean, clinical, thetaBetaAx, multiBandAx, asymmetryAx, bandBarAx)
    % GENERATECLINICALVISUALIZATIONS - Create clinical diagnostic visualizations
    %
    % Inputs:
    %   EEG_clean      - Cleaned EEG structure
    %   clinical       - Clinical metrics from computeClinicalMetrics()
    %   thetaBetaAx    - UIAxes for theta/beta ratio map
    %   multiBandAx    - UIAxes for multi-band power distribution
    %   asymmetryAx    - UIAxes for hemispheric asymmetry analysis
    %   bandBarAx      - UIAxes for frequency band bar chart

    %% 1. THETA/BETA RATIO TOPOGRAPHIC MAP
    try
        cla(thetaBetaAx);
        hold(thetaBetaAx, 'on');

        % Get electrode positions
        [elec_x, elec_y, use_real_positions] = getElectrodePositions(EEG_clean);

        % Get theta/beta ratio values
        theta_beta_values = clinical.theta_beta_ratio;

        % Create interpolated topographic map
        if length(elec_x) >= 3
            % Create fine grid
            grid_res = 100;
            [xi, yi] = meshgrid(linspace(-1.2, 1.2, grid_res), linspace(-1.2, 1.2, grid_res));

            % Filter valid data
            valid_idx = ~isnan(theta_beta_values);
            valid_x = elec_x(valid_idx);
            valid_y = elec_y(valid_idx);
            valid_tb = theta_beta_values(valid_idx);

            if length(valid_x) >= 3
                % Interpolate theta/beta ratios
                F = scatteredInterpolant(valid_x(:), valid_y(:), valid_tb(:), 'natural', 'linear');
                zi = F(xi, yi);

                % Mask to head boundary
                head_mask = sqrt(xi.^2 + yi.^2) <= 1.0;
                zi(~head_mask) = NaN;

                % Create color-coded contour (Red = high, Green = normal)
                contourf(thetaBetaAx, xi, yi, zi, 20, 'LineStyle', 'none');

                % Use custom colormap: Green → Yellow → Red
                n_colors = 256;
                low_color = [0.2 0.8 0.2];   % Green (normal)
                mid_color = [0.95 0.85 0.2]; % Yellow (elevated)
                high_color = [0.9 0.2 0.2];  % Red (high)

                % Create colormap segments
                half = round(n_colors/2);
                cmap_low = [linspace(low_color(1), mid_color(1), half)', ...
                           linspace(low_color(2), mid_color(2), half)', ...
                           linspace(low_color(3), mid_color(3), half)'];
                cmap_high = [linspace(mid_color(1), high_color(1), n_colors-half)', ...
                            linspace(mid_color(2), high_color(2), n_colors-half)', ...
                            linspace(mid_color(3), high_color(3), n_colors-half)'];
                custom_cmap = [cmap_low; cmap_high];
                colormap(thetaBetaAx, custom_cmap);

                % Overlay electrode positions
                scatter(thetaBetaAx, elec_x, elec_y, 30, 'k', 'filled', ...
                    'MarkerEdgeColor', 'w', 'LineWidth', 0.5);

                % Highlight frontal electrodes
                if isfield(clinical, 'frontal_indices') && ~isempty(clinical.frontal_indices)
                    frontal_x = elec_x(clinical.frontal_indices);
                    frontal_y = elec_y(clinical.frontal_indices);
                    scatter(thetaBetaAx, frontal_x, frontal_y, 80, 'c', 'filled', ...
                        'MarkerEdgeColor', 'k', 'LineWidth', 2, 'Marker', 's');
                end

                % Draw head outline
                theta = linspace(0, 2*pi, 100);
                plot(thetaBetaAx, cos(theta), sin(theta), 'k', 'LineWidth', 2.5);

                % Nose
                nose_x = [0.15, 0, -0.15];
                nose_y = [1, 1.15, 1];
                plot(thetaBetaAx, nose_x, nose_y, 'k', 'LineWidth', 2.5);

                % Ears
                ear_theta = linspace(-pi/2, pi/2, 20);
                ear_r = 0.1;
                ear_x_left = -1 + ear_r * cos(ear_theta + pi);
                ear_y_left = ear_r * sin(ear_theta + pi);
                plot(thetaBetaAx, ear_x_left, ear_y_left, 'k', 'LineWidth', 2.5);
                ear_x_right = 1 + ear_r * cos(ear_theta);
                ear_y_right = ear_r * sin(ear_theta);
                plot(thetaBetaAx, ear_x_right, ear_y_right, 'k', 'LineWidth', 2.5);

                % Colorbar
                c = colorbar(thetaBetaAx);
                c.Label.String = 'Theta/Beta Ratio';
                c.Label.FontSize = 10;

                % Set colorbar limits around clinical thresholds
                caxis(thetaBetaAx, [1.5 4.5]);

                % Add threshold lines to colorbar
                hold(thetaBetaAx, 'on');

                % Display Fz value and status
                if isfield(clinical, 'fz_theta_beta') && isfield(clinical, 'clinical_markers_a')
                    fz_value = clinical.fz_theta_beta;
                    status = clinical.clinical_markers_a.theta_beta_status;

                    % Traffic light indicator
                    if strcmp(status, 'HIGH')
                        traffic_light = '🔴 HIGH';
                        light_color = [0.9 0.2 0.2];
                    elseif strcmp(status, 'ELEVATED')
                        traffic_light = '🟡 ELEVATED';
                        light_color = [0.95 0.85 0.2];
                    else
                        traffic_light = '🟢 NORMAL';
                        light_color = [0.2 0.8 0.2];
                    end

                    % Display status
                    text(thetaBetaAx, 0, -1.35, sprintf('Fz Ratio: %.2f - %s', fz_value, traffic_light), ...
                        'HorizontalAlignment', 'center', 'FontSize', 10, ...
                        'Color', light_color, 'FontWeight', 'bold');
                end
            end
        end

        % Formatting
        axis(thetaBetaAx, 'equal');
        thetaBetaAx.XLim = [-1.4 1.4];
        thetaBetaAx.YLim = [-1.4 1.5];
        thetaBetaAx.XTick = [];
        thetaBetaAx.YTick = [];
        thetaBetaAx.Box = 'off';
        title(thetaBetaAx, 'Theta/Beta Ratio', 'FontSize', 12, 'FontWeight', 'bold');

        hold(thetaBetaAx, 'off');

    catch ME
        warning('Failed to create theta/beta map: %s', ME.message);
        cla(thetaBetaAx);
        text(thetaBetaAx, 0.5, 0.5, 'Theta/Beta visualization unavailable', ...
            'Units', 'normalized', 'HorizontalAlignment', 'center');
    end

    %% 2. MULTI-BAND POWER DISTRIBUTION
    try
        cla(multiBandAx);
        hold(multiBandAx, 'on');

        % Get electrode positions
        [elec_x, elec_y, ~] = getElectrodePositions(EEG_clean);

        % Band data
        bands = {'delta', 'theta', 'alpha', 'beta', 'gamma'};
        band_labels = {'Delta\n(0.5-4 Hz)', 'Theta\n(4-8 Hz)', 'Alpha\n(8-13 Hz)', ...
                      'Beta\n(13-30 Hz)', 'Gamma\n(30-50 Hz)'};
        n_bands = length(bands);

        if length(elec_x) >= 3
            % Calculate global color scale across all bands
            all_powers = [];
            for b = 1:n_bands
                band_power = clinical.band_powers.(bands{b});
                all_powers = [all_powers, band_power(~isnan(band_power))];
            end
            global_min = prctile(all_powers, 5);
            global_max = prctile(all_powers, 95);

            % Create 5 small topomaps side-by-side
            for b = 1:n_bands
                band_name = bands{b};
                band_power = clinical.band_powers.(band_name);

                % Create subplot position
                subplot_width = 0.18;
                subplot_height = 0.7;
                subplot_x = 0.02 + (b-1) * 0.195;
                subplot_y = 0.15;

                % Create axes for this band
                ax_band = axes(multiBandAx.Parent, 'Position', ...
                    [multiBandAx.Position(1) + multiBandAx.Position(3)*subplot_x, ...
                     multiBandAx.Position(2) + multiBandAx.Position(4)*subplot_y, ...
                     multiBandAx.Position(3)*subplot_width, ...
                     multiBandAx.Position(4)*subplot_height]);

                hold(ax_band, 'on');

                % Filter valid data
                valid_idx = ~isnan(band_power);
                valid_x = elec_x(valid_idx);
                valid_y = elec_y(valid_idx);
                valid_power = band_power(valid_idx);

                if length(valid_x) >= 3
                    % Create interpolation grid
                    grid_res = 80;
                    [xi, yi] = meshgrid(linspace(-1.2, 1.2, grid_res), linspace(-1.2, 1.2, grid_res));

                    % Interpolate
                    F = scatteredInterpolant(valid_x(:), valid_y(:), valid_power(:), 'natural', 'linear');
                    zi = F(xi, yi);

                    % Mask to head
                    head_mask = sqrt(xi.^2 + yi.^2) <= 1.0;
                    zi(~head_mask) = NaN;

                    % Create contour
                    contourf(ax_band, xi, yi, zi, 20, 'LineStyle', 'none');

                    % Consistent colormap and scale
                    colormap(ax_band, 'jet');
                    caxis(ax_band, [global_min global_max]);

                    % Overlay electrodes
                    scatter(ax_band, elec_x, elec_y, 15, 'k', 'filled', ...
                        'MarkerEdgeColor', 'w', 'LineWidth', 0.3);

                    % Draw head outline
                    theta_circle = linspace(0, 2*pi, 100);
                    plot(ax_band, cos(theta_circle), sin(theta_circle), 'k', 'LineWidth', 1.5);

                    % Nose
                    nose_x = [0.15, 0, -0.15];
                    nose_y = [1, 1.15, 1];
                    plot(ax_band, nose_x, nose_y, 'k', 'LineWidth', 1.5);
                end

                % Formatting
                axis(ax_band, 'equal');
                ax_band.XLim = [-1.3 1.3];
                ax_band.YLim = [-1.3 1.4];
                ax_band.XTick = [];
                ax_band.YTick = [];
                ax_band.Box = 'off';
                title(ax_band, sprintf(band_labels{b}), 'FontSize', 9, 'FontWeight', 'bold');

                hold(ax_band, 'off');
            end

            % Add shared colorbar
            c = colorbar(ax_band);
            c.Label.String = 'Power (µV²)';
            c.Label.FontSize = 9;
            c.Position(1) = 0.93;
        end

        % Hide the main multiBandAx (we created subplots instead)
        multiBandAx.Visible = 'off';

    catch ME
        warning('Failed to create multi-band power map: %s', ME.message);
        cla(multiBandAx);
        text(multiBandAx, 0.5, 0.5, 'Multi-band visualization unavailable', ...
            'Units', 'normalized', 'HorizontalAlignment', 'center');
    end

    %% 3. HEMISPHERIC ASYMMETRY ANALYSIS
    try
        cla(asymmetryAx);
        hold(asymmetryAx, 'on');

        % Get electrode positions
        [elec_x, elec_y, ~] = getElectrodePositions(EEG_clean);

        if length(elec_x) >= 3
            % Focus on alpha asymmetry (most clinically relevant)
            alpha_asym = clinical.hemispheric_asymmetry.alpha;

            % Compute asymmetry for each electrode
            n_elecs = EEG_clean.nbchan;
            asymmetry_values = zeros(1, n_elecs);

            % Get left and right indices
            left_indices = clinical.left_indices;
            right_indices = clinical.right_indices;

            % Assign asymmetry values
            for i = 1:length(left_indices)
                if left_indices(i) <= n_elecs
                    asymmetry_values(left_indices(i)) = alpha_asym.asymmetry_index;
                end
            end
            for i = 1:length(right_indices)
                if right_indices(i) <= n_elecs
                    asymmetry_values(right_indices(i)) = -alpha_asym.asymmetry_index;
                end
            end

            % Filter valid data
            valid_idx = ~isnan(asymmetry_values) & asymmetry_values ~= 0;
            valid_x = elec_x(valid_idx);
            valid_y = elec_y(valid_idx);
            valid_asym = asymmetry_values(valid_idx);

            if length(valid_x) >= 3
                % Create interpolation grid
                grid_res = 100;
                [xi, yi] = meshgrid(linspace(-1.2, 1.2, grid_res), linspace(-1.2, 1.2, grid_res));

                % Interpolate asymmetry
                F = scatteredInterpolant(valid_x(:), valid_y(:), valid_asym(:), 'natural', 'linear');
                zi = F(xi, yi);

                % Mask to head
                head_mask = sqrt(xi.^2 + yi.^2) <= 1.0;
                zi(~head_mask) = NaN;

                % Create diverging colormap (Blue = right dominant, Red = left dominant)
                contourf(asymmetryAx, xi, yi, zi, 20, 'LineStyle', 'none');

                % Custom diverging colormap
                n_colors = 256;
                blue_to_white = [linspace(0.2, 1, n_colors/2)', ...
                                linspace(0.4, 1, n_colors/2)', ...
                                linspace(0.9, 1, n_colors/2)'];
                white_to_red = [linspace(1, 0.9, n_colors/2)', ...
                               linspace(1, 0.2, n_colors/2)', ...
                               linspace(1, 0.2, n_colors/2)'];
                diverging_cmap = [blue_to_white; white_to_red];
                colormap(asymmetryAx, diverging_cmap);

                % Symmetric color axis
                max_asym = max(abs(zi(:)), [], 'omitnan');
                caxis(asymmetryAx, [-max_asym, max_asym]);

                % Overlay electrodes
                scatter(asymmetryAx, elec_x, elec_y, 30, 'k', 'filled', ...
                    'MarkerEdgeColor', 'w', 'LineWidth', 0.5);

                % Draw head outline
                theta = linspace(0, 2*pi, 100);
                plot(asymmetryAx, cos(theta), sin(theta), 'k', 'LineWidth', 2.5);

                % Nose
                nose_x = [0.15, 0, -0.15];
                nose_y = [1, 1.15, 1];
                plot(asymmetryAx, nose_x, nose_y, 'k', 'LineWidth', 2.5);

                % Ears
                ear_theta = linspace(-pi/2, pi/2, 20);
                ear_r = 0.1;
                ear_x_left = -1 + ear_r * cos(ear_theta + pi);
                ear_y_left = ear_r * sin(ear_theta + pi);
                plot(asymmetryAx, ear_x_left, ear_y_left, 'k', 'LineWidth', 2.5);
                ear_x_right = 1 + ear_r * cos(ear_theta);
                ear_y_right = ear_r * sin(ear_theta);
                plot(asymmetryAx, ear_x_right, ear_y_right, 'k', 'LineWidth', 2.5);

                % Colorbar
                c = colorbar(asymmetryAx);
                c.Label.String = 'Asymmetry Index';
                c.Label.FontSize = 10;

                % Display asymmetry status
                mean_asym = alpha_asym.asymmetry_index;
                if abs(mean_asym) > 0.3
                    asym_status = '⚠️ ASYMMETRIC';
                    asym_color = [0.9 0.5 0.2];
                else
                    asym_status = '✓ SYMMETRIC';
                    asym_color = [0.2 0.7 0.2];
                end

                text(asymmetryAx, 0, -1.35, sprintf('Alpha Asym: %.2f - %s', mean_asym, asym_status), ...
                    'HorizontalAlignment', 'center', 'FontSize', 10, ...
                    'Color', asym_color, 'FontWeight', 'bold');

                % Add labels
                text(asymmetryAx, -1.1, 0, 'L', 'FontSize', 14, 'FontWeight', 'bold', 'Color', [0.9 0.2 0.2]);
                text(asymmetryAx, 1.1, 0, 'R', 'FontSize', 14, 'FontWeight', 'bold', 'Color', [0.2 0.4 0.9]);
            end
        end

        % Formatting
        axis(asymmetryAx, 'equal');
        asymmetryAx.XLim = [-1.4 1.4];
        asymmetryAx.YLim = [-1.4 1.5];
        asymmetryAx.XTick = [];
        asymmetryAx.YTick = [];
        asymmetryAx.Box = 'off';
        title(asymmetryAx, 'Hemispheric Asymmetry (Alpha Band)', 'FontSize', 12, 'FontWeight', 'bold');

        hold(asymmetryAx, 'off');

    catch ME
        warning('Failed to create asymmetry map: %s', ME.message);
        cla(asymmetryAx);
        text(asymmetryAx, 0.5, 0.5, 'Asymmetry visualization unavailable', ...
            'Units', 'normalized', 'HorizontalAlignment', 'center');
    end

    %% 4. FREQUENCY BAND BAR CHART
    try
        cla(bandBarAx);
        hold(bandBarAx, 'on');

        % Get mean power for each band (averaged across all channels)
        delta_mean = mean(clinical.band_powers.delta, 'omitnan');
        theta_mean = mean(clinical.band_powers.theta, 'omitnan');
        alpha_mean = mean(clinical.band_powers.alpha, 'omitnan');
        beta_mean = mean(clinical.band_powers.beta, 'omitnan');
        gamma_mean = mean(clinical.band_powers.gamma, 'omitnan');

        % Calculate relative power (percentage of total)
        total_power = delta_mean + theta_mean + alpha_mean + beta_mean + gamma_mean;

        delta_rel = (delta_mean / total_power) * 100;
        theta_rel = (theta_mean / total_power) * 100;
        alpha_rel = (alpha_mean / total_power) * 100;
        beta_rel = (beta_mean / total_power) * 100;
        gamma_rel = (gamma_mean / total_power) * 100;

        % Create bar data
        band_powers = [delta_rel, theta_rel, alpha_rel, beta_rel, gamma_rel];
        band_names = {'Delta\n(0.5-4 Hz)', 'Theta\n(4-8 Hz)', 'Alpha\n(8-13 Hz)', ...
                      'Beta\n(13-30 Hz)', 'Gamma\n(30-50 Hz)'};

        % Create bar chart
        b = bar(bandBarAx, 1:5, band_powers, 'FaceColor', 'flat');

        % Color each bar with its frequency band color
        band_colors = [0.9 0.7 0.7;   % Delta - red
                       0.9 0.9 0.6;   % Theta - yellow
                       0.6 0.9 0.6;   % Alpha - green
                       0.7 0.8 0.9;   % Beta - blue
                       0.9 0.7 0.9];  % Gamma - purple
        b.CData = band_colors;

        % Add value labels on top of each bar
        for i = 1:5
            text(bandBarAx, i, band_powers(i) + 2, sprintf('%.1f%%', band_powers(i)), ...
                'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');
        end

        % Formatting
        bandBarAx.XTick = 1:5;
        bandBarAx.XTickLabel = band_names;
        bandBarAx.XTickLabelRotation = 0;
        bandBarAx.YLim = [0 max(band_powers) + 8];
        bandBarAx.Box = 'off';
        grid(bandBarAx, 'on');
        bandBarAx.GridAlpha = 0.3;

        title(bandBarAx, 'Frequency Band Power Comparison (Mean Across All Channels)', ...
            'FontSize', 12, 'FontWeight', 'bold');
        ylabel(bandBarAx, 'Relative Power (%)', 'FontSize', 10);

        hold(bandBarAx, 'off');

    catch ME
        warning('Failed to create band bar chart: %s', ME.message);
        cla(bandBarAx);
        text(bandBarAx, 0.5, 0.5, 'Bar chart unavailable', ...
            'Units', 'normalized', 'HorizontalAlignment', 'center');
    end

end

%% HELPER FUNCTION: Get electrode positions
function [elec_x, elec_y, use_real_positions] = getElectrodePositions(EEG_clean)
    % Extract electrode positions from EEG structure

    elec_x = [];
    elec_y = [];
    valid_power = [];
    use_real_positions = false;

    % Try to get REAL electrode positions from EEG structure
    if isfield(EEG_clean, 'chanlocs') && ~isempty(EEG_clean.chanlocs) && ...
       isfield(EEG_clean.chanlocs, 'X') && isfield(EEG_clean.chanlocs, 'Y')

        for ch = 1:EEG_clean.nbchan
            if ~isempty(EEG_clean.chanlocs(ch).X) && ~isempty(EEG_clean.chanlocs(ch).Y)
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
                    end
                end
            end
        end
        use_real_positions = length(elec_x) >= 3;
    end

    % If no real positions, create generic circular arrangement
    if ~use_real_positions
        n_elecs = EEG_clean.nbchan;
        elec_angles = linspace(0, 2*pi, n_elecs+1);
        elec_angles = elec_angles(1:end-1);
        elec_radii = 0.6 * ones(1, n_elecs);

        elec_x = elec_radii .* cos(elec_angles);
        elec_y = elec_radii .* sin(elec_angles);
    end
end
