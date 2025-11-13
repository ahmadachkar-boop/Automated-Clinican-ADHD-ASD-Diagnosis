function launchJuanAnalyzer()
    % LAUNCHJUANANALYZER - Start the Juan Analyzer GUI
    %
    % Usage:
    %   launchJuanAnalyzer()
    %
    % This function initializes EEGLAB (if needed) and launches the
    % Juan Analyzer graphical interface for AI-powered ERP analysis.
    %
    % Requirements:
    %   - MATLAB R2018b or later
    %   - EEGLAB toolbox (https://sccn.ucsd.edu/eeglab/)
    %   - Signal Processing Toolbox
    %   - AI API Key (Anthropic Claude or OpenAI)
    %
    % Features:
    %   - AI-only event detection (no heuristics)
    %   - N400, N250, P600 component analysis
    %   - Frequency band analysis
    %   - Bad channel warnings (keeps channels)
    %   - Publication-ready visualizations
    %
    % Example:
    %   launchJuanAnalyzer()

    fprintf('\n========================================\n');
    fprintf('  Juan Analyzer\n');
    fprintf('  AI-Powered ERP Analysis Tool\n');
    fprintf('========================================\n\n');

    % Check MATLAB version
    if verLessThan('matlab', '9.5')
        error('MATLAB R2018b or later is required');
    end

    % Check for required toolboxes
    fprintf('Checking requirements...\n');

    % Signal Processing Toolbox
    if ~license('test', 'Signal_Toolbox')
        warning('Signal Processing Toolbox not found. Some features may not work.');
    else
        fprintf('✓ Signal Processing Toolbox found\n');
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

    % Check for mffimport plugin (for .mff files)
    fprintf('Checking EEGLAB plugins...\n');
    try
        which('pop_mffimport');
        fprintf('✓ mffimport plugin found\n');
    catch
        fprintf('  ℹ mffimport plugin not found (needed for .mff files)\n');
        fprintf('    Install from EEGLAB Plugin Manager if needed\n');
    end

    % Add current directory to path (where JuanAnalyzer files are)
    currentDir = fileparts(mfilename('fullpath'));
    addpath(currentDir);
    fprintf('✓ JuanAnalyzer path added: %s\n', currentDir);

    % Check AI integration files
    fprintf('Checking AI integration...\n');
    if exist('autoSelectTrialEventsUniversal.m', 'file')
        fprintf('✓ Universal event selection system found\n');
    else
        error('Universal event selection files not found. Please ensure all files are in path.');
    end

    % API key reminder
    fprintf('\n⚠ IMPORTANT: API Key Required\n');
    fprintf('  You will need either:\n');
    fprintf('    - Anthropic API key (for Claude)\n');
    fprintf('    - OpenAI API key (for GPT-4)\n\n');
    fprintf('  Set environment variable before launching:\n');
    fprintf('    setenv(''ANTHROPIC_API_KEY'', ''your-key'')\n');
    fprintf('    setenv(''OPENAI_API_KEY'', ''your-key'')\n\n');
    fprintf('  Or enter it in the GUI when prompted.\n\n');

    % Launch the GUI
    fprintf('✓ All checks passed!\n');
    fprintf('Launching Juan Analyzer...\n\n');

    try
        app = JuanAnalyzer();
        fprintf('✓ Application started successfully\n\n');
        fprintf('Getting Started:\n');
        fprintf('  1. Select your EEG file (.mff, .set, .edf)\n');
        fprintf('  2. Enter AI API key (or use environment variable)\n');
        fprintf('  3. Click "Start Analysis"\n');
        fprintf('  4. Wait for AI-powered processing\n');
        fprintf('  5. Review ERP components and frequency analysis\n');
        fprintf('  6. Export results if needed\n\n');

        fprintf('Features:\n');
        fprintf('  • 🤖 AI-Only Event Detection (Claude/OpenAI)\n');
        fprintf('  • 📊 ERP Components: N250, N400, P600\n');
        fprintf('  • 📈 Frequency Analysis: Delta-Gamma bands\n');
        fprintf('  • ⚙️  Complete Preprocessing Pipeline:\n');
        fprintf('       - Resample to 250 Hz\n');
        fprintf('       - High-pass filter: 0.5 Hz\n');
        fprintf('       - Low-pass filter: 50 Hz\n');
        fprintf('       - Notch filter: 60 Hz (±2 Hz)\n');
        fprintf('       - Average re-reference\n');
        fprintf('       - ICA artifact removal (>90%% threshold)\n');
        fprintf('  • ⚠️  Bad Channel Warnings (channels kept)\n');
        fprintf('  • 💾 Export results to .mat file\n\n');

    catch ME
        fprintf('\n❌ Error launching application:\n');
        fprintf('   %s\n\n', ME.message);

        if contains(ME.message, 'uifigure')
            fprintf('Note: This application requires MATLAB R2018b or later with App Designer.\n');
        end

        rethrow(ME);
    end
end
