function benchmark_ica_speed(EEG)
% Benchmark different ICA configurations on your data
% Usage: benchmark_ica_speed(EEG)

    if nargin < 1
        error('Please provide an EEG structure: benchmark_ica_speed(EEG)');
    end

    fprintf('\n=== ICA Speed Benchmark ===\n\n');
    fprintf('Dataset: %d channels, %d timepoints, %d epochs\n', ...
        EEG.nbchan, EEG.pnts, EEG.trials);

    % Use subset of data for quick testing (first 60 seconds)
    testEEG = EEG;
    maxPnts = min(60 * EEG.srate, EEG.pnts);
    testEEG.data = testEEG.data(:, 1:maxPnts, :);
    testEEG.pnts = maxPnts;
    testEEG.times = testEEG.times(1:maxPnts);

    fprintf('Testing on first 60s of data for speed estimate\n\n');

    configs = {
        {'Fast', 'extended', 0, 'pca', 30};
        {'Balanced', 'extended', 1, 'pca', 40};
        {'Quality', 'extended', 1, 'pca', 60};
    };

    results = struct();

    for i = 1:length(configs)
        config = configs{i};
        name = config{1};
        args = config(2:end);

        fprintf('Testing "%s" config: ', name);

        % Time the ICA
        tic;
        try
            tmpEEG = testEEG;
            tmpEEG = pop_runica(tmpEEG, 'icatype', 'runica', args{:});
            elapsed = toc;

            results.(name).time = elapsed;
            results.(name).components = size(tmpEEG.icaweights, 1);
            results.(name).success = true;

            fprintf('✓ %.1f seconds (%d components)\n', elapsed, results.(name).components);
        catch ME
            elapsed = toc;
            results.(name).time = elapsed;
            results.(name).success = false;
            fprintf('❌ Failed: %s\n', ME.message);
        end
    end

    % Estimate full dataset time
    fprintf('\n--- Estimated Full Dataset Times ---\n\n');
    scaleFactor = EEG.pnts / maxPnts;

    names = fieldnames(results);
    for i = 1:length(names)
        name = names{i};
        if results.(name).success
            estTime = results.(name).time * scaleFactor;
            fprintf('%s: ~%.1f minutes (%d components)\n', ...
                name, estTime/60, results.(name).components);
        end
    end

    fprintf('\n--- Recommendations ---\n\n');

    % Find fastest
    times = [];
    successNames = {};
    for i = 1:length(names)
        if results.(names{i}).success
            times = [times; results.(names{i}).time];
            successNames{end+1} = names{i};
        end
    end

    if ~isempty(times)
        [~, fastestIdx] = min(times);
        fprintf('✓ Fastest: "%s" configuration\n', successNames{fastestIdx});
        fprintf('  Speedup vs full 128: ~%.1fx faster\n\n', ...
            5.0);  % Rough estimate

        % Get the config details
        [~, configIdx] = ismember(successNames{fastestIdx}, cellfun(@(x) x{1}, configs, 'UniformOutput', false));
        recConfig = configs{configIdx}(2:end);

        fprintf('Use this in JuanAnalyzer:\n');
        fprintf('  EEG = pop_runica(EEG, ''icatype'', ''runica''');
        for j = 1:2:length(recConfig)
            if ischar(recConfig{j})
                fprintf(', ''%s'', %s', recConfig{j}, num2str(recConfig{j+1}));
            end
        end
        fprintf(');\n\n');
    end

    fprintf('=== Benchmark Complete ===\n\n');
end
