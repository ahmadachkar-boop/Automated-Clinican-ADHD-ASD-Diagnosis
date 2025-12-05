function generateRestingStateVisualizations(restingMetrics, ax1, ax2, ax3, ax4, topoThetaBetaEC, topoThetaBetaEO, topoThetaAlphaEC, topoThetaAlphaEO, EEG)
    % Generate visualizations comparing resting state conditions
    % Shows band power comparisons between conditions (e.g., eyes open vs closed)
    %
    % Inputs:
    %   restingMetrics - Output from computeRestingStateMetrics
    %   ax1, ax2, ax3, ax4 - Axes handles for the 4 clinical tab plots
    %   topoThetaBetaEC/EO - Axes for theta/beta ratio topographic maps
    %   topoThetaAlphaEC/EO - Axes for theta/alpha ratio topographic maps
    %   EEG - EEG structure with channel locations

    if isempty(restingMetrics) || ~isfield(restingMetrics, 'conditions')
        % No data to visualize
        for ax = [ax1, ax2, ax3, ax4]
            cla(ax);
            text(ax, 0.5, 0.5, 'No resting state data available', ...
                'Units', 'normalized', 'HorizontalAlignment', 'center', 'FontSize', 12);
        end
        return;
    end

    conditions = restingMetrics.conditions;
    bandNames = restingMetrics.bandNames;

    % PLOT 1: Relative Band Powers Comparison (Bar Chart)
    cla(ax1);
    hold(ax1, 'on');

    numBands = length(bandNames);
    numConds = length(conditions);
    barWidth = 0.8 / numConds;

    % Prepare data
    relativeData = zeros(numBands, numConds);
    for condIdx = 1:numConds
        cond = conditions{condIdx};
        for bandIdx = 1:numBands
            bandName = bandNames{bandIdx};
            relativeData(bandIdx, condIdx) = restingMetrics.(cond).relative.(bandName).mean;
        end
    end

    % Create grouped bar chart
    x = 1:numBands;
    colors = [0.2 0.4 0.8; 0.8 0.4 0.2; 0.2 0.8 0.4];  % Blue, Orange, Green

    for condIdx = 1:numConds
        barX = x + (condIdx - (numConds+1)/2) * barWidth;
        bar(ax1, barX, relativeData(:, condIdx), barWidth, ...
            'FaceColor', colors(condIdx, :), 'EdgeColor', 'none');
    end

    % Formatting
    ax1.XTick = 1:numBands;
    ax1.XTickLabel = cellfun(@upper, bandNames, 'UniformOutput', false);
    ylabel(ax1, 'Relative Power (%)');
    title(ax1, 'Relative Band Powers by Condition');
    legend(ax1, conditions, 'Location', 'best');
    grid(ax1, 'on');
    ax1.FontSize = 10;
    hold(ax1, 'off');

    % PLOT 2: Absolute Band Powers Comparison (Bar Chart)
    cla(ax2);
    hold(ax2, 'on');

    % Prepare absolute data
    absoluteData = zeros(numBands, numConds);
    for condIdx = 1:numConds
        cond = conditions{condIdx};
        for bandIdx = 1:numBands
            bandName = bandNames{bandIdx};
            absoluteData(bandIdx, condIdx) = restingMetrics.(cond).absolute.(bandName).mean;
        end
    end

    % Create grouped bar chart (log scale for better visibility)
    for condIdx = 1:numConds
        barX = x + (condIdx - (numConds+1)/2) * barWidth;
        bar(ax2, barX, absoluteData(:, condIdx), barWidth, ...
            'FaceColor', colors(condIdx, :), 'EdgeColor', 'none');
    end

    % Formatting
    ax2.XTick = 1:numBands;
    ax2.XTickLabel = cellfun(@upper, bandNames, 'UniformOutput', false);
    ylabel(ax2, 'Absolute Power (µV²)');
    title(ax2, 'Absolute Band Powers by Condition');
    legend(ax2, conditions, 'Location', 'best');
    grid(ax2, 'on');
    ax2.YScale = 'log';  % Log scale for better visualization
    ax2.FontSize = 10;
    hold(ax2, 'off');

    % PLOT 3: Band Power Differences (if 2 conditions)
    cla(ax3);
    if numConds == 2 && isfield(restingMetrics, 'comparison')
        hold(ax3, 'on');

        % Extract differences
        diffs = zeros(numBands, 1);
        for bandIdx = 1:numBands
            bandName = bandNames{bandIdx};
            diffs(bandIdx) = restingMetrics.comparison.(bandName).relativeDiff;
        end

        % Create bar chart with color indicating direction
        barColors = zeros(numBands, 3);
        for i = 1:numBands
            if diffs(i) > 0
                barColors(i, :) = [0.2 0.6 0.8];  % Positive = blue
            else
                barColors(i, :) = [0.8 0.4 0.2];  % Negative = orange
            end
        end

        for i = 1:numBands
            bar(ax3, i, diffs(i), 'FaceColor', barColors(i, :), 'EdgeColor', 'none');
        end

        % Add zero reference line
        plot(ax3, [0.5 numBands+0.5], [0 0], 'k--', 'LineWidth', 1.5);

        % Formatting
        ax3.XTick = 1:numBands;
        ax3.XTickLabel = cellfun(@upper, bandNames, 'UniformOutput', false);
        ylabel(ax3, 'Relative Power Difference (%)');
        title(ax3, sprintf('Difference: %s - %s', conditions{1}, conditions{2}));
        grid(ax3, 'on');
        ax3.FontSize = 10;
        hold(ax3, 'off');
    else
        text(ax3, 0.5, 0.5, 'Difference analysis requires exactly 2 conditions', ...
            'Units', 'normalized', 'HorizontalAlignment', 'center', 'FontSize', 10);
    end

    % PLOT 4: Detailed Statistics and Band Powers
    cla(ax4);
    hold(ax4, 'off');
    axis(ax4, 'off');

    % Create text summary
    yPos = 0.98;
    lineHeight = 0.045;  % Smaller line height to fit more content

    % Title
    text(ax4, 0.5, yPos, 'Resting State Analysis Summary', ...
        'Units', 'normalized', 'HorizontalAlignment', 'center', ...
        'FontSize', 13, 'FontWeight', 'bold');
    yPos = yPos - lineHeight * 1.3;

    % For each condition
    for condIdx = 1:numConds
        cond = conditions{condIdx};
        condMetrics = restingMetrics.(cond);

        % Condition name
        text(ax4, 0.05, yPos, sprintf('%s:', cond), ...
            'Units', 'normalized', 'FontSize', 11, 'FontWeight', 'bold', ...
            'Color', colors(condIdx, :));
        yPos = yPos - lineHeight;

        % Segment stats
        text(ax4, 0.08, yPos, sprintf('Segments: %d  |  Total: %.1f sec  |  Mean: %.1f sec', ...
            condMetrics.numSegments, condMetrics.totalDuration, condMetrics.meanDuration), ...
            'Units', 'normalized', 'FontSize', 9);
        yPos = yPos - lineHeight * 1.2;

        % Band Powers - two columns
        text(ax4, 0.08, yPos, 'Relative Band Powers:', ...
            'Units', 'normalized', 'FontSize', 10, 'FontWeight', 'bold');
        yPos = yPos - lineHeight;

        % Left column: Delta, Theta, Alpha
        text(ax4, 0.10, yPos, sprintf('Delta (2-4 Hz):   %.2f%% ± %.2f%%', ...
            condMetrics.relative.delta.mean, condMetrics.relative.delta.std), ...
            'Units', 'normalized', 'FontSize', 9);
        yPos = yPos - lineHeight;

        text(ax4, 0.10, yPos, sprintf('Theta (4-8 Hz):   %.2f%% ± %.2f%%', ...
            condMetrics.relative.theta.mean, condMetrics.relative.theta.std), ...
            'Units', 'normalized', 'FontSize', 9);
        yPos = yPos - lineHeight;

        text(ax4, 0.10, yPos, sprintf('Alpha (8-13 Hz):  %.2f%% ± %.2f%%', ...
            condMetrics.relative.alpha.mean, condMetrics.relative.alpha.std), ...
            'Units', 'normalized', 'FontSize', 9, 'FontWeight', 'bold', 'Color', [0 0.4 0.8]);
        yPos = yPos - lineHeight;

        text(ax4, 0.10, yPos, sprintf('Beta (13-30 Hz):  %.2f%% ± %.2f%%', ...
            condMetrics.relative.beta.mean, condMetrics.relative.beta.std), ...
            'Units', 'normalized', 'FontSize', 9);
        yPos = yPos - lineHeight;

        text(ax4, 0.10, yPos, sprintf('Gamma (30-50 Hz): %.2f%% ± %.2f%%', ...
            condMetrics.relative.gamma.mean, condMetrics.relative.gamma.std), ...
            'Units', 'normalized', 'FontSize', 9);
        yPos = yPos - lineHeight * 1.5;
    end

    % Condition comparison if 2 conditions
    if numConds == 2
        text(ax4, 0.05, yPos, 'Condition Comparison:', ...
            'Units', 'normalized', 'FontSize', 11, 'FontWeight', 'bold');
        yPos = yPos - lineHeight;

        cond1 = conditions{1};
        cond2 = conditions{2};

        % Alpha comparison (most important)
        alpha1 = restingMetrics.(cond1).relative.alpha.mean;
        alpha2 = restingMetrics.(cond2).relative.alpha.mean;
        alphaDiff = alpha1 - alpha2;
        text(ax4, 0.08, yPos, sprintf('Alpha: %.2f%% (%s) vs %.2f%% (%s) → %+.2f%%', ...
            alpha1, cond1, alpha2, cond2, alphaDiff), ...
            'Units', 'normalized', 'FontSize', 9, 'FontWeight', 'bold', 'Color', [0 0.4 0.8]);
        yPos = yPos - lineHeight;

        % Delta comparison
        delta1 = restingMetrics.(cond1).relative.delta.mean;
        delta2 = restingMetrics.(cond2).relative.delta.mean;
        deltaDiff = delta1 - delta2;
        text(ax4, 0.08, yPos, sprintf('Delta: %.2f%% (%s) vs %.2f%% (%s) → %+.2f%%', ...
            delta1, cond1, delta2, cond2, deltaDiff), ...
            'Units', 'normalized', 'FontSize', 9);
        yPos = yPos - lineHeight;

        % Theta comparison
        theta1 = restingMetrics.(cond1).relative.theta.mean;
        theta2 = restingMetrics.(cond2).relative.theta.mean;
        thetaDiff = theta1 - theta2;
        text(ax4, 0.08, yPos, sprintf('Theta: %.2f%% (%s) vs %.2f%% (%s) → %+.2f%%', ...
            theta1, cond1, theta2, cond2, thetaDiff), ...
            'Units', 'normalized', 'FontSize', 9);
        yPos = yPos - lineHeight * 1.5;

        % Clinical indicators
        text(ax4, 0.05, yPos, 'Clinical Ratios:', ...
            'Units', 'normalized', 'FontSize', 11, 'FontWeight', 'bold');
        yPos = yPos - lineHeight;

        for condIdx = 1:numConds
            cond = conditions{condIdx};
            alphaRel = restingMetrics.(cond).relative.alpha.mean;
            thetaRel = restingMetrics.(cond).relative.theta.mean;
            ratio = alphaRel / thetaRel;
            text(ax4, 0.08, yPos, sprintf('%s - Alpha/Theta: %.2f', cond, ratio), ...
                'Units', 'normalized', 'FontSize', 9);
            yPos = yPos - lineHeight;
        end
        yPos = yPos - lineHeight * 0.5;

        % Interpretation note
        text(ax4, 0.05, yPos, 'Interpretation:', ...
            'Units', 'normalized', 'FontSize', 10, 'FontWeight', 'bold', 'Color', [0.2 0.5 0.2]);
        yPos = yPos - lineHeight;

        if alphaDiff > 5
            interpText = sprintf('✓ Strong alpha suppression with %s (%+.1f%%) - Normal pattern', cond2, -alphaDiff);
        elseif alphaDiff > 2
            interpText = sprintf('✓ Moderate alpha suppression with %s (%+.1f%%)', cond2, -alphaDiff);
        else
            interpText = sprintf('⚠ Weak alpha suppression (%+.1f%%) - May indicate drowsiness', -alphaDiff);
        end
        text(ax4, 0.08, yPos, interpText, ...
            'Units', 'normalized', 'FontSize', 9, 'Color', [0.2 0.5 0.2]);
    end

    % TOPOGRAPHIC MAPS: Theta/Beta and Theta/Alpha Ratios
    % Only generate if we have channel locations and per-channel data
    fprintf('\n=== TOPOGRAPHIC MAP CHECK ===\n');
    fprintf('  nargin: %d (need >= 10)\n', nargin);
    fprintf('  EEG empty: %d\n', isempty(EEG));
    if ~isempty(EEG)
        fprintf('  EEG has chanlocs field: %d\n', isfield(EEG, 'chanlocs'));
        if isfield(EEG, 'chanlocs')
            fprintf('  Number of chanlocs: %d\n', length(EEG.chanlocs));
        end
    end
    fprintf('  conditions: %s\n', strjoin(conditions, ', '));

    if nargin >= 10 && ~isempty(EEG) && isfield(EEG, 'chanlocs') && length(EEG.chanlocs) > 0
        fprintf('  ✓ Basic checks passed, attempting topomap generation...\n');
        try
            % Find eyes-closed and eyes-open conditions
            eyesClosedIdx = find(contains(lower(conditions), 'closed'));
            eyesOpenIdx = find(contains(lower(conditions), 'open'));

            fprintf('  Found %d closed conditions, %d open conditions\n', ...
                length(eyesClosedIdx), length(eyesOpenIdx));

            if ~isempty(eyesClosedIdx) && ~isempty(eyesOpenIdx)
                condEC = conditions{eyesClosedIdx(1)};
                condEO = conditions{eyesOpenIdx(1)};

                fprintf('  Using conditions: %s (closed) and %s (open)\n', condEC, condEO);

                % Get per-channel data
                fprintf('  Checking for perChannel data in condition "%s"\n', condEC);
                fprintf('  Has perChannel field: %d\n', isfield(restingMetrics.(condEC), 'perChannel'));

                if isfield(restingMetrics.(condEC), 'perChannel')
                    fprintf('  ✓ perChannel data found!\n');
                    perChan = restingMetrics.(condEC).perChannel;
                    fprintf('  perChannel fields: %s\n', strjoin(fieldnames(perChan), ', '));

                    % Compute ratios for each channel
                    numChans = size(restingMetrics.(condEC).perChannel.theta, 1);
                    fprintf('  Number of channels: %d\n', numChans);

                    % Eyes Closed ratios
                    thetaBetaEC = mean(restingMetrics.(condEC).perChannel.theta, 2) ./ ...
                                  mean(restingMetrics.(condEC).perChannel.beta, 2);
                    thetaAlphaEC = mean(restingMetrics.(condEC).perChannel.theta, 2) ./ ...
                                   mean(restingMetrics.(condEC).perChannel.alpha, 2);

                    % Eyes Open ratios
                    thetaBetaEO = mean(restingMetrics.(condEO).perChannel.theta, 2) ./ ...
                                  mean(restingMetrics.(condEO).perChannel.beta, 2);
                    thetaAlphaEO = mean(restingMetrics.(condEO).perChannel.theta, 2) ./ ...
                                   mean(restingMetrics.(condEO).perChannel.alpha, 2);

                    % Compute common color scales for comparison
                    thetaBetaMin = min([min(thetaBetaEC), min(thetaBetaEO)]);
                    thetaBetaMax = max([max(thetaBetaEC), max(thetaBetaEO)]);
                    thetaAlphaMin = min([min(thetaAlphaEC), min(thetaAlphaEO)]);
                    thetaAlphaMax = max([max(thetaAlphaEC), max(thetaAlphaEO)]);

                    fprintf('  Computing topographic maps...\n');
                    fprintf('  θ/β range: [%.3f, %.3f]\n', thetaBetaMin, thetaBetaMax);
                    fprintf('  θ/α range: [%.3f, %.3f]\n', thetaAlphaMin, thetaAlphaMax);

                    % Plot topographic maps with common color scales
                    plotTopoMap(topoThetaBetaEC, thetaBetaEC, EEG, 'θ/β Ratio - Eyes Closed', [thetaBetaMin, thetaBetaMax]);
                    plotTopoMap(topoThetaBetaEO, thetaBetaEO, EEG, 'θ/β Ratio - Eyes Open', [thetaBetaMin, thetaBetaMax]);
                    plotTopoMap(topoThetaAlphaEC, thetaAlphaEC, EEG, 'θ/α Ratio - Eyes Closed', [thetaAlphaMin, thetaAlphaMax]);
                    plotTopoMap(topoThetaAlphaEO, thetaAlphaEO, EEG, 'θ/α Ratio - Eyes Open', [thetaAlphaMin, thetaAlphaMax]);
                else
                    fprintf('  ✗ No perChannel data found - topomaps cannot be generated\n');
                    fprintf('  Available fields in condition: %s\n', strjoin(fieldnames(restingMetrics.(condEC)), ', '));
                end
            else
                fprintf('  ✗ Could not find both closed and open conditions\n');
            end
        catch ME
            fprintf('  ✗ Topographic map generation failed: %s\n', ME.message);
            fprintf('  Error stack:\n%s\n', ME.getReport());
        end
    else
        fprintf('  ✗ Basic checks failed - skipping topomaps\n');
    end
    fprintf('=== END TOPOGRAPHIC MAP CHECK ===\n\n');
end

function plotTopoMap(ax, data, EEG, titleStr, colorLims)
    % Helper function to plot topographic maps
    % Inputs:
    %   ax - axes handle
    %   data - channel data values
    %   EEG - EEG structure with chanlocs
    %   titleStr - title string
    %   colorLims - [min max] color limits (optional)

    cla(ax);
    hold(ax, 'on');

    fprintf('Plotting topomap: %s\n', titleStr);
    fprintf('  Data size: %d channels\n', length(data));
    fprintf('  EEG chanlocs: %d\n', length(EEG.chanlocs));

    try
        % Simple approach: use cartesian coordinates directly
        if isfield(EEG.chanlocs, 'X') && isfield(EEG.chanlocs, 'Y')
            x = [EEG.chanlocs.X];
            y = [EEG.chanlocs.Y];
            z = [EEG.chanlocs.Z];

            % Project to 2D (top view)
            % Normalize to unit circle
            xy_dist = sqrt(x.^2 + y.^2);
            max_dist = max(xy_dist);
            if max_dist > 0
                x = x / max_dist * 0.45;  % Scale to 0.45 radius
                y = y / max_dist * 0.45;
            end

            fprintf('  X range: [%.2f, %.2f], Y range: [%.2f, %.2f]\n', min(x), max(x), min(y), max(y));

        elseif isfield(EEG.chanlocs, 'theta') && isfield(EEG.chanlocs, 'radius')
            % Use polar coordinates
            theta = [EEG.chanlocs.theta];
            radius = [EEG.chanlocs.radius];
            [x, y] = pol2cart(theta * pi/180, radius * 0.45);

        else
            error('No valid channel location coordinates found');
        end

        % Identify and exclude reference electrode from interpolation
        % Reference will be interpolated from surrounding electrodes instead
        refIdx = [];

        % Method 1: Try common reference electrode labels
        if isfield(EEG.chanlocs, 'labels')
            labels = {EEG.chanlocs.labels};
            fprintf('  [DEBUG] Looking for reference electrode in %d channels\n', length(labels));

            % Try multiple common reference electrode names
            refIdx = find(strcmpi(labels, 'Cz') | strcmpi(labels, 'CZ') | ...
                         strcmpi(labels, 'E129') | strcmpi(labels, 'REF') | ...
                         strcmpi(labels, 'VREF') | strcmpi(labels, 'Reference') | ...
                         strcmpi(labels, 'CMS') | strcmpi(labels, 'DRL'));

            if ~isempty(refIdx)
                fprintf('  [DEBUG] Found reference by label: index %d, label "%s"\n', ...
                    refIdx(1), labels{refIdx(1)});
            end
        end

        % Method 2: If not found by label, auto-detect by finding channel with lowest ratio value
        if isempty(refIdx)
            fprintf('  [DEBUG] Reference not found by label - auto-detecting by data value\n');

            % Find channel with minimum ratio value (likely the reference)
            [minVal, refIdx] = min(data);

            % Only use this if it's significantly lower than median (outlier check)
            medianVal = median(data);
            if minVal < 0.5 * medianVal  % Reference should be much lower
                fprintf('  [DEBUG] Auto-detected reference: index %d, value %.6f (median=%.6f)\n', ...
                    refIdx, minVal, medianVal);
                if isfield(EEG.chanlocs, 'labels')
                    fprintf('  [DEBUG] Auto-detected channel label: "%s"\n', EEG.chanlocs(refIdx).labels);
                end
            else
                fprintf('  [DEBUG] No clear reference outlier found (min=%.6f, median=%.6f)\n', minVal, medianVal);
                refIdx = [];  % Don't exclude anything
            end
        end

        % Create interpolation data excluding reference
        if ~isempty(refIdx)
            fprintf('  [DEBUG] EXCLUDING reference channel %d from interpolation\n', refIdx);
            fprintf('  [DEBUG] Reference data value: %.6f\n', data(refIdx));

            interpMask = true(size(x));
            interpMask(refIdx) = false;
            x_interp = x(interpMask);
            y_interp = y(interpMask);
            data_interp = data(interpMask);

            fprintf('  [DEBUG] Interpolation using %d channels (excluded reference)\n', length(x_interp));
        else
            fprintf('  [DEBUG] No reference electrode to exclude - using all %d channels\n', length(x));
            x_interp = x;
            y_interp = y;
            data_interp = data;
        end

        % Draw head outline
        headRadius = 0.5;
        angles = linspace(0, 2*pi, 100);
        plot(ax, headRadius * cos(angles), headRadius * sin(angles), 'k', 'LineWidth', 3);

        % Draw nose (triangle pointing up)
        noseX = [0.08, 0, -0.08, 0.08];
        noseY = [0.5, 0.58, 0.5, 0.5];
        plot(ax, noseX, noseY, 'k', 'LineWidth', 2);

        % Draw ears
        earWidth = 0.08;
        % Left ear
        plot(ax, [-0.5, -0.5-earWidth], [0.1, 0.1], 'k', 'LineWidth', 2);
        plot(ax, [-0.5, -0.5-earWidth], [-0.1, -0.1], 'k', 'LineWidth', 2);
        plot(ax, [-0.5-earWidth, -0.5-earWidth], [0.1, -0.1], 'k', 'LineWidth', 2);
        % Right ear
        plot(ax, [0.5, 0.5+earWidth], [0.1, 0.1], 'k', 'LineWidth', 2);
        plot(ax, [0.5, 0.5+earWidth], [-0.1, -0.1], 'k', 'LineWidth', 2);
        plot(ax, [0.5+earWidth, 0.5+earWidth], [0.1, -0.1], 'k', 'LineWidth', 2);

        % Create interpolated surface with room for overflow
        overfillRadius = headRadius * 1.2;  % Allow 20% overflow beyond head
        xi = linspace(-overfillRadius, overfillRadius, 120);
        yi = linspace(-overfillRadius, overfillRadius, 120);
        [Xi, Yi] = meshgrid(xi, yi);

        % Interpolate using only real electrode data (no extrapolation)
        % Natural interpolation within electrode array, NaN outside
        % Uses filtered data (excluding Cz) so reference electrode is interpolated
        F = scatteredInterpolant(x_interp', y_interp', data_interp, 'natural', 'none');
        Zi = F(Xi, Yi);

        % Don't mask - let colors overflow naturally based on interpolation
        % (Areas outside electrode convex hull will be NaN automatically)

        % Plot colored surface
        surf(ax, Xi, Yi, zeros(size(Zi)), Zi, 'EdgeColor', 'none', 'FaceAlpha', 0.9);

        % Plot electrode dots - very small and subtle to avoid obscuring interpolation
        scatter(ax, x, y, 5, 'k', 'filled', 'MarkerFaceAlpha', 0.15, 'MarkerEdgeColor', 'none');

        % Formatting
        colormap(ax, jet);
        cb = colorbar(ax);
        cb.Label.String = 'Ratio Value';
        cb.FontSize = 9;

        % Apply color limits if provided
        if nargin >= 5 && ~isempty(colorLims)
            caxis(ax, colorLims);
            fprintf('  Applied color limits: [%.3f, %.3f]\n', colorLims(1), colorLims(2));
        end

        axis(ax, 'equal');
        axis(ax, 'off');
        xlim(ax, [-overfillRadius overfillRadius]);
        ylim(ax, [-overfillRadius overfillRadius]);
        view(ax, 0, 90);
        title(ax, titleStr, 'FontSize', 11, 'FontWeight', 'bold');
        hold(ax, 'off');

        fprintf('  Topomap plotted successfully!\n');

    catch ME
        fprintf('  ERROR in topomap: %s\n', ME.message);

        % Ultra-simple fallback
        cla(ax);

        % Just draw a circle and some text
        angles = linspace(0, 2*pi, 100);
        plot(ax, cos(angles), sin(angles), 'k', 'LineWidth', 2);
        text(ax, 0, 0, sprintf('Topomap Error\n%s', ME.message), ...
            'HorizontalAlignment', 'center', 'FontSize', 8);
        axis(ax, 'equal', 'off');
        xlim(ax, [-1.2 1.2]);
        ylim(ax, [-1.2 1.2]);
        title(ax, titleStr, 'FontSize', 10);
    end
end
