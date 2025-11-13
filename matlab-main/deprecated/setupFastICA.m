function setupFastICA()
    % SETUPFASTICA - Download and install FastICA for MATLAB
    %
    % This function downloads FastICA from the official Aalto University source
    % and adds it to your MATLAB path.
    %
    % Usage:
    %   setupFastICA()
    %
    % After running this function, FastICA will be ready to use.

    fprintf('\n========================================\n');
    fprintf('  FastICA Setup for MATLAB\n');
    fprintf('========================================\n\n');

    % Check if FastICA is already installed
    if exist('fastica', 'file')
        fprintf('✓ FastICA is already installed!\n');
        fasticaPath = which('fastica');
        fprintf('  Location: %s\n\n', fasticaPath);

        response = input('FastICA is already installed. Reinstall? (y/n): ', 's');
        if ~strcmpi(response, 'y')
            fprintf('Setup cancelled.\n');
            return;
        end
    end

    % Define installation directory
    matlabDir = pwd;
    fasticaDir = fullfile(matlabDir, 'FastICA');

    % Check if directory already exists
    if exist(fasticaDir, 'dir')
        fprintf('FastICA directory already exists at: %s\n', fasticaDir);
        response = input('Remove and reinstall? (y/n): ', 's');
        if strcmpi(response, 'y')
            rmdir(fasticaDir, 's');
        else
            fprintf('Setup cancelled.\n');
            return;
        end
    end

    fprintf('FastICA will be installed to: %s\n\n', fasticaDir);

    % Download FastICA
    fprintf('Downloading FastICA from Aalto University...\n');
    url = 'https://research.ics.aalto.fi/ica/fastica/code/dlcode.shtml';

    fprintf('\n⚠️  MANUAL DOWNLOAD REQUIRED ⚠️\n');
    fprintf('=================================\n');
    fprintf('Please follow these steps:\n\n');
    fprintf('1. Visit: %s\n', url);
    fprintf('2. Download FastICA package for MATLAB\n');
    fprintf('3. Extract the ZIP file\n');
    fprintf('4. Move the extracted folder to: %s\n', matlabDir);
    fprintf('5. Rename the folder to "FastICA"\n');
    fprintf('6. Run this function again\n\n');

    fprintf('Alternative - If you already downloaded FastICA:\n');
    fprintf('Enter the path where you extracted FastICA,\n');
    fprintf('or press Enter to exit: ');

    userPath = input('', 's');

    if isempty(userPath)
        fprintf('\nSetup cancelled. Please download FastICA and run this function again.\n');
        return;
    end

    % Validate user path
    if exist(userPath, 'dir')
        % Check if fastica.m exists in that directory or subdirectories
        fasticaFile = '';
        if exist(fullfile(userPath, 'fastica.m'), 'file')
            fasticaFile = userPath;
        else
            % Search in subdirectories
            searchPath = dir(fullfile(userPath, '**/fastica.m'));
            if ~isempty(searchPath)
                fasticaFile = searchPath(1).folder;
            end
        end

        if ~isempty(fasticaFile)
            fprintf('\n✓ Found fastica.m at: %s\n', fasticaFile);
            addpath(genpath(fasticaFile));
            savepath;
            fprintf('✓ FastICA added to MATLAB path\n');
            fprintf('✓ Setup complete!\n\n');

            % Test installation
            fprintf('Testing installation...\n');
            try
                testData = randn(10, 1000);
                [~, ~, ~] = fastica(testData, 'verbose', 'off');
                fprintf('✓ FastICA test successful!\n\n');
                fprintf('You can now use runFastICA() with your EEG data.\n');
            catch ME
                warning('FastICA test failed: %s', ME.message);
            end
        else
            fprintf('\n❌ Could not find fastica.m in the specified directory.\n');
            fprintf('Please ensure you have extracted the complete FastICA package.\n');
        end
    else
        fprintf('\n❌ Directory not found: %s\n', userPath);
        fprintf('Please check the path and try again.\n');
    end

    fprintf('\n========================================\n\n');
end
