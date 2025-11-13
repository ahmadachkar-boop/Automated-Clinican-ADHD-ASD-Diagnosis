% LAUNCHJUANANALYZER - Start the Juan Analyzer GUI
%
% This is a convenience launcher that adds the JuanAnalyzer folder
% to the path and launches the application.
%
% Usage:
%   From matlab root directory: launchJuanAnalyzer
%   Or from anywhere with full path

% Get the directory where this script is located
scriptDir = fileparts(which('launchJuanAnalyzer'));

% Add JuanAnalyzer folder to path
juanAnalyzerPath = fullfile(scriptDir, 'JuanAnalyzer');

if exist(juanAnalyzerPath, 'dir')
    addpath(juanAnalyzerPath);
    fprintf('========================================\n');
    fprintf('  Juan Analyzer\n');
    fprintf('  AI-Powered ERP Analysis Tool\n');
    fprintf('========================================\n\n');
    fprintf('✓ JuanAnalyzer path added: %s\n\n', juanAnalyzerPath);

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
    fprintf('Launching Juan Analyzer GUI...\n\n');
    try
        JuanAnalyzer();
        fprintf('✓ Application started successfully\n\n');
    catch ME
        fprintf('\n❌ Error launching application:\n');
        fprintf('   %s\n\n', ME.message);
        rethrow(ME);
    end
else
    error('JuanAnalyzer folder not found at: %s', juanAnalyzerPath);
end
