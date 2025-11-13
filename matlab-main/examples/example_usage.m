%% EEG QUALITY ANALYZER - EXAMPLE USAGE
% This script demonstrates how to use the EEG Quality Analyzer
% for automated EEG quality assessment

%% ========================================================================
%% METHOD 1: GRAPHICAL USER INTERFACE (RECOMMENDED FOR CLINICIANS)
%% ========================================================================

% Simply launch the GUI application
% The GUI provides a complete hands-free workflow:
% 1. Upload file (drag & drop or browse)
% 2. Automatic processing with progress display
% 3. Quality assessment and visualizations
% 4. PDF export capability

fprintf('========================================\n');
fprintf('LAUNCHING EEG QUALITY ANALYZER GUI\n');
fprintf('========================================\n\n');

% Launch the application
launchEEGAnalyzer();

fprintf('The GUI has been launched!\n\n');
fprintf('Follow these steps:\n');
fprintf('1. Click "Browse Files" or drag & drop your EEG file\n');
fprintf('2. Review file information (duration, channels)\n');
fprintf('3. Click "Start Analysis" to begin automated processing\n');
fprintf('4. Wait for processing (5-20 minutes depending on file size)\n');
fprintf('5. Review quality score and visualizations\n');
fprintf('6. Optionally export PDF report\n\n');

%% ========================================================================
%% METHOD 2: PROGRAMMATIC USAGE (FOR BATCH PROCESSING)
%% ========================================================================

% For researchers who need to process multiple files automatically,
% you can use the underlying functions directly

fprintf('========================================\n');
fprintf('BATCH PROCESSING EXAMPLE\n');
fprintf('========================================\n\n');

% Example: Process multiple EEG files in a directory
% (Uncomment and modify paths as needed)

%{
% Initialize EEGLAB
eeglab nogui;

% Define input and output directories
input_dir = '/path/to/eeg/files/';
output_dir = '/path/to/results/';

% Get list of EEG files
eeg_files = dir(fullfile(input_dir, '*.set')); % or *.edf, *.mff, etc.

% Initialize results table
results = table();

fprintf('Found %d EEG files to process\n\n', length(eeg_files));

% Process each file
for i = 1:length(eeg_files)
    fprintf('Processing file %d/%d: %s\n', i, length(eeg_files), eeg_files(i).name);

    try
        % Load EEG
        EEG_original = pop_loadset('filename', eeg_files(i).name, ...
                                   'filepath', input_dir);

        % Preprocessing pipeline (simplified)
        EEG = EEG_original;

        % Resample
        EEG = pop_resample(EEG, 250);

        % Filter
        EEG = pop_eegfiltnew(EEG, 'locutoff', 0.5, 'plotfreqz', 0);
        EEG = pop_eegfiltnew(EEG, 'hicutoff', 50, 'plotfreqz', 0);
        EEG = pop_eegfiltnew(EEG, 'locutoff', 58, 'hicutoff', 62, ...
                            'revfilt', 1, 'plotfreqz', 0);

        % Re-reference
        EEG = pop_reref(EEG, []);

        % Bad channel rejection
        try
            EEG = pop_rejchan(EEG, 'elec', 1:EEG.nbchan, ...
                            'threshold', 7, 'norm', 'on', 'measure', 'kurt');
        catch
            warning('Bad channel rejection failed for %s', eeg_files(i).name);
        end

        % ICA
        fprintf('  Running ICA...\n');
        EEG = pop_runica(EEG, 'icatype', 'runica', 'extended', 1);

        % ICLabel
        fprintf('  Classifying components...\n');
        EEG = pop_iclabel(EEG, 'default');

        % Auto-flag artifacts
        EEG = pop_icflag(EEG, [0 0; 0.9 1; 0.9 1; 0.9 1; 0.9 1; 0.9 1; 0 0]);

        % Remove artifacts
        bad_comps = find(EEG.reject.gcompreject);
        if ~isempty(bad_comps)
            EEG = pop_subcomp(EEG, bad_comps, 0);
        end

        % Compute quality metrics
        fprintf('  Computing quality metrics...\n');
        metrics = computeAdvancedQualityMetrics(EEG_original, EEG);

        % Store results
        results = [results; struct2table(struct(...
            'Filename', eeg_files(i).name, ...
            'QualityScore', metrics.total_score, ...
            'QualityLevel', metrics.quality_level, ...
            'IsClean', metrics.is_clean, ...
            'ChannelsRetained', metrics.channels_clean, ...
            'ArtifactComponents', metrics.artifact_components, ...
            'SNR_dB', metrics.snr_db, ...
            'Duration_min', metrics.duration/60))];

        % Save cleaned data
        [~, name, ~] = fileparts(eeg_files(i).name);
        output_file = fullfile(output_dir, [name '_cleaned.set']);
        pop_saveset(EEG, 'filename', [name '_cleaned.set'], ...
                   'filepath', output_dir);

        fprintf('  ✓ Complete! Quality Score: %d/100 (%s)\n\n', ...
                metrics.total_score, metrics.quality_level);

    catch ME
        fprintf('  ✗ Error processing %s: %s\n\n', ...
                eeg_files(i).name, ME.message);
        continue;
    end
end

% Save results summary
writetable(results, fullfile(output_dir, 'quality_assessment_summary.csv'));

fprintf('========================================\n');
fprintf('BATCH PROCESSING COMPLETE\n');
fprintf('========================================\n\n');
fprintf('Results saved to: %s\n', ...
        fullfile(output_dir, 'quality_assessment_summary.csv'));
%}

%% ========================================================================
%% METHOD 3: STANDALONE QUALITY ASSESSMENT (NO GUI)
%% ========================================================================

% If you already have preprocessed EEG data and just want quality metrics

fprintf('========================================\n');
fprintf('STANDALONE QUALITY ASSESSMENT\n');
fprintf('========================================\n\n');

% Example usage (uncomment and modify as needed)
%{
% Load your preprocessed EEG data
EEG_original = pop_loadset('filename', 'my_eeg_original.set');
EEG_clean = pop_loadset('filename', 'my_eeg_cleaned.set');

% Compute quality metrics
metrics = computeAdvancedQualityMetrics(EEG_original, EEG_clean);

% Display results
fprintf('Quality Assessment Results:\n');
fprintf('---------------------------\n');
fprintf('Overall Score: %d/100 (%s)\n', metrics.total_score, metrics.quality_level);
fprintf('Clean Data: %s\n', mat2str(metrics.is_clean));
fprintf('\nDetailed Metrics:\n');
fprintf('  Channel Score: %.1f/25\n', metrics.channel_score);
fprintf('  Artifact Score: %.1f/30\n', metrics.artifact_score);
fprintf('  Signal Score: %.1f/25\n', metrics.signal_score);
fprintf('  Spectral Score: %.1f/20\n', metrics.spectral_score);
fprintf('\nChannel Information:\n');
fprintf('  Original: %d channels\n', metrics.channels_original);
fprintf('  Retained: %d channels (%.1f%%)\n', metrics.channels_clean, ...
        metrics.channel_retention*100);
fprintf('\nArtifact Information:\n');
fprintf('  Total components: %d\n', metrics.total_components);
fprintf('  Artifact components: %d (%.1f%%)\n', metrics.artifact_components, ...
        metrics.artifact_ratio*100);
fprintf('  - Eye artifacts: %d\n', metrics.eye_artifacts);
fprintf('  - Muscle artifacts: %d\n', metrics.muscle_artifacts);
fprintf('  - Heart artifacts: %d\n', metrics.heart_artifacts);
fprintf('  - Line noise: %d\n', metrics.line_noise);
fprintf('\nSignal Quality:\n');
fprintf('  SNR: %.1f dB\n', metrics.snr_db);
fprintf('  Kurtosis: %.2f\n', metrics.kurtosis);
fprintf('\nSpectral Features:\n');
fprintf('  Delta power: %.1f%% (0.5-4 Hz)\n', metrics.delta_relative*100);
fprintf('  Theta power: %.1f%% (4-8 Hz)\n', metrics.theta_relative*100);
fprintf('  Alpha power: %.1f%% (8-13 Hz)\n', metrics.alpha_relative*100);
fprintf('  Beta power: %.1f%% (13-30 Hz)\n', metrics.beta_relative*100);
fprintf('  Gamma power: %.1f%% (30-50 Hz)\n', metrics.gamma_relative*100);

% Display noise sources if data is poor quality
if ~metrics.is_clean && ~isempty(metrics.noise_sources)
    fprintf('\nDominant Noise Sources:\n');
    for j = 1:length(metrics.noise_sources)
        fprintf('  - %s\n', metrics.noise_sources{j});
    end
end

% Display recommendations
if ~isempty(metrics.recommendations)
    fprintf('\nRecommendations:\n');
    for j = 1:length(metrics.recommendations)
        fprintf('  %d. %s\n', j, metrics.recommendations{j});
    end
end
%}

%% ========================================================================
%% METHOD 4: CUSTOM VISUALIZATION
%% ========================================================================

% Create custom visualizations using the provided function

fprintf('========================================\n');
fprintf('CUSTOM VISUALIZATION EXAMPLE\n');
fprintf('========================================\n\n');

%{
% Load your data and metrics
EEG_clean = pop_loadset('filename', 'my_eeg_cleaned.set');
metrics = computeAdvancedQualityMetrics(EEG_original, EEG_clean);

% Create figure for visualizations
fig = figure('Position', [100 100 1400 500]);

% Create axes
ax1 = subplot(1, 3, 1);
ax2 = subplot(1, 3, 2);
ax3 = subplot(1, 3, 3);

% Generate visualizations
generateEEGVisualizations(EEG_clean, metrics, ax1, ax2, ax3);

% Add overall title
sgtitle(sprintf('EEG Quality Assessment - Score: %d/100 (%s)', ...
               metrics.total_score, metrics.quality_level), ...
        'FontSize', 16, 'FontWeight', 'bold');

% Save figure
saveas(fig, 'eeg_quality_report.png');
fprintf('Visualization saved to: eeg_quality_report.png\n');
%}

%% ========================================================================
%% ADDITIONAL TIPS
%% ========================================================================

fprintf('========================================\n');
fprintf('ADDITIONAL TIPS\n');
fprintf('========================================\n\n');

fprintf('1. File Formats:\n');
fprintf('   - .set files: Use pop_loadset()\n');
fprintf('   - .edf files: Use pop_biosig()\n');
fprintf('   - .mff files: Use pop_mffimport()\n');
fprintf('   - .fif files: Use pop_fileio()\n\n');

fprintf('2. Processing Time:\n');
fprintf('   - Small files (<5 min, <32 chan): 5-10 minutes\n');
fprintf('   - Medium files (5-10 min, 32-64 chan): 10-20 minutes\n');
fprintf('   - Large files (>10 min, >64 chan): 20-40 minutes\n\n');

fprintf('3. Quality Thresholds:\n');
fprintf('   - Excellent (75-100): Reliable for all analyses\n');
fprintf('   - Good (60-74): Acceptable for clinical use\n');
fprintf('   - Fair (45-59): Use with caution\n');
fprintf('   - Poor (0-44): Consider re-recording\n\n');

fprintf('4. Common Issues:\n');
fprintf('   - Low score due to channel loss → Check impedances\n');
fprintf('   - High artifact ratio → Instruct patient to relax\n');
fprintf('   - Low SNR → Check equipment and electrode contact\n\n');

fprintf('5. For Research Studies:\n');
fprintf('   - Process all participants with same parameters\n');
fprintf('   - Document quality scores for each recording\n');
fprintf('   - Consider excluding participants with scores <60\n');
fprintf('   - Report mean quality score in methods section\n\n');

fprintf('========================================\n');
fprintf('For more information, see README.md\n');
fprintf('========================================\n');
