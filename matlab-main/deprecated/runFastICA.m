function EEG = runFastICA(EEG, varargin)
    % RUNFASTICA - Wrapper to run FastICA on EEGLAB EEG data
    %
    % Usage:
    %   EEG = runFastICA(EEG)
    %   EEG = runFastICA(EEG, 'param', value, ...)
    %
    % Inputs:
    %   EEG - EEGLAB EEG structure
    %
    % Optional Parameters:
    %   'approach'    - 'symm' (symmetric/parallel) or 'defl' (deflation/sequential)
    %                   Default: 'symm'
    %   'numOfIC'     - Number of independent components (default: auto = number of channels)
    %   'g'           - Nonlinearity: 'pow3', 'tanh', 'gauss', 'skew'
    %                   Default: 'tanh'
    %   'finetune'    - Fine-tuning scheme: 'pow3', 'tanh', 'gauss', 'skew', 'off'
    %                   Default: 'tanh'
    %   'stabilization' - 'on' or 'off' (default: 'on')
    %   'maxNumIterations' - Maximum iterations (default: 1000)
    %   'maxFinetune' - Maximum fine-tuning iterations (default: 100)
    %   'epsilon'     - Convergence threshold (default: 0.0001)
    %   'verbose'     - 'on' or 'off' (default: 'off')
    %
    % Outputs:
    %   EEG - EEGLAB structure with ICA weights added
    %
    % Example:
    %   EEG = runFastICA(EEG);
    %   EEG = runFastICA(EEG, 'approach', 'symm', 'g', 'tanh', 'verbose', 'on');
    %
    % Note: This function requires FastICA to be in the MATLAB path
    % Download from: https://research.ics.aalto.fi/ica/fastica/

    %% Parse inputs
    p = inputParser;
    addRequired(p, 'EEG', @isstruct);
    addParameter(p, 'approach', 'symm', @(x) ismember(x, {'symm', 'defl'}));
    addParameter(p, 'numOfIC', [], @isnumeric);
    addParameter(p, 'g', 'tanh', @(x) ismember(x, {'pow3', 'tanh', 'gauss', 'skew'}));
    addParameter(p, 'finetune', 'tanh', @(x) ismember(x, {'pow3', 'tanh', 'gauss', 'skew', 'off'}));
    addParameter(p, 'stabilization', 'on', @(x) ismember(x, {'on', 'off'}));
    addParameter(p, 'maxNumIterations', 1000, @isnumeric);
    addParameter(p, 'maxFinetune', 100, @isnumeric);
    addParameter(p, 'epsilon', 0.0001, @isnumeric);
    addParameter(p, 'verbose', 'off', @(x) ismember(x, {'on', 'off'}));

    parse(p, EEG, varargin{:});
    params = p.Results;

    %% Check if FastICA is available
    if ~exist('fastica', 'file')
        error(['FastICA not found in MATLAB path!\n', ...
               'Please download from: https://research.ics.aalto.fi/ica/fastica/\n', ...
               'Or specify the path where you downloaded it.']);
    end

    %% Prepare data
    % Get EEG data matrix (channels x timepoints)
    data = double(EEG.data(:, :));

    % Handle epoched data by reshaping to 2D
    if ndims(data) == 3
        [nchans, npnts, ntrials] = size(data);
        data = reshape(data, nchans, npnts * ntrials);
    else
        nchans = size(data, 1);
    end

    % Set number of components
    if isempty(params.numOfIC)
        numOfIC = nchans;
    else
        numOfIC = min(params.numOfIC, nchans);
    end

    %% Check if dataset is too large for efficient FastICA
    % For high-density EEG (>64 channels), use runica which is more robust
    if nchans > 64
        if strcmp(params.verbose, 'on')
            fprintf('High-density EEG detected (%d channels)\n', nchans);
            fprintf('Using runica for better convergence with large datasets...\n');
        end
        % Fall back to runica immediately for large datasets
        EEG = pop_runica(EEG, 'icatype', 'runica', 'extended', 1);
        return;
    end

    if strcmp(params.verbose, 'on')
        fprintf('Running FastICA on %d channels, extracting %d components...\n', nchans, numOfIC);
    end

    %% Run FastICA
    try
        [icasig, A, W] = fastica(data, ...
            'approach', params.approach, ...
            'numOfIC', numOfIC, ...
            'g', params.g, ...
            'finetune', params.finetune, ...
            'stabilization', params.stabilization, ...
            'maxNumIterations', params.maxNumIterations, ...
            'maxFinetune', params.maxFinetune, ...
            'epsilon', params.epsilon, ...
            'verbose', params.verbose);

        if isempty(W) || isempty(A)
            error('FastICA failed to converge or returned empty results');
        end

        %% Store results in EEGLAB format
        % W is the unmixing matrix (components x channels)
        % A is the mixing matrix (channels x components)
        EEG.icaweights = W;
        EEG.icasphere = eye(nchans);  % FastICA already does whitening internally
        EEG.icawinv = A;
        EEG.icaact = [];  % Will be computed when needed

        % Store algorithm info
        EEG.etc.icainfo.algorithm = 'FastICA';
        EEG.etc.icainfo.approach = params.approach;
        EEG.etc.icainfo.nonlinearity = params.g;
        EEG.etc.icainfo.numOfIC = numOfIC;

        if strcmp(params.verbose, 'on')
            fprintf('✓ FastICA completed successfully\n');
            fprintf('  Extracted %d independent components\n', size(W, 1));
        end

    catch ME
        warning('FastICA failed: %s\nFalling back to runica...', ME.message);
        % Fallback to EEGLAB's runica
        EEG = pop_runica(EEG, 'icatype', 'runica', 'extended', 1);
    end
end
