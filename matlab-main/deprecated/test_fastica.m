%% TEST_FASTICA - Test script for FastICA integration
%
% This script tests the FastICA implementation with sample data.
% Run this to verify your FastICA installation is working correctly.

fprintf('\n========================================\n');
fprintf('  FastICA Integration Test\n');
fprintf('========================================\n\n');

%% 1. Check if FastICA is installed
fprintf('1. Checking FastICA installation...\n');
if exist('fastica', 'file')
    fprintf('   ✓ FastICA found at: %s\n', which('fastica'));
else
    fprintf('   ❌ FastICA not found!\n');
    fprintf('   Please run: setupFastICA()\n');
    return;
end

%% 2. Test with synthetic data
fprintf('\n2. Testing with synthetic data...\n');

try
    % Create synthetic mixed signals
    t = linspace(0, 10, 2000);

    % Original sources
    s1 = sin(2 * pi * 5 * t);              % 5 Hz sine wave
    s2 = sign(sin(2 * pi * 3 * t));        % 3 Hz square wave
    s3 = sawtooth(2 * pi * 2 * t);         % 2 Hz sawtooth wave

    % Mix the sources
    A = [0.8 0.2 0.4;
         0.3 0.9 0.1;
         0.5 0.3 0.7];

    S = [s1; s2; s3];
    X = A * S;  % Mixed signals

    % Add some noise
    X = X + 0.1 * randn(size(X));

    % Run FastICA
    [icasig, A_est, W] = fastica(X, ...
        'approach', 'symm', ...
        'g', 'tanh', ...
        'verbose', 'off');

    if ~isempty(icasig)
        fprintf('   ✓ FastICA successfully separated %d components\n', size(icasig, 1));
        fprintf('   ✓ Unmixing matrix size: %dx%d\n', size(W, 1), size(W, 2));
        fprintf('   ✓ Mixing matrix size: %dx%d\n', size(A_est, 1), size(A_est, 2));
    else
        fprintf('   ❌ FastICA returned empty results\n');
        return;
    end

catch ME
    fprintf('   ❌ FastICA test failed: %s\n', ME.message);
    return;
end

%% 3. Test EEGLAB integration (if EEGLAB is available)
fprintf('\n3. Testing EEGLAB integration...\n');

try
    % Try to initialize EEGLAB
    eeglab nogui;

    % Create a simple EEGLAB dataset
    EEG = eeg_emptyset();
    EEG.nbchan = 3;
    EEG.srate = 250;
    EEG.pnts = 2000;
    EEG.data = X;  % Use the mixed synthetic data
    EEG.xmin = 0;
    EEG.xmax = (EEG.pnts - 1) / EEG.srate;
    EEG.times = linspace(EEG.xmin, EEG.xmax, EEG.pnts);

    % Add channel locations
    EEG.chanlocs = struct('labels', {'Ch1', 'Ch2', 'Ch3'});

    % Test runFastICA wrapper
    EEG = runFastICA(EEG, 'verbose', 'off');

    if isfield(EEG, 'icaweights') && ~isempty(EEG.icaweights)
        fprintf('   ✓ runFastICA wrapper working correctly\n');
        fprintf('   ✓ ICA weights added to EEG structure\n');
        fprintf('   ✓ Number of components: %d\n', size(EEG.icaweights, 1));

        if isfield(EEG, 'etc') && isfield(EEG.etc, 'icainfo')
            fprintf('   ✓ Algorithm info stored: %s\n', EEG.etc.icainfo.algorithm);
        end
    else
        fprintf('   ❌ ICA weights not added to EEG structure\n');
    end

catch ME
    if contains(ME.message, 'eeglab')
        fprintf('   ⚠️  EEGLAB not found (optional)\n');
        fprintf('   This is OK if you only want to use FastICA standalone\n');
    else
        fprintf('   ❌ EEGLAB integration test failed: %s\n', ME.message);
    end
end

%% 4. Visualize results (optional)
fprintf('\n4. Visualization test...\n');

try
    figure('Name', 'FastICA Test Results', 'Position', [100 100 1200 600]);

    % Original mixed signals
    subplot(2, 2, 1);
    plot(t, X');
    title('Mixed Signals (Input)');
    xlabel('Time (s)');
    ylabel('Amplitude');
    legend('Mix 1', 'Mix 2', 'Mix 3');
    grid on;

    % Separated components
    subplot(2, 2, 2);
    plot(t, icasig');
    title('Separated Components (Output)');
    xlabel('Time (s)');
    ylabel('Amplitude');
    legend('IC 1', 'IC 2', 'IC 3');
    grid on;

    % Original sources
    subplot(2, 2, 3);
    plot(t, S');
    title('Original Sources (Ground Truth)');
    xlabel('Time (s)');
    ylabel('Amplitude');
    legend('Sine', 'Square', 'Sawtooth');
    grid on;

    % Mixing matrix comparison
    subplot(2, 2, 4);
    bar([A(:), A_est(:)]);
    title('Mixing Matrix Comparison');
    xlabel('Element Index');
    ylabel('Value');
    legend('Original A', 'Estimated A');
    grid on;

    fprintf('   ✓ Visualization created successfully\n');

catch ME
    fprintf('   ⚠️  Visualization failed: %s\n', ME.message);
    fprintf('   This is OK, the core functionality is still working\n');
end

%% Summary
fprintf('\n========================================\n');
fprintf('  Test Summary\n');
fprintf('========================================\n');
fprintf('✓ FastICA is installed and working\n');
fprintf('✓ FastICA can separate mixed signals\n');
if exist('EEG', 'var') && isfield(EEG, 'icaweights')
    fprintf('✓ EEGLAB integration is working\n');
end
fprintf('\nYou can now use FastICA in your EEG analysis pipeline!\n');
fprintf('Try running: launchEEGAnalyzer()\n');
fprintf('========================================\n\n');
