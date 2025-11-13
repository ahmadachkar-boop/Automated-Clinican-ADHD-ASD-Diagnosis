% MATLAB Startup Script for EEG Analysis Optimization
%
% To use this:
% 1. Copy this file to: ~/Documents/MATLAB/startup.m
% 2. It will run automatically every time MATLAB starts
%
% Or manually run: startup_template

fprintf('Initializing EEG analysis environment...\n');

%% 1. Enable Multi-Threading for BLAS/LAPACK
% This speeds up matrix operations in runica, ICA, and other linear algebra
maxNumCompThreads('automatic');
fprintf('✓ BLAS multi-threading enabled (%d threads)\n', maxNumCompThreads());

%% 2. Set EEGLAB Path (if installed)
% Modify this path to your EEGLAB installation
eeglabPath = '/Applications/EEGLAB';  % Common macOS location
if exist(eeglabPath, 'dir')
    addpath(eeglabPath);
    fprintf('✓ EEGLAB path added\n');
end

%% 3. Optimize Java Heap (if using GUI apps)
% Increases memory for Java-based GUI components
try
    currentHeap = java.lang.Runtime.getRuntime.maxMemory / 1024^3;
    fprintf('  Java heap: %.1f GB\n', currentHeap);
catch
    % Java heap info not available
end

%% 4. Set Default Figure Renderer
% 'painters' is faster for 2D plots, 'opengl' for 3D
set(0, 'DefaultFigureRenderer', 'painters');

%% 5. Display System Info
if ismac
    [~, cpuInfo] = system('sysctl -n machdep.cpu.brand_string');
    fprintf('  CPU: %s', cpuInfo);

    [~, memInfo] = system('sysctl -n hw.memsize');
    memGB = str2double(memInfo) / 1024^3;
    fprintf('  RAM: %.1f GB\n', memGB);
end

%% 6. Pre-allocate Parallel Pool (optional)
% Uncomment if you have Parallel Computing Toolbox and want to use it
% if license('test', 'Distrib_Computing_Toolbox')
%     try
%         parpool(4);  % Adjust number of workers for your CPU
%         fprintf('✓ Parallel pool started\n');
%     catch
%         fprintf('  Parallel pool already active or unavailable\n');
%     end
% end

fprintf('Environment ready!\n\n');
