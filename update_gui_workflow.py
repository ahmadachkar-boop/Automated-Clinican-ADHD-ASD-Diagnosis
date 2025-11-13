#!/usr/bin/env python3
"""
Script to update EEGQualityAnalyzer.m to use JuanAnalyzer's upload workflow
This replaces the complex epoch builder with simple 2-step event selection
"""

import re

# Read both files
with open('matlab-main/EEGQualityAnalyzer/EEGQualityAnalyzer.m', 'r') as f:
    eeg_content = f.read()

with open('matlab-main/JuanAnalyzerManual/JuanAnalyzer.m', 'r') as f:
    juan_content = f.read()

print("Updating EEGQualityAnalyzer to match JuanAnalyzer workflow...")

# Step 1: Replace upload screen properties
print("1. Replacing upload screen properties...")
old_props = r'''        % Upload Screen Components
        DropZonePanel.*?
        DropZoneLabel.*?
        BrowseButton.*?
        FileInfoPanel.*?
        FilenameLabel.*?
        DurationLabel.*?
        ChannelsLabel.*?
        EventsDetectedLabel.*?

        % Event Field Selection Components
        EventFieldLabel.*?
        EventFieldDropdown.*?
        DetectMarkersButton.*?

        % Epoch Definition Builder Components
        EpochBuilderLabel.*?
        StartMarkerLabel.*?
        StartMarkerDropdown.*?
        EndMarkerLabel.*?
        EndMarkerDropdown.*?
        EpochNameLabel.*?
        EpochNameField.*?
        AddEpochButton.*?
        EpochListLabel.*?
        EpochListBox.*?
        RemoveEpochButton.*?

        StartButton'''

new_props = '''        % Upload Screen Components (matching JuanAnalyzer)
        TitleLabel              matlab.ui.control.Label
        SubtitleLabel           matlab.ui.control.Label
        BrowseButton            matlab.ui.control.Button
        FileInfoLabel           matlab.ui.control.Label
        EventSelectionButton    matlab.ui.control.Button
        EventSelectionLabel     matlab.ui.control.Label
        StartButton'''

eeg_content = re.sub(old_props, new_props, eeg_content, flags=re.DOTALL)

# Step 2: Add SelectedEvents and SelectedFields properties
print("2. Adding SelectedEvents and SelectedFields properties...")
data_props_pattern = r'(EventInfo\s+struct)'
data_props_replacement = r'''\1
        SelectedEvents          cell = {}
        SelectedFields          cell = {}'''
eeg_content = re.sub(data_props_pattern, data_props_replacement, eeg_content)

# Step 3: Replace createUploadPanel function
print("3. Replacing createUploadPanel function...")
# Extract JuanAnalyzer's createUploadPanel
juan_upload_match = re.search(
    r'function createUploadPanel\(app\).*?end\n\n        function createProcessingPanel',
    juan_content, re.DOTALL)

if juan_upload_match:
    juan_upload_func = juan_upload_match.group(0).replace(
        'function createProcessingPanel', '').strip()

    # Replace title
    juan_upload_func = juan_upload_func.replace(
        "'Juan Analyzer'", "'EEG Quality Analyzer'")
    juan_upload_func = juan_upload_func.replace(
        "'Manual Event Selection | N400, N250, P600 Components'",
        "'Automated Quality Assessment with Manual Event Selection'")

    # Replace in EEGQualityAnalyzer
    eeg_content = re.sub(
        r'function createUploadPanel\(app\).*?end\n\n        function createProcessingPanel',
        juan_upload_func + '\n\n        function createProcessingPanel',
        eeg_content, re.DOTALL)

# Step 4: Add selectEventsManually function
print("4. Adding selectEventsManually function...")
# Extract from JuanAnalyzer
juan_select_match = re.search(
    r'function selectEventsManually\(app\).*?        end\n\n        function startAnalysis',
    juan_content, re.DOTALL)

if juan_select_match:
    juan_select_func = juan_select_match.group(0).replace(
        'function startAnalysis', '').strip()

    # Insert before startProcessing function
    eeg_content = re.sub(
        r'(function startProcessing\(app\))',
        juan_select_func + '\n\n        function startAnalysis(app)\n            startProcessing(app);\n        end\n\n        \\1',
        eeg_content)

# Step 5: Update browseFile function
print("5. Updating browseFile function...")
juan_browse_match = re.search(
    r'function browseFile\(app\).*?        end\n\n        function selectEventsManually',
    juan_content, re.DOTALL)

if juan_browse_match:
    juan_browse_func = juan_browse_match.group(0).replace(
        'function selectEventsManually', '').strip()

    # Replace in EEGQualityAnalyzer
    eeg_content = re.sub(
        r'function browseFile\(app\).*?        end\n\n        function (loadFileInfo|selectEventsManually)',
        juan_browse_func + '\n\n        function \\1',
        eeg_content, re.DOTALL)

# Step 6: Update processEEG to use selected events
print("6. Updating processEEG to use selected events...")
epoch_stage_old = r'''            % Stage 6: Event Analysis \(if epochs defined\)
            if ~isempty\(app\.EpochDefinitions\).*?            else
                updateProgress\(app, 6, 'No Epochs Defined \(Continuous Analysis\)\.\.\.'\);
            end'''

epoch_stage_new = '''            % Stage 6: Epoch Extraction (using selected events)
            if ~isempty(app.SelectedEvents)
                updateProgress(app, 6, 'Extracting Epochs from Selected Events...');
                try
                    % Detect event structure
                    structure = detectEventStructure(EEG);
                    discovery = struct();
                    discovery.groupingFields = app.SelectedFields;
                    discovery.practicePatterns = {};
                    discovery.valueMappings = struct();

                    % Extract epochs using universal function
                    timeWindow = [-0.2, 0.8];
                    app.EpochedData = epochEEGByEventsUniversal(EEG, app.SelectedEvents, ...
                        timeWindow, structure, discovery, app.SelectedFields);
                    fprintf('Extracted %d epoch types\\n', length(app.EpochedData));
                catch ME
                    fprintf('Epoch extraction failed: %s\\n', ME.message);
                    app.EpochedData = [];
                end
            else
                updateProgress(app, 6, 'No Events Selected (Continuous Analysis)...');
                app.EpochedData = [];
            end'''

eeg_content = re.sub(epoch_stage_old, epoch_stage_new, eeg_content, flags=re.DOTALL)

# Write updated file
print("7. Writing updated file...")
with open('matlab-main/EEGQualityAnalyzer/EEGQualityAnalyzer.m', 'w') as f:
    f.write(eeg_content)

print("\n✅ EEGQualityAnalyzer.m updated successfully!")
print("\nChanges made:")
print("  - Replaced upload screen properties with JuanAnalyzer's simple interface")
print("  - Added SelectedEvents and SelectedFields properties")
print("  - Replaced createUploadPanel with JuanAnalyzer's version")
print("  - Added selectEventsManually function (2-step event selection)")
print("  - Updated browseFile to enable event selection")
print("  - Updated processEEG Stage 6 to use epochEEGByEventsUniversal")
print("\nThe GUI should now match JuanAnalyzer's workflow exactly!")
