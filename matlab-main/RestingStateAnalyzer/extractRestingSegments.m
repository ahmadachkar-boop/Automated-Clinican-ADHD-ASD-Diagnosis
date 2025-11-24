function segmentData = extractRestingSegments(EEG, startMarkerTypes, endMarkerTypes, segmentConditions, eventField)
    % Extract continuous EEG segments between start-end marker pairs
    % For resting state analysis (eyes open/closed, etc.)
    %
    % Inputs:
    %   EEG                - EEGLAB EEG structure
    %   startMarkerTypes   - Cell array of start marker strings
    %   endMarkerTypes     - Cell array of end marker strings
    %   segmentConditions  - Cell array of condition labels
    %   eventField         - Field name to use for matching (e.g., 'type')
    %
    % Output:
    %   segmentData        - Structure array with fields:
    %                        .condition - condition label
    %                        .data      - EEG data [channels x timepoints]
    %                        .times     - time vector
    %                        .startTime - start time in seconds
    %                        .endTime   - end time in seconds
    %                        .duration  - duration in seconds

    fprintf('\n=== Extracting Resting State Segments ===\n');

    if isempty(EEG.event)
        error('No events found in EEG data');
    end

    % Extract event values from the specified field
    eventValues = {};
    eventLatencies = [];
    for i = 1:length(EEG.event)
        if isfield(EEG.event(i), eventField)
            val = EEG.event(i).(eventField);
            if ischar(val) || isstring(val)
                eventValues{end+1} = char(val);
                eventLatencies(end+1) = EEG.event(i).latency;
            end
        end
    end

    fprintf('Found %d events in field ''%s''\n', length(eventValues), eventField);

    % Initialize segment storage
    segmentData = [];
    segmentCount = 0;

    % Process each condition
    for condIdx = 1:length(segmentConditions)
        startMarker = startMarkerTypes{condIdx};
        endMarker = endMarkerTypes{condIdx};
        condition = segmentConditions{condIdx};

        fprintf('\nProcessing condition: %s\n', condition);
        fprintf('  Start marker: %s\n', startMarker);
        fprintf('  End marker:   %s\n', endMarker);

        % Find all start and end indices
        startIndices = find(strcmp(eventValues, startMarker));
        endIndices = find(strcmp(eventValues, endMarker));

        fprintf('  Found %d start markers and %d end markers\n', ...
            length(startIndices), length(endIndices));

        % Match start-end pairs
        pairCount = 0;
        for sIdx = 1:length(startIndices)
            startEventIdx = startIndices(sIdx);
            startLat = eventLatencies(startEventIdx);

            % Find next end marker after this start
            validEnds = endIndices(endIndices > startEventIdx);
            if ~isempty(validEnds)
                endEventIdx = validEnds(1);
                endLat = eventLatencies(endEventIdx);

                % Check if there's another start marker between this start and end
                % (would indicate overlapping segments - skip if so)
                otherStarts = startIndices(startIndices > startEventIdx & startIndices < endEventIdx);
                if ~isempty(otherStarts)
                    fprintf('  Warning: Overlapping segment detected, skipping\n');
                    continue;
                end

                % Extract segment
                startSample = round(startLat);
                endSample = round(endLat);

                if startSample < 1 || endSample > size(EEG.data, 2)
                    fprintf('  Warning: Segment out of bounds, skipping\n');
                    continue;
                end

                if endSample <= startSample
                    fprintf('  Warning: Invalid segment range, skipping\n');
                    continue;
                end

                % Extract data
                segmentEEG = EEG.data(:, startSample:endSample);
                segmentTimes = (startSample:endSample) / EEG.srate;

                % Store segment
                segmentCount = segmentCount + 1;
                pairCount = pairCount + 1;

                segmentData(segmentCount).condition = condition;
                segmentData(segmentCount).data = segmentEEG;
                segmentData(segmentCount).times = segmentTimes;
                segmentData(segmentCount).startTime = startSample / EEG.srate;
                segmentData(segmentCount).endTime = endSample / EEG.srate;
                segmentData(segmentCount).duration = (endSample - startSample) / EEG.srate;
                segmentData(segmentCount).srate = EEG.srate;
                segmentData(segmentCount).chanlocs = EEG.chanlocs;
                segmentData(segmentCount).nbchan = EEG.nbchan;

                fprintf('  Segment %d: %.2f - %.2f sec (%.2f sec duration)\n', ...
                    pairCount, segmentData(segmentCount).startTime, ...
                    segmentData(segmentCount).endTime, segmentData(segmentCount).duration);
            end
        end

        fprintf('  Extracted %d segments for condition %s\n', pairCount, condition);
    end

    fprintf('\n=== Extraction Complete ===\n');
    fprintf('Total segments extracted: %d\n', segmentCount);

    if segmentCount == 0
        warning('No segments were extracted. Check your marker definitions.');
    end

    % Group segments by condition for summary
    uniqueConditions = unique({segmentData.condition});
    for i = 1:length(uniqueConditions)
        cond = uniqueConditions{i};
        condSegments = strcmp({segmentData.condition}, cond);
        totalDuration = sum([segmentData(condSegments).duration]);
        fprintf('  %s: %d segments, %.2f sec total\n', cond, sum(condSegments), totalDuration);
    end
end
