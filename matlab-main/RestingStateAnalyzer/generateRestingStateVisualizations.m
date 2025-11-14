function generateRestingStateVisualizations(restingMetrics, ax1, ax2, ax3, ax4)
    % Generate visualizations comparing resting state conditions
    % Shows band power comparisons between conditions (e.g., eyes open vs closed)
    %
    % Inputs:
    %   restingMetrics - Output from computeRestingStateMetrics
    %   ax1, ax2, ax3, ax4 - Axes handles for the 4 clinical tab plots

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

    % PLOT 4: Segment Statistics Summary
    cla(ax4);
    hold(ax4, 'off');
    axis(ax4, 'off');

    % Create text summary
    yPos = 0.95;
    lineHeight = 0.15;

    % Title
    text(ax4, 0.5, yPos, 'Segment Statistics', ...
        'Units', 'normalized', 'HorizontalAlignment', 'center', ...
        'FontSize', 14, 'FontWeight', 'bold');
    yPos = yPos - lineHeight;

    % For each condition
    for condIdx = 1:numConds
        cond = conditions{condIdx};
        condMetrics = restingMetrics.(cond);

        % Condition name
        yPos = yPos - lineHeight/2;
        text(ax4, 0.1, yPos, sprintf('%s:', cond), ...
            'Units', 'normalized', 'FontSize', 12, 'FontWeight', 'bold', ...
            'Color', colors(condIdx, :));
        yPos = yPos - lineHeight;

        % Stats
        text(ax4, 0.15, yPos, sprintf('Segments: %d', condMetrics.numSegments), ...
            'Units', 'normalized', 'FontSize', 10);
        yPos = yPos - lineHeight;

        text(ax4, 0.15, yPos, sprintf('Total Duration: %.2f sec', condMetrics.totalDuration), ...
            'Units', 'normalized', 'FontSize', 10);
        yPos = yPos - lineHeight;

        text(ax4, 0.15, yPos, sprintf('Mean Duration: %.2f sec', condMetrics.meanDuration), ...
            'Units', 'normalized', 'FontSize', 10);
        yPos = yPos - lineHeight;

        % Dominant band
        [maxPower, maxIdx] = max([condMetrics.relative.delta.mean, ...
            condMetrics.relative.theta.mean, ...
            condMetrics.relative.alpha.mean, ...
            condMetrics.relative.beta.mean, ...
            condMetrics.relative.gamma.mean]);
        dominantBand = upper(bandNames{maxIdx});
        text(ax4, 0.15, yPos, sprintf('Dominant Band: %s (%.1f%%)', dominantBand, maxPower), ...
            'Units', 'normalized', 'FontSize', 10, 'FontWeight', 'bold');
        yPos = yPos - lineHeight * 1.5;
    end

    % Alpha/Theta ratio comparison (eyes open vs closed marker)
    if numConds == 2
        yPos = yPos - lineHeight/2;
        text(ax4, 0.1, yPos, 'Clinical Indicators:', ...
            'Units', 'normalized', 'FontSize', 12, 'FontWeight', 'bold');
        yPos = yPos - lineHeight;

        for condIdx = 1:numConds
            cond = conditions{condIdx};
            alphaRel = restingMetrics.(cond).relative.alpha.mean;
            thetaRel = restingMetrics.(cond).relative.theta.mean;
            ratio = alphaRel / thetaRel;
            text(ax4, 0.15, yPos, sprintf('%s Alpha/Theta: %.2f', cond, ratio), ...
                'Units', 'normalized', 'FontSize', 10);
            yPos = yPos - lineHeight;
        end
    end
end
