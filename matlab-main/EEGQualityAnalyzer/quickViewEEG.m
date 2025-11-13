% QUICK VIEW EEG WITH MARKERS
% Simple script to visualize your EEG data with event markers
%
% Instructions:
%   1. Run this script (press F5 or type: quickViewEEG)
%   2. Select your EEG file from the dialog
%   3. View the interactive visualization!
%
% The visualization will show:
%   - Multiple EEG channels over the entire recording
%   - Vertical lines at event markers (color-coded by type)
%   - Event timeline at the bottom
%   - Statistics about event timing

%% Initialize EEGLAB (if not already done)
if ~exist('ALLCOM', 'var')
    fprintf('Initializing EEGLAB...\n');
    eeglab nogui;
end

%% Open file picker dialog
fprintf('Opening file picker...\n');
[file, path] = uigetfile({...
    '*.mff', 'MFF Files (*.mff)'; ...
    '*.set', 'EEGLAB SET Files (*.set)'; ...
    '*.edf', 'EDF Files (*.edf)'; ...
    '*.fif', 'FIF Files (*.fif)'; ...
    '*.*', 'All Files (*.*)'}, ...
    'Select EEG File');

% Check if user cancelled
if file == 0
    fprintf('File selection cancelled.\n');
    return;
end

eegFile = fullfile(path, file);

%% Load EEG file
fprintf('Loading EEG file: %s\n', eegFile);

[~, ~, ext] = fileparts(eegFile);

try
    if strcmp(ext, '.mff')
        EEG = pop_mffimport(eegFile, {'code'});
    elseif strcmp(ext, '.set')
        EEG = pop_loadset(eegFile);
    elseif strcmp(ext, '.edf')
        EEG = pop_biosig(eegFile);
    elseif strcmp(ext, '.fif')
        EEG = pop_fileio(eegFile);
    else
        error('Unsupported file format: %s', ext);
    end

    fprintf('✓ Loaded successfully!\n');
    fprintf('  Duration: %.2f seconds (%.2f minutes)\n', EEG.xmax, EEG.xmax/60);
    fprintf('  Channels: %d\n', EEG.nbchan);
    fprintf('  Sample rate: %d Hz\n', EEG.srate);

    %% Visualize
    visualizeEEGWithMarkers(EEG);

catch ME
    fprintf('Error loading file: %s\n', ME.message);
    fprintf('\nTroubleshooting:\n');
    fprintf('  1. Check that the file format is supported\n');
    fprintf('  2. Make sure EEGLAB is properly installed\n');
    fprintf('  3. For .mff files, ensure mffmatlabio plugin is installed\n');
    fprintf('  4. Try: eegplugin_mffmatlabio or install from EEGLAB plugin manager\n');
end
