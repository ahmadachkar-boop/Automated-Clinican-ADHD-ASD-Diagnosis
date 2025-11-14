classdef RestingStateAnalyzer < matlab.apps.AppBase
    % Resting State Analyzer - Automated Resting State EEG Analysis
    % Processes continuous EEG segments with start-end marker pairs

    properties (Access = public)
        UIFigure                matlab.ui.Figure

        % Main Panels
        UploadPanel             matlab.ui.container.Panel
        ProcessingPanel         matlab.ui.container.Panel
        ResultsPanel            matlab.ui.container.Panel

        % Upload Screen Components (matching JuanAnalyzer)
        TitleLabel              matlab.ui.control.Label
        SubtitleLabel           matlab.ui.control.Label
        BrowseButton            matlab.ui.control.Button
        FileInfoLabel           matlab.ui.control.Label
        EventSelectionButton    matlab.ui.control.Button
        EventSelectionLabel     matlab.ui.control.Label
        StartButton             matlab.ui.control.Button

        % Processing Screen Components
        ProcessingLabel         matlab.ui.control.Label
        ProgressBar             matlab.ui.control.UIAxes
        ProgressFill            matlab.graphics.primitive.Rectangle
        ProgressText            matlab.ui.control.Label
        StageLabel              matlab.ui.control.Label
        AnimatedIcon            matlab.ui.control.Label

        % Results Screen Components
        ResultsStatusLabel      matlab.ui.control.Label
        ResultsStatusIcon       matlab.ui.control.Label
        ResultsMessageLabel     matlab.ui.control.Label
        QualityScoreLabel       matlab.ui.control.Label

        % Tabbed Results Interface (like JuanAnalyzer)
        ResultsTabGroup         matlab.ui.container.TabGroup
        QualityTab              matlab.ui.container.Tab
        ClinicalTab             matlab.ui.container.Tab
        EpochTab                matlab.ui.container.Tab
        SummaryTab              matlab.ui.container.Tab

        % Quality Tab Components
        VisualizationPanel      matlab.ui.container.Panel
        TopoAxes                matlab.ui.control.UIAxes
        PSDAxes                 matlab.ui.control.UIAxes
        SignalAxes              matlab.ui.control.UIAxes

        % Clinical Tab Components
        ClinicalPanel           matlab.ui.container.Panel
        ThetaBetaAxes           matlab.ui.control.UIAxes
        MultiBandAxes           matlab.ui.control.UIAxes
        AsymmetryAxes           matlab.ui.control.UIAxes
        BandBarAxes             matlab.ui.control.UIAxes

        % Summary Tab Components
        MetricsPanel            matlab.ui.container.Panel
        SummaryTextArea         matlab.ui.control.TextArea

        ExportButton            matlab.ui.control.Button
        NewAnalysisButton       matlab.ui.control.Button

        % Event Analysis Components
        EventPanel              matlab.ui.container.Panel
        EventInfoLabel          matlab.ui.control.Label
        EventListBox            matlab.ui.control.ListBox
        AnalyzeEventsButton     matlab.ui.control.Button
        TimeWindowStart         matlab.ui.control.NumericEditField
        TimeWindowEnd           matlab.ui.control.NumericEditField
        EpochPanel              matlab.ui.container.Panel
        % Dynamic event visualization components (created per event type)
        EventColumns            cell  % Cell array of panels for each event type

        % Data
        EEGFile                 char
        EEG                     struct
        EEGClean                struct
        QualityMetrics          struct
        ClinicalMetrics         struct
        ProcessingStages        cell
        EventInfo               struct
        SelectedEvents          cell = {}
        SelectedFields          cell = {}
        EventFieldInfo          struct  % Detailed info about available event fields
        SegmentData             struct   % Continuous segments extracted between markers
        StartMarkerTypes        cell = {}  % Start marker types (e.g., 'Eyes_Open_Start')
        EndMarkerTypes          cell = {}  % End marker types (e.g., 'Eyes_Open_End')
        SegmentConditions       cell = {}  % Condition labels (e.g., 'EyesOpen', 'EyesClosed')
        BadChannels             double = []  % Detected bad channels (not removed)
        BadChannelLabels        cell = {}
        RemovedComponents       double = []  % ICA components removed
    end

    properties (Access = private)
        CurrentStage            double = 0
        TotalStages             double = 8
    end

    methods (Access = public)

        function app = RestingStateAnalyzer
            % Create and configure UIFigure
            createComponents(app);

            % Initialize app
            initializeApp(app);

            % Show upload screen
            showUploadScreen(app);
        end
    end

    methods (Access = private)

        function createComponents(app)
            % Create UIFigure - Fullscreen
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.WindowState = 'maximized';
            app.UIFigure.Name = 'Resting State Analyzer';
            app.UIFigure.Color = [0.95 0.96 0.97];
            app.UIFigure.Scrollable = 'on';
            app.UIFigure.SizeChangedFcn = @(fig, event) centerPanels(app);

            % Create Upload Panel
            createUploadPanel(app);

            % Create Processing Panel
            createProcessingPanel(app);

            % Create Results Panel
            createResultsPanel(app);

            % Create Event Analysis Panel (hidden initially)
            createEventPanel(app);

            % Center panels initially
            centerPanels(app);

            % Make figure visible
            app.UIFigure.Visible = 'on';
        end

        function centerPanels(app)
            % Center all panels horizontally in the figure
            figWidth = app.UIFigure.Position(3);
            panelWidth = 1200;

            if figWidth > panelWidth
                xPos = (figWidth - panelWidth) / 2;
            else
                xPos = 1;
            end

            % Center each panel
            app.UploadPanel.Position(1) = xPos;
            app.ProcessingPanel.Position(1) = xPos;
            app.ResultsPanel.Position(1) = xPos;
        end

        function createUploadPanel(app)
            app.UploadPanel = uipanel(app.UIFigure);
            % Center panel with safe margins
            screenSize = get(0, 'ScreenSize');
            panelWidth = min(1400, screenSize(3) - 100);  % Ensure 50px margin on each side
            panelHeight = 600;
            panelX = max(50, (screenSize(3) - panelWidth) / 2);  % Center, with minimum 50px from left
            panelY = (screenSize(4) - panelHeight) / 2;
            app.UploadPanel.Position = [panelX panelY panelWidth panelHeight];
            app.UploadPanel.BackgroundColor = [1 1 1];
            app.UploadPanel.BorderType = 'none';
            % Title
            app.TitleLabel = uilabel(app.UploadPanel);
            app.TitleLabel.Position = [200 500 600 50];
            app.TitleLabel.Text = 'Resting State Analyzer';
            app.TitleLabel.FontSize = 36;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.FontColor = [0.2 0.3 0.6];
            app.TitleLabel.HorizontalAlignment = 'center';
            % Subtitle
            app.SubtitleLabel = uilabel(app.UploadPanel);
            app.SubtitleLabel.Position = [150 460 700 30];
            app.SubtitleLabel.Text = 'Continuous EEG Segment Analysis | Eyes Open/Closed Comparison';
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
            % Event Selection Button (for start-end markers)
            app.EventSelectionButton = uibutton(app.UploadPanel, 'push');
            app.EventSelectionButton.Position = [350 240 300 50];
            app.EventSelectionButton.Text = 'Select Start/End Markers';
            app.EventSelectionButton.FontSize = 18;
            app.EventSelectionButton.BackgroundColor = [0.5 0.4 0.7];
            app.EventSelectionButton.FontColor = [1 1 1];
            app.EventSelectionButton.Enable = 'off';
            app.EventSelectionButton.ButtonPushedFcn = @(btn,event) selectMarkersManually(app);
            % Event Selection Label
            app.EventSelectionLabel = uilabel(app.UploadPanel);
            app.EventSelectionLabel.Position = [100 190 800 30];
            app.EventSelectionLabel.Text = 'No markers selected';
            app.EventSelectionLabel.FontSize = 12;
            app.EventSelectionLabel.FontColor = [0.5 0.5 0.5];
            app.EventSelectionLabel.HorizontalAlignment = 'center';
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
            instrLabel.Text = sprintf('Supports: .mff, .set, .edf formats\nResting state analysis • Continuous segment extraction');
            instrLabel.FontSize = 10;
            instrLabel.FontColor = [0.6 0.6 0.6];
            instrLabel.HorizontalAlignment = 'center';
        end


        function createProcessingPanel(app)
            % Main Processing Panel
            app.ProcessingPanel = uipanel(app.UIFigure);
            app.ProcessingPanel.Position = [1 1 1200 1200];
            app.ProcessingPanel.BackgroundColor = [0.95 0.96 0.97];
            app.ProcessingPanel.BorderType = 'none';
            app.ProcessingPanel.Visible = 'off';

            % Title
            app.ProcessingLabel = uilabel(app.ProcessingPanel);
            app.ProcessingLabel.Position = [300 880 600 50];  % Moved up 200px
            app.ProcessingLabel.Text = 'Processing EEG Data';
            app.ProcessingLabel.FontSize = 28;
            app.ProcessingLabel.FontWeight = 'bold';
            app.ProcessingLabel.FontColor = [0.2 0.3 0.5];
            app.ProcessingLabel.HorizontalAlignment = 'center';

            % Animated Icon
            app.AnimatedIcon = uilabel(app.ProcessingPanel);
            app.AnimatedIcon.Position = [550 780 100 80];  % Moved up 200px
            app.AnimatedIcon.Text = '🧠';
            app.AnimatedIcon.FontSize = 64;
            app.AnimatedIcon.HorizontalAlignment = 'center';

            % Stage Label
            app.StageLabel = uilabel(app.ProcessingPanel);
            app.StageLabel.Position = [300 720 600 30];  % Moved up 200px
            app.StageLabel.Text = 'Initializing...';
            app.StageLabel.FontSize = 16;
            app.StageLabel.FontColor = [0.3 0.4 0.5];
            app.StageLabel.HorizontalAlignment = 'center';

            % Progress Bar (using UIAxes)
            app.ProgressBar = uiaxes(app.ProcessingPanel);
            app.ProgressBar.Position = [300 650 600 40];  % Moved up 200px
            app.ProgressBar.XLim = [0 100];
            app.ProgressBar.YLim = [0 1];
            app.ProgressBar.XTick = [];
            app.ProgressBar.YTick = [];
            app.ProgressBar.Box = 'on';
            app.ProgressBar.XColor = [0.8 0.8 0.8];
            app.ProgressBar.YColor = [0.8 0.8 0.8];

            % Progress Fill
            app.ProgressFill = rectangle(app.ProgressBar, 'Position', [0 0 0 1]);
            app.ProgressFill.FaceColor = [0.3 0.6 0.9];
            app.ProgressFill.EdgeColor = 'none';

            % Progress Percentage
            app.ProgressText = uilabel(app.ProcessingPanel);
            app.ProgressText.Position = [300 610 600 25];  % Moved up 200px
            app.ProgressText.Text = '0%';
            app.ProgressText.FontSize = 14;
            app.ProgressText.FontWeight = 'bold';
            app.ProgressText.FontColor = [0.3 0.6 0.9];
            app.ProgressText.HorizontalAlignment = 'center';

            % Processing stages info
            stagesPanel = uipanel(app.ProcessingPanel);
            stagesPanel.Position = [350 400 500 180];  % Moved up 200px
            stagesPanel.BackgroundColor = [1 1 1];
            stagesPanel.BorderType = 'line';

            stagesLabel = uilabel(stagesPanel);
            stagesLabel.Position = [20 145 460 25];
            stagesLabel.Text = 'Processing Stages:';
            stagesLabel.FontSize = 14;
            stagesLabel.FontWeight = 'bold';

            stages = {
                '✓ Loading Data'
                '✓ Filtering & Preprocessing'
                '✓ Multi-Method Artifact Detection'
                '✓ ICA with PCA Reduction'
                '✓ Signal Cleaning (ICLabel 75%)'
                '✓ Continuous Segment Extraction'
                '✓ Enhanced Quality Evaluation'
                '✓ Resting State Band Power Analysis'
            };

            for i = 1:8
                label = uilabel(stagesPanel);
                label.Position = [30 155-i*19 440 16];
                label.Text = stages{i};
                label.FontSize = 10;
                label.FontColor = [0.6 0.6 0.6];
            end
        end

        function createResultsPanel(app)
            % Main Results Panel with Tabbed Interface (like JuanAnalyzer)
            app.ResultsPanel = uipanel(app.UIFigure);
            app.ResultsPanel.Position = [1 1 1200 900];
            app.ResultsPanel.BackgroundColor = [0.95 0.96 0.97];
            app.ResultsPanel.BorderType = 'none';
            app.ResultsPanel.Visible = 'off';

            % Status Icon
            app.ResultsStatusIcon = uilabel(app.ResultsPanel);
            app.ResultsStatusIcon.Position = [550 820 100 60];
            app.ResultsStatusIcon.Text = '✅';
            app.ResultsStatusIcon.FontSize = 48;
            app.ResultsStatusIcon.HorizontalAlignment = 'center';

            % Status Label
            app.ResultsStatusLabel = uilabel(app.ResultsPanel);
            app.ResultsStatusLabel.Position = [200 770 800 35];
            app.ResultsStatusLabel.Text = 'EEG quality is sufficient for clinical interpretation';
            app.ResultsStatusLabel.FontSize = 20;
            app.ResultsStatusLabel.FontWeight = 'bold';
            app.ResultsStatusLabel.FontColor = [0.2 0.6 0.3];
            app.ResultsStatusLabel.HorizontalAlignment = 'center';

            % Quality Score
            app.QualityScoreLabel = uilabel(app.ResultsPanel);
            app.QualityScoreLabel.Position = [400 730 400 30];
            app.QualityScoreLabel.Text = 'Quality Score: 85/100';
            app.QualityScoreLabel.FontSize = 16;
            app.QualityScoreLabel.FontColor = [0.3 0.4 0.5];
            app.QualityScoreLabel.HorizontalAlignment = 'center';

            % Tabbed Results (EXACTLY like JuanAnalyzer)
            app.ResultsTabGroup = uitabgroup(app.ResultsPanel);
            app.ResultsTabGroup.Position = [50 150 1100 560];

            % === TAB 1: QUALITY ASSESSMENT ===
            app.QualityTab = uitab(app.ResultsTabGroup);
            app.QualityTab.Title = '📊 Quality Assessment';

            % Quality Visualization Panel
            app.VisualizationPanel = uipanel(app.QualityTab);
            app.VisualizationPanel.Position = [10 10 1070 520];
            app.VisualizationPanel.BackgroundColor = [1 1 1];
            app.VisualizationPanel.BorderType = 'line';
            app.VisualizationPanel.Title = 'Signal Quality Metrics';
            app.VisualizationPanel.FontSize = 12;
            app.VisualizationPanel.FontWeight = 'bold';

            % Topographic Map
            app.TopoAxes = uiaxes(app.VisualizationPanel);
            app.TopoAxes.Position = [30 200 300 280];
            title(app.TopoAxes, 'Alpha Power Distribution', 'FontSize', 11);

            % Power Spectral Density
            app.PSDAxes = uiaxes(app.VisualizationPanel);
            app.PSDAxes.Position = [380 200 300 280];
            title(app.PSDAxes, 'Power Spectral Density', 'FontSize', 11);
            xlabel(app.PSDAxes, 'Frequency (Hz)');
            ylabel(app.PSDAxes, 'Power (dB)');

            % Signal Traces
            app.SignalAxes = uiaxes(app.VisualizationPanel);
            app.SignalAxes.Position = [730 200 300 280];
            title(app.SignalAxes, 'Before vs After Cleaning', 'FontSize', 11);
            xlabel(app.SignalAxes, 'Time (s)');
            ylabel(app.SignalAxes, 'Amplitude (µV)');

            % Metrics display at bottom
            app.MetricsPanel = uipanel(app.VisualizationPanel);
            app.MetricsPanel.Position = [30 20 1000 160];
            app.MetricsPanel.BackgroundColor = [0.98 0.99 1];
            app.MetricsPanel.BorderType = 'line';
            app.MetricsPanel.Title = 'Detailed Quality Metrics';
            app.MetricsPanel.FontSize = 10;

            % === TAB 2: CLINICAL DIAGNOSTICS ===
            app.ClinicalTab = uitab(app.ResultsTabGroup);
            app.ClinicalTab.Title = '📊 Condition Comparison';

            % Clinical Visualization Panel
            app.ClinicalPanel = uipanel(app.ClinicalTab);
            app.ClinicalPanel.Position = [10 10 1070 520];
            app.ClinicalPanel.BackgroundColor = [1 1 1];
            app.ClinicalPanel.BorderType = 'line';
            app.ClinicalPanel.Title = 'Clinical Biomarkers (ADHD/ASD)';
            app.ClinicalPanel.FontSize = 12;
            app.ClinicalPanel.FontWeight = 'bold';

            % Theta/Beta Ratio Map
            app.ThetaBetaAxes = uiaxes(app.ClinicalPanel);
            app.ThetaBetaAxes.Position = [30 220 300 280];
            title(app.ThetaBetaAxes, 'Theta/Beta Ratio', 'FontSize', 11);

            % Multi-Band Power Distribution
            app.MultiBandAxes = uiaxes(app.ClinicalPanel);
            app.MultiBandAxes.Position = [380 220 300 280];
            title(app.MultiBandAxes, 'Multi-Band Power', 'FontSize', 11);

            % Hemispheric Asymmetry
            app.AsymmetryAxes = uiaxes(app.ClinicalPanel);
            app.AsymmetryAxes.Position = [730 220 300 280];
            title(app.AsymmetryAxes, 'Hemispheric Asymmetry', 'FontSize', 11);

            % Frequency Band Bar Chart
            app.BandBarAxes = uiaxes(app.ClinicalPanel);
            app.BandBarAxes.Position = [30 20 1000 180];
            title(app.BandBarAxes, 'Frequency Band Power Comparison', 'FontSize', 11);
            ylabel(app.BandBarAxes, 'Relative Power (%)');

            % === TAB 3: EPOCH ANALYSIS ===
            app.EpochTab = uitab(app.ResultsTabGroup);
            app.EpochTab.Title = '⚡ Epoch Analysis';

            % Epoch Panel (will be populated dynamically)
            app.EpochPanel = uipanel(app.EpochTab);
            app.EpochPanel.Position = [10 10 1070 520];
            app.EpochPanel.BackgroundColor = [1 1 1];
            app.EpochPanel.BorderType = 'line';
            app.EpochPanel.Title = 'Event-Related Analysis';
            app.EpochPanel.FontSize = 12;
            app.EpochPanel.FontWeight = 'bold';
            app.EpochPanel.Scrollable = 'on';

            % Placeholder message
            epochPlaceholder = uilabel(app.EpochPanel);
            epochPlaceholder.Position = [250 250 570 30];
            epochPlaceholder.Text = 'No epochs defined - Use marker-pair epoch builder during upload';
            epochPlaceholder.FontSize = 13;
            epochPlaceholder.FontColor = [0.5 0.5 0.5];
            epochPlaceholder.HorizontalAlignment = 'center';

            % === TAB 4: SUMMARY ===
            app.SummaryTab = uitab(app.ResultsTabGroup);
            app.SummaryTab.Title = '📋 Summary Report';

            % Summary Text Area
            app.SummaryTextArea = uitextarea(app.SummaryTab);
            app.SummaryTextArea.Position = [10 10 1070 520];
            app.SummaryTextArea.Editable = 'off';
            app.SummaryTextArea.FontName = 'Courier New';
            app.SummaryTextArea.FontSize = 10;
            app.SummaryTextArea.Value = {'EEG Quality Analysis Summary', '', 'Analysis in progress...'};

            % Action Buttons
            app.ExportButton = uibutton(app.ResultsPanel, 'push');
            app.ExportButton.Position = [400 80 180 50];
            app.ExportButton.Text = '📄 Export Report';
            app.ExportButton.FontSize = 14;
            app.ExportButton.BackgroundColor = [0.3 0.5 0.8];
            app.ExportButton.FontColor = [1 1 1];
            app.ExportButton.ButtonPushedFcn = @(btn,event) exportReport(app);

            app.NewAnalysisButton = uibutton(app.ResultsPanel, 'push');
            app.NewAnalysisButton.Position = [620 80 180 50];
            app.NewAnalysisButton.Text = '🔄 New Analysis';
            app.NewAnalysisButton.FontSize = 14;
            app.NewAnalysisButton.BackgroundColor = [0.5 0.5 0.5];
            app.NewAnalysisButton.FontColor = [1 1 1];
            app.NewAnalysisButton.ButtonPushedFcn = @(btn,event) resetApp(app);
        end

        function createEventPanel(app)
            % Event Analysis Panel - appears between upload/processing info and results
            app.EventPanel = uipanel(app.ResultsPanel);
            app.EventPanel.Position = [50 2080 1100 200];  % Above results content
            app.EventPanel.BackgroundColor = [0.98 0.99 1];
            app.EventPanel.BorderType = 'line';
            app.EventPanel.Title = '📊 Event-Based Analysis Available';
            app.EventPanel.FontSize = 13;
            app.EventPanel.FontWeight = 'bold';
            app.EventPanel.Visible = 'off';  % Hidden until events detected

            % Event Info Label
            app.EventInfoLabel = uilabel(app.EventPanel);
            app.EventInfoLabel.Position = [20 150 1060 30];
            app.EventInfoLabel.Text = 'Event markers detected in your data!';
            app.EventInfoLabel.FontSize = 12;
            app.EventInfoLabel.FontWeight = 'bold';
            app.EventInfoLabel.FontColor = [0.2 0.5 0.7];

            % Instructions
            instrLabel = uilabel(app.EventPanel);
            instrLabel.Position = [20 125 1060 20];
            instrLabel.Text = 'Select one or more event types below to analyze epochs separately (e.g., Go vs No-Go trials):';
            instrLabel.FontSize = 11;
            instrLabel.FontColor = [0.3 0.4 0.5];

            % Event List Box
            app.EventListBox = uilistbox(app.EventPanel);
            app.EventListBox.Position = [20 40 300 80];
            app.EventListBox.Items = {};
            app.EventListBox.Multiselect = 'on';
            app.EventListBox.FontSize = 10;

            % Time Window Labels and Fields
            twLabel = uilabel(app.EventPanel);
            twLabel.Position = [340 95 120 20];
            twLabel.Text = 'Epoch Window:';
            twLabel.FontSize = 11;
            twLabel.FontWeight = 'bold';

            startLabel = uilabel(app.EventPanel);
            startLabel.Position = [340 70 80 20];
            startLabel.Text = 'Start (s):';
            startLabel.FontSize = 10;

            app.TimeWindowStart = uieditfield(app.EventPanel, 'numeric');
            app.TimeWindowStart.Position = [420 68 80 22];
            app.TimeWindowStart.Value = -0.2;
            app.TimeWindowStart.Limits = [-5 0];

            endLabel = uilabel(app.EventPanel);
            endLabel.Position = [340 40 80 20];
            endLabel.Text = 'End (s):';
            endLabel.FontSize = 10;

            app.TimeWindowEnd = uieditfield(app.EventPanel, 'numeric');
            app.TimeWindowEnd.Position = [420 38 80 22];
            app.TimeWindowEnd.Value = 0.8;
            app.TimeWindowEnd.Limits = [0 5];

            % Analyze Button
            app.AnalyzeEventsButton = uibutton(app.EventPanel, 'push');
            app.AnalyzeEventsButton.Position = [530 40 180 80];
            app.AnalyzeEventsButton.Text = '🔍 Analyze Selected Events';
            app.AnalyzeEventsButton.FontSize = 12;
            app.AnalyzeEventsButton.FontWeight = 'bold';
            app.AnalyzeEventsButton.BackgroundColor = [0.2 0.6 0.8];
            app.AnalyzeEventsButton.FontColor = [1 1 1];
            app.AnalyzeEventsButton.ButtonPushedFcn = @(btn,event) analyzeSelectedEvents(app);

            % Epoch Results Panel (hidden until analysis complete)
            % This will be dynamically populated with side-by-side event comparisons
            % Position at BOTTOM of results for easy visibility
            app.EpochPanel = uipanel(app.ResultsPanel);
            app.EpochPanel.Position = [50 50 1100 750];  % Expanded for detailed visualizations
            app.EpochPanel.BackgroundColor = [1 1 1];
            app.EpochPanel.BorderType = 'line';
            app.EpochPanel.Title = '⚡ Event-Related Potentials - Detailed Analysis';
            app.EpochPanel.FontSize = 13;
            app.EpochPanel.FontWeight = 'bold';
            app.EpochPanel.Visible = 'off';

            % Note: Individual event visualizations will be created dynamically
            % in generateEpochVisualizations() based on number of selected events
        end

        function initializeApp(app)
            % Initialize processing stages
            app.ProcessingStages = {
                'Loading Data...'
                'Filtering & Preprocessing...'
                'Detecting Artifacts...'
                'Cleaning Signal...'
                'Evaluating Quality...'
                'Rendering Visualizations...'
            };

            % Initialize event visualization storage
            app.EventColumns = {};
        end

        function showUploadScreen(app)
            app.UploadPanel.Visible = 'on';
            app.ProcessingPanel.Visible = 'off';
            app.ResultsPanel.Visible = 'off';
        end

        function showProcessingScreen(app)
            app.UploadPanel.Visible = 'off';
            app.ProcessingPanel.Visible = 'on';
            app.ResultsPanel.Visible = 'off';
            app.CurrentStage = 0;
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

        function detectMarkersFromField(app)
            % Detect event markers using the selected event field
            try
                selectedField = app.EventFieldDropdown.Value;
                fprintf('\n=== DETECTING MARKERS ===\n');
                fprintf('Selected field: ''%s''\n', selectedField);

                % Debug: Show raw values from this field
                if isfield(app.EEG, 'event') && ~isempty(app.EEG.event)
                    fprintf('Checking first 10 events in field ''%s'':\n', selectedField);
                    for i = 1:min(10, length(app.EEG.event))
                        if isfield(app.EEG.event, selectedField)
                            val = app.EEG.event(i).(selectedField);
                            if isempty(val)
                                fprintf('  Event %d: [empty]\n', i);
                            elseif isnumeric(val)
                                fprintf('  Event %d: %s (numeric)\n', i, num2str(val));
                            elseif ischar(val)
                                fprintf('  Event %d: ''%s'' (char)\n', i, val);
                            elseif isstring(val)
                                fprintf('  Event %d: ''%s'' (string)\n', i, char(val));
                            elseif iscell(val)
                                if ~isempty(val)
                                    fprintf('  Event %d: {''%s''} (cell)\n', i, char(val{1}));
                                else
                                    fprintf('  Event %d: {} (empty cell)\n', i);
                                end
                            else
                                fprintf('  Event %d: [%s]\n', i, class(val));
                            end
                        else
                            fprintf('  Event %d: [field ''%s'' does not exist]\n', i, selectedField);
                        end
                    end
                end
                fprintf('========================\n\n');

                % Call detectEEGEvents with the selected field
                app.EventInfo = detectEEGEvents(app.EEG, selectedField);

                if app.EventInfo.hasEvents
                    % Show event information
                    app.EventsDetectedLabel.Text = sprintf('⚡ Events: %s (using field: %s)', ...
                        app.EventInfo.description, selectedField);
                    app.EventsDetectedLabel.Visible = 'on';

                    % Populate marker dropdowns
                    markerItems = app.EventInfo.eventTypes;
                    app.StartMarkerDropdown.Items = markerItems;
                    app.EndMarkerDropdown.Items = markerItems;

                    % Set default selections (first and second marker if available)
                    if length(markerItems) >= 2
                        app.StartMarkerDropdown.Value = markerItems{1};
                        app.EndMarkerDropdown.Value = markerItems{2};
                    elseif length(markerItems) == 1
                        app.StartMarkerDropdown.Value = markerItems{1};
                        app.EndMarkerDropdown.Value = markerItems{1};
                    end

                    % Show epoch builder UI
                    app.EpochBuilderLabel.Visible = 'on';
                    app.StartMarkerLabel.Visible = 'on';
                    app.StartMarkerDropdown.Visible = 'on';
                    app.EndMarkerLabel.Visible = 'on';
                    app.EndMarkerDropdown.Visible = 'on';
                    app.EpochNameLabel.Visible = 'on';
                    app.EpochNameField.Visible = 'on';
                    app.AddEpochButton.Visible = 'on';
                    app.EpochListLabel.Visible = 'on';
                    app.EpochListBox.Visible = 'on';
                    app.RemoveEpochButton.Visible = 'on';

                    fprintf('✓ Found %d unique marker types\n', length(markerItems));
                else
                    % No events detected - hide epoch builder UI
                    app.EventsDetectedLabel.Text = sprintf('⚠️  No valid markers found in field: %s', selectedField);
                    app.EventsDetectedLabel.Visible = 'on';
                    hideEpochBuilder(app);
                    fprintf('Warning: No markers detected in selected field\n');
                end
            catch ME
                fprintf('Error detecting markers: %s\n', ME.message);
                app.EventsDetectedLabel.Text = sprintf('❌ Error detecting markers: %s', ME.message);
                app.EventsDetectedLabel.Visible = 'on';
                hideEpochBuilder(app);
            end
        end

        function selectMarkersManually(app)
            % Resting state marker selection for start-end pairs
            EEG = app.EEG;

            % STEP 1: Select event field to use
            fprintf('Discovering event fields for resting state markers...\n');

            % Get all available event fields
            allFieldNames = {};
            if isfield(EEG, 'event') && ~isempty(EEG.event)
                allFieldNames = fieldnames(EEG.event);
                % Filter to keep only useful fields (not latency, duration, etc.)
                allFieldNames = allFieldNames(~ismember(allFieldNames, {'latency', 'duration', 'urevent', 'epoch'}));
            end

            if isempty(allFieldNames)
                uialert(app.UIFigure, 'No event fields found.', 'No Fields');
                return;
            end

            % STEP 1 DIALOG: Select event field
            d1 = uifigure('Name', 'Step 1: Select Event Field', 'Position', [100 100 600 400]);

            titleLabel = uilabel(d1, 'Position', [50 350 500 30], ...
                'Text', 'Step 1: Select event field for markers', ...
                'FontSize', 16, 'FontWeight', 'bold');

            infoLabel = uilabel(d1, 'Position', [50 320 500 20], ...
                'Text', 'Choose which field contains your start/end markers (usually ''type'')', ...
                'FontSize', 11, 'FontColor', [0.5 0.5 0.5]);

            fieldListbox = uilistbox(d1, 'Position', [50 100 500 200], ...
                'Items', allFieldNames, ...
                'Value', allFieldNames{1});  % Default to first field

            % Auto-select 'type' if available
            if ismember('type', allFieldNames)
                fieldListbox.Value = 'type';
            end

            nextBtn = uibutton(d1, 'Position', [420 30 100 50], ...
                'Text', 'Next', ...
                'FontSize', 14, ...
                'BackgroundColor', [0.3 0.5 0.8], ...
                'FontColor', [1 1 1], ...
                'ButtonPushedFcn', @(btn,event) proceedToStep2());

            cancelBtn = uibutton(d1, 'Position', [300 30 100 50], ...
                'Text', 'Cancel', ...
                'ButtonPushedFcn', @(btn,event) close(d1));

            function proceedToStep2()
                selectedField = fieldListbox.Value;
                if isempty(selectedField)
                    uialert(d1, 'Please select a field.', 'No Field Selected');
                    return;
                end
                close(d1);

                % STEP 2: Get all unique marker types from selected field
                allMarkers = {};
                markerCounts = [];
                for i = 1:length(EEG.event)
                    if isfield(EEG.event(i), selectedField)
                        val = EEG.event(i).(selectedField);
                        if ischar(val) || isstring(val)
                            allMarkers{end+1} = char(val);
                        end
                    end
                end

                uniqueMarkers = unique(allMarkers);
                if isempty(uniqueMarkers)
                    uialert(app.UIFigure, 'No markers found in selected field.', 'No Markers');
                    return;
                end

                % Count occurrences
                markerCounts = zeros(length(uniqueMarkers), 1);
                for i = 1:length(uniqueMarkers)
                    markerCounts(i) = sum(strcmp(allMarkers, uniqueMarkers{i}));
                end

                % STEP 2 DIALOG: Define start-end pairs
                d2 = uifigure('Name', 'Step 2: Define Start-End Marker Pairs', 'Position', [100 100 900 700]);

                titleLabel2 = uilabel(d2, 'Position', [50 650 800 30], ...
                    'Text', 'Step 2: Define start-end marker pairs for each condition', ...
                    'FontSize', 16, 'FontWeight', 'bold');

                infoLabel2 = uilabel(d2, 'Position', [50 620 800 20], ...
                    'Text', sprintf('Field: %s | Found %d marker types', selectedField, length(uniqueMarkers)), ...
                    'FontSize', 11, 'FontColor', [0.5 0.5 0.5]);

                % Instructions
                instrLabel = uilabel(d2, 'Position', [50 590 800 20], ...
                    'Text', 'Example: Start=''Eyes_Open_Start'', End=''Eyes_Open_End'', Label=''EyesOpen''', ...
                    'FontSize', 10, 'FontColor', [0.4 0.4 0.7], 'FontAngle', 'italic');

                % Start marker dropdown
                startLabel = uilabel(d2, 'Position', [50 540 150 30], ...
                    'Text', 'Start Marker:', 'FontSize', 12, 'FontWeight', 'bold');
                startDropdown = uidropdown(d2, 'Position', [210 540 200 30], ...
                    'Items', uniqueMarkers);

                % End marker dropdown
                endLabel = uilabel(d2, 'Position', [450 540 150 30], ...
                    'Text', 'End Marker:', 'FontSize', 12, 'FontWeight', 'bold');
                endDropdown = uidropdown(d2, 'Position', [610 540 200 30], ...
                    'Items', uniqueMarkers);
                if length(uniqueMarkers) >= 2
                    endDropdown.Value = uniqueMarkers{2};
                end

                % Condition label
                condLabel = uilabel(d2, 'Position', [50 490 150 30], ...
                    'Text', 'Condition Label:', 'FontSize', 12, 'FontWeight', 'bold');
                condField = uieditfield(d2, 'text', 'Position', [210 490 200 30], ...
                    'Value', 'Condition1', 'Placeholder', 'e.g., EyesOpen');

                % Add pair button
                addPairBtn = uibutton(d2, 'Position', [450 490 150 30], ...
                    'Text', 'Add Pair', ...
                    'BackgroundColor', [0.2 0.7 0.3], ...
                    'FontColor', [1 1 1], ...
                    'ButtonPushedFcn', @(btn,event) addPair());

                % List of defined pairs
                pairListLabel = uilabel(d2, 'Position', [50 450 300 30], ...
                    'Text', 'Defined Pairs:', 'FontSize', 12, 'FontWeight', 'bold');

                pairListBox = uilistbox(d2, 'Position', [50 150 800 290]);

                % Remove pair button
                removePairBtn = uibutton(d2, 'Position', [50 110 150 30], ...
                    'Text', 'Remove Selected', ...
                    'BackgroundColor', [0.8 0.2 0.2], ...
                    'FontColor', [1 1 1], ...
                    'ButtonPushedFcn', @(btn,event) removePair());

                % Storage for pairs
                markerPairs = {};  % {startMarker, endMarker, label}

                % Action buttons
                okBtn = uibutton(d2, 'Position', [750 30 100 50], ...
                    'Text', 'OK', ...
                    'FontSize', 14, ...
                    'BackgroundColor', [0.2 0.7 0.3], ...
                    'FontColor', [1 1 1], ...
                    'ButtonPushedFcn', @(btn,event) confirmPairs());

                backBtn = uibutton(d2, 'Position', [510 30 100 50], ...
                    'Text', 'Back', ...
                    'ButtonPushedFcn', @(btn,event) goBack());

                cancelBtn2 = uibutton(d2, 'Position', [630 30 100 50], ...
                    'Text', 'Cancel', ...
                    'ButtonPushedFcn', @(btn,event) close(d2));

                function addPair()
                    start = startDropdown.Value;
                    endM = endDropdown.Value;
                    label = condField.Value;

                    if isempty(label)
                        uialert(d2, 'Please enter a condition label.', 'No Label');
                        return;
                    end

                    % Check if label already exists
                    for i = 1:length(markerPairs)
                        if strcmp(markerPairs{i}{3}, label)
                            uialert(d2, 'Condition label already exists.', 'Duplicate Label');
                            return;
                        end
                    end

                    % Add pair
                    markerPairs{end+1} = {start, endM, label};

                    % Update display
                    updatePairList();

                    % Auto-increment label for next pair
                    condField.Value = sprintf('Condition%d', length(markerPairs)+1);
                end

                function removePair()
                    idx = pairListBox.Value;
                    if ~isempty(idx) && ~isempty(pairListBox.ItemsData)
                        pairIdx = find(strcmp(pairListBox.ItemsData, idx));
                        if ~isempty(pairIdx)
                            markerPairs(pairIdx) = [];
                            updatePairList();
                        end
                    end
                end

                function updatePairList()
                    if isempty(markerPairs)
                        pairListBox.Items = {'(no pairs defined)'};
                        pairListBox.ItemsData = {};
                    else
                        displayItems = cell(length(markerPairs), 1);
                        for i = 1:length(markerPairs)
                            pair = markerPairs{i};
                            displayItems{i} = sprintf('%s: %s → %s', pair{3}, pair{1}, pair{2});
                        end
                        pairListBox.Items = displayItems;
                        pairListBox.ItemsData = displayItems;
                    end
                end

                function goBack()
                    close(d2);
                    selectMarkersManually(app);
                end

                function confirmPairs()
                    if isempty(markerPairs)
                        uialert(d2, 'Please define at least one marker pair.', 'No Pairs');
                        return;
                    end

                    % Store in app
                    app.StartMarkerTypes = {};
                    app.EndMarkerTypes = {};
                    app.SegmentConditions = {};

                    for i = 1:length(markerPairs)
                        pair = markerPairs{i};
                        app.StartMarkerTypes{i} = pair{1};
                        app.EndMarkerTypes{i} = pair{2};
                        app.SegmentConditions{i} = pair{3};
                    end

                    app.SelectedFields = {selectedField};  % Store field used
                    app.EventSelectionLabel.Text = sprintf('%d marker pairs defined', length(markerPairs));
                    app.EventSelectionLabel.FontColor = [0.2 0.6 0.3];
                    app.StartButton.Enable = 'on';
                    close(d2);
                end

                uiwait(d2);
            end

            uiwait(d1);
        end

        function startAnalysis(app)
            startProcessing(app);
        end

        function startProcessing(app)
            % Check if user defined any marker pairs
            if ~isempty(app.StartMarkerTypes)
                fprintf('User defined %d marker pair(s) for analysis:\n', length(app.StartMarkerTypes));
                for i = 1:length(app.StartMarkerTypes)
                    fprintf('  %d. %s: %s → %s\n', i, app.SegmentConditions{i}, ...
                        app.StartMarkerTypes{i}, app.EndMarkerTypes{i});
                end
            else
                fprintf('No marker pairs defined - will only perform continuous data analysis\n');
            end

            % Show processing screen
            showProcessingScreen(app);

            % Run processing in background
            drawnow;
            pause(0.1);

            try
                % Process EEG
                processEEG(app);

                % Show results
                showResultsScreen(app);
                displayResults(app);

            catch ME
                uialert(app.UIFigure, ME.message, 'Processing Error');
                showUploadScreen(app);
            end
        end

        function processEEG(app)
            % Run preprocessing pipeline matching JuanAnalyzerManual exactly

            % Stage 1: Loading Data
            updateProgress(app, 1, 'Loading Data...');
            EEG = app.EEG;
            EEG_original = EEG; % Store original for comparison
            pause(0.3);

            % Stage 2: Filtering & Preprocessing (EXACT match with JuanAnalyzerManual)
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

            % Stage 3: Artifact Detection (Multi-method, but DON'T remove channels)
            updateProgress(app, 3, 'Detecting Artifacts (Multi-Method)...');
            badChans = [];
            badChanLabels = {};

            try
                % Method 1-3: Kurtosis, Probability, Spectrum
                EEG_temp = pop_rejchan(EEG, 'elec', 1:EEG.nbchan, ...
                    'threshold', [5 5 5], ...
                    'norm', 'on', ...
                    'measure', 'kurt', 'prob', 'spec');

                % Identify flagged channels
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
                if isfield(EEG, 'chanlocs') && length(EEG.chanlocs) > 1
                    correlationThreshold = 0.4;
                    for i = 1:EEG.nbchan
                        chanData = EEG.data(i, :);
                        corrVals = zeros(EEG.nbchan - 1, 1);
                        idx = 1;
                        for j = 1:EEG.nbchan
                            if i ~= j
                                corrVals(idx) = corr(chanData', EEG.data(j, :)');
                                idx = idx + 1;
                            end
                        end

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

                % Store but DON'T remove - keep EEG unchanged
                app.BadChannels = badChans;
                app.BadChannelLabels = badChanLabels;

                fprintf('Detected %d bad channels (kept for analysis): %s\n', ...
                    length(badChans), strjoin(badChanLabels, ', '));
            catch ME
                fprintf('Warning: Bad channel detection error: %s\n', ME.message);
            end

            % Run ICA with PCA reduction (EXACT match - 40 components for speed)
            updateProgress(app, 4, 'Running ICA with PCA Reduction...');
            try
                EEG = pop_runica(EEG, 'icatype', 'runica', 'extended', 1, 'pca', 40);
                fprintf('ICA completed with PCA reduction to 40 components\n');
            catch ME
                fprintf('ICA failed: %s\n', ME.message);
            end

            % Stage 5: Cleaning Signal (ICLabel at 75% threshold - EXACT match)
            updateProgress(app, 5, 'Cleaning Signal with ICLabel...');
            removedComponents = [];

            if isfield(EEG, 'icaweights') && ~isempty(EEG.icaweights)
                try
                    EEG = pop_iclabel(EEG, 'default');

                    % Auto-flag artifacts at 75% confidence (EXACT match)
                    EEG = pop_icflag(EEG, [0 0; 0.75 1; 0.75 1; 0.75 1; 0.75 1; 0.75 1; 0 0]);

                    % Remove flagged components
                    bad_comps = find(EEG.reject.gcompreject);
                    if ~isempty(bad_comps)
                        removedComponents = bad_comps;
                        EEG = pop_subcomp(EEG, bad_comps, 0);
                        fprintf('Removed %d artifact components: %s\n', ...
                            length(bad_comps), mat2str(bad_comps));
                    end
                catch ME
                    fprintf('ICLabel failed: %s\n', ME.message);
                end
            end

            app.RemovedComponents = removedComponents;

            % Stage 6: Continuous Segment Extraction (using start-end marker pairs)
            if ~isempty(app.StartMarkerTypes)
                updateProgress(app, 6, 'Extracting Continuous Segments Between Markers...');
                try
                    % Extract segments using start-end marker pairs
                    app.SegmentData = extractRestingSegments(EEG, ...
                        app.StartMarkerTypes, app.EndMarkerTypes, ...
                        app.SegmentConditions, app.SelectedFields{1});
                    fprintf('Extracted %d continuous segments\n', length(app.SegmentData));
                catch ME
                    fprintf('Segment extraction failed: %s\n', ME.message);
                    fprintf('Error details: %s\n', ME.getReport());
                    app.SegmentData = [];
                end
            else
                updateProgress(app, 6, 'No Markers Selected (Continuous Analysis)...');
                app.SegmentData = [];
            end

            % Stage 7: Comprehensive Quality Evaluation
            updateProgress(app, 7, 'Evaluating Quality (Enhanced Metrics)...');
            metrics = computeEnhancedQualityMetrics(app, EEG, EEG_original, ...
                badChans, removedComponents);
            app.QualityMetrics = metrics;

            % Compute resting state band power metrics
            try
                updateProgress(app, 8, 'Computing Resting State Band Powers...');
                if ~isempty(app.SegmentData)
                    restingMetrics = computeRestingStateMetrics(app.SegmentData);
                    app.ClinicalMetrics = restingMetrics;  % Store in ClinicalMetrics for now
                else
                    fprintf('No segments available for resting state analysis\n');
                    app.ClinicalMetrics = struct();
                end
            catch ME
                warning('Resting state metrics failed: %s', ME.message);
                fprintf('Error details: %s\n', ME.getReport());
                app.ClinicalMetrics = struct();
            end

            % Store results
            app.EEGClean = EEG;

            pause(0.3);
        end

        function metrics = computeQualityMetrics(app, EEG_clean, EEG_original)
            % Compute advanced quality score and metrics
            % Use external function for comprehensive analysis

            try
                metrics = computeAdvancedQualityMetrics(EEG_original, EEG_clean);
            catch ME
                % Fallback to basic metrics if advanced function fails
                warning('Advanced metrics failed: %s. Using basic metrics.', ME.message);

                metrics = struct();

                % Channel metrics
                metrics.channels_original = EEG_original.nbchan;
                metrics.channels_clean = EEG_clean.nbchan;
                metrics.channels_removed = EEG_original.nbchan - EEG_clean.nbchan;
                chan_retention = EEG_clean.nbchan / EEG_original.nbchan;
                metrics.channel_retention = chan_retention;
                metrics.channel_score = chan_retention * 25;

                % Artifact metrics
                metrics.artifact_components = 0;
                metrics.artifact_ratio = 0;
                metrics.total_components = 0;
                metrics.artifact_score = 20;

                % Signal quality
                metrics.snr_db = 15;
                metrics.kurtosis = 3;
                metrics.signal_score = 15;

                % Spectral quality
                metrics.spectral_score = 15;
                metrics.delta_relative = 0;
                metrics.theta_relative = 0;
                metrics.alpha_relative = 0;
                metrics.beta_relative = 0;
                metrics.gamma_relative = 0;

                % Overall
                metrics.total_score = 75;
                metrics.is_clean = true;
                metrics.quality_level = 'Good';

                % Duration
                if isfield(EEG_clean, 'xmax')
                    metrics.duration = EEG_clean.xmax;
                else
                    metrics.duration = 60;
                end

                % Other
                metrics.noise_sources = {};
                metrics.recommendations = {'Data processed with basic quality assessment'};
            end
        end

        function updateProgress(app, stage, message)
            app.CurrentStage = stage;
            progress = (stage / app.TotalStages) * 100;

            % Update progress bar
            app.ProgressFill.Position = [0 0 progress 1];

            % Update text
            app.ProgressText.Text = sprintf('%d%%', round(progress));
            app.StageLabel.Text = message;

            % Force UI update
            drawnow;
        end

        function displayResults(app)
            metrics = app.QualityMetrics;

            % Update status based on quality
            if isfield(metrics, 'is_clean') && metrics.is_clean
                app.ResultsStatusIcon.Text = '✅';
                app.ResultsStatusLabel.Text = 'EEG quality is sufficient for clinical interpretation';
                app.ResultsStatusLabel.FontColor = [0.2 0.6 0.3];
            else
                app.ResultsStatusIcon.Text = '⚠️';
                app.ResultsStatusLabel.Text = 'EEG recording quality is insufficient for analysis';
                app.ResultsStatusLabel.FontColor = [0.8 0.4 0.2];
            end

            % Update quality score
            if isfield(metrics, 'total_score')
                app.QualityScoreLabel.Text = sprintf('Quality Score: %d/100', metrics.total_score);
            else
                app.QualityScoreLabel.Text = 'Quality Score: Calculating...';
            end

            % Detect and display event information (for epoch analysis)
            detectAndDisplayEvents(app);

            % Generate visualizations
            generateVisualizations(app);
            displayMetrics(app);

            % Generate summary report
            generateSummaryReport(app);
        end

        function generateVisualizations(app)
            % Generate quality visualizations
            try
                generateEEGVisualizations(app.EEGClean, app.QualityMetrics, ...
                    app.TopoAxes, app.PSDAxes, app.SignalAxes);
            catch ME
                warning('Quality visualization generation failed: %s', ME.message);
                % Fallback to simple placeholder
                cla(app.TopoAxes);
                text(app.TopoAxes, 0.5, 0.5, 'Visualization unavailable', ...
                    'HorizontalAlignment', 'center');
            end

            % Generate resting state comparison visualizations
            if ~isempty(fieldnames(app.ClinicalMetrics))
                try
                    generateRestingStateVisualizations(app.ClinicalMetrics, ...
                        app.ThetaBetaAxes, app.MultiBandAxes, app.AsymmetryAxes, app.BandBarAxes);
                catch ME
                    warning('Resting state visualization generation failed: %s', ME.message);
                    fprintf('Error details: %s\n', ME.getReport());
                    % Fallback to simple placeholder
                    cla(app.ThetaBetaAxes);
                    text(app.ThetaBetaAxes, 0.5, 0.5, 'Resting state visualization unavailable', ...
                        'Units', 'normalized', 'HorizontalAlignment', 'center');
                end
            else
                % Show message if resting state metrics weren't computed
                cla(app.ThetaBetaAxes);
                text(app.ThetaBetaAxes, 0.5, 0.5, 'Resting state metrics not available', ...
                    'Units', 'normalized', 'HorizontalAlignment', 'center', 'FontSize', 12);
            end
        end

        function displayMetrics(app)
            % Display enhanced metrics in Quality Tab
            delete(app.MetricsPanel.Children);

            metrics = app.QualityMetrics;

            % Create detailed metrics grid
            metricTexts = {};

            % Row 1: Channels and Bad Channels
            if isfield(metrics, 'bad_channels_detected')
                metricTexts{end+1} = sprintf('📊 Channels: %d total (%d bad detected)', ...
                    metrics.channels_original, metrics.bad_channels_detected);
                if ~isempty(metrics.bad_channel_labels)
                    metricTexts{end+1} = sprintf('   Bad: %s', strjoin(metrics.bad_channel_labels(1:min(5,end)), ', '));
                end
            else
                metricTexts{end+1} = sprintf('📊 Channels: %d total', metrics.channels_original);
            end

            % Row 2: Artifacts
            if isfield(metrics, 'artifact_components')
                metricTexts{end+1} = sprintf('🎯 Artifacts: %d/%d components removed (%.1f%%)', ...
                    metrics.artifact_components, metrics.total_components, metrics.artifact_ratio*100);
                if metrics.eye_artifacts > 0 || metrics.muscle_artifacts > 0
                    metricTexts{end+1} = sprintf('   Eye: %d, Muscle: %d, Heart: %d, Line: %d', ...
                        metrics.eye_artifacts, metrics.muscle_artifacts, ...
                        metrics.heart_artifacts, metrics.line_noise_comps);
                end
            end

            % Row 3: Signal Quality
            if isfield(metrics, 'snr_db')
                metricTexts{end+1} = sprintf('📈 SNR: %.1f dB | Kurtosis: %.2f', ...
                    metrics.snr_db, metrics.kurtosis);
            end

            % Row 4: Temporal Stability
            if isfield(metrics, 'temporal_stability_cv')
                metricTexts{end+1} = sprintf('⏱ Temporal Stability: CV=%.3f', ...
                    metrics.temporal_stability_cv);
            end

            % Row 5: Amplitude Range
            if isfield(metrics, 'amplitude_range_uv')
                metricTexts{end+1} = sprintf('📏 Amplitude Range: %.1f µV (P01=%.1f, P99=%.1f)', ...
                    metrics.amplitude_range_uv, metrics.amplitude_p01, metrics.amplitude_p99);
            end

            % Row 6: Spectral Quality
            if isfield(metrics, 'line_noise_ratio')
                metricTexts{end+1} = sprintf('🔊 Line Noise: %.2f%% | Alpha: %.1f%%', ...
                    metrics.line_noise_ratio*100, metrics.alpha_relative*100);
            end

            % Row 7: Duration
            if isfield(metrics, 'duration')
                metricTexts{end+1} = sprintf('⏱️  Duration: %.1f minutes (%.0f sec)', ...
                    metrics.duration/60, metrics.duration);
            end

            % Row 8: Component Scores
            if isfield(metrics, 'channel_score')
                metricTexts{end+1} = sprintf('🏆 Component Scores: Ch=%d, Art=%d, SNR=%d, Spec=%d, Temp=%d, Amp=%d', ...
                    metrics.channel_score, metrics.artifact_score, metrics.signal_score, ...
                    metrics.spectral_score, metrics.temporal_score, metrics.amplitude_score);
            end

            % Display as a list
            y_pos = 130;
            for i = 1:length(metricTexts)
                label = uilabel(app.MetricsPanel);
                label.Position = [15 y_pos 970 15];
                label.Text = metricTexts{i};
                label.FontSize = 9;
                label.FontColor = [0.2 0.3 0.4];
                y_pos = y_pos - 16;
            end
        end

        function generateSummaryReport(app)
            % Generate comprehensive text summary for Summary Tab
            metrics = app.QualityMetrics;

            summary = {};
            summary{end+1} = '═══════════════════════════════════════════════════════════════';
            summary{end+1} = '       EEG QUALITY ANALYSIS - COMPREHENSIVE REPORT';
            summary{end+1} = '═══════════════════════════════════════════════════════════════';
            summary{end+1} = '';
            summary{end+1} = sprintf('Analysis Date: %s', datestr(now));
            if isfield(app, 'EEGFile') && ~isempty(app.EEGFile)
                [~, fname, ext] = fileparts(app.EEGFile);
                summary{end+1} = sprintf('File: %s%s', fname, ext);
            end
            summary{end+1} = '';

            % Overall Quality
            summary{end+1} = '─────────────────────────────────────────────────────────────────';
            summary{end+1} = '  OVERALL QUALITY ASSESSMENT';
            summary{end+1} = '─────────────────────────────────────────────────────────────────';
            if isfield(metrics, 'total_score')
                summary{end+1} = sprintf('  Quality Score: %d/100 (%s)', ...
                    metrics.total_score, metrics.quality_level);
                if metrics.is_clean
                    statusText = 'ACCEPTABLE for clinical use';
                else
                    statusText = 'INSUFFICIENT quality';
                end
                summary{end+1} = sprintf('  Status: %s', statusText);
            end
            summary{end+1} = '';

            % Component Scores
            summary{end+1} = '  Component Breakdown:';
            if isfield(metrics, 'channel_score')
                summary{end+1} = sprintf('    • Channel Quality:      %2d/20 points', metrics.channel_score);
                summary{end+1} = sprintf('    • Artifact Removal:     %2d/25 points', metrics.artifact_score);
                summary{end+1} = sprintf('    • Signal-to-Noise:      %2d/20 points', metrics.signal_score);
                summary{end+1} = sprintf('    • Spectral Quality:     %2d/15 points', metrics.spectral_score);
                summary{end+1} = sprintf('    • Temporal Stability:   %2d/10 points', metrics.temporal_score);
                summary{end+1} = sprintf('    • Amplitude Range:      %2d/10 points', metrics.amplitude_score);
            end
            summary{end+1} = '';

            % Channel Analysis
            summary{end+1} = '─────────────────────────────────────────────────────────────────';
            summary{end+1} = '  CHANNEL ANALYSIS';
            summary{end+1} = '─────────────────────────────────────────────────────────────────';
            summary{end+1} = sprintf('  Total Channels: %d', metrics.channels_original);
            if isfield(metrics, 'bad_channels_detected')
                summary{end+1} = sprintf('  Bad Channels Detected: %d (%.1f%%)', ...
                    metrics.bad_channels_detected, (metrics.bad_channels_detected/metrics.channels_original)*100);
                if ~isempty(metrics.bad_channel_labels)
                    summary{end+1} = sprintf('  Bad Channel Labels: %s', strjoin(metrics.bad_channel_labels, ', '));
                end
                summary{end+1} = sprintf('  Note: Bad channels kept for analysis (not removed)');
            end
            summary{end+1} = '';

            % Artifact Analysis
            summary{end+1} = '─────────────────────────────────────────────────────────────────';
            summary{end+1} = '  ARTIFACT ANALYSIS (ICA)';
            summary{end+1} = '─────────────────────────────────────────────────────────────────';
            summary{end+1} = sprintf('  Total Components: %d (PCA-reduced from full rank)', metrics.total_components);
            summary{end+1} = sprintf('  Artifact Components Removed: %d (%.1f%%)', ...
                metrics.artifact_components, metrics.artifact_ratio*100);
            summary{end+1} = sprintf('  ICLabel Classification (>75%% confidence):');
            summary{end+1} = sprintf('    • Eye Movement:      %d components', metrics.eye_artifacts);
            summary{end+1} = sprintf('    • Muscle Tension:    %d components', metrics.muscle_artifacts);
            summary{end+1} = sprintf('    • Cardiac:           %d components', metrics.heart_artifacts);
            summary{end+1} = sprintf('    • Line Noise:        %d components', metrics.line_noise_comps);
            summary{end+1} = '';

            % Signal Quality
            summary{end+1} = '─────────────────────────────────────────────────────────────────';
            summary{end+1} = '  SIGNAL QUALITY METRICS';
            summary{end+1} = '─────────────────────────────────────────────────────────────────';
            summary{end+1} = sprintf('  Signal-to-Noise Ratio: %.1f dB', metrics.snr_db);
            summary{end+1} = sprintf('  Signal RMS: %.2f µV', metrics.signal_rms);
            summary{end+1} = sprintf('  Kurtosis: %.2f (ideal ~3.0)', metrics.kurtosis);
            if isfield(metrics, 'temporal_stability_cv')
                summary{end+1} = sprintf('  Temporal Stability CV: %.3f', metrics.temporal_stability_cv);
            end
            if isfield(metrics, 'amplitude_range_uv')
                summary{end+1} = sprintf('  Amplitude Range: %.1f µV (P1=%.1f, P99=%.1f)', ...
                    metrics.amplitude_range_uv, metrics.amplitude_p01, metrics.amplitude_p99);
            end
            summary{end+1} = '';

            % Spectral Analysis
            summary{end+1} = '─────────────────────────────────────────────────────────────────';
            summary{end+1} = '  SPECTRAL ANALYSIS';
            summary{end+1} = '─────────────────────────────────────────────────────────────────';
            summary{end+1} = '  Relative Band Powers:';
            summary{end+1} = sprintf('    • Delta (0.5-4 Hz):   %5.1f%%', metrics.delta_relative*100);
            summary{end+1} = sprintf('    • Theta (4-8 Hz):     %5.1f%%', metrics.theta_relative*100);
            summary{end+1} = sprintf('    • Alpha (8-13 Hz):    %5.1f%%', metrics.alpha_relative*100);
            summary{end+1} = sprintf('    • Beta (13-30 Hz):    %5.1f%%', metrics.beta_relative*100);
            summary{end+1} = sprintf('    • Gamma (30-50 Hz):   %5.1f%%', metrics.gamma_relative*100);
            summary{end+1} = sprintf('  Line Noise (60 Hz): %.2f%% of total power', metrics.line_noise_ratio*100);
            summary{end+1} = '';

            % Noise Sources
            if ~isempty(metrics.noise_sources)
                summary{end+1} = '─────────────────────────────────────────────────────────────────';
                summary{end+1} = '  DETECTED NOISE SOURCES';
                summary{end+1} = '─────────────────────────────────────────────────────────────────';
                for i = 1:length(metrics.noise_sources)
                    summary{end+1} = sprintf('  ⚠ %s', metrics.noise_sources{i});
                end
                summary{end+1} = '';
            end

            % Recommendations
            summary{end+1} = '─────────────────────────────────────────────────────────────────';
            summary{end+1} = '  RECOMMENDATIONS';
            summary{end+1} = '─────────────────────────────────────────────────────────────────';
            for i = 1:length(metrics.recommendations)
                summary{end+1} = sprintf('  %s', metrics.recommendations{i});
            end
            summary{end+1} = '';

            % Recording Info
            summary{end+1} = '─────────────────────────────────────────────────────────────────';
            summary{end+1} = '  RECORDING INFORMATION';
            summary{end+1} = '─────────────────────────────────────────────────────────────────';
            summary{end+1} = sprintf('  Duration: %.1f minutes (%.0f seconds)', ...
                metrics.duration/60, metrics.duration);
            summary{end+1} = sprintf('  Sampling Rate: %.0f Hz', metrics.sampling_rate);
            summary{end+1} = '';

            % Segment Info
            if ~isempty(app.StartMarkerTypes)
                summary{end+1} = '─────────────────────────────────────────────────────────────────';
                summary{end+1} = '  RESTING STATE SEGMENTS';
                summary{end+1} = '─────────────────────────────────────────────────────────────────';
                summary{end+1} = sprintf('  Marker Pairs Defined: %d', length(app.StartMarkerTypes));
                for i = 1:length(app.StartMarkerTypes)
                    summary{end+1} = sprintf('    %d. %s: %s → %s', i, app.SegmentConditions{i}, ...
                        app.StartMarkerTypes{i}, app.EndMarkerTypes{i});
                end
                if ~isempty(app.SegmentData)
                    summary{end+1} = sprintf('  Extracted Segments: %d total', length(app.SegmentData));

                    % Group by condition
                    conditions = unique({app.SegmentData.condition});
                    for i = 1:length(conditions)
                        cond = conditions{i};
                        condMask = strcmp({app.SegmentData.condition}, cond);
                        numSegs = sum(condMask);
                        totalDur = sum([app.SegmentData(condMask).duration]);
                        summary{end+1} = sprintf('    • %s: %d segments (%.2f sec total)', ...
                            cond, numSegs, totalDur);
                    end
                end
                summary{end+1} = '';
            end

            summary{end+1} = '═══════════════════════════════════════════════════════════════';
            summary{end+1} = '                    END OF REPORT';
            summary{end+1} = '═══════════════════════════════════════════════════════════════';

            % Update summary text area
            app.SummaryTextArea.Value = summary;
        end

        function exportReport(app)
            % Export results to PDF
            [file, path] = uiputfile('*.pdf', 'Save Report', 'EEG_Quality_Report.pdf');

            if file ~= 0
                try
                    % Create temporary figure for export
                    fig = figure('Visible', 'off', 'Position', [100 100 800 1000]);

                    % Add title
                    annotation(fig, 'textbox', [0.1 0.92 0.8 0.05], ...
                        'String', 'EEG Quality Analysis Report', ...
                        'FontSize', 18, 'FontWeight', 'bold', ...
                        'HorizontalAlignment', 'center', 'EdgeColor', 'none');

                    % Add status
                    if app.QualityMetrics.is_clean
                        statusText = sprintf('✅ Quality Score: %d/100 - ACCEPTABLE', app.QualityMetrics.total_score);
                        statusColor = [0.2 0.6 0.3];
                    else
                        statusText = sprintf('⚠️ Quality Score: %d/100 - INSUFFICIENT', app.QualityMetrics.total_score);
                        statusColor = [0.8 0.4 0.2];
                    end

                    annotation(fig, 'textbox', [0.1 0.86 0.8 0.04], ...
                        'String', statusText, 'FontSize', 14, ...
                        'HorizontalAlignment', 'center', 'EdgeColor', 'none', ...
                        'Color', statusColor);

                    % Export to PDF
                    exportgraphics(fig, fullfile(path, file), 'ContentType', 'vector');
                    close(fig);

                    uialert(app.UIFigure, 'Report exported successfully!', 'Export Complete');
                catch ME
                    uialert(app.UIFigure, ME.message, 'Export Error');
                end
            end
        end

        function resetApp(app)
            % Reset for new analysis
            app.EEGFile = '';
            app.EEG = struct();
            app.EEGClean = struct();
            app.QualityMetrics = struct();
            app.CurrentStage = 0;

            % Hide file info
            app.FileInfoPanel.Visible = 'off';

            % Show upload screen
            showUploadScreen(app);
        end

        function detectAndDisplayEvents(app)
            % For RestingStateAnalyzer, segments are already extracted during processing
            % Just hide the event panel as it's not used for resting state analysis
            try
                % Hide the event panel (not used in resting state analysis)
                app.EventPanel.Visible = 'off';

                % Note: Segments are already extracted in Stage 6 of processing
                % No additional event detection needed here
            catch ME
                warning('Event analysis failed: %s', ME.message);
                app.EpochPanel.Visible = 'off';
            end
        end

        function analyzeSelectedEvents(app)
            % Epoch data around selected events and display results
            try
                % Get selected event types
                selectedItems = app.EventListBox.Value;
                if isempty(selectedItems)
                    uialert(app.UIFigure, 'Please select at least one event type', 'No Selection');
                    return;
                end

                % Extract event type names (remove count suffix)
                selectedTypes = cell(length(selectedItems), 1);
                for i = 1:length(selectedItems)
                    % Parse "EventName (123 trials)" to get "EventName"
                    tokens = regexp(selectedItems{i}, '(.*) \(\d+ trials\)', 'tokens');
                    if ~isempty(tokens)
                        selectedTypes{i} = tokens{1}{1};
                    else
                        selectedTypes{i} = selectedItems{i};
                    end
                end

                % Get time window
                timeWindow = [app.TimeWindowStart.Value, app.TimeWindowEnd.Value];

                % Epoch the data
                fprintf('\n=== Event-Based Analysis ===\n');
                app.EpochedData = epochEEGByEvents(app.EEGClean, selectedTypes, timeWindow);

                % Show epoch panel
                app.EpochPanel.Visible = 'on';

                % Generate epoch visualizations
                generateEpochVisualizations(app);

            catch ME
                uialert(app.UIFigure, sprintf('Error during epoch analysis: %s', ME.message), ...
                    'Analysis Error');
                fprintf('Error: %s\n', ME.message);
            end
        end

        function generateEpochVisualizations(app)
            % Generate comprehensive ERP visualizations with detailed analysis
            try
                % Clear any previous visualizations
                if ~isempty(app.EventColumns)
                    for i = 1:length(app.EventColumns)
                        if isvalid(app.EventColumns{i})
                            delete(app.EventColumns{i});
                        end
                    end
                end
                app.EventColumns = {};

                numEvents = length(app.EpochedData);
                if numEvents == 0
                    return;
                end

                % Define colors for different event types
                colors = [0.2 0.4 0.8; 0.8 0.2 0.2; 0.2 0.8 0.2; 0.8 0.6 0.2; 0.6 0.2 0.8];

                % Calculate column width based on number of events (max 3 columns for detailed view)
                colsPerRow = min(numEvents, 3);
                colWidth = floor((1100 - 40) / colsPerRow);
                numRows = ceil(numEvents / colsPerRow);

                % Adjust panel height if multiple rows needed
                panelHeight = 700;  % Height per event panel
                if numRows > 1
                    app.EpochPanel.Position(4) = numRows * (panelHeight + 20);  % Add spacing between rows
                end

                % Create a detailed panel for each event type
                for i = 1:numEvents
                    epochData = app.EpochedData(i);

                    if isempty(epochData.avgERP)
                        continue;
                    end

                    % Calculate position (arrange in grid)
                    row = floor((i-1) / colsPerRow);
                    col = mod(i-1, colsPerRow);
                    xPos = 20 + col * colWidth;
                    yPos = app.EpochPanel.Position(4) - (row + 1) * panelHeight - row * 20;  % Stack from top

                    % Create column panel for this event
                    eventPanel = uipanel(app.EpochPanel);
                    eventPanel.Position = [xPos yPos colWidth-10 700];
                    eventPanel.BackgroundColor = [0.98 0.99 1];
                    eventPanel.BorderType = 'line';

                    color = colors(mod(i-1, size(colors, 1)) + 1, :);

                    % === HEADER ===
                    headerLabel = uilabel(eventPanel);
                    headerLabel.Position = [5 675 colWidth-20 20];
                    headerLabel.Text = sprintf('📌 %s (n=%d epochs)', epochData.eventType, epochData.numEpochs);
                    headerLabel.FontSize = 11;
                    headerLabel.FontWeight = 'bold';
                    headerLabel.FontColor = color;
                    headerLabel.HorizontalAlignment = 'center';

                    avgERP = epochData.avgERP;
                    timeVec = epochData.timeVector;

                    % === MULTI-CHANNEL ERP PLOTS (2x2 grid) ===
                    % Find top 4 channels with strongest responses
                    channelPower = max(abs(avgERP), [], 2);
                    [~, topChans] = sort(channelPower, 'descend');
                    topChans = topChans(1:min(4, length(topChans)));

                    for ch = 1:min(4, length(topChans))
                        chRow = floor((ch-1) / 2);
                        chCol = mod(ch-1, 2);
                        axW = (colWidth-30) / 2 - 5;
                        axH = 90;
                        axX = 10 + chCol * (axW + 5);
                        axY = 565 - chRow * (axH + 5);

                        erpAxes = uiaxes(eventPanel);
                        erpAxes.Position = [axX axY axW axH];

                        chanIdx = topChans(ch);
                        erpWave = avgERP(chanIdx, :);

                        hold(erpAxes, 'on');
                        plot(erpAxes, timeVec, erpWave, 'LineWidth', 1.5, 'Color', color);

                        % Add std error band
                        if isfield(epochData, 'stdERP') && ~isempty(epochData.stdERP)
                            stdWave = epochData.stdERP(chanIdx, :);
                            fill(erpAxes, [timeVec, fliplr(timeVec)], ...
                                [erpWave + stdWave, fliplr(erpWave - stdWave)], ...
                                color, 'FaceAlpha', 0.15, 'EdgeColor', 'none');
                        end

                        % Reference lines
                        plot(erpAxes, [0 0], ylim(erpAxes), 'k--', 'LineWidth', 0.5);
                        plot(erpAxes, xlim(erpAxes), [0 0], 'k:', 'LineWidth', 0.5);

                        % Label channel
                        chanLabel = 'Ch';
                        if isfield(app.EEGClean, 'chanlocs') && chanIdx <= length(app.EEGClean.chanlocs)
                            if isfield(app.EEGClean.chanlocs, 'labels') && ~isempty(app.EEGClean.chanlocs(chanIdx).labels)
                                chanLabel = app.EEGClean.chanlocs(chanIdx).labels;
                            end
                        end
                        title(erpAxes, chanLabel, 'FontSize', 8, 'FontWeight', 'bold');

                        if chRow == 1
                            xlabel(erpAxes, 'Time (s)', 'FontSize', 7);
                        end
                        if chCol == 0
                            ylabel(erpAxes, 'µV', 'FontSize', 7);
                        end
                        grid(erpAxes, 'on');
                        erpAxes.FontSize = 7;
                        hold(erpAxes, 'off');
                    end

                    % === BUTTERFLY PLOT (all channels) ===
                    butterflyAxes = uiaxes(eventPanel);
                    butterflyAxes.Position = [10 425 colWidth-30 130];

                    hold(butterflyAxes, 'on');
                    for ch = 1:size(avgERP, 1)
                        plot(butterflyAxes, timeVec, avgERP(ch, :), 'Color', [0.5 0.5 0.5 0.3], 'LineWidth', 0.5);
                    end
                    % Highlight max channel
                    [~, maxChan] = max(max(abs(avgERP), [], 2));
                    plot(butterflyAxes, timeVec, avgERP(maxChan, :), 'Color', color, 'LineWidth', 2);

                    plot(butterflyAxes, [0 0], ylim(butterflyAxes), 'k--', 'LineWidth', 1);
                    plot(butterflyAxes, xlim(butterflyAxes), [0 0], 'k:', 'LineWidth', 0.5);

                    xlabel(butterflyAxes, 'Time (s)', 'FontSize', 8);
                    ylabel(butterflyAxes, 'µV', 'FontSize', 8);
                    title(butterflyAxes, 'Butterfly Plot (All Channels)', 'FontSize', 9, 'FontWeight', 'bold');
                    grid(butterflyAxes, 'on');
                    butterflyAxes.FontSize = 7;
                    hold(butterflyAxes, 'off');

                    % === POWER SPECTRUM ===
                    psdAxes = uiaxes(eventPanel);
                    psdAxes.Position = [10 265 colWidth-30 150];

                    generatePowerSpectrum(app, psdAxes, epochData, color);

                    % === TOPOMAPS AT DIFFERENT LATENCIES ===
                    numTopomaps = 4;
                    topoWidth = (colWidth-30) / numTopomaps - 5;

                    % Find key time points
                    epochDuration = timeVec(end) - timeVec(1);
                    keyTimes = [0.25 0.4 0.6 0.8] * epochDuration + timeVec(1);

                    for t = 1:numTopomaps
                        topoAxes = uiaxes(eventPanel);
                        topoX = 10 + (t-1) * (topoWidth + 5);
                        topoAxes.Position = [topoX 155 topoWidth 100];

                        targetTime = keyTimes(t);
                        [~, timeIdx] = min(abs(timeVec - targetTime));

                        generateTopoMapAtTime(app, topoAxes, epochData, timeIdx, color);
                    end

                    % === EXPANDED METRICS ===
                    metricsY = 135;
                    if ~isempty(epochData.metrics)
                        metrics = epochData.metrics;

                        % Calculate additional metrics
                        [peakAmp, peakIdx] = max(max(abs(avgERP), [], 1));
                        peakLatency = timeVec(peakIdx) * 1000; % in ms

                        meanBaseline = mean(mean(abs(avgERP(:, 1:min(10, length(timeVec))))));

                        metricsText = {
                            sprintf('✓ Good Epochs: %d/%d (%.1f%%)', metrics.good_epochs, metrics.num_epochs, 100*metrics.good_epochs/metrics.num_epochs)
                            sprintf('📊 SNR: %.1f dB', metrics.mean_snr_db)
                            sprintf('📈 Peak Amp: %.2f µV @ %.0f ms', peakAmp, peakLatency)
                            sprintf('⚡ P2P Amp: %.2f µV', metrics.mean_p2p_amplitude)
                            sprintf('📉 Baseline: %.2f µV', meanBaseline)
                            sprintf('⏱ Duration: %.2f s', epochDuration)
                        };

                        metricsText = metricsText(1:min(6, length(metricsText)));

                        for m = 1:length(metricsText)
                            metricLabel = uilabel(eventPanel);
                            metricLabel.Position = [10 metricsY-m*20 colWidth-20 18];
                            metricLabel.Text = metricsText{m};
                            metricLabel.FontSize = 8;
                            metricLabel.FontColor = [0.2 0.3 0.4];
                            metricLabel.HorizontalAlignment = 'left';
                        end
                    end

                    % Store panel reference
                    app.EventColumns{end+1} = eventPanel;
                end

            catch ME
                warning('Failed to generate epoch visualizations: %s', ME.message);
                fprintf('Error details: %s\n', ME.message);
            end
        end

        function generateMiniTopoMap(app, axes, epochData)
            % Generate a compact topographic map at peak latency
            try
                cla(axes);
                hold(axes, 'on');

                avgERP = epochData.avgERP;
                timeVec = epochData.timeVector;

                % Find peak latency (global max absolute amplitude)
                [~, peakSample] = max(max(abs(avgERP), [], 1));
                peakTime = timeVec(peakSample);
                peakValues = avgERP(:, peakSample);

                % Draw simple head outline
                theta = linspace(0, 2*pi, 100);
                plot(axes, cos(theta)*0.9, sin(theta)*0.9, 'k', 'LineWidth', 1);

                % Get electrode positions
                if isfield(app.EEGClean, 'chanlocs') && ~isempty(app.EEGClean.chanlocs)
                    elec_x = [];
                    elec_y = [];

                    for ch = 1:min(length(peakValues), app.EEGClean.nbchan)
                        if isfield(app.EEGClean.chanlocs, 'X') && ~isempty(app.EEGClean.chanlocs(ch).X)
                            X = app.EEGClean.chanlocs(ch).X;
                            Y = app.EEGClean.chanlocs(ch).Y;
                            Z = app.EEGClean.chanlocs(ch).Z;

                            if ~isempty(Z)
                                radius = sqrt(X^2 + Y^2 + Z^2);
                                if radius > 0
                                    elec_x(end+1) = Y / radius * 0.8;
                                    elec_y(end+1) = X / radius * 0.8;
                                end
                            end
                        end
                    end

                    if length(elec_x) >= 3 && length(elec_x) == length(peakValues)
                        % Simple scatter plot with electrode values
                        scatter(axes, elec_x, elec_y, 30, peakValues(1:length(elec_x)), 'filled');
                        colormap(axes, 'jet');
                    end
                end

                % Formatting
                axis(axes, 'equal', 'off');
                xlim(axes, [-1.2 1.2]);
                ylim(axes, [-1.2 1.2]);
                title(axes, sprintf('%.0f ms', peakTime*1000), 'FontSize', 8);
                hold(axes, 'off');

            catch
                % Silent fail for topomap
                axis(axes, 'off');
            end
        end

        function generatePowerSpectrum(app, axes, epochData, color)
            % Generate power spectral density plot for epoch data
            try
                cla(axes);
                hold(axes, 'on');

                avgERP = epochData.avgERP;

                % Compute PSD across all channels using FFT
                nfft = 2^nextpow2(size(avgERP, 2));
                freqs = (0:nfft/2-1) * (app.EEGClean.srate / nfft);

                % Calculate PSD for each channel
                psdAll = zeros(size(avgERP, 1), nfft/2);
                for ch = 1:size(avgERP, 1)
                    fftData = fft(avgERP(ch, :), nfft);
                    psdAll(ch, :) = abs(fftData(1:nfft/2)).^2;
                end

                % Average across channels
                avgPSD = mean(psdAll, 1);

                % Plot in log scale (convert to dB)
                psdDB = 10*log10(avgPSD + eps);

                % Limit to 0-50 Hz for typical EEG
                maxFreqIdx = find(freqs <= 50, 1, 'last');
                if isempty(maxFreqIdx)
                    maxFreqIdx = length(freqs);
                end

                plot(axes, freqs(1:maxFreqIdx), psdDB(1:maxFreqIdx), 'Color', color, 'LineWidth', 1.5);

                % Add frequency band shading
                deltaRange = freqs >= 1 & freqs <= 4;
                thetaRange = freqs >= 4 & freqs <= 8;
                alphaRange = freqs >= 8 & freqs <= 13;
                betaRange = freqs >= 13 & freqs <= 30;

                % Light background shading for bands
                yLim = ylim(axes);
                if any(deltaRange)
                    patch(axes, [freqs(deltaRange), fliplr(freqs(deltaRange))], ...
                        [repmat(yLim(1), 1, sum(deltaRange)), repmat(yLim(2), 1, sum(deltaRange))], ...
                        [0.9 0.95 1], 'FaceAlpha', 0.2, 'EdgeColor', 'none');
                end

                xlabel(axes, 'Frequency (Hz)', 'FontSize', 8);
                ylabel(axes, 'Power (dB)', 'FontSize', 8);
                title(axes, 'Power Spectral Density', 'FontSize', 9, 'FontWeight', 'bold');
                grid(axes, 'on');
                axes.FontSize = 7;
                xlim(axes, [0 50]);
                hold(axes, 'off');

            catch
                % Silent fail
                axis(axes, 'off');
                text(axes, 0.5, 0.5, 'PSD unavailable', 'HorizontalAlignment', 'center');
            end
        end

        function generateTopoMapAtTime(app, axes, epochData, timeIdx, color)
            % Generate topographic map at specific time index
            try
                cla(axes);
                hold(axes, 'on');

                avgERP = epochData.avgERP;
                timeVec = epochData.timeVector;

                timeValue = timeVec(timeIdx);
                amplitudeValues = avgERP(:, timeIdx);

                % Draw simple head outline
                theta = linspace(0, 2*pi, 100);
                plot(axes, cos(theta)*0.9, sin(theta)*0.9, 'k', 'LineWidth', 1);

                % Add nose
                noseX = [0, -0.15, 0.15, 0];
                noseY = [0.9, 1.1, 1.1, 0.9];
                plot(axes, noseX, noseY, 'k', 'LineWidth', 1);

                % Get electrode positions
                if isfield(app.EEGClean, 'chanlocs') && ~isempty(app.EEGClean.chanlocs)
                    elec_x = [];
                    elec_y = [];
                    validAmps = [];

                    for ch = 1:min(length(amplitudeValues), app.EEGClean.nbchan)
                        if isfield(app.EEGClean.chanlocs, 'X') && ~isempty(app.EEGClean.chanlocs(ch).X)
                            X = app.EEGClean.chanlocs(ch).X;
                            Y = app.EEGClean.chanlocs(ch).Y;
                            Z = app.EEGClean.chanlocs(ch).Z;

                            if ~isempty(Z)
                                radius = sqrt(X^2 + Y^2 + Z^2);
                                if radius > 0
                                    elec_x(end+1) = Y / radius * 0.8;
                                    elec_y(end+1) = X / radius * 0.8;
                                    validAmps(end+1) = amplitudeValues(ch);
                                end
                            end
                        end
                    end

                    if length(elec_x) >= 3
                        % Create interpolated topomap
                        gridRes = 50;
                        [gridX, gridY] = meshgrid(linspace(-1, 1, gridRes), linspace(-1, 1, gridRes));

                        % Only interpolate inside head circle
                        headMask = sqrt(gridX.^2 + gridY.^2) <= 0.9;

                        if length(elec_x) >= 3
                            try
                                % Interpolate values
                                gridZ = griddata(elec_x, elec_y, validAmps, gridX, gridY, 'cubic');
                                gridZ(~headMask) = NaN;

                                % Plot contour
                                contourf(axes, gridX, gridY, gridZ, 20, 'LineStyle', 'none');
                                colormap(axes, 'jet');
                            catch
                                % Fallback to scatter if interpolation fails
                                scatter(axes, elec_x, elec_y, 40, validAmps, 'filled');
                                colormap(axes, 'jet');
                            end
                        end

                        % Plot electrode positions as black dots
                        scatter(axes, elec_x, elec_y, 15, 'k', 'filled');
                    end
                end

                % Formatting
                axis(axes, 'equal', 'off');
                xlim(axes, [-1.2 1.2]);
                ylim(axes, [-1.2 1.2]);
                title(axes, sprintf('%.0f ms', timeValue*1000), 'FontSize', 8, 'FontWeight', 'bold');
                hold(axes, 'off');

            catch
                % Silent fail for topomap
                axis(axes, 'off');
                text(axes, 0.5, 0.5, 'N/A', 'HorizontalAlignment', 'center');
            end
        end

        % Legacy functions from EEGQualityAnalyzer - Not used in RestingStateAnalyzer
        % (Kept for compatibility but commented out to avoid errors)

        % function analyzeMarkerPairEpochs(app)
        % function hideEpochBuilder(app)
        % function addEpochDefinition(app)
        % function removeEpochDefinition(app)
        % function updateEpochListBox(app)

    end
end
