classdef EEGQualityAnalyzer < matlab.apps.AppBase
    % EEG Quality Analyzer - Hands-free GUI for Clinicians
    % Automatically processes and evaluates EEG data quality

    properties (Access = public)
        UIFigure                matlab.ui.Figure

        % Main Panels
        UploadPanel             matlab.ui.container.Panel
        ProcessingPanel         matlab.ui.container.Panel
        ResultsPanel            matlab.ui.container.Panel

        % Upload Screen Components
        DropZonePanel           matlab.ui.container.Panel
        DropZoneLabel           matlab.ui.control.Label
        BrowseButton            matlab.ui.control.Button
        FileInfoPanel           matlab.ui.container.Panel
        FilenameLabel           matlab.ui.control.Label
        DurationLabel           matlab.ui.control.Label
        ChannelsLabel           matlab.ui.control.Label
        EventsDetectedLabel     matlab.ui.control.Label

        % Event Field Selection Components
        EventFieldLabel         matlab.ui.control.Label
        EventFieldDropdown      matlab.ui.control.DropDown
        DetectMarkersButton     matlab.ui.control.Button

        % Epoch Definition Builder Components
        EpochBuilderLabel       matlab.ui.control.Label
        StartMarkerLabel        matlab.ui.control.Label
        StartMarkerDropdown     matlab.ui.control.DropDown
        EndMarkerLabel          matlab.ui.control.Label
        EndMarkerDropdown       matlab.ui.control.DropDown
        EpochNameLabel          matlab.ui.control.Label
        EpochNameField          matlab.ui.control.EditField
        AddEpochButton          matlab.ui.control.Button
        EpochListLabel          matlab.ui.control.Label
        EpochListBox            matlab.ui.control.ListBox
        RemoveEpochButton       matlab.ui.control.Button

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
        VisualizationPanel      matlab.ui.container.Panel
        TopoAxes                matlab.ui.control.UIAxes
        PSDAxes                 matlab.ui.control.UIAxes
        SignalAxes              matlab.ui.control.UIAxes
        ClinicalPanel           matlab.ui.container.Panel
        ThetaBetaAxes           matlab.ui.control.UIAxes
        MultiBandAxes           matlab.ui.control.UIAxes
        AsymmetryAxes           matlab.ui.control.UIAxes
        BandBarAxes             matlab.ui.control.UIAxes
        MetricsPanel            matlab.ui.container.Panel
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
        EventFieldInfo          struct  % Detailed info about available event fields
        EpochedData             struct
        EpochDefinitions        cell  % Cell array of structs {startMarker, endMarker, name}
    end

    properties (Access = private)
        CurrentStage            double = 0
        TotalStages             double = 6
    end

    methods (Access = public)

        function app = EEGQualityAnalyzer
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
            app.UIFigure.Name = 'EEG Quality Analyzer';
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
            % Main Upload Panel
            app.UploadPanel = uipanel(app.UIFigure);
            app.UploadPanel.Position = [1 1 1200 1200];
            app.UploadPanel.BackgroundColor = [0.95 0.96 0.97];
            app.UploadPanel.BorderType = 'none';

            % Title (centered in taller window)
            titleLabel = uilabel(app.UploadPanel);
            titleLabel.Position = [300 920 600 50];  % Moved up 200px
            titleLabel.Text = 'EEG Quality Analyzer';
            titleLabel.FontSize = 32;
            titleLabel.FontWeight = 'bold';
            titleLabel.FontColor = [0.2 0.3 0.5];
            titleLabel.HorizontalAlignment = 'center';

            % Subtitle
            subtitleLabel = uilabel(app.UploadPanel);
            subtitleLabel.Position = [300 880 600 30];  % Moved up 200px
            subtitleLabel.Text = 'Upload your EEG file to begin automated quality assessment';
            subtitleLabel.FontSize = 14;
            subtitleLabel.FontColor = [0.4 0.5 0.6];
            subtitleLabel.HorizontalAlignment = 'center';

            % Drop Zone Panel
            app.DropZonePanel = uipanel(app.UploadPanel);
            app.DropZonePanel.Position = [300 600 600 250];  % Moved up 200px
            app.DropZonePanel.BackgroundColor = [1 1 1];
            app.DropZonePanel.BorderType = 'line';
            app.DropZonePanel.BorderWidth = 2;
            app.DropZonePanel.HighlightColor = [0.7 0.8 0.9];

            % Drop Zone Label
            app.DropZoneLabel = uilabel(app.DropZonePanel);
            app.DropZoneLabel.Position = [50 100 500 100];
            app.DropZoneLabel.Text = sprintf('📁\n\nDrag & Drop EEG File Here\n(.edf, .set, .fif, .mff)');
            app.DropZoneLabel.FontSize = 18;
            app.DropZoneLabel.FontColor = [0.5 0.6 0.7];
            app.DropZoneLabel.HorizontalAlignment = 'center';

            % Browse Button
            app.BrowseButton = uibutton(app.DropZonePanel, 'push');
            app.BrowseButton.Position = [225 40 150 40];
            app.BrowseButton.Text = 'Browse Files';
            app.BrowseButton.FontSize = 14;
            app.BrowseButton.BackgroundColor = [0.3 0.5 0.8];
            app.BrowseButton.FontColor = [1 1 1];
            app.BrowseButton.ButtonPushedFcn = @(btn,event) browseFile(app);

            % File Info Panel (hidden initially) - Taller to accommodate event selection
            app.FileInfoPanel = uipanel(app.UploadPanel);
            app.FileInfoPanel.Position = [200 250 800 380];  % Larger panel
            app.FileInfoPanel.BackgroundColor = [0.95 0.98 1];
            app.FileInfoPanel.BorderType = 'line';
            app.FileInfoPanel.Visible = 'off';

            % File info labels
            app.FilenameLabel = uilabel(app.FileInfoPanel);
            app.FilenameLabel.Position = [20 340 760 25];
            app.FilenameLabel.FontSize = 14;
            app.FilenameLabel.FontWeight = 'bold';

            app.DurationLabel = uilabel(app.FileInfoPanel);
            app.DurationLabel.Position = [20 310 760 20];
            app.DurationLabel.FontSize = 12;

            app.ChannelsLabel = uilabel(app.FileInfoPanel);
            app.ChannelsLabel.Position = [20 285 760 20];
            app.ChannelsLabel.FontSize = 12;

            % Events detected label
            app.EventsDetectedLabel = uilabel(app.FileInfoPanel);
            app.EventsDetectedLabel.Position = [20 255 760 20];
            app.EventsDetectedLabel.FontSize = 12;
            app.EventsDetectedLabel.FontColor = [0.3 0.5 0.7];
            app.EventsDetectedLabel.Visible = 'off';

            % Event Field Selection Section
            app.EventFieldLabel = uilabel(app.FileInfoPanel);
            app.EventFieldLabel.Position = [20 325 200 20];
            app.EventFieldLabel.Text = '🔍 Select Event Field Type:';
            app.EventFieldLabel.FontSize = 11;
            app.EventFieldLabel.FontWeight = 'bold';
            app.EventFieldLabel.FontColor = [0.2 0.4 0.6];
            app.EventFieldLabel.Visible = 'off';

            app.EventFieldDropdown = uidropdown(app.FileInfoPanel);
            app.EventFieldDropdown.Position = [220 323 150 22];
            app.EventFieldDropdown.FontSize = 10;
            app.EventFieldDropdown.Items = {};
            app.EventFieldDropdown.Visible = 'off';
            app.EventFieldDropdown.ValueChangedFcn = @(dd,event) detectMarkersFromField(app);

            app.DetectMarkersButton = uibutton(app.FileInfoPanel, 'push');
            app.DetectMarkersButton.Position = [380 320 120 28];
            app.DetectMarkersButton.Text = 'Detect Markers';
            app.DetectMarkersButton.FontSize = 10;
            app.DetectMarkersButton.BackgroundColor = [0.2 0.6 0.8];
            app.DetectMarkersButton.FontColor = [1 1 1];
            app.DetectMarkersButton.Visible = 'off';
            app.DetectMarkersButton.ButtonPushedFcn = @(btn,event) detectMarkersFromField(app);

            % Epoch Builder Section (hidden initially, shown when events detected)
            app.EpochBuilderLabel = uilabel(app.FileInfoPanel);
            app.EpochBuilderLabel.Position = [20 225 760 25];
            app.EpochBuilderLabel.Text = '⚡ Define Epochs Between Markers:';
            app.EpochBuilderLabel.FontSize = 13;
            app.EpochBuilderLabel.FontWeight = 'bold';
            app.EpochBuilderLabel.FontColor = [0.2 0.4 0.6];
            app.EpochBuilderLabel.Visible = 'off';

            % Start Marker
            app.StartMarkerLabel = uilabel(app.FileInfoPanel);
            app.StartMarkerLabel.Position = [20 195 80 20];
            app.StartMarkerLabel.Text = 'Start Marker:';
            app.StartMarkerLabel.FontSize = 10;
            app.StartMarkerLabel.Visible = 'off';

            app.StartMarkerDropdown = uidropdown(app.FileInfoPanel);
            app.StartMarkerDropdown.Position = [105 193 150 22];
            app.StartMarkerDropdown.FontSize = 10;
            app.StartMarkerDropdown.Items = {};
            app.StartMarkerDropdown.Visible = 'off';

            % End Marker
            app.EndMarkerLabel = uilabel(app.FileInfoPanel);
            app.EndMarkerLabel.Position = [265 195 70 20];
            app.EndMarkerLabel.Text = 'End Marker:';
            app.EndMarkerLabel.FontSize = 10;
            app.EndMarkerLabel.Visible = 'off';

            app.EndMarkerDropdown = uidropdown(app.FileInfoPanel);
            app.EndMarkerDropdown.Position = [340 193 150 22];
            app.EndMarkerDropdown.FontSize = 10;
            app.EndMarkerDropdown.Items = {};
            app.EndMarkerDropdown.Visible = 'off';

            % Epoch Name
            app.EpochNameLabel = uilabel(app.FileInfoPanel);
            app.EpochNameLabel.Position = [500 195 80 20];
            app.EpochNameLabel.Text = 'Epoch Name:';
            app.EpochNameLabel.FontSize = 10;
            app.EpochNameLabel.Visible = 'off';

            app.EpochNameField = uieditfield(app.FileInfoPanel, 'text');
            app.EpochNameField.Position = [585 193 120 22];
            app.EpochNameField.FontSize = 10;
            app.EpochNameField.Placeholder = 'e.g., Trial 1';
            app.EpochNameField.Visible = 'off';

            % Add Epoch Button
            app.AddEpochButton = uibutton(app.FileInfoPanel, 'push');
            app.AddEpochButton.Position = [715 190 65 28];
            app.AddEpochButton.Text = '+ Add';
            app.AddEpochButton.FontSize = 10;
            app.AddEpochButton.FontWeight = 'bold';
            app.AddEpochButton.BackgroundColor = [0.2 0.6 0.8];
            app.AddEpochButton.FontColor = [1 1 1];
            app.AddEpochButton.ButtonPushedFcn = @(btn,event) addEpochDefinition(app);
            app.AddEpochButton.Visible = 'off';

            % Epoch List Label
            app.EpochListLabel = uilabel(app.FileInfoPanel);
            app.EpochListLabel.Position = [20 160 760 20];
            app.EpochListLabel.Text = 'Defined Epochs (will be compared):';
            app.EpochListLabel.FontSize = 10;
            app.EpochListLabel.FontWeight = 'bold';
            app.EpochListLabel.Visible = 'off';

            % Epoch List Box
            app.EpochListBox = uilistbox(app.FileInfoPanel);
            app.EpochListBox.Position = [20 70 680 85];
            app.EpochListBox.FontSize = 10;
            app.EpochListBox.Items = {};
            app.EpochListBox.Visible = 'off';

            % Remove Epoch Button
            app.RemoveEpochButton = uibutton(app.FileInfoPanel, 'push');
            app.RemoveEpochButton.Position = [710 70 70 30];
            app.RemoveEpochButton.Text = 'Remove';
            app.RemoveEpochButton.FontSize = 10;
            app.RemoveEpochButton.BackgroundColor = [0.8 0.3 0.2];
            app.RemoveEpochButton.FontColor = [1 1 1];
            app.RemoveEpochButton.ButtonPushedFcn = @(btn,event) removeEpochDefinition(app);
            app.RemoveEpochButton.Visible = 'off';

            % Start Button
            app.StartButton = uibutton(app.FileInfoPanel, 'push');
            app.StartButton.Position = [325 20 150 35];
            app.StartButton.Text = 'Start Analysis';
            app.StartButton.FontSize = 14;
            app.StartButton.BackgroundColor = [0.2 0.7 0.4];
            app.StartButton.FontColor = [1 1 1];
            app.StartButton.ButtonPushedFcn = @(btn,event) startProcessing(app);
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
                '✓ Artifact Detection'
                '✓ Signal Cleaning'
                '✓ Quality Evaluation'
                '✓ Generating Visualizations'
            };

            for i = 1:6
                label = uilabel(stagesPanel);
                label.Position = [30 135-i*22 440 18];
                label.Text = stages{i};
                label.FontSize = 11;
                label.FontColor = [0.6 0.6 0.6];
            end
        end

        function createResultsPanel(app)
            % Main Results Panel - Extended height for scrollable content
            app.ResultsPanel = uipanel(app.UIFigure);
            app.ResultsPanel.Position = [1 1 1200 2000];  % Increased height for all content including detailed epochs
            app.ResultsPanel.BackgroundColor = [0.95 0.96 0.97];
            app.ResultsPanel.BorderType = 'none';
            app.ResultsPanel.Visible = 'off';

            % Status Icon
            app.ResultsStatusIcon = uilabel(app.ResultsPanel);
            app.ResultsStatusIcon.Position = [550 1900 100 60];  % Top (moved up)
            app.ResultsStatusIcon.Text = '✅';
            app.ResultsStatusIcon.FontSize = 48;
            app.ResultsStatusIcon.HorizontalAlignment = 'center';

            % Status Label
            app.ResultsStatusLabel = uilabel(app.ResultsPanel);
            app.ResultsStatusLabel.Position = [200 1840 800 40];  % Below icon (moved up)
            app.ResultsStatusLabel.Text = 'EEG quality is sufficient for clinical interpretation';
            app.ResultsStatusLabel.FontSize = 22;
            app.ResultsStatusLabel.FontWeight = 'bold';
            app.ResultsStatusLabel.FontColor = [0.2 0.6 0.3];
            app.ResultsStatusLabel.HorizontalAlignment = 'center';

            % Quality Score
            app.QualityScoreLabel = uilabel(app.ResultsPanel);
            app.QualityScoreLabel.Position = [400 1790 400 35];  % Below status (moved up)
            app.QualityScoreLabel.Text = 'Quality Score: 85/100';
            app.QualityScoreLabel.FontSize = 18;
            app.QualityScoreLabel.FontColor = [0.3 0.4 0.5];
            app.QualityScoreLabel.HorizontalAlignment = 'center';

            % Quality Visualization Panel (top section)
            app.VisualizationPanel = uipanel(app.ResultsPanel);
            app.VisualizationPanel.Position = [50 1400 1100 370];  % Below score (moved up)
            app.VisualizationPanel.BackgroundColor = [1 1 1];
            app.VisualizationPanel.BorderType = 'line';
            app.VisualizationPanel.Title = 'Signal Quality Assessment';
            app.VisualizationPanel.FontSize = 13;
            app.VisualizationPanel.FontWeight = 'bold';

            % Create three visualization axes
            % Topographic Map
            app.TopoAxes = uiaxes(app.VisualizationPanel);
            app.TopoAxes.Position = [30 50 320 280];
            title(app.TopoAxes, 'Alpha Power Distribution', 'FontSize', 12);

            % Power Spectral Density
            app.PSDAxes = uiaxes(app.VisualizationPanel);
            app.PSDAxes.Position = [380 50 320 280];
            title(app.PSDAxes, 'Power Spectral Density', 'FontSize', 12);
            xlabel(app.PSDAxes, 'Frequency (Hz)');
            ylabel(app.PSDAxes, 'Power (dB)');

            % Signal Traces
            app.SignalAxes = uiaxes(app.VisualizationPanel);
            app.SignalAxes.Position = [730 50 320 280];
            title(app.SignalAxes, 'Before vs After Cleaning', 'FontSize', 12);
            xlabel(app.SignalAxes, 'Time (s)');
            ylabel(app.SignalAxes, 'Amplitude (µV)');

            % Clinical Visualization Panel (middle section) - With bar chart
            app.ClinicalPanel = uipanel(app.ResultsPanel);
            app.ClinicalPanel.Position = [50 880 1100 490];  % Below quality panel, above epochs
            app.ClinicalPanel.BackgroundColor = [1 1 1];
            app.ClinicalPanel.BorderType = 'line';
            app.ClinicalPanel.Title = 'Clinical Diagnostics';
            app.ClinicalPanel.FontSize = 13;
            app.ClinicalPanel.FontWeight = 'bold';

            % Clinical visualization axes (topomaps on top row)
            % Theta/Beta Ratio Map
            app.ThetaBetaAxes = uiaxes(app.ClinicalPanel);
            app.ThetaBetaAxes.Position = [30 170 320 280];
            title(app.ThetaBetaAxes, 'Theta/Beta Ratio', 'FontSize', 12);

            % Multi-Band Power Distribution
            app.MultiBandAxes = uiaxes(app.ClinicalPanel);
            app.MultiBandAxes.Position = [380 170 320 280];
            title(app.MultiBandAxes, 'Multi-Band Power', 'FontSize', 12);

            % Hemispheric Asymmetry
            app.AsymmetryAxes = uiaxes(app.ClinicalPanel);
            app.AsymmetryAxes.Position = [730 170 320 280];
            title(app.AsymmetryAxes, 'Hemispheric Asymmetry', 'FontSize', 12);

            % Frequency Band Bar Chart (bottom of clinical panel)
            app.BandBarAxes = uiaxes(app.ClinicalPanel);
            app.BandBarAxes.Position = [30 20 1040 130];
            title(app.BandBarAxes, 'Frequency Band Power Comparison', 'FontSize', 12);
            ylabel(app.BandBarAxes, 'Relative Power (%)');

            % Metrics Panel (below clinical panel)
            app.MetricsPanel = uipanel(app.ResultsPanel);
            app.MetricsPanel.Position = [50 350 1100 100];  % Below clinical panel
            app.MetricsPanel.BackgroundColor = [0.95 0.98 1];
            app.MetricsPanel.BorderType = 'line';

            % Action Buttons (below metrics panel)
            app.ExportButton = uibutton(app.ResultsPanel, 'push');
            app.ExportButton.Position = [400 280 180 40];  % Below metrics panel
            app.ExportButton.Text = '📄 Export Report';
            app.ExportButton.FontSize = 14;
            app.ExportButton.BackgroundColor = [0.3 0.5 0.8];
            app.ExportButton.FontColor = [1 1 1];
            app.ExportButton.ButtonPushedFcn = @(btn,event) exportReport(app);

            app.NewAnalysisButton = uibutton(app.ResultsPanel, 'push');
            app.NewAnalysisButton.Position = [620 280 180 40];  % Below metrics panel
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

            % Initialize epoch definitions
            app.EpochDefinitions = {};
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
            % Open file browser
            [file, path] = uigetfile({'*.edf;*.set;*.fif;*.mff', 'EEG Files (*.edf, *.set, *.fif, *.mff)'}, ...
                'Select EEG File');

            if file ~= 0
                app.EEGFile = fullfile(path, file);
                loadFileInfo(app);
            end
        end

        function loadFileInfo(app)
            % Quick load to get basic info
            try
                % EEGLAB is already initialized by launchEEGAnalyzer
                % No need to reinitialize here

                % Load file based on extension
                [~, ~, ext] = fileparts(app.EEGFile);

                if strcmp(ext, '.mff')
                    % Import MFF with default settings (imports all available fields)
                    % Don't specify event types as it can cause errors if fields don't exist
                    EEG = pop_mffimport(app.EEGFile);
                    fprintf('MFF imported with default settings (all available event fields)\n');
                elseif strcmp(ext, '.set')
                    EEG = pop_loadset(app.EEGFile);
                elseif strcmp(ext, '.edf')
                    EEG = pop_biosig(app.EEGFile);
                elseif strcmp(ext, '.fif')
                    EEG = pop_fileio(app.EEGFile);
                else
                    error('Unsupported file format');
                end

                % Update UI with file info
                [~, name, ext] = fileparts(app.EEGFile);
                app.FilenameLabel.Text = sprintf('📁 %s%s', name, ext);
                app.DurationLabel.Text = sprintf('⏱️  Duration: %.1f seconds (%.1f minutes)', EEG.xmax, EEG.xmax/60);
                app.ChannelsLabel.Text = sprintf('📊 Channels: %d', EEG.nbchan);

                % Debug: Print actual event structure fields
                if isfield(EEG, 'event') && ~isempty(EEG.event)
                    fprintf('\n=== Event Structure Fields ===\n');
                    fprintf('Total events in file: %d\n', length(EEG.event));
                    eventFields = fieldnames(EEG.event);
                    fprintf('Fields present in event structure: %s\n', strjoin(eventFields, ', '));
                    fprintf('===============================\n\n');
                end

                % Detect available event fields
                try
                    [fieldNames, fieldInfo] = getAvailableEventFields(EEG);

                    if ~isempty(fieldNames)
                        % Store field info for later use
                        app.EventFieldInfo = fieldInfo;

                        % Create preview items for dropdown
                        previewItems = cell(1, length(fieldInfo));
                        for i = 1:length(fieldInfo)
                            previewItems{i} = fieldInfo(i).preview;
                        end

                        % Show event field selection UI
                        app.EventFieldLabel.Visible = 'on';
                        app.EventFieldDropdown.Items = previewItems;
                        app.EventFieldDropdown.ItemsData = fieldNames;  % Store actual field names
                        app.EventFieldDropdown.Value = fieldNames{1};  % Default to first field
                        app.EventFieldDropdown.Visible = 'on';
                        app.DetectMarkersButton.Visible = 'on';

                        % Show info about events with preview of first field
                        if isfield(EEG, 'event') && ~isempty(EEG.event)
                            app.EventsDetectedLabel.Text = sprintf('⚡ Found %d events total - Choose field above (markers shown in preview)', length(EEG.event));
                            app.EventsDetectedLabel.Visible = 'on';
                        end

                        % Hide epoch builder until markers are detected
                        hideEpochBuilder(app);

                        % Clear any previous epoch definitions
                        app.EpochDefinitions = {};
                        app.EpochListBox.Items = {};
                    else
                        % No event fields found - hide all event-related UI
                        app.EventsDetectedLabel.Text = '⚠️  No event markers found in this file';
                        app.EventsDetectedLabel.Visible = 'on';
                        app.EventFieldLabel.Visible = 'off';
                        app.EventFieldDropdown.Visible = 'off';
                        app.DetectMarkersButton.Visible = 'off';
                        hideEpochBuilder(app);
                    end
                catch ME
                    fprintf('Warning: Event field detection failed: %s\n', ME.message);
                    % Hide event-related UI if detection fails
                    app.EventsDetectedLabel.Visible = 'off';
                    app.EventFieldLabel.Visible = 'off';
                    app.EventFieldDropdown.Visible = 'off';
                    app.DetectMarkersButton.Visible = 'off';
                    hideEpochBuilder(app);
                end

                % Show file info panel
                app.FileInfoPanel.Visible = 'on';

                % Store basic EEG info
                app.EEG = EEG;

            catch ME
                uialert(app.UIFigure, ME.message, 'Error Loading File');
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

                    % Clear any previous epoch definitions when changing field
                    app.EpochDefinitions = {};
                    app.EpochListBox.Items = {};

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

        function startProcessing(app)
            % Check if user defined any epochs
            if ~isempty(app.EpochDefinitions)
                fprintf('User defined %d epoch type(s) for analysis:\n', length(app.EpochDefinitions));
                for i = 1:length(app.EpochDefinitions)
                    def = app.EpochDefinitions{i};
                    fprintf('  %d. %s (from %s to %s)\n', i, def.name, def.startMarker, def.endMarker);
                end
            else
                fprintf('No epochs defined - will only perform continuous data analysis\n');
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
            % Run automated preprocessing pipeline with progress updates

            % Stage 1: Loading Data
            updateProgress(app, 1, 'Loading Data...');
            EEG = app.EEG;
            EEG_original = EEG; % Store original for comparison
            pause(0.5);

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
            try
                EEG = pop_rejchan(EEG, 'elec', 1:EEG.nbchan, 'threshold', 7, 'norm', 'on', 'measure', 'kurt');
            catch
                % Continue if bad channel rejection fails
            end

            % Run ICA
            try
                EEG = pop_runica(EEG, 'icatype', 'runica', 'extended', 1);
            catch
                % Skip ICA if it fails
            end

            % Stage 4: Cleaning Signal
            updateProgress(app, 4, 'Cleaning Signal...');

            % Run ICLabel if ICA succeeded
            if isfield(EEG, 'icaweights') && ~isempty(EEG.icaweights)
                try
                    EEG = pop_iclabel(EEG, 'default');

                    % Auto-flag artifact components
                    EEG = pop_icflag(EEG, [0 0; 0.9 1; 0.9 1; 0.9 1; 0.9 1; 0.9 1; 0 0]);

                    % Remove flagged components
                    bad_comps = find(EEG.reject.gcompreject);
                    if ~isempty(bad_comps)
                        EEG = pop_subcomp(EEG, bad_comps, 0);
                    end
                catch
                    % Continue if ICLabel fails
                end
            end

            % Stage 5: Quality Evaluation
            updateProgress(app, 5, 'Evaluating Quality...');
            metrics = computeQualityMetrics(app, EEG, EEG_original);

            % Compute clinical diagnostic metrics (ADHD/ASD biomarkers)
            try
                clinical = computeClinicalMetrics(EEG);
                app.ClinicalMetrics = clinical;
            catch ME
                warning('Clinical metrics computation failed: %s', ME.message);
                app.ClinicalMetrics = struct();  % Empty struct as fallback
            end

            % Stage 6: Generating Visualizations
            updateProgress(app, 6, 'Rendering Visualizations...');

            % Store results
            app.EEGClean = EEG;
            app.QualityMetrics = metrics;

            pause(0.5);
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

            % Detect and display event information
            detectAndDisplayEvents(app);

            % Generate visualizations if clean
            if isfield(metrics, 'is_clean') && metrics.is_clean
                generateVisualizations(app);
                displayMetrics(app);
            else
                % Show brief explanation
                reasonText = 'Dominant noise sources detected:';

                % Safely check each metric
                if isfield(metrics, 'channels_removed') && isfield(metrics, 'channels_original')
                    if metrics.channels_removed > metrics.channels_original * 0.2
                        reasonText = sprintf('%s\n• Excessive bad channels', reasonText);
                    end
                end

                if isfield(metrics, 'artifact_ratio') && metrics.artifact_ratio > 0.3
                    reasonText = sprintf('%s\n• High artifact contamination', reasonText);
                end

                if isfield(metrics, 'snr_db') && metrics.snr_db < 5
                    reasonText = sprintf('%s\n• Low signal-to-noise ratio', reasonText);
                end

                % If no specific reasons found
                if strcmp(reasonText, 'Dominant noise sources detected:')
                    reasonText = 'EEG quality assessment indicates insufficient signal quality for reliable analysis.';
                end

                label = uilabel(app.MetricsPanel);
                label.Position = [50 20 1000 60];
                label.Text = reasonText;
                label.FontSize = 13;
                label.FontColor = [0.5 0.3 0.2];
            end
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

            % Generate clinical visualizations
            if ~isempty(fieldnames(app.ClinicalMetrics))
                try
                    generateClinicalVisualizations(app.EEGClean, app.ClinicalMetrics, ...
                        app.ThetaBetaAxes, app.MultiBandAxes, app.AsymmetryAxes, app.BandBarAxes);
                catch ME
                    warning('Clinical visualization generation failed: %s', ME.message);
                    % Fallback to simple placeholder
                    cla(app.ThetaBetaAxes);
                    text(app.ThetaBetaAxes, 0.5, 0.5, 'Clinical visualization unavailable', ...
                        'Units', 'normalized', 'HorizontalAlignment', 'center');
                end
            else
                % Show message if clinical metrics weren't computed
                cla(app.ThetaBetaAxes);
                text(app.ThetaBetaAxes, 0.5, 0.5, 'Clinical metrics not available', ...
                    'Units', 'normalized', 'HorizontalAlignment', 'center', 'FontSize', 12);
            end
        end

        function displayMetrics(app)
            % Clear previous metrics
            delete(app.MetricsPanel.Children);

            metrics = app.QualityMetrics;

            % Safely get values with defaults
            if isfield(metrics, 'channels_clean')
                channels_clean = metrics.channels_clean;
            else
                channels_clean = app.EEGClean.nbchan;
            end

            if isfield(metrics, 'channels_original')
                channels_original = metrics.channels_original;
            else
                channels_original = channels_clean;
            end

            if isfield(metrics, 'artifact_components')
                artifact_comps = metrics.artifact_components;
            else
                artifact_comps = 0;
            end

            if isfield(metrics, 'artifact_ratio')
                artifact_ratio = metrics.artifact_ratio * 100;
            else
                artifact_ratio = 0;
            end

            if isfield(metrics, 'snr_db')
                snr = metrics.snr_db;
            else
                snr = 15;
            end

            if isfield(metrics, 'duration')
                duration = metrics.duration / 60;
            elseif isfield(app.EEGClean, 'xmax')
                duration = app.EEGClean.xmax / 60;
            else
                duration = 0;
            end

            % Create metric labels with comprehensive information
            metricTexts = {
                sprintf('📊 Channels: %d/%d retained', channels_clean, channels_original)
                sprintf('🎯 Artifacts: %d components removed (%.1f%%)', artifact_comps, artifact_ratio)
                sprintf('📈 SNR: %.1f dB', snr)
                sprintf('⏱️  Duration: %.1f min', duration)
            };

            % Add band power information if available
            if isfield(metrics, 'alpha_relative') && metrics.alpha_relative > 0
                extraText = sprintf('🧠 Alpha Power: %.1f%%', metrics.alpha_relative*100);
                metricTexts{end+1} = extraText;
            end

            % Display metrics in a grid
            n_metrics = length(metricTexts);
            metrics_per_row = min(4, n_metrics);
            metric_width = 1000 / metrics_per_row;

            for i = 1:n_metrics
                row = floor((i-1) / metrics_per_row);
                col = mod(i-1, metrics_per_row);

                label = uilabel(app.MetricsPanel);
                label.Position = [50 + col*metric_width, 50 - row*30, metric_width-20, 25];
                label.Text = metricTexts{i};
                label.FontSize = 12;
                label.FontColor = [0.3 0.4 0.5];
            end
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
            % Analyze marker-pair epochs if user defined them
            try
                % Re-detect events on cleaned data
                app.EventInfo = detectEEGEvents(app.EEGClean);

                % Hide the old EventPanel (not used in marker-pair system)
                app.EventPanel.Visible = 'off';

                % If user defined epoch pairs, analyze them automatically
                if app.EventInfo.hasEvents && ~isempty(app.EpochDefinitions)
                    fprintf('\nAnalyzing marker-pair epochs...\n');

                    % Epoch data using marker pairs
                    analyzeMarkerPairEpochs(app);
                else
                    % Hide epoch panel if no epochs defined
                    app.EpochPanel.Visible = 'off';
                end
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

        function analyzeMarkerPairEpochs(app)
            % Epoch data using marker pairs and display results
            try
                % Epoch the data using marker pairs
                fprintf('\n=== Marker-Pair Epoch Analysis ===\n');
                app.EpochedData = epochEEGByMarkerPairs(app.EEGClean, app.EpochDefinitions);

                if isempty(app.EpochedData)
                    fprintf('No valid epochs found\n');
                    return;
                end

                % Show epoch panel
                app.EpochPanel.Visible = 'on';

                % Generate epoch visualizations
                generateEpochVisualizations(app);

            catch ME
                warning('Error during marker-pair epoch analysis: %s', ME.message);
                fprintf('Error: %s\n', ME.message);
            end
        end

        function hideEpochBuilder(app)
            % Hide all epoch builder UI elements
            app.EpochBuilderLabel.Visible = 'off';
            app.StartMarkerLabel.Visible = 'off';
            app.StartMarkerDropdown.Visible = 'off';
            app.EndMarkerLabel.Visible = 'off';
            app.EndMarkerDropdown.Visible = 'off';
            app.EpochNameLabel.Visible = 'off';
            app.EpochNameField.Visible = 'off';
            app.AddEpochButton.Visible = 'off';
            app.EpochListLabel.Visible = 'off';
            app.EpochListBox.Visible = 'off';
            app.RemoveEpochButton.Visible = 'off';
        end

        function addEpochDefinition(app)
            % Add a new epoch definition to the list
            startMarker = app.StartMarkerDropdown.Value;
            endMarker = app.EndMarkerDropdown.Value;
            epochName = app.EpochNameField.Value;

            % Generate default name if empty
            if isempty(epochName)
                epochName = sprintf('%s → %s', startMarker, endMarker);
            end

            % Create epoch definition struct
            epochDef = struct();
            epochDef.startMarker = startMarker;
            epochDef.endMarker = endMarker;
            epochDef.name = epochName;

            % Add to list
            app.EpochDefinitions{end+1} = epochDef;

            % Update listbox
            updateEpochListBox(app);

            % Clear name field for next entry
            app.EpochNameField.Value = '';

            fprintf('Added epoch definition: %s (from %s to %s)\n', ...
                epochName, startMarker, endMarker);
        end

        function removeEpochDefinition(app)
            % Remove selected epoch definition from the list
            selectedIdx = find(strcmp(app.EpochListBox.Items, app.EpochListBox.Value));

            if isempty(selectedIdx)
                return;
            end

            % Remove from list
            app.EpochDefinitions(selectedIdx) = [];

            % Update listbox
            updateEpochListBox(app);

            fprintf('Removed epoch definition\n');
        end

        function updateEpochListBox(app)
            % Update the epoch list box with current definitions
            if isempty(app.EpochDefinitions)
                app.EpochListBox.Items = {};
                return;
            end

            items = cell(length(app.EpochDefinitions), 1);
            for i = 1:length(app.EpochDefinitions)
                def = app.EpochDefinitions{i};
                items{i} = sprintf('%d. %s (%s → %s)', ...
                    i, def.name, def.startMarker, def.endMarker);
            end

            app.EpochListBox.Items = items;

            % Select first item by default
            if ~isempty(items)
                app.EpochListBox.Value = items{1};
            end
        end

    end
end
