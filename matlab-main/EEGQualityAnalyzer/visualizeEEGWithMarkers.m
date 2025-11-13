function visualizeEEGWithMarkers(EEG)
    % VISUALIZEEEGWITHMARKERS - Interactive visualization of EEG with event markers
    %
    % Usage:
    %   visualizeEEGWithMarkers(EEG)
    %
    % Input:
    %   EEG - EEGLAB EEG structure with event markers
    %
    % This creates an interactive plot showing:
    %   - Multiple EEG channels over time
    %   - Vertical lines at event markers
    %   - Color-coded event types
    %   - Event labels and timing information
    %
    % Example:
    %   EEG = pop_mffimport('yourfile.mff', {'code'});
    %   visualizeEEGWithMarkers(EEG);

    %% Detect events
    fprintf('Detecting event markers...\n');
    eventInfo = detectEEGEvents(EEG);

    if ~eventInfo.hasEvents
        fprintf('No events found in this EEG file.\n');
        return;
    end

    fprintf('Found %d events across %d types:\n', eventInfo.numEvents, length(eventInfo.eventTypes));
    for i = 1:length(eventInfo.eventTypes)
        fprintf('  %s: %d events\n', eventInfo.eventTypes{i}, eventInfo.eventCounts(i));
    end

    %% Setup figure
    figure('Name', 'EEG Timeline with Event Markers', ...
           'NumberTitle', 'off', ...
           'Position', [100 100 1400 800], ...
           'Color', 'w');

    %% Select channels to display (avoid clutter)
    % Display up to 8 channels evenly spaced
    numChanDisplay = min(8, EEG.nbchan);
    chanIdx = round(linspace(1, EEG.nbchan, numChanDisplay));

    % Get channel labels
    chanLabels = cell(numChanDisplay, 1);
    for i = 1:numChanDisplay
        if isfield(EEG.chanlocs, 'labels') && length(EEG.chanlocs) >= chanIdx(i)
            chanLabels{i} = EEG.chanlocs(chanIdx(i)).labels;
        else
            chanLabels{i} = sprintf('Ch%d', chanIdx(i));
        end
    end

    %% Prepare data
    % Time vector
    timeVec = (0:EEG.pnts-1) / EEG.srate;

    % Get data for selected channels
    data = EEG.data(chanIdx, :);

    % Normalize and offset channels for display
    dataDisplay = zeros(size(data));
    spacing = 100; % Spacing between channels in µV

    for i = 1:numChanDisplay
        % Normalize to reasonable scale
        channelData = data(i, :);
        channelData = channelData - mean(channelData); % Remove DC offset

        % Scale to fit display
        maxAmp = prctile(abs(channelData), 99); % Use 99th percentile to avoid outliers
        if maxAmp > 0
            channelData = channelData / maxAmp * (spacing * 0.4);
        end

        % Add vertical offset
        dataDisplay(i, :) = channelData + (numChanDisplay - i) * spacing;
    end

    %% Create main plot
    subplot('Position', [0.08 0.25 0.88 0.68]);
    hold on;

    % Plot EEG traces
    plot(timeVec, dataDisplay', 'Color', [0.3 0.3 0.3], 'LineWidth', 0.5);

    % Add channel labels on left
    yTicks = (1:numChanDisplay) * spacing;
    yTicks = fliplr(yTicks);

    for i = 1:numChanDisplay
        yPos = (numChanDisplay - i) * spacing;
        text(-EEG.xmax*0.02, yPos, chanLabels{i}, ...
             'FontSize', 10, 'FontWeight', 'bold', ...
             'HorizontalAlignment', 'right', 'Color', [0.2 0.3 0.5]);
    end

    %% Plot event markers
    % Assign colors to event types
    eventColors = [
        0.8 0.2 0.2;  % Red
        0.2 0.4 0.8;  % Blue
        0.2 0.8 0.2;  % Green
        0.8 0.6 0.2;  % Orange
        0.6 0.2 0.8;  % Purple
        0.8 0.2 0.6;  % Magenta
        0.2 0.8 0.8;  % Cyan
    ];

    % Create color map for each event type
    eventTypeMap = containers.Map();
    for i = 1:length(eventInfo.eventTypes)
        colorIdx = mod(i-1, size(eventColors, 1)) + 1;
        eventTypeMap(eventInfo.eventTypes{i}) = eventColors(colorIdx, :);
    end

    % Extract event latencies and types
    events = EEG.event;
    eventLatencies = [];
    eventTypes = {};
    eventLabels = {};

    for i = 1:length(events)
        % Get latency in seconds
        if isfield(events, 'latency') && ~isempty(events(i).latency)
            latSec = (events(i).latency - 1) / EEG.srate;

            % Find event type
            type_fields = {'type', 'code', 'label', 'name'};
            eventType = '';
            for f = 1:length(type_fields)
                field = type_fields{f};
                if isfield(events, field) && ~isempty(events(i).(field))
                    value = events(i).(field);
                    if ischar(value)
                        eventType = value;
                        break;
                    elseif isnumeric(value)
                        eventType = num2str(value);
                        break;
                    end
                end
            end

            if ~isempty(eventType)
                eventLatencies(end+1) = latSec;
                eventTypes{end+1} = eventType;
                eventLabels{end+1} = sprintf('%s\n%.2fs', eventType, latSec);
            end
        end
    end

    % Plot vertical lines for events
    yLimits = ylim;
    for i = 1:length(eventLatencies)
        if eventTypeMap.isKey(eventTypes{i})
            color = eventTypeMap(eventTypes{i});
        else
            color = [0.5 0.5 0.5]; % Gray for unknown
        end

        % Draw vertical line
        line([eventLatencies(i) eventLatencies(i)], yLimits, ...
             'Color', color, 'LineWidth', 2, 'LineStyle', '--');

        % Add event label at top
        text(eventLatencies(i), yLimits(2), sprintf(' %s ', eventTypes{i}), ...
             'FontSize', 9, 'FontWeight', 'bold', ...
             'Color', color, 'Rotation', 90, ...
             'VerticalAlignment', 'bottom');
    end

    % Formatting
    xlabel('Time (seconds)', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Channels', 'FontSize', 12, 'FontWeight', 'bold');
    title(sprintf('EEG Recording with Event Markers (Total: %d events)', length(eventLatencies)), ...
          'FontSize', 14, 'FontWeight', 'bold');
    xlim([0 EEG.xmax]);
    grid on;
    set(gca, 'YTick', []);
    hold off;

    %% Create event timeline below
    subplot('Position', [0.08 0.08 0.88 0.12]);
    hold on;

    % Draw timeline
    plot([0 EEG.xmax], [0.5 0.5], 'k-', 'LineWidth', 2);

    % Plot events on timeline
    for i = 1:length(eventLatencies)
        if eventTypeMap.isKey(eventTypes{i})
            color = eventTypeMap(eventTypes{i});
        else
            color = [0.5 0.5 0.5];
        end

        % Draw event marker
        plot(eventLatencies(i), 0.5, 'v', ...
             'MarkerSize', 12, 'MarkerFaceColor', color, ...
             'MarkerEdgeColor', 'k', 'LineWidth', 1);
    end

    % Formatting
    xlabel('Time (seconds)', 'FontSize', 12, 'FontWeight', 'bold');
    title('Event Timeline', 'FontSize', 12, 'FontWeight', 'bold');
    xlim([0 EEG.xmax]);
    ylim([0 1]);
    set(gca, 'YTick', []);
    grid on;
    hold off;

    %% Create legend for event types
    legendEntries = cell(length(eventInfo.eventTypes), 1);
    legendColors = zeros(length(eventInfo.eventTypes), 3);

    for i = 1:length(eventInfo.eventTypes)
        legendEntries{i} = sprintf('%s (%d)', eventInfo.eventTypes{i}, eventInfo.eventCounts(i));
        if eventTypeMap.isKey(eventInfo.eventTypes{i})
            legendColors(i, :) = eventTypeMap(eventInfo.eventTypes{i});
        end
    end

    % Add legend patches
    subplot('Position', [0.08 0.25 0.88 0.68]);
    hold on;
    legendHandles = [];
    for i = 1:length(legendEntries)
        h = plot(NaN, NaN, 's', 'MarkerSize', 10, ...
                 'MarkerFaceColor', legendColors(i, :), ...
                 'MarkerEdgeColor', 'k', 'LineWidth', 1);
        legendHandles(end+1) = h;
    end
    legend(legendHandles, legendEntries, 'Location', 'northeastoutside', ...
           'FontSize', 10);
    hold off;

    %% Print summary
    fprintf('\n=== Event Summary ===\n');
    fprintf('Recording duration: %.2f seconds (%.2f minutes)\n', EEG.xmax, EEG.xmax/60);
    fprintf('Total events: %d\n', length(eventLatencies));

    % Calculate inter-event intervals for each type
    for i = 1:length(eventInfo.eventTypes)
        eventType = eventInfo.eventTypes{i};
        typeLatencies = [];

        for j = 1:length(eventLatencies)
            if strcmp(eventTypes{j}, eventType)
                typeLatencies(end+1) = eventLatencies(j);
            end
        end

        if length(typeLatencies) > 1
            intervals = diff(typeLatencies);
            fprintf('\n%s events:\n', eventType);
            fprintf('  Count: %d\n', length(typeLatencies));
            fprintf('  First at: %.2f s\n', typeLatencies(1));
            fprintf('  Last at: %.2f s\n', typeLatencies(end));
            fprintf('  Mean interval: %.2f s (SD: %.2f s)\n', mean(intervals), std(intervals));
        else
            fprintf('\n%s events:\n', eventType);
            fprintf('  Count: %d at %.2f s\n', length(typeLatencies), typeLatencies(1));
        end
    end

    fprintf('\n✓ Visualization complete! Use zoom/pan tools to explore.\n');
end
