%% BENCHMARK_ICA - Compare FastICA vs runica performance
%
% This script benchmarks the speed of FastICA vs EEGLAB's runica

fprintf('\n========================================\n');
fprintf('  ICA Performance Benchmark\n');
fprintf('========================================\n\n');

% Test with different data sizes
test_cases = [
    16, 30000;   % Small: 16 channels, 2 min @ 250 Hz
    32, 60000;   % Medium: 32 channels, 4 min @ 250 Hz
    64, 30000;   % Large: 64 channels, 2 min @ 250 Hz
];

results = struct();

for tc = 1:size(test_cases, 1)
    nchans = test_cases(tc, 1);
    npnts = test_cases(tc, 2);

    fprintf('Test %d: %d channels, %d timepoints (%.1f min @ 250 Hz)\n', ...
        tc, nchans, npnts, npnts/250/60);
    fprintf('--------------------------------------------------\n');

    % Generate random EEG-like data
    data = randn(nchans, npnts);

    % Test FastICA
    fprintf('  Running FastICA...\n');
    tic;
    [icasig_fast, A_fast, W_fast] = fastica(data, 'verbose', 'off');
    time_fastica = toc;
    fprintf('  ✓ FastICA completed in %.2f seconds\n', time_fastica);

    % Test runica (if EEGLAB available)
    try
        eeglab nogui;
        EEG = eeg_emptyset();
        EEG.data = data;
        EEG.nbchan = nchans;
        EEG.pnts = npnts;
        EEG.srate = 250;

        fprintf('  Running runica...\n');
        tic;
        EEG = pop_runica(EEG, 'icatype', 'runica', 'extended', 1);
        time_runica = toc;
        fprintf('  ✓ runica completed in %.2f seconds\n', time_runica);

        % Calculate speedup
        speedup = time_runica / time_fastica;
        fprintf('\n  Speedup: %.2fx %s\n', abs(speedup), ...
            speedup > 1 ? '(FastICA faster)' : '(runica faster)');

        results(tc).fastica_time = time_fastica;
        results(tc).runica_time = time_runica;
        results(tc).speedup = speedup;
    catch
        fprintf('  ⚠️  runica not available (EEGLAB not found)\n');
        results(tc).fastica_time = time_fastica;
        results(tc).runica_time = NaN;
        results(tc).speedup = NaN;
    end

    results(tc).nchans = nchans;
    results(tc).npnts = npnts;

    fprintf('\n');
end

%% Summary
fprintf('========================================\n');
fprintf('  Summary\n');
fprintf('========================================\n');
for tc = 1:length(results)
    fprintf('Test %d (%d ch, %d pts):\n', tc, results(tc).nchans, results(tc).npnts);
    fprintf('  FastICA: %.2f sec\n', results(tc).fastica_time);
    if ~isnan(results(tc).runica_time)
        fprintf('  runica:  %.2f sec\n', results(tc).runica_time);
        fprintf('  Speedup: %.2fx\n', results(tc).speedup);
    end
    fprintf('\n');
end
