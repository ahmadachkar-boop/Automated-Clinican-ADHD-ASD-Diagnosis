% Quick FastICA test
fprintf('Testing FastICA implementation...\n');

% Create test data
t = linspace(0, 10, 2000);
s1 = sin(2 * pi * 5 * t);
s2 = sign(sin(2 * pi * 3 * t));
s3 = sawtooth(2 * pi * 2 * t);

% Mix signals
A = [0.8 0.2 0.4; 0.3 0.9 0.1; 0.5 0.3 0.7];
S = [s1; s2; s3];
X = A * S + 0.1 * randn(size(A * S));

% Run FastICA
[icasig, A_est, W] = fastica(X, 'verbose', 'on');

fprintf('\n✓ FastICA completed successfully!\n');
fprintf('  Input: %d mixed signals\n', size(X, 1));
fprintf('  Output: %d independent components\n', size(icasig, 1));
fprintf('  Unmixing matrix: %dx%d\n', size(W, 1), size(W, 2));
