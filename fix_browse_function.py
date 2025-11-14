#!/usr/bin/env python3
"""Replace browseFile and remove old helper functions"""

# Read the file
with open('matlab-main/EEGQualityAnalyzer/EEGQualityAnalyzer.m', 'r') as f:
    lines = f.readlines()

# Find line numbers
browse_start = None
detect_markers_start = None

for i, line in enumerate(lines):
    if 'function browseFile(app)' in line and browse_start is None:
        browse_start = i
    if 'function detectMarkersFromField(app)' in line:
        detect_markers_start = i
        break

print(f"Found browseFile at line {browse_start + 1}")
print(f"Found detectMarkersFromField at line {detect_markers_start + 1}")

# JuanAnalyzer's browseFile function
juan_browse = '''        function browseFile(app)
            [file, path] = uigetfile({'*.mff;*.set;*.edf', 'EEG Files (*.mff, *.set, *.edf)'}, ...
                'Select EEG File');

            if file == 0
                return;
            end

            app.EEGFile = fullfile(path, file);
            app.FileInfoLabel.Text = sprintf('Loading: %s...', file);
            app.FileInfoLabel.FontColor = [0.5 0.5 0.5];
            drawnow;

            % Load file
            try
                if endsWith(file, '.mff')
                    EEG = pop_mffimport(app.EEGFile, {});
                else
                    EEG = pop_loadset(app.EEGFile);
                end
                app.EEG = EEG;
                app.FileInfoLabel.Text = sprintf('%s | %d channels | %d events | %.1f sec', ...
                    file, EEG.nbchan, length(EEG.event), EEG.xmax);
                app.FileInfoLabel.FontColor = [0.2 0.6 0.3];
                app.EventSelectionButton.Enable = 'on';
            catch ME
                uialert(app.UIFigure, sprintf('Failed to load file: %s', ME.message), 'Load Error');
                app.FileInfoLabel.Text = 'File load failed';
                app.FileInfoLabel.FontColor = [0.8 0.2 0.2];
            end
        end

'''

# Replace lines from browseFile to just before detectMarkersFromField
new_lines = lines[:browse_start] + [juan_browse] + lines[detect_markers_start:]

# Write back
with open('matlab-main/EEGQualityAnalyzer/EEGQualityAnalyzer.m', 'w') as f:
    f.writelines(new_lines)

print(f"✅ browseFile function replaced!")
print(f"   Removed {detect_markers_start - browse_start} old lines (browseFile + loadFileInfo)")
print(f"   Added simple browseFile from JuanAnalyzer")
