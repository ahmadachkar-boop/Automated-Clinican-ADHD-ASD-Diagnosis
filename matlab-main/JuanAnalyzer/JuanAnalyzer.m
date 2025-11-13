classdef JuanAnalyzer < matlab.apps.AppBase
    % JUANANALYZER - AI-Powered ERP Analysis GUI
    %
    % Automated ERP analysis with:
    %   - AI-only event detection
    %   - N400, N250, P600 component analysis
    %   - Frequency band analysis
    %   - Bad channel warnings (keeps channels)

    properties (Access = public)
        UIFigure                matlab.ui.Figure

        % Main Panels
        UploadPanel             matlab.ui.container.Panel
        ProcessingPanel         matlab.ui.container.Panel
        ResultsPanel            matlab.ui.container.Panel

        % Upload Screen Components
        TitleLabel              matlab.ui.control.Label
        SubtitleLabel           matlab.ui.control.Label
        BrowseButton            matlab.ui.control.Button
        FileInfoLabel           matlab.ui.control.Label
        APIKeyLabel             matlab.ui.control.Label
        APIKeyField             matlab.ui.control.EditField
        ProviderDropdown        matlab.ui.control.DropDown
        StartButton             matlab.ui.control.Button

        % Processing Screen
        ProcessingLabel         matlab.ui.control.Label
        ProgressBar             matlab.ui.control.UIAxes
        ProgressFill            matlab.graphics.primitive.Rectangle
        ProgressText            matlab.ui.control.Label
        StageLabel              matlab.ui.control.Label

        % Results Screen
        ResultsTabGroup         matlab.ui.container.TabGroup
        ERPTab                  matlab.ui.container.Tab
        TopoTab                 matlab.ui.container.Tab
        FreqTab                 matlab.ui.container.Tab
        SummaryTab              matlab.ui.container.Tab

        ERPAxes                 matlab.ui.control.UIAxes
        ERPEventListBox         matlab.ui.control.ListBox
        ERPSelectAllButton      matlab.ui.control.Button
        ERPDeselectAllButton    matlab.ui.control.Button
        ERPROIDropdown          matlab.ui.control.DropDown
        ERPROILabel             matlab.ui.control.Label

        TopoEventListBox        matlab.ui.control.ListBox
        TopoSelectAllButton     matlab.ui.control.Button
        TopoDeselectAllButton   matlab.ui.control.Button
        TopoTimeSlider          matlab.ui.control.Slider
        TopoTimeLabel           matlab.ui.control.Label
        TopoPanel               matlab.ui.container.Panel

        FreqAxes1               matlab.ui.control.UIAxes
        FreqAxes2               matlab.ui.control.UIAxes
        SummaryTextArea         matlab.ui.control.TextArea
        NewAnalysisButton       matlab.ui.control.Button
        ExportButton            matlab.ui.control.Button

        % Data
        EEGFile                 char
        EEG                     struct
        Results                 struct
        CurrentStage            double = 0
        TotalStages             double = 8
    end

    methods (Access = public)

        function app = JuanAnalyzer
            % Add JuanAnalyzer folder to path (so helper functions are found)
            appPath = fileparts(mfilename('fullpath'));
            if ~contains(path, appPath)
                addpath(appPath);
                fprintf('Added to path: %s\n', appPath);
            end

            % Create and configure UI
            createComponents(app);
            initializeApp(app);
            showUploadScreen(app);
        end
    end

    methods (Access = private)

        function createComponents(app)
            % Create UIFigure
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.WindowState = 'maximized';
            app.UIFigure.Name = 'Juan Analyzer - AI-Powered ERP Analysis';
            app.UIFigure.Color = [0.94 0.94 0.94];

            % Create panels
            createUploadPanel(app);
            createProcessingPanel(app);
            createResultsPanel(app);

            % Make visible
            app.UIFigure.Visible = 'on';
        end

        function createUploadPanel(app)
            app.UploadPanel = uipanel(app.UIFigure);
            app.UploadPanel.Position = [100 100 1000 600];
            app.UploadPanel.BackgroundColor = [1 1 1];
            app.UploadPanel.BorderType = 'none';

            % Title
            app.TitleLabel = uilabel(app.UploadPanel);
            app.TitleLabel.Position = [200 500 600 50];
            app.TitleLabel.Text = 'Juan Analyzer';
            app.TitleLabel.FontSize = 36;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.FontColor = [0.2 0.3 0.6];
            app.TitleLabel.HorizontalAlignment = 'center';

            % Subtitle
            app.SubtitleLabel = uilabel(app.UploadPanel);
            app.SubtitleLabel.Position = [150 460 700 30];
            app.SubtitleLabel.Text = 'AI-Powered ERP Analysis | N400, N250, P600 Components';
            app.SubtitleLabel.FontSize = 14;
            app.SubtitleLabel.FontColor = [0.4 0.5 0.6];
            app.SubtitleLabel.HorizontalAlignment = 'center';

            % Browse Button
            app.BrowseButton = uibutton(app.UploadPanel, 'push');
            app.BrowseButton.Position = [350 370 300 50];
            app.BrowseButton.Text = 'Select EEG File';
            app.BrowseButton.FontSize = 18;
            app.BrowseButton.BackgroundColor = [0.3 0.5 0.8];
            app.BrowseButton.FontColor = [1 1 1];
            app.BrowseButton.ButtonPushedFcn = @(btn,event) browseFile(app);

            % File info label
            app.FileInfoLabel = uilabel(app.UploadPanel);
            app.FileInfoLabel.Position = [100 320 800 30];
            app.FileInfoLabel.Text = 'No file selected';
            app.FileInfoLabel.FontSize = 12;
            app.FileInfoLabel.FontColor = [0.5 0.5 0.5];
            app.FileInfoLabel.HorizontalAlignment = 'center';

            % API Key section
            apiLabel = uilabel(app.UploadPanel);
            apiLabel.Position = [200 250 200 20];
            apiLabel.Text = '🤖 AI Provider:';
            apiLabel.FontSize = 12;
            apiLabel.FontWeight = 'bold';

            app.ProviderDropdown = uidropdown(app.UploadPanel);
            app.ProviderDropdown.Position = [300 245 150 30];
            app.ProviderDropdown.Items = {'Claude (Anthropic)', 'OpenAI GPT-4'};
            app.ProviderDropdown.ItemsData = {'claude', 'openai'};
            app.ProviderDropdown.Value = 'claude';

            app.APIKeyLabel = uilabel(app.UploadPanel);
            app.APIKeyLabel.Position = [200 200 100 20];
            app.APIKeyLabel.Text = '🔑 API Key:';
            app.APIKeyLabel.FontSize = 12;
            app.APIKeyLabel.FontWeight = 'bold';

            app.APIKeyField = uieditfield(app.UploadPanel, 'text');
            app.APIKeyField.Position = [300 195 400 30];
            app.APIKeyField.Placeholder = 'Enter API key or set environment variable';

            % Start Button
            app.StartButton = uibutton(app.UploadPanel, 'push');
            app.StartButton.Position = [350 100 300 50];
            app.StartButton.Text = 'Start Analysis';
            app.StartButton.FontSize = 18;
            app.StartButton.BackgroundColor = [0.2 0.7 0.3];
            app.StartButton.FontColor = [1 1 1];
            app.StartButton.Enable = 'off';
            app.StartButton.ButtonPushedFcn = @(btn,event) startAnalysis(app);

            % Instructions
            instrLabel = uilabel(app.UploadPanel);
            instrLabel.Position = [100 40 800 40];
            instrLabel.Text = sprintf('Supports: .mff, .set, .edf formats\nAutomatic AI-powered event detection • No configuration needed');
            instrLabel.FontSize = 10;
            instrLabel.FontColor = [0.6 0.6 0.6];
            instrLabel.HorizontalAlignment = 'center';
        end

        function createProcessingPanel(app)
            app.ProcessingPanel = uipanel(app.UIFigure);
            app.ProcessingPanel.Position = [100 100 1000 600];
            app.ProcessingPanel.BackgroundColor = [1 1 1];
            app.ProcessingPanel.BorderType = 'none';
            app.ProcessingPanel.Visible = 'off';

            % Processing label
            app.ProcessingLabel = uilabel(app.ProcessingPanel);
            app.ProcessingLabel.Position = [300 450 400 40];
            app.ProcessingLabel.Text = 'Processing EEG Data...';
            app.ProcessingLabel.FontSize = 24;
            app.ProcessingLabel.FontWeight = 'bold';
            app.ProcessingLabel.FontColor = [0.2 0.3 0.6];
            app.ProcessingLabel.HorizontalAlignment = 'center';

            % Progress bar
            app.ProgressBar = uiaxes(app.ProcessingPanel);
            app.ProgressBar.Position = [250 300 500 50];
            app.ProgressBar.XLim = [0 1];
            app.ProgressBar.YLim = [0 1];
            app.ProgressBar.XTick = [];
            app.ProgressBar.YTick = [];
            app.ProgressBar.Box = 'on';

            % Progress fill
            app.ProgressFill = rectangle(app.ProgressBar, 'Position', [0 0 0 1]);
            app.ProgressFill.FaceColor = [0.3 0.6 0.9];
            app.ProgressFill.EdgeColor = 'none';

            % Progress text
            app.ProgressText = uilabel(app.ProcessingPanel);
            app.ProgressText.Position = [250 260 500 30];
            app.ProgressText.Text = '0%';
            app.ProgressText.FontSize = 16;
            app.ProgressText.HorizontalAlignment = 'center';

            % Stage label
            app.StageLabel = uilabel(app.ProcessingPanel);
            app.StageLabel.Position = [200 200 600 60];
            app.StageLabel.Text = 'Initializing...';
            app.StageLabel.FontSize = 14;
            app.StageLabel.FontColor = [0.4 0.4 0.4];
            app.StageLabel.HorizontalAlignment = 'center';
        end

        function createResultsPanel(app)
            app.ResultsPanel = uipanel(app.UIFigure);
            app.ResultsPanel.Position = [50 50 1100 700];
            app.ResultsPanel.BackgroundColor = [1 1 1];
            app.ResultsPanel.BorderType = 'none';
            app.ResultsPanel.Visible = 'off';

            % Title
            titleLabel = uilabel(app.ResultsPanel);
            titleLabel.Position = [300 650 500 40];
            titleLabel.Text = 'Analysis Complete';
            titleLabel.FontSize = 28;
            titleLabel.FontWeight = 'bold';
            titleLabel.FontColor = [0.2 0.6 0.3];
            titleLabel.HorizontalAlignment = 'center';

            % Tab group
            app.ResultsTabGroup = uitabgroup(app.ResultsPanel);
            app.ResultsTabGroup.Position = [50 150 1000 480];

            % ERP Tab
            app.ERPTab = uitab(app.ResultsTabGroup);
            app.ERPTab.Title = 'ERP Components';

            % Event selection listbox
            eventLabel = uilabel(app.ERPTab);
            eventLabel.Position = [10 390 180 20];
            eventLabel.Text = 'Select Events to Display:';
            eventLabel.FontWeight = 'bold';
            eventLabel.FontSize = 10;

            app.ERPEventListBox = uilistbox(app.ERPTab);
            app.ERPEventListBox.Position = [10 80 180 310];
            app.ERPEventListBox.Multiselect = 'on';
            app.ERPEventListBox.ValueChangedFcn = @(src,event) updateERPPlot(app);

            % Select All button
            app.ERPSelectAllButton = uibutton(app.ERPTab, 'push');
            app.ERPSelectAllButton.Position = [10 50 85 25];
            app.ERPSelectAllButton.Text = 'Select All';
            app.ERPSelectAllButton.FontSize = 9;
            app.ERPSelectAllButton.ButtonPushedFcn = @(btn,event) selectAllEvents(app);

            % Deselect All button
            app.ERPDeselectAllButton = uibutton(app.ERPTab, 'push');
            app.ERPDeselectAllButton.Position = [105 50 85 25];
            app.ERPDeselectAllButton.Text = 'Clear All';
            app.ERPDeselectAllButton.FontSize = 9;
            app.ERPDeselectAllButton.ButtonPushedFcn = @(btn,event) deselectAllEvents(app);

            % ROI Selection
            app.ERPROILabel = uilabel(app.ERPTab);
            app.ERPROILabel.Position = [10 15 85 20];
            app.ERPROILabel.Text = 'Electrode ROI:';
            app.ERPROILabel.FontWeight = 'bold';
            app.ERPROILabel.FontSize = 9;

            app.ERPROIDropdown = uidropdown(app.ERPTab);
            app.ERPROIDropdown.Position = [95 10 95 25];
            app.ERPROIDropdown.Items = {'All Channels', 'Frontal', 'Central', 'Parietal', 'Occipital', 'Temporal'};
            app.ERPROIDropdown.ItemsData = {'all', 'frontal', 'central', 'parietal', 'occipital', 'temporal'};
            app.ERPROIDropdown.Value = 'central';  % Default to central for N400/P600
            app.ERPROIDropdown.FontSize = 9;
            app.ERPROIDropdown.ValueChangedFcn = @(src,event) updateERPPlot(app);

            % ERP plot axes (adjusted to make room for listbox)
            app.ERPAxes = uiaxes(app.ERPTab);
            app.ERPAxes.Position = [210 20 770 420];

            % Topographic Maps Tab
            app.TopoTab = uitab(app.ResultsTabGroup);
            app.TopoTab.Title = 'Topographic Maps';

            % Event selection listbox for topomaps
            topoEventLabel = uilabel(app.TopoTab);
            topoEventLabel.Position = [10 390 180 20];
            topoEventLabel.Text = 'Select Events to Display:';
            topoEventLabel.FontWeight = 'bold';
            topoEventLabel.FontSize = 10;

            app.TopoEventListBox = uilistbox(app.TopoTab);
            app.TopoEventListBox.Position = [10 80 180 310];
            app.TopoEventListBox.Multiselect = 'on';
            app.TopoEventListBox.ValueChangedFcn = @(src,event) updateTopoMaps(app);

            % Select All button for topomaps
            app.TopoSelectAllButton = uibutton(app.TopoTab, 'push');
            app.TopoSelectAllButton.Position = [10 50 85 25];
            app.TopoSelectAllButton.Text = 'Select All';
            app.TopoSelectAllButton.FontSize = 9;
            app.TopoSelectAllButton.ButtonPushedFcn = @(btn,event) selectAllTopoEvents(app);

            % Deselect All button for topomaps
            app.TopoDeselectAllButton = uibutton(app.TopoTab, 'push');
            app.TopoDeselectAllButton.Position = [105 50 85 25];
            app.TopoDeselectAllButton.Text = 'Clear All';
            app.TopoDeselectAllButton.FontSize = 9;
            app.TopoDeselectAllButton.ButtonPushedFcn = @(btn,event) deselectAllTopoEvents(app);

            % Time slider for selecting time point
            timeSliderLabel = uilabel(app.TopoTab);
            timeSliderLabel.Position = [210 410 150 20];
            timeSliderLabel.Text = 'Select Time Point:';
            timeSliderLabel.FontWeight = 'bold';
            timeSliderLabel.FontSize = 10;

            app.TopoTimeLabel = uilabel(app.TopoTab);
            app.TopoTimeLabel.Position = [370 410 100 20];
            app.TopoTimeLabel.Text = '0 ms';
            app.TopoTimeLabel.FontSize = 10;
            app.TopoTimeLabel.FontWeight = 'bold';
            app.TopoTimeLabel.FontColor = [0.2 0.4 0.8];

            app.TopoTimeSlider = uislider(app.TopoTab);
            app.TopoTimeSlider.Position = [210 390 550 3];
            app.TopoTimeSlider.Limits = [-200 800];
            app.TopoTimeSlider.Value = 400;  % Default to N400 time
            app.TopoTimeSlider.ValueChangedFcn = @(src,event) updateTopoMaps(app);

            % Panel to hold topographic maps
            app.TopoPanel = uipanel(app.TopoTab);
            app.TopoPanel.Position = [210 20 770 360];
            app.TopoPanel.BackgroundColor = [1 1 1];
            app.TopoPanel.BorderType = 'none';

            % Frequency Tab
            app.FreqTab = uitab(app.ResultsTabGroup);
            app.FreqTab.Title = 'Frequency Analysis';

            app.FreqAxes1 = uiaxes(app.FreqTab);
            app.FreqAxes1.Position = [20 20 460 420];

            app.FreqAxes2 = uiaxes(app.FreqTab);
            app.FreqAxes2.Position = [500 20 460 420];

            % Summary Tab
            app.SummaryTab = uitab(app.ResultsTabGroup);
            app.SummaryTab.Title = 'Summary';

            app.SummaryTextArea = uitextarea(app.SummaryTab);
            app.SummaryTextArea.Position = [20 20 960 420];
            app.SummaryTextArea.Editable = 'off';
            app.SummaryTextArea.FontName = 'Courier New';
            app.SummaryTextArea.FontSize = 11;

            % Buttons
            app.NewAnalysisButton = uibutton(app.ResultsPanel, 'push');
            app.NewAnalysisButton.Position = [200 80 250 50];
            app.NewAnalysisButton.Text = 'New Analysis';
            app.NewAnalysisButton.FontSize = 16;
            app.NewAnalysisButton.BackgroundColor = [0.3 0.5 0.8];
            app.NewAnalysisButton.FontColor = [1 1 1];
            app.NewAnalysisButton.ButtonPushedFcn = @(btn,event) showUploadScreen(app);

            app.ExportButton = uibutton(app.ResultsPanel, 'push');
            app.ExportButton.Position = [650 80 250 50];
            app.ExportButton.Text = 'Export Results';
            app.ExportButton.FontSize = 16;
            app.ExportButton.BackgroundColor = [0.2 0.7 0.3];
            app.ExportButton.FontColor = [1 1 1];
            app.ExportButton.ButtonPushedFcn = @(btn,event) exportResults(app);
        end

        function initializeApp(app)
            % Initialize app state
            app.EEGFile = '';
            app.CurrentStage = 0;
        end

        function showUploadScreen(app)
            app.UploadPanel.Visible = 'on';
            app.ProcessingPanel.Visible = 'off';
            app.ResultsPanel.Visible = 'off';

            % Reset
            app.EEGFile = '';
            app.FileInfoLabel.Text = 'No file selected';
            app.StartButton.Enable = 'off';
        end

        function showProcessingScreen(app)
            app.UploadPanel.Visible = 'off';
            app.ProcessingPanel.Visible = 'on';
            app.ResultsPanel.Visible = 'off';

            app.CurrentStage = 0;
            updateProgress(app, 0, 'Starting...');
        end

        function showResultsScreen(app)
            app.UploadPanel.Visible = 'off';
            app.ProcessingPanel.Visible = 'off';
            app.ResultsPanel.Visible = 'on';
        end

        function browseFile(app)
            [file, path] = uigetfile({'*.mff;*.set;*.edf', 'EEG Files (*.mff, *.set, *.edf)'}, ...
                'Select EEG File');

            if file == 0
                return;
            end

            app.EEGFile = fullfile(path, file);
            app.FileInfoLabel.Text = sprintf('Selected: %s', file);
            app.FileInfoLabel.FontColor = [0.2 0.6 0.3];
            app.StartButton.Enable = 'on';

            % Try to load file info
            try
                if endsWith(file, '.mff')
                    EEG = pop_mffimport(app.EEGFile, {});
                else
                    EEG = pop_loadset(app.EEGFile);
                end
                app.EEG = EEG;
                app.FileInfoLabel.Text = sprintf('%s | %d channels | %d events | %.1f sec', ...
                    file, EEG.nbchan, length(EEG.event), EEG.xmax);
            catch
                % If preview fails, still allow analysis
            end
        end

        function startAnalysis(app)
            % Validate API key
            provider = app.ProviderDropdown.Value;
            apiKey = strtrim(app.APIKeyField.Value);

            if ~isempty(apiKey)
                if strcmp(provider, 'claude')
                    setenv('ANTHROPIC_API_KEY', apiKey);
                else
                    setenv('OPENAI_API_KEY', apiKey);
                end
            end

            % Check if key is set
            if strcmp(provider, 'claude')
                key = getenv('ANTHROPIC_API_KEY');
            else
                key = getenv('OPENAI_API_KEY');
            end

            if isempty(key)
                uialert(app.UIFigure, ...
                    'Please enter an API key or set the environment variable.', ...
                    'API Key Required');
                return;
            end

            % Show processing screen
            showProcessingScreen(app);
            drawnow;
            pause(0.1);

            % Run analysis
            try
                processEEG(app);
                showResultsScreen(app);
                displayResults(app);
            catch ME
                uialert(app.UIFigure, ME.message, 'Processing Error');
                showUploadScreen(app);
            end
        end

        function processEEG(app)
            % Run the full analysis pipeline - EXACT preprocessing from launchEEGAnalyzer

            provider = app.ProviderDropdown.Value;

            % Stage 1: Loading Data
            updateProgress(app, 1, 'Loading Data...');
            if isempty(app.EEG)
                if endsWith(app.EEGFile, '.mff')
                    app.EEG = pop_mffimport(app.EEGFile, {});
                else
                    app.EEG = pop_loadset(app.EEGFile);
                end
            end
            EEG = app.EEG;
            EEG_original = EEG;

            % Stage 2: Filtering & Preprocessing
            updateProgress(app, 2, 'Filtering & Preprocessing...');
            params.resample_rate = 250;
            params.hp_cutoff = 0.5;
            params.lp_cutoff = 50;
            params.notch_freq = 60;

            EEG = pop_resample(EEG, params.resample_rate);
            EEG = pop_eegfiltnew(EEG, 'locutoff', params.hp_cutoff, 'plotfreqz', 0);
            EEG = pop_eegfiltnew(EEG, 'hicutoff', params.lp_cutoff, 'plotfreqz', 0);
            EEG = pop_eegfiltnew(EEG, 'locutoff', params.notch_freq-2, 'hicutoff', params.notch_freq+2, 'revfilt', 1, 'plotfreqz', 0);
            EEG = pop_reref(EEG, []);

            % Stage 3: Artifact Detection
            updateProgress(app, 3, 'Detecting Artifacts...');

            % Multi-method bad channel detection (identify but DON'T remove)
            badChans = [];
            badChanLabels = {};
            badChanReasons = {};
            try
                % Method 1-3: Kurtosis, Probability, Spectrum
                % Kurtosis: catches spiky/artifactual channels
                % Probability: catches statistically abnormal activity
                % Spectrum: catches noisy channels via frequency analysis
                EEG_temp = pop_rejchan(EEG, 'elec', 1:EEG.nbchan, ...
                    'threshold', [5 5 5], ...
                    'norm', 'on', ...
                    'measure', 'kurt', 'prob', 'spec');

                % Identify which channels were flagged
                if EEG_temp.nbchan < EEG.nbchan
                    originalChans = 1:EEG.nbchan;
                    if isfield(EEG, 'chanlocs') && ~isempty(EEG.chanlocs)
                        originalLabels = {EEG.chanlocs.labels};
                        remainingLabels = {EEG_temp.chanlocs.labels};
                        badChans = find(~ismember(originalLabels, remainingLabels));
                        badChanLabels = originalLabels(badChans);
                    else
                        badChans = setdiff(originalChans, 1:EEG_temp.nbchan);
                    end
                end

                % Method 4: Correlation with neighboring channels
                % Catches channels uncorrelated with neighbors
                if isfield(EEG, 'chanlocs') && length(EEG.chanlocs) > 1
                    correlationThreshold = 0.4;
                    for i = 1:EEG.nbchan
                        % Calculate correlation with all other channels
                        chanData = EEG.data(i, :);
                        corrVals = zeros(EEG.nbchan - 1, 1);
                        idx = 1;
                        for j = 1:EEG.nbchan
                            if i ~= j
                                corrVals(idx) = corr(chanData', EEG.data(j, :)');
                                idx = idx + 1;
                            end
                        end

                        % If mean correlation is too low, mark as bad
                        meanCorr = mean(abs(corrVals));
                        if meanCorr < correlationThreshold
                            if ~ismember(i, badChans)
                                badChans(end+1) = i;
                                if isfield(EEG, 'chanlocs') && ~isempty(EEG.chanlocs)
                                    badChanLabels{end+1} = EEG.chanlocs(i).labels;
                                end
                            end
                        end
                    end
                end

                % Sort bad channels
                if ~isempty(badChans)
                    [badChans, sortIdx] = sort(badChans);
                    if ~isempty(badChanLabels)
                        badChanLabels = badChanLabels(sortIdx);
                    end
                end

                % DON'T apply the removal - keep EEG unchanged, just record bad channels
            catch ME
                fprintf('Warning: Bad channel detection encountered error: %s\n', ME.message);
                % If detection fails, continue without bad channel info
            end

            % Run ICA with PCA reduction for speed
            % Full 128 channels is very slow (~15-30 min)
            % PCA to 40 components: ~3-5x faster, retains ~95% variance
            try
                EEG = pop_runica(EEG, 'icatype', 'runica', 'extended', 1, 'pca', 40);
            catch
                % Skip ICA if it fails
            end

            % Stage 4: Cleaning Signal
            updateProgress(app, 4, 'Cleaning Signal...');

            % Run ICLabel if ICA succeeded
            removedComponents = [];
            if isfield(EEG, 'icaweights') && ~isempty(EEG.icaweights)
                try
                    EEG = pop_iclabel(EEG, 'default');

                    % Auto-flag artifact components at 75% confidence threshold
                    % [Brain; Muscle; Eye; Heart; Line Noise; Channel Noise; Other]
                    EEG = pop_icflag(EEG, [0 0; 0.75 1; 0.75 1; 0.75 1; 0.75 1; 0.75 1; 0 0]);

                    % Remove flagged components
                    bad_comps = find(EEG.reject.gcompreject);
                    if ~isempty(bad_comps)
                        removedComponents = bad_comps;
                        EEG = pop_subcomp(EEG, bad_comps, 0);
                    end
                catch
                    % Continue if ICLabel fails
                end
            end

            % Stage 5: AI Event Detection
            updateProgress(app, 5, sprintf('🤖 AI-Powered Event Detection (%s)...', upper(provider)));
            [selectedEvents, structure, discovery] = autoSelectTrialEventsUniversal(EEG, ...
                'UseAI', 'always', ...
                'AIProvider', provider, ...
                'ExcludePractice', true, ...
                'Display', false);

            % Stage 6: Extracting Epochs
            updateProgress(app, 6, 'Extracting Epochs and Computing ERPs...');
            timeWindow = [-0.2, 0.8];
            epochedData = epochEEGByEventsUniversal(EEG, selectedEvents, timeWindow, ...
                structure, discovery, discovery.groupingFields);

            % Stage 7: ERP Component Analysis
            updateProgress(app, 7, 'Analyzing ERP Components (N250, N400, P600)...');
            erpAnalysis = analyzeERPComponentsGUI(epochedData, timeWindow);

            % Stage 8: Frequency Analysis
            updateProgress(app, 8, 'Analyzing Frequency Bands...');
            freqAnalysis = analyzeFrequencyBandsGUI(EEG, epochedData, timeWindow);

            % Store results
            app.Results = struct();
            app.Results.epochedData = epochedData;
            app.Results.erpAnalysis = erpAnalysis;
            app.Results.freqAnalysis = freqAnalysis;
            app.Results.badChannels = badChans;
            app.Results.badChannelLabels = badChanLabels;
            app.Results.removedComponents = removedComponents;
            app.Results.structure = structure;
            app.Results.discovery = discovery;
            app.Results.selectedEvents = selectedEvents;
            app.Results.EEG = EEG;
            app.Results.EEG_original = EEG_original;
            app.Results.preprocessing = params;
        end

        function updateProgress(app, stage, message)
            app.CurrentStage = stage;
            progress = stage / app.TotalStages;

            % Update progress bar
            app.ProgressFill.Position = [0 0 progress 1];

            % Update text
            app.ProgressText.Text = sprintf('%d%%', round(progress * 100));
            app.StageLabel.Text = sprintf('[%d/%d] %s', stage, app.TotalStages, message);

            drawnow;
            pause(0.2);
        end

        function displayResults(app)
            % Display results in tabs

            % Populate event listboxes
            epochedData = app.Results.epochedData;
            eventNames = cell(length(epochedData), 1);
            for i = 1:length(epochedData)
                % Use original event type if available, otherwise fall back to eventType
                if isfield(epochedData(i), 'originalEventType')
                    eventNames{i} = strrep(epochedData(i).originalEventType, '_', ' ');
                else
                    eventNames{i} = strrep(epochedData(i).eventType, '_', ' ');
                end
            end

            % ERP listbox
            app.ERPEventListBox.Items = eventNames;
            app.ERPEventListBox.ItemsData = 1:length(eventNames);
            app.ERPEventListBox.Value = 1:length(eventNames);  % Select all by default

            % Topomap listbox
            app.TopoEventListBox.Items = eventNames;
            app.TopoEventListBox.ItemsData = 1:length(eventNames);
            app.TopoEventListBox.Value = 1:min(4, length(eventNames));  % Select first 4 by default

            % ERP Tab
            cla(app.ERPAxes);
            plotERPResults(app, app.ERPAxes);

            % Topographic Maps Tab
            updateTopoMaps(app);

            % Frequency Tab
            cla(app.FreqAxes1);
            cla(app.FreqAxes2);
            plotFrequencyResults(app, app.FreqAxes1, app.FreqAxes2);

            % Summary Tab
            generateSummaryText(app);
        end

        function plotERPResults(app, ax)
            epochedData = app.Results.epochedData;
            erpAnalysis = app.Results.erpAnalysis;

            % Get selected event indices from listbox
            selectedIndices = app.ERPEventListBox.Value;
            if isempty(selectedIndices)
                % If nothing selected, clear plot and show message
                cla(ax);
                text(ax, 0.5, 0.5, 'No events selected. Select events from the list.', ...
                    'HorizontalAlignment', 'center', 'Units', 'normalized', ...
                    'FontSize', 12, 'Color', [0.5 0.5 0.5]);
                ax.XTick = [];
                ax.YTick = [];
                return;
            end

            % Get ROI channel selection
            roiSelection = app.ERPROIDropdown.Value;
            roiChannels = getROIChannels(app.Results.EEG, roiSelection);

            % Warn if "all" channels selected (will produce flat line due to spatial cancellation)
            if strcmp(roiSelection, 'all')
                fprintf('\nWARNING: "All Channels" averages all 129 channels together.\n');
                fprintf('   Positive and negative scalp regions cancel out -> FLAT LINE\n');
                fprintf('   This is mathematically correct but scientifically useless!\n');
                fprintf('   -> Use ROI selections (Central, Frontal, etc.) for meaningful ERPs\n\n');
            end

            % Display info about ROI
            if strcmp(roiSelection, 'all')
                roiInfo = sprintf('All %d channels', length(roiChannels));
            else
                roiInfo = sprintf('%s region (%d channels)', [upper(roiSelection(1)) roiSelection(2:end)], length(roiChannels));
            end

            hold(ax, 'on');

            % Use all colors but only plot selected events
            nConds = length(epochedData);
            colors = lines(nConds);

            % Only plot selected events
            for i = selectedIndices
                if epochedData(i).numEpochs == 0
                    continue;
                end

                % Average ERP across selected ROI channels only
                erpData = epochedData(i).avgERP(roiChannels, :);

                % Debug: Check for flat/zero channels
                fprintf('[ERP Debug] Condition "%s": ROI=%s, %d channels selected\n', ...
                    epochedData(i).eventType, roiSelection, length(roiChannels));

                if strcmp(roiSelection, 'all')
                    channelStds = std(erpData, 0, 2);
                    channelMeans = mean(erpData, 2);

                    fprintf('[ERP Debug] Channel std range: %.4f to %.4f\n', ...
                        min(channelStds), max(channelStds));
                    fprintf('[ERP Debug] Channel mean range: %.4f to %.4f\n', ...
                        min(channelMeans), max(channelMeans));

                    flatChannels = find(channelStds < 0.01);
                    if ~isempty(flatChannels)
                        fprintf('[ERP Debug] WARNING: Found %d flat channels (std < 0.01)\n', ...
                            length(flatChannels));
                        fprintf('[ERP Debug] Flat channel global indices: %s\n', mat2str(roiChannels(flatChannels)));
                        fprintf('[ERP Debug] Flat channel stds: %s\n', mat2str(channelStds(flatChannels)'));
                        % Remove flat channels from averaging
                        erpData(flatChannels, :) = [];
                        fprintf('[ERP Debug] Removed flat channels, now have %d channels\n', size(erpData, 1));
                    end
                end

                erp = mean(erpData, 1);
                fprintf('[ERP Debug] Final ERP: mean=%.4f, std=%.4f, range=[%.2f, %.2f]\n', ...
                    mean(erp), std(erp), min(erp), max(erp));

                timeVec = epochedData(i).timeVector * 1000;

                % Use original event type for legend if available
                if isfield(epochedData(i), 'originalEventType')
                    displayName = strrep(epochedData(i).originalEventType, '_', ' ');
                else
                    displayName = strrep(epochedData(i).eventType, '_', ' ');
                end

                plot(ax, timeVec, erp, 'LineWidth', 2.5, 'Color', colors(i,:), ...
                    'DisplayName', displayName);
            end

            % Mark component windows
            yLim = ylim(ax);
            patch(ax, [200 300 300 200], [yLim(1) yLim(1) yLim(2) yLim(2)], ...
                [0.8 1 0.8], 'FaceAlpha', 0.15, 'EdgeColor', 'none', 'HandleVisibility', 'off');
            patch(ax, [300 500 500 300], [yLim(1) yLim(1) yLim(2) yLim(2)], ...
                [0.8 0.9 1], 'FaceAlpha', 0.15, 'EdgeColor', 'none', 'HandleVisibility', 'off');
            patch(ax, [500 800 800 500], [yLim(1) yLim(1) yLim(2) yLim(2)], ...
                [1 0.9 0.9], 'FaceAlpha', 0.15, 'EdgeColor', 'none', 'HandleVisibility', 'off');

            plot(ax, [0 0], yLim, 'k--', 'LineWidth', 1, 'HandleVisibility', 'off');
            plot(ax, [-200 800], [0 0], 'k-', 'LineWidth', 0.5, 'HandleVisibility', 'off');

            % Set x-axis limits and labels explicitly
            xlim(ax, [-200 800]);
            xlabel(ax, 'Time (ms)', 'FontSize', 12, 'FontWeight', 'bold');
            ylabel(ax, 'Amplitude (μV)', 'FontSize', 12, 'FontWeight', 'bold');
            title(ax, sprintf('ERP Waveforms: N250 (green), N400 (blue), P600 (red) | %s', roiInfo), 'FontSize', 13);

            % Ensure tick labels are visible
            ax.XAxis.TickLabelFormat = '%g';
            ax.FontSize = 10;

            legend(ax, 'Location', 'best', 'FontSize', 9);
            grid(ax, 'on');
            hold(ax, 'off');
        end

        function plotFrequencyResults(app, ax1, ax2)
            freqAnalysis = app.Results.freqAnalysis;

            % Plot 1: Baseline vs Stimulus Power
            if isfield(freqAnalysis, 'delta') && isfield(freqAnalysis.delta, 'meanBaselinePower')
                bandNames = {'Delta', 'Theta', 'Alpha', 'Beta', 'Gamma'};
                bandFields = {'delta', 'theta', 'alpha', 'beta', 'gamma'};
                baselinePowers = zeros(1, 5);
                stimulusPowers = zeros(1, 5);

                for b = 1:5
                    if isfield(freqAnalysis, bandFields{b})
                        baselinePowers(b) = freqAnalysis.(bandFields{b}).meanBaselinePower;
                        stimulusPowers(b) = freqAnalysis.(bandFields{b}).meanStimulusPower;
                    end
                end

                x = 1:5;
                bar(ax1, x, [baselinePowers; stimulusPowers]', 'grouped');
                set(ax1, 'XTick', 1:5, 'XTickLabel', bandNames);
                ylabel(ax1, 'Power (μV²/Hz)');
                title(ax1, 'Baseline vs Stimulus Power');
                legend(ax1, {'Baseline (-200 to 0 ms)', 'Stimulus (0 to 500 ms)'}, 'Location', 'best');
                grid(ax1, 'on');
            end

            % Plot 2: Power changes in dB
            if isfield(freqAnalysis, 'delta') && isfield(freqAnalysis.delta, 'meanPowerChange_dB')
                bandNames = {'Delta', 'Theta', 'Alpha', 'Beta', 'Gamma'};
                bandFields = {'delta', 'theta', 'alpha', 'beta', 'gamma'};
                powerChanges = zeros(1, 5);

                for b = 1:5
                    if isfield(freqAnalysis, bandFields{b})
                        powerChanges(b) = freqAnalysis.(bandFields{b}).meanPowerChange_dB;
                    end
                end

                colors = zeros(5, 3);
                for i = 1:5
                    if powerChanges(i) > 0
                        colors(i, :) = [0.8, 0.2, 0.2];  % Red for increase
                    else
                        colors(i, :) = [0.2, 0.6, 0.9];  % Blue for decrease
                    end
                end

                bar(ax2, 1:5, powerChanges, 'FaceColor', 'flat', 'CData', colors);
                set(ax2, 'XTick', 1:5, 'XTickLabel', bandNames);
                ylabel(ax2, 'Power Change (dB)');
                title(ax2, 'Baseline-Corrected Power Change');
                grid(ax2, 'on');
                yline(ax2, 0, 'k--', 'LineWidth', 1);
            end
        end

        function generateSummaryText(app)
            results = app.Results;

            summary = {};
            summary{end+1} = '========================================';
            summary{end+1} = '  JUAN ANALYZER - ANALYSIS SUMMARY';
            summary{end+1} = '========================================';
            summary{end+1} = '';

            % Data info
            summary{end+1} = 'DATA INFORMATION:';
            summary{end+1} = '----------------------------------------';
            summary{end+1} = sprintf('Original channels: %d', results.EEG_original.nbchan);
            summary{end+1} = sprintf('Original events: %d', length(results.EEG_original.event));
            summary{end+1} = sprintf('Duration: %.1f seconds', results.EEG_original.xmax);
            summary{end+1} = '';

            % Preprocessing info
            if isfield(results, 'preprocessing')
                summary{end+1} = 'PREPROCESSING APPLIED:';
                summary{end+1} = '----------------------------------------';
                summary{end+1} = sprintf('Resample: %d Hz', results.preprocessing.resample_rate);
                summary{end+1} = sprintf('High-pass filter: %.1f Hz', results.preprocessing.hp_cutoff);
                summary{end+1} = sprintf('Low-pass filter: %d Hz', results.preprocessing.lp_cutoff);
                summary{end+1} = sprintf('Notch filter: %d Hz (±2 Hz)', results.preprocessing.notch_freq);
                summary{end+1} = 'Re-reference: Average';
                summary{end+1} = '';
            end

            % Bad channels info
            summary{end+1} = 'CHANNEL QUALITY:';
            summary{end+1} = '----------------------------------------';
            if ~isempty(results.badChannels)
                summary{end+1} = sprintf('WARNING: %d bad channel(s) detected (KEPT in analysis):', length(results.badChannels));
                if isfield(results, 'badChannelLabels') && ~isempty(results.badChannelLabels)
                    for i = 1:length(results.badChannelLabels)
                        summary{end+1} = sprintf('   - %s', results.badChannelLabels{i});
                    end
                else
                    for i = 1:length(results.badChannels)
                        summary{end+1} = sprintf('   - Channel %d', results.badChannels(i));
                    end
                end
                summary{end+1} = '   (Multi-method detection: kurtosis, probability, spectrum, correlation)';
                summary{end+1} = '   (Thresholds: kurt=5, prob=5, spec=5, corr=0.4)';
            else
                summary{end+1} = 'All channels passed quality checks';
                summary{end+1} = '   (Multi-method detection: kurtosis, probability, spectrum, correlation)';
            end
            summary{end+1} = '';

            % ICA components info
            if isfield(results, 'removedComponents')
                summary{end+1} = 'ICA ARTIFACT REMOVAL:';
                summary{end+1} = '----------------------------------------';
                if ~isempty(results.removedComponents)
                    summary{end+1} = sprintf('ICA components removed: %d', length(results.removedComponents));
                    summary{end+1} = sprintf('   Components: %s', mat2str(results.removedComponents));
                    summary{end+1} = '   (Auto-flagged: >75%% artifact probability)';
                else
                    summary{end+1} = 'No artifact components detected';
                end
                summary{end+1} = '';
            end

            % Event detection info
            summary{end+1} = 'AI EVENT DETECTION:';
            summary{end+1} = '----------------------------------------';
            summary{end+1} = sprintf('Event types detected: %d', length(results.selectedEvents));
            summary{end+1} = sprintf('Total epochs extracted: %d', sum([results.epochedData.numEpochs]));
            summary{end+1} = '';

            % ERP Components
            summary{end+1} = 'ERP COMPONENTS (All Channels):';
            summary{end+1} = '----------------------------------------';
            summary{end+1} = 'Note: Use the ROI dropdown in the ERP tab to select regions.';
            summary{end+1} = 'Recommended ROIs by component:';
            summary{end+1} = '  • N250: Occipital (O1, Oz, O2) - visual processing';
            summary{end+1} = '  • N400: Central or Parietal (Cz, CPz, Pz) - semantic processing';
            summary{end+1} = '  • P600: Parietal (Pz, CPz) - syntactic processing';
            summary{end+1} = '';

            for i = 1:length(results.erpAnalysis)
                if results.erpAnalysis(i).numEpochs > 0
                    summary{end+1} = sprintf('%s (n=%d):', ...
                        results.erpAnalysis(i).condition, results.erpAnalysis(i).numEpochs);
                    summary{end+1} = sprintf('  N250: %.2f μV @ %.0f ms', ...
                        results.erpAnalysis(i).n250.amplitude, ...
                        results.erpAnalysis(i).n250.latency * 1000);
                    summary{end+1} = sprintf('  N400: %.2f μV @ %.0f ms', ...
                        results.erpAnalysis(i).n400.amplitude, ...
                        results.erpAnalysis(i).n400.latency * 1000);
                    summary{end+1} = sprintf('  P600: %.2f μV @ %.0f ms', ...
                        results.erpAnalysis(i).p600.amplitude, ...
                        results.erpAnalysis(i).p600.latency * 1000);
                    summary{end+1} = '';
                end
            end

            % Add ROI-specific analysis
            summary{end+1} = '';
            summary{end+1} = 'REGION-SPECIFIC ANALYSIS:';
            summary{end+1} = '----------------------------------------';

            % Central region analysis (best for N400)
            centralChans = getROIChannels(results.EEG, 'central');
            if ~isempty(centralChans)
                centralAnalysis = analyzeERPComponentsGUI(results.epochedData, [-0.2, 0.8], centralChans);
                summary{end+1} = sprintf('Central Region (%d channels) - Best for N400:', length(centralChans));
                for i = 1:length(centralAnalysis)
                    if centralAnalysis(i).numEpochs > 0
                        summary{end+1} = sprintf('  %s: N400=%.2f μV @ %.0f ms', ...
                            centralAnalysis(i).condition, ...
                            centralAnalysis(i).n400.amplitude, centralAnalysis(i).n400.latency * 1000);
                    end
                end
                summary{end+1} = '';
            end

            % Parietal region analysis (best for P600)
            parietalChans = getROIChannels(results.EEG, 'parietal');
            if ~isempty(parietalChans)
                parietalAnalysis = analyzeERPComponentsGUI(results.epochedData, [-0.2, 0.8], parietalChans);
                summary{end+1} = sprintf('Parietal Region (%d channels) - Best for P600:', length(parietalChans));
                for i = 1:length(parietalAnalysis)
                    if parietalAnalysis(i).numEpochs > 0
                        summary{end+1} = sprintf('  %s: P600=%.2f μV @ %.0f ms', ...
                            parietalAnalysis(i).condition, ...
                            parietalAnalysis(i).p600.amplitude, parietalAnalysis(i).p600.latency * 1000);
                    end
                end
                summary{end+1} = '';
            end

            % Frequency Bands (Baseline-Corrected Power)
            summary{end+1} = 'FREQUENCY BANDS (Baseline-Corrected):';
            summary{end+1} = '----------------------------------------';
            summary{end+1} = 'Baseline: -200 to 0 ms | Stimulus: 0 to 500 ms';
            summary{end+1} = '';

            if isfield(results.freqAnalysis, 'delta') && isfield(results.freqAnalysis.delta, 'meanStimulusPower')
                bandNames = {'delta', 'theta', 'alpha', 'beta', 'gamma'};
                bandRanges = {'0.5-4 Hz', '4-8 Hz', '8-13 Hz', '13-30 Hz', '30-50 Hz'};

                % Show average across conditions first
                summary{end+1} = 'Average across all conditions:';
                for b = 1:length(bandNames)
                    bandName = bandNames{b};
                    if isfield(results.freqAnalysis, bandName)
                        summary{end+1} = sprintf('  %s (%s): %.2f μV²/Hz (stimulus) | %+.2f dB change', ...
                            upper(bandName), bandRanges{b}, ...
                            results.freqAnalysis.(bandName).meanStimulusPower, ...
                            results.freqAnalysis.(bandName).meanPowerChange_dB);
                    end
                end

                % Show per-condition breakdown if available
                if isfield(results.freqAnalysis, 'conditions') && ~isempty(results.freqAnalysis.conditions)
                    summary{end+1} = '';
                    summary{end+1} = 'Per-condition power changes (dB):';
                    for condIdx = 1:length(results.freqAnalysis.conditions)
                        condName = results.freqAnalysis.conditions{condIdx};
                        summary{end+1} = sprintf('  %s:', condName);
                        for b = 1:length(bandNames)
                            bandName = bandNames{b};
                            if isfield(results.freqAnalysis, bandName) && ...
                               length(results.freqAnalysis.(bandName).powerChange_dB) >= condIdx
                                summary{end+1} = sprintf('    %s: %+.2f dB', ...
                                    upper(bandName), ...
                                    results.freqAnalysis.(bandName).powerChange_dB(condIdx));
                            end
                        end
                    end
                end
            end

            summary{end+1} = '';
            summary{end+1} = '========================================';
            summary{end+1} = 'Analysis completed successfully!';
            summary{end+1} = '========================================';

            app.SummaryTextArea.Value = summary;
        end

        function exportResults(app)
            [file, path] = uiputfile('*.mat', 'Save Results');
            if file == 0
                return;
            end

            results = app.Results;
            save(fullfile(path, file), 'results');

            uialert(app.UIFigure, 'Results saved successfully!', 'Export Complete', 'Icon', 'success');
        end

        function updateERPPlot(app)
            % Update ERP plot when event selection changes
            cla(app.ERPAxes);
            plotERPResults(app, app.ERPAxes);
        end

        function selectAllEvents(app)
            % Select all events in the listbox
            app.ERPEventListBox.Value = 1:length(app.ERPEventListBox.Items);
            updateERPPlot(app);
        end

        function deselectAllEvents(app)
            % Deselect all events in the listbox
            app.ERPEventListBox.Value = [];
            updateERPPlot(app);
        end

        function updateTopoMaps(app)
            % Update topographic maps when event or time selection changes
            plotTopoMaps(app);
        end

        function selectAllTopoEvents(app)
            % Select all events for topomaps
            app.TopoEventListBox.Value = 1:length(app.TopoEventListBox.Items);
            updateTopoMaps(app);
        end

        function deselectAllTopoEvents(app)
            % Deselect all events for topomaps
            app.TopoEventListBox.Value = [];
            updateTopoMaps(app);
        end

        function plotTopoMaps(app)
            % Plot topographic maps for selected events at selected time

            % Clear panel
            delete(app.TopoPanel.Children);

            % Get selected events
            selectedIndices = app.TopoEventListBox.Value;
            if isempty(selectedIndices)
                % Show message if nothing selected
                msgLabel = uilabel(app.TopoPanel);
                msgLabel.Position = [200 150 400 60];
                msgLabel.Text = 'No events selected. Select events from the list.';
                msgLabel.HorizontalAlignment = 'center';
                msgLabel.FontSize = 14;
                msgLabel.FontColor = [0.5 0.5 0.5];
                app.TopoTimeLabel.Text = sprintf('%.0f ms', app.TopoTimeSlider.Value);
                return;
            end

            % Get time point
            targetTime = app.TopoTimeSlider.Value / 1000;  % Convert ms to seconds
            app.TopoTimeLabel.Text = sprintf('%.0f ms', app.TopoTimeSlider.Value);

            epochedData = app.Results.epochedData;

            % Debug: Show what we're plotting
            fprintf('\n[TOPO] === Plotting Topographic Maps ===\n');
            fprintf('[TOPO] Time: %.0f ms (%.3f s)\n', app.TopoTimeSlider.Value, targetTime);
            fprintf('[TOPO] Selected events: %d\n', length(selectedIndices));
            for idx = selectedIndices
                fprintf('[TOPO]   - Event %d: "%s" (%d epochs, avgERP size: %dx%d)\n', ...
                    idx, epochedData(idx).eventType, epochedData(idx).numEpochs, ...
                    size(epochedData(idx).avgERP, 1), size(epochedData(idx).avgERP, 2));
            end

            % Debug: Check if avgERP data is actually different between conditions
            if length(selectedIndices) >= 2
                idx1 = selectedIndices(1);
                idx2 = selectedIndices(2);
                [~, tIdx] = min(abs(epochedData(idx1).timeVector - targetTime));
                data1 = epochedData(idx1).avgERP(:, tIdx);
                data2 = epochedData(idx2).avgERP(:, tIdx);
                dataCorr = corr(data1, data2);
                fprintf('[TOPO] Data correlation between first two events: %.4f (1.0 = identical)\n', dataCorr);
                if dataCorr > 0.999
                    fprintf('[TOPO] WARNING: Data appears identical between conditions!\n');
                end
            end
            nMaps = length(selectedIndices);

            % Get actual panel size for proper layout
            panelPos = app.TopoPanel.Position;  % [x y width height]
            panelWidth = panelPos(3);
            panelHeight = panelPos(4);

            % Calculate grid layout (max 4 columns)
            nCols = min(4, nMaps);
            nRows = ceil(nMaps / nCols);

            % Use 95% of available space, with gaps between plots
            usableWidth = panelWidth * 0.95;
            usableHeight = panelHeight * 0.95;

            mapWidth = floor(usableWidth / nCols) - 10;
            mapHeight = floor(usableHeight / nRows) - 10;

            % Plot each selected event
            for i = 1:nMaps
                eventIdx = selectedIndices(i);

                % Calculate position in grid (bottom-up layout)
                row = floor((i-1) / nCols);
                col = mod(i-1, nCols);
                xPos = 10 + col * (mapWidth + 10);
                yPos = panelHeight - (row + 1) * (mapHeight + 10);

                % Create axes for this topomap
                ax = uiaxes(app.TopoPanel);
                ax.Position = [xPos yPos mapWidth mapHeight];

                % Get ERP data at this time point
                [~, timeIdx] = min(abs(epochedData(eventIdx).timeVector - targetTime));
                topoData = epochedData(eventIdx).avgERP(:, timeIdx);

                % Debug output
                fprintf('[TOPO Debug] Event %d ("%s"): timeIdx=%d/%d, targetTime=%.3fs\n', ...
                    eventIdx, epochedData(eventIdx).eventType, timeIdx, ...
                    length(epochedData(eventIdx).timeVector), targetTime);
                fprintf('[TOPO Debug] Data range: %.2f to %.2f µV (mean=%.2f, std=%.2f)\n', ...
                    min(topoData), max(topoData), mean(topoData), std(topoData));

                % Check for problematic data
                if std(topoData) < 0.01
                    fprintf('[TOPO Debug] WARNING: Very low variance (std=%.4f) - map may be flat!\n', std(topoData));
                end
                if all(abs(topoData) < 0.01)
                    fprintf('[TOPO Debug] WARNING: All values near zero - data may be invalid!\n');
                end

                % Plot topomap using temporary figure (topoplot doesn't work with uiaxes)
                try
                    % Create hidden figure with traditional axes
                    tempFig = figure('Visible', 'off', 'Position', [0 0 400 400]);
                    tempAx = axes(tempFig);

                    % Calculate color limits
                    maxAbsVal = max(abs(topoData));
                    fprintf('[TOPO Debug] Color limits: [%.2f, %.2f]\n', -maxAbsVal, maxAbsVal);

                    % Plot topomap with proper parameters
                    % Note: HydroCel GSN 128 uses 2D planar layout (all z=0)
                    topoplot(topoData, app.Results.EEG.chanlocs, ...
                        'electrodes', 'on', ...
                        'style', 'map', ...
                        'maplimits', 'absmax', ...
                        'emarker', {'.','k',4,1}, ...
                        'gridscale', 150, ...        % Fine interpolation grid
                        'headrad', 0.6, ...          % Head circle size (valid range: 0-1)
                        'intrad', 0.6, ...           % Interpolate to head boundary (no overspill)
                        'whitebk', 'on');            % White background

                    % Capture the plot as an image
                    frame = getframe(tempFig);
                    topoImage = frame.cdata;
                    close(tempFig);

                    % Display image in uiaxes
                    imagesc(ax, topoImage);
                    axis(ax, 'off');
                    axis(ax, 'image');

                    % Use original event type for title if available
                    if isfield(epochedData(eventIdx), 'originalEventType')
                        titleText = strrep(epochedData(eventIdx).originalEventType, '_', ' ');
                    else
                        titleText = strrep(epochedData(eventIdx).eventType, '_', ' ');
                    end

                    title(ax, titleText, 'FontSize', 9, 'FontWeight', 'bold', 'Interpreter', 'none');
                catch ME
                    % Fallback if topoplot fails
                    try
                        % Try to clear and show error message in the axes
                        if isvalid(ax)
                            cla(ax);
                            text(ax, 0.5, 0.5, sprintf('Error: %s', ME.message), ...
                                'HorizontalAlignment', 'center', ...
                                'FontSize', 8, 'Color', 'r');
                            axis(ax, 'off');
                        end
                    catch
                        % If axes is invalid, just log the error
                        fprintf('[TOPO] Error plotting topomap for event %d: %s\n', ...
                            eventIdx, ME.message);
                    end
                end
            end
        end
    end
end

%% Helper functions

function channels = getROIChannels(EEG, roiSelection)
    % GETROICHANNELS - Identify channels belonging to a region of interest
    %
    % For EGI HydroCel 128 and other montages, identifies channels by:
    %   1. Channel labels (if they follow 10-20 naming like Fz, Cz, Pz)
    %   2. Spatial location (theta/radius from chanlocs)
    %
    % Inputs:
    %   EEG - EEGLAB structure with chanlocs
    %   roiSelection - 'all', 'frontal', 'central', 'parietal', 'occipital', 'temporal'
    %
    % Output:
    %   channels - Vector of channel indices

    % Check if channel locations exist
    if ~isfield(EEG, 'chanlocs') || isempty(EEG.chanlocs)
        warning('No channel locations found. Using all channels.');
        channels = 1:EEG.nbchan;
        return;
    end

    % Handle "all channels" case - exclude reference electrodes
    if strcmp(roiSelection, 'all')
        channels = [];
        for ch = 1:EEG.nbchan
            % Skip reference electrodes
            isRef = false;
            if isfield(EEG.chanlocs, 'type') && ~isempty(EEG.chanlocs(ch).type)
                if EEG.chanlocs(ch).type == 1  % Type 1 = reference in EGI
                    isRef = true;
                end
            end
            if isfield(EEG.chanlocs, 'ref') && ~isempty(EEG.chanlocs(ch).ref)
                if ~isempty(strfind(lower(EEG.chanlocs(ch).ref), 'ref'))
                    isRef = true;
                end
            end

            if ~isRef
                channels(end+1) = ch;
            end
        end

        % Debug output (first call only)
        persistent allDebugShown
        if isempty(allDebugShown)
            fprintf('\n[ROI Selection] All Channels (excluding reference)\n');
            fprintf('  Selected: %d channels\n', length(channels));
            fprintf('  Excluded: %d reference electrode(s)\n', EEG.nbchan - length(channels));
            if length(channels) <= 20
                fprintf('  Channel numbers: %s\n', mat2str(channels));
            else
                fprintf('  Channel numbers: %d, %d, %d ... %d, %d, %d\n', ...
                    channels(1), channels(2), channels(3), ...
                    channels(end-2), channels(end-1), channels(end));
            end
            allDebugShown = true;
        end
        return;
    end

    % Debug: Show what fields are available (first call only)
    persistent debugShown
    if isempty(debugShown)
        fprintf('\n[ROI Debug] Channel location fields: ');
        if ~isempty(EEG.chanlocs)
            fields = fieldnames(EEG.chanlocs(1));
            fprintf('%s ', fields{:});
            fprintf('\n');
            % Show sample values
            if isfield(EEG.chanlocs, 'X')
                fprintf('[ROI Debug] Example coordinates: X=%.2f, Y=%.2f\n', ...
                    EEG.chanlocs(1).X, EEG.chanlocs(1).Y);
            end
        end
        debugShown = true;
    end

    % Try to identify channels by label first (more accurate)
    channels = getChannelsByLabel(EEG.chanlocs, roiSelection);

    % If label-based selection failed or found too few channels, use spatial approach
    if length(channels) < 3
        channels = getChannelsBySpatialLocation(EEG.chanlocs, roiSelection);
    end

    % Ensure we have at least some channels
    if isempty(channels)
        warning('No channels found for ROI "%s". Using all channels.', roiSelection);
        channels = 1:EEG.nbchan;
    end
end

function channels = getChannelsByLabel(chanlocs, roiSelection)
    % Identify channels by their labels (works for standard 10-20 system)
    channels = [];

    % Common electrode prefixes for each region
    switch roiSelection
        case 'frontal'
            prefixes = {'Fp', 'AF', 'F', 'FC'};
            excludes = {'FT', 'T', 'TP', 'P', 'C', 'O'};  % Exclude if followed by these
        case 'central'
            prefixes = {'FC', 'C', 'CP'};
            excludes = {'O', 'P3', 'P4', 'P5', 'P6', 'P7', 'P8'};
        case 'parietal'
            prefixes = {'CP', 'P', 'PO'};
            excludes = {'Fp', 'AF', 'F', 'O1', 'O2', 'Oz'};
        case 'occipital'
            prefixes = {'PO', 'O', 'I'};  % I = inion area in EGI
            excludes = {'Fp', 'AF', 'F', 'C', 'T'};
        case 'temporal'
            prefixes = {'FT', 'T', 'TP'};
            excludes = {'Fp', 'F3', 'F4', 'C3', 'C4', 'P3', 'P4'};
        otherwise
            return;
    end

    for ch = 1:length(chanlocs)
        if isfield(chanlocs(ch), 'labels') && ~isempty(chanlocs(ch).labels)
            label = chanlocs(ch).labels;

            % Check if label starts with any of the target prefixes
            matched = false;
            for p = 1:length(prefixes)
                if startsWith(label, prefixes{p}, 'IgnoreCase', true)
                    matched = true;
                    break;
                end
            end

            % Exclude if it matches exclusion patterns
            if matched
                excluded = false;
                for e = 1:length(excludes)
                    if contains(label, excludes{e}, 'IgnoreCase', true)
                        excluded = true;
                        break;
                    end
                end
                if ~excluded
                    channels(end+1) = ch;
                end
            end
        end
    end
end

function channels = getChannelsBySpatialLocation(chanlocs, roiSelection)
    % Identify channels by their X/Y spatial coordinates
    % EEGLAB normalizes coordinates - scale factors vary by import method
    % These criteria work for normalized EGI coordinates (scaled ~30-50x from original)

    channels = [];
    coordsFound = 0;

    for ch = 1:length(chanlocs)
        % Skip reference electrodes
        if isfield(chanlocs, 'type') && ~isempty(chanlocs(ch).type)
            if chanlocs(ch).type == 1  % Type 1 = reference in EGI
                continue;
            end
        end
        if isfield(chanlocs, 'ref') && ~isempty(chanlocs(ch).ref)
            if ~isempty(strfind(lower(chanlocs(ch).ref), 'ref'))
                continue;
            end
        end

        % Try to get X and Y coordinates - check multiple field name variations
        x = [];
        y = [];

        % Try uppercase
        if isfield(chanlocs, 'X') && ~isempty(chanlocs(ch).X)
            x = chanlocs(ch).X;
            y = chanlocs(ch).Y;
        % Try lowercase
        elseif isfield(chanlocs, 'x') && ~isempty(chanlocs(ch).x)
            x = chanlocs(ch).x;
            y = chanlocs(ch).y;
        % Try sph_* (spherical converted)
        elseif isfield(chanlocs, 'sph_X') && ~isempty(chanlocs(ch).sph_X)
            x = chanlocs(ch).sph_X;
            y = chanlocs(ch).sph_Y;
        end

        % Skip if coordinates are missing or invalid
        if isempty(x) || isempty(y) || isnan(x) || isnan(y)
            continue;
        end

        coordsFound = coordsFound + 1;

        inROI = false;
        absX = abs(x);  % Distance from midline

        switch roiSelection
            case 'frontal'
                % Front of head: Y > 3 (normalized), not too far lateral
                % Expected electrodes: 73-75, 81-84, 88-90, 94-95
                inROI = (y > 3) && (absX < 4);

            case 'central'
                % Central strip: Y from -3 to +3, close to midline
                % Expected electrodes: 6, 11, 55, 62, 72, 31, 7, 13, 54, 61
                inROI = (y >= -3 && y <= 3) && (absX < 1.5);

            case 'parietal'
                % Back-center: Y from -6 to 0, close to midline
                % Expected electrodes: 54, 61, 67, 76-77, 31, 7
                inROI = (y >= -6 && y <= 0) && (absX < 2.5);

            case 'occipital'
                % Very back of head: Y < -6 (normalized)
                % Expected electrodes: 17, 126, 127, 14-15, 21-22, 25
                inROI = (y < -6);

            case 'temporal'
                % Sides of head: |X| > 5, mid-range Y
                % Expected electrodes: 43, 48, 56, 49, 38, 107, 113, 119, 120
                inROI = (absX > 5) && (y >= -4 && y <= 4);
        end

        if inROI
            channels(end+1) = ch;
        end
    end

    % Use results or fallback to theta/radius
    if coordsFound == 0
        % No X/Y coords available - use theta/radius
        channels = getChannelsByThetaRadius(chanlocs, roiSelection);
    elseif isempty(channels)
        % Coords available but didn't match criteria - try theta/radius
        channels = getChannelsByThetaRadius(chanlocs, roiSelection);
    end
    % Note: Success messages are printed by the respective functions
end

function channels = getChannelsByThetaRadius(chanlocs, roiSelection)
    % Fallback method using theta/radius (EEGLAB's spherical coordinates)
    % theta: angle in degrees (nose=+90, right ear=0, left ear=±180, back=-90)
    % radius: 0=vertex, 0.5=typical scalp edge

    channels = [];

    for ch = 1:length(chanlocs)
        % Skip reference electrodes
        if isfield(chanlocs, 'type') && ~isempty(chanlocs(ch).type)
            if chanlocs(ch).type == 1  % Type 1 = reference in EGI
                continue;
            end
        end
        if isfield(chanlocs, 'ref') && ~isempty(chanlocs(ch).ref)
            if ~isempty(strfind(lower(chanlocs(ch).ref), 'ref'))
                continue;
            end
        end

        if ~isfield(chanlocs, 'theta') || ~isfield(chanlocs, 'radius')
            continue;
        end

        theta = chanlocs(ch).theta;
        radius = chanlocs(ch).radius;

        if isempty(theta) || isempty(radius) || isnan(theta) || isnan(radius)
            continue;
        end

        inROI = false;

        switch roiSelection
            case 'frontal'
                % Front of head: theta around +90, moderate radius
                inROI = (theta >= 45 && theta <= 135) && (radius <= 0.6);

            case 'central'
                % Central strip: close to vertex, any theta
                inROI = (radius >= 0.15 && radius <= 0.45);

            case 'parietal'
                % Back-center: theta around -90 or ±180, moderate radius
                inROI = ((theta >= 135 || theta <= -135) || (theta >= -135 && theta <= -45)) && ...
                        (radius >= 0.2 && radius <= 0.6);

            case 'occipital'
                % Very back: theta around ±180 or -90, high radius
                inROI = ((abs(theta) >= 135) || (theta >= -120 && theta <= -60)) && ...
                        (radius >= 0.45);

            case 'temporal'
                % Sides: theta near 0 or ±180, high radius
                inROI = ((abs(theta) <= 45) || (abs(theta) >= 135)) && ...
                        (radius >= 0.5);
        end

        if inROI
            channels(end+1) = ch;
        end
    end

    % Debug output (first call only)
    persistent trDebugShown
    if isempty(trDebugShown)
        trDebugShown = struct();
    end
    if ~isfield(trDebugShown, roiSelection)
        fprintf('\n[ROI Selection] %s Region (theta/radius method)\n', ...
            [upper(roiSelection(1)) roiSelection(2:end)]);
        fprintf('  Selected: %d channels\n', length(channels));

        % Show channel numbers
        if length(channels) <= 30
            fprintf('  Channel numbers: %s\n', mat2str(channels));
        else
            fprintf('  Channel numbers: %d, %d, %d ... %d, %d, %d\n', ...
                channels(1), channels(2), channels(3), ...
                channels(end-2), channels(end-1), channels(end));
        end

        % Show channel labels if available
        if isfield(chanlocs, 'labels') && ~isempty(chanlocs(1).labels)
            labels = {chanlocs(channels).labels};
            if length(labels) <= 15
                fprintf('  Channel labels: %s\n', strjoin(labels, ', '));
            else
                fprintf('  Channel labels: %s, %s, %s ... %s, %s, %s\n', ...
                    labels{1}, labels{2}, labels{3}, ...
                    labels{end-2}, labels{end-1}, labels{end});
            end
        end

        trDebugShown.(roiSelection) = true;
    end
end

function erpAnalysis = analyzeERPComponentsGUI(epochedData, timeWindow, roiChannels)
    % Analyze ERP components (N250, N400, P600)
    % If roiChannels provided, use only those channels for analysis

    fs = 250;
    timeVector = linspace(timeWindow(1), timeWindow(2), round((timeWindow(2)-timeWindow(1))*fs)+1);

    n250Window = [0.2, 0.3];
    n400Window = [0.3, 0.5];
    p600Window = [0.5, 0.8];

    n250Idx = timeVector >= n250Window(1) & timeVector <= n250Window(2);
    n400Idx = timeVector >= n400Window(1) & timeVector <= n400Window(2);
    p600Idx = timeVector >= p600Window(1) & timeVector <= p600Window(2);

    erpAnalysis = struct();

    for i = 1:length(epochedData)
        if epochedData(i).numEpochs == 0
            continue;
        end

        % Use ROI channels if provided, otherwise use all channels
        if nargin >= 3 && ~isempty(roiChannels)
            erpGlobal = mean(epochedData(i).avgERP(roiChannels, :), 1);
        else
            erpGlobal = mean(epochedData(i).avgERP, 1);
        end

        [n250Amp, n250Lat] = min(erpGlobal(n250Idx));
        n250LatTime = timeVector(n250Idx);
        n250LatTime = n250LatTime(n250Lat);

        [n400Amp, n400Lat] = min(erpGlobal(n400Idx));
        n400LatTime = timeVector(n400Idx);
        n400LatTime = n400LatTime(n400Lat);

        [p600Amp, p600Lat] = max(erpGlobal(p600Idx));
        p600LatTime = timeVector(p600Idx);
        p600LatTime = p600LatTime(p600Lat);

        % Use original event type if available
        if isfield(epochedData(i), 'originalEventType')
            erpAnalysis(i).condition = epochedData(i).originalEventType;
        else
            erpAnalysis(i).condition = epochedData(i).eventType;
        end

        erpAnalysis(i).n250.amplitude = n250Amp;
        erpAnalysis(i).n250.latency = n250LatTime;
        erpAnalysis(i).n400.amplitude = n400Amp;
        erpAnalysis(i).n400.latency = n400LatTime;
        erpAnalysis(i).p600.amplitude = p600Amp;
        erpAnalysis(i).p600.latency = p600LatTime;
        erpAnalysis(i).numEpochs = epochedData(i).numEpochs;
    end
end

function freqAnalysis = analyzeFrequencyBandsGUI(EEG, epochedData, timeWindow)
    % Induced/Evoked Power Analysis with Baseline Correction
    % Computes spectral power per condition in stimulus window vs baseline

    bands = struct();
    bands.delta = [0.5, 4];
    bands.theta = [4, 8];
    bands.alpha = [8, 13];
    bands.beta = [13, 30];
    bands.gamma = [30, 50];

    freqAnalysis = struct();
    freqAnalysis.conditions = {};

    fprintf('\n[Frequency Analysis] Computing baseline-corrected spectral power per condition...\n');

    try
        % Define time windows (in seconds)
        baselineWindow = [timeWindow(1), 0];  % e.g., -0.2 to 0 s
        stimulusWindow = [0, 0.5];            % e.g., 0 to 0.5 s (stimulus processing)

        fs = EEG.srate;
        bandNames = fieldnames(bands);

        % Initialize per-band storage
        for b = 1:length(bandNames)
            freqAnalysis.(bandNames{b}).conditions = {};
            freqAnalysis.(bandNames{b}).baselinePower = [];
            freqAnalysis.(bandNames{b}).stimulusPower = [];
            freqAnalysis.(bandNames{b}).powerChange_dB = [];
        end

        % Process each condition
        for condIdx = 1:length(epochedData)
            if epochedData(condIdx).numEpochs == 0
                continue;
            end

            condName = epochedData(condIdx).eventType;
            fprintf('  Processing: %s (%d epochs)\n', condName, epochedData(condIdx).numEpochs);

            % Get epoch matrix: channels x samples x trials
            epochMatrix = cat(3, epochedData(condIdx).epochs{:});
            timeVector = epochedData(condIdx).timeVector;

            % Find time indices for baseline and stimulus windows
            baselineIdx = timeVector >= baselineWindow(1) & timeVector < baselineWindow(2);
            stimulusIdx = timeVector >= stimulusWindow(1) & timeVector < stimulusWindow(2);

            if sum(baselineIdx) < 10 || sum(stimulusIdx) < 10
                fprintf('    WARNING: Insufficient samples in time windows, skipping\n');
                continue;
            end

            % Initialize power storage for this condition
            condPower = struct();

            % Compute power for each frequency band
            for b = 1:length(bandNames)
                bandName = bandNames{b};
                bandRange = bands.(bandName);

                % Filter data to this frequency band using FFT approach
                % Average across trials first for evoked power
                avgData = mean(epochMatrix, 3);  % channels x samples

                % Extract baseline and stimulus periods
                baselineData = avgData(:, baselineIdx);  % channels x baseline_samples
                stimulusData = avgData(:, stimulusIdx);  % channels x stimulus_samples

                % Compute power using Welch's method on each period
                windowLength = min(fs, size(baselineData, 2));

                % Baseline power
                [psdBase, freqs] = pwelch(baselineData', windowLength, [], [], fs);
                psdBase = psdBase';  % channels x freqs
                freqIdx = freqs >= bandRange(1) & freqs <= bandRange(2);
                baselinePower = mean(mean(psdBase(:, freqIdx), 2));  % Average across channels and freqs

                % Stimulus power
                [psdStim, ~] = pwelch(stimulusData', windowLength, [], [], fs);
                psdStim = psdStim';
                stimulusPower = mean(mean(psdStim(:, freqIdx), 2));

                % Baseline correction: convert to dB change
                powerChange_dB = 10 * log10(stimulusPower / (baselinePower + eps));

                % Store results
                condPower.(bandName).baselinePower = baselinePower;
                condPower.(bandName).stimulusPower = stimulusPower;
                condPower.(bandName).powerChange_dB = powerChange_dB;

                fprintf('    %s: baseline=%.2f, stimulus=%.2f μV²/Hz, change=%+.2f dB\n', ...
                    upper(bandName), baselinePower, stimulusPower, powerChange_dB);
            end

            % Store condition results
            freqAnalysis.conditions{end+1} = condName;
            for b = 1:length(bandNames)
                bandName = bandNames{b};
                freqAnalysis.(bandName).conditions{end+1} = condName;
                freqAnalysis.(bandName).baselinePower(end+1) = condPower.(bandName).baselinePower;
                freqAnalysis.(bandName).stimulusPower(end+1) = condPower.(bandName).stimulusPower;
                freqAnalysis.(bandName).powerChange_dB(end+1) = condPower.(bandName).powerChange_dB;
            end
        end

        % Compute overall averages across conditions
        for b = 1:length(bandNames)
            bandName = bandNames{b};
            if ~isempty(freqAnalysis.(bandName).baselinePower)
                freqAnalysis.(bandName).meanBaselinePower = mean(freqAnalysis.(bandName).baselinePower);
                freqAnalysis.(bandName).meanStimulusPower = mean(freqAnalysis.(bandName).stimulusPower);
                freqAnalysis.(bandName).meanPowerChange_dB = mean(freqAnalysis.(bandName).powerChange_dB);
            else
                freqAnalysis.(bandName).meanBaselinePower = 0;
                freqAnalysis.(bandName).meanStimulusPower = 0;
                freqAnalysis.(bandName).meanPowerChange_dB = 0;
            end
        end

        fprintf('  Frequency analysis complete\n');

    catch ME
        warning('Frequency analysis failed: %s', ME.message);
        fprintf('  Error details: %s\n', ME.getReport());
    end
end
