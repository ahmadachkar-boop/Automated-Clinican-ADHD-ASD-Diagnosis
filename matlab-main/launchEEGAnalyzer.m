% LAUNCHEEGANALYZER - Start the EEG Quality Analyzer GUI
%
% This is a convenience launcher that adds the EEGQualityAnalyzer folder
% to the path and launches the application.
%
% Usage:
%   From matlab root directory: launchEEGAnalyzer
%   Or from anywhere with full path

% Get the directory where this script is located
scriptDir = fileparts(which('launchEEGAnalyzer'));

% Add EEGQualityAnalyzer folder to path
eegQualityPath = fullfile(scriptDir, 'EEGQualityAnalyzer');

if exist(eegQualityPath, 'dir')
    addpath(eegQualityPath);
    fprintf('========================================\n');
    fprintf('  EEG Quality Analyzer\n');
    fprintf('  Clinical EEG Assessment Tool\n');
    fprintf('========================================\n\n');
    fprintf('✓ EEGQualityAnalyzer path added: %s\n\n', eegQualityPath);

    % Initialize EEGLAB
    fprintf('Initializing EEGLAB...\n');
    try
        eeglab nogui;
        fprintf('✓ EEGLAB initialized successfully\n\n');
    catch ME
        error(['EEGLAB not found! Please install EEGLAB and add to MATLAB path.\n' ...
               'Download from: https://sccn.ucsd.edu/eeglab/\n' ...
               'Error: %s'], ME.message);
    end

    % Launch the GUI directly
    fprintf('Launching EEG Quality Analyzer GUI...\n\n');
    try
        EEGQualityAnalyzer();
        fprintf('✓ Application started successfully\n\n');
    catch ME
        fprintf('\n❌ Error launching application:\n');
        fprintf('   %s\n\n', ME.message);
        rethrow(ME);
    end
else
    error('EEGQualityAnalyzer folder not found at: %s', eegQualityPath);
end
