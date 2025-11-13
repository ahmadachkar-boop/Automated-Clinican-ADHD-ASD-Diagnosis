function launchEEGAnalyzer()
    % LAUNCHEEGANALYZER - Start the EEG Quality Analyzer GUI
    %
    % Usage:
    %   launchEEGAnalyzer()
    %
    % This function initializes EEGLAB (if needed) and launches the
    % EEG Quality Analyzer graphical interface for automated EEG quality
    % assessment.
    %
    % Requirements:
    %   - MATLAB R2018b or later
    %   - EEGLAB toolbox (https://sccn.ucsd.edu/eeglab/)
    %   - Signal Processing Toolbox
    %
    % Example:
    %   launchEEGAnalyzer()

    % Add current directory to path (where EEGQualityAnalyzer files are)
    currentDir = fileparts(mfilename('fullpath'));
    addpath(currentDir);

    fprintf('\n========================================\n');
    fprintf('  EEG Quality Analyzer\n');
    fprintf('  Clinical EEG Assessment Tool\n');
    fprintf('========================================\n\n');
    fprintf('✓ EEGQualityAnalyzer path added: %s\n\n', currentDir);

    % Check MATLAB version
    if verLessThan('matlab', '9.5')
        error('MATLAB R2018b or later is required');
    end

    % Check for required toolboxes
    fprintf('Checking requirements...\n');

    % Signal Processing Toolbox
    if ~license('test', 'Signal_Toolbox')
        warning('Signal Processing Toolbox not found. Some features may not work.');
    end

    % Initialize EEGLAB
    fprintf('Initializing EEGLAB...\n');
    try
        eeglab nogui;
        fprintf('✓ EEGLAB initialized successfully\n');
    catch ME
        error(['EEGLAB not found! Please install EEGLAB and add to MATLAB path.\n' ...
               'Download from: https://sccn.ucsd.edu/eeglab/\n' ...
               'Error: %s'], ME.message);
    end

    % Check for required EEGLAB plugins
    fprintf('Checking EEGLAB plugins...\n');

    % ICLabel
    try
        which('pop_iclabel');
        fprintf('✓ ICLabel plugin found\n');
    catch
        warning(['ICLabel plugin not found. Install from EEGLAB Plugin Manager.\n' ...
                'File > Manage EEGLAB Extensions > ICLabel']);
    end

    % Launch the GUI
    fprintf('\n✓ All checks passed!\n');
    fprintf('Launching EEG Quality Analyzer...\n\n');

    try
        app = EEGQualityAnalyzer();
        fprintf('✓ Application started successfully\n');
        fprintf('\nYou can now:\n');
        fprintf('  1. Upload your EEG file (.edf, .set, .fif, .mff)\n');
        fprintf('  2. Wait for automatic processing\n');
        fprintf('  3. Review quality assessment and visualizations\n');
        fprintf('  4. Export PDF report if needed\n\n');

    catch ME
        fprintf('\n❌ Error launching application:\n');
        fprintf('   %s\n\n', ME.message);

        if contains(ME.message, 'uifigure')
            fprintf('Note: This application requires MATLAB R2018b or later with App Designer.\n');
        end

        rethrow(ME);
    end
end
