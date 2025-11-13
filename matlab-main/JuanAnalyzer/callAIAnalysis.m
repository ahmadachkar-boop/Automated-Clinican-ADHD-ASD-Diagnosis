function aiAnalysis = callAIAnalysis(fieldStats, structure, provider, eventSamples)
% CALLAIANALYSIS - Call LLM API for intelligent field classification
%
% This function sends field metadata and sample events to an LLM (Claude or OpenAI)
% and receives intelligent recommendations for field classification and analysis.
%
% Inputs:
%   fieldStats - Struct with field statistics from discoverEventFields
%   structure - Detected event structure from detectEventStructure
%   provider - (Optional) 'claude' or 'openai' (default: 'claude')
%   eventSamples - (Optional) Cell array of sample event structures
%
% Output:
%   aiAnalysis - Struct containing AI recommendations:
%     .experimental_paradigm - Identified experimental design
%     .practice_trial_patterns - Detected practice trial patterns
%     .condition_recommendations - Which conditions to include/exclude
%     .grouping_fields - Recommended fields for grouping
%     .exclude_fields - Fields to exclude
%     .field_classifications - Detailed classifications
%     .confidence - AI's confidence score
%     .overall_assessment - Summary of analysis
%
% Environment Variables Required:
%   For Claude: ANTHROPIC_API_KEY
%   For OpenAI: OPENAI_API_KEY
%
% Example:
%   aiAnalysis = callAIAnalysis(fieldStats, structure, 'claude', eventSamples);

    if nargin < 3
        provider = 'claude';
    end
    if nargin < 4
        eventSamples = {};
    end

    fprintf('🤖 Calling %s API for intelligent analysis...\n', upper(provider));
    if ~isempty(eventSamples)
        fprintf('   Providing %d sample events for context...\n', length(eventSamples));
    end

    % Build the enhanced prompt with event samples
    prompt = buildFieldAnalysisPrompt(fieldStats, structure, eventSamples);

    % Call the appropriate API
    switch lower(provider)
        case 'claude'
            response = callClaudeAPI(prompt);
        case 'openai'
            response = callOpenAIAPI(prompt);
        otherwise
            error('Unknown AI provider: %s. Use "claude" or "openai"', provider);
    end

    % Parse the JSON response
    try
        % Strip markdown code fences if present (Claude sometimes wraps JSON in ```json...```)
        response = strtrim(response);
        if startsWith(response, '```')
            % Remove opening fence (```json or just ```)
            response = regexprep(response, '^```\w*\s*', '', 'once');
            % Remove closing fence
            response = regexprep(response, '\s*```$', '', 'once');
            response = strtrim(response);
        end

        aiAnalysis = jsondecode(response);
        fprintf('✓ AI analysis received (confidence: %.0f%%)\n', aiAnalysis.confidence * 100);
    catch ME
        warning('Failed to parse AI response as JSON. Error: %s', ME.message);
        fprintf('Raw response:\n%s\n', response);
        error('AI returned invalid JSON. Please check API response.');
    end

    % Validate required fields
    requiredFields = {'grouping_fields', 'exclude_fields', 'field_classifications'};
    for i = 1:length(requiredFields)
        if ~isfield(aiAnalysis, requiredFields{i})
            error('AI response missing required field: %s', requiredFields{i});
        end
    end

    % Display AI assessment
    if isfield(aiAnalysis, 'overall_assessment')
        fprintf('\nAI Assessment:\n');
        fprintf('  %s\n\n', aiAnalysis.overall_assessment);
    end
end


function response = callClaudeAPI(prompt)
    % Call Anthropic Claude API

    % Get API key from environment
    apiKey = getenv('ANTHROPIC_API_KEY');
    if isempty(apiKey)
        error(['ANTHROPIC_API_KEY not set. Please set it:\n', ...
               'setenv(''ANTHROPIC_API_KEY'', ''your-api-key-here'')']);
    end

    % API endpoint
    url = 'https://api.anthropic.com/v1/messages';

    % Prepare headers
    headers = [...
        matlab.net.http.HeaderField('x-api-key', apiKey), ...
        matlab.net.http.HeaderField('anthropic-version', '2023-06-01'), ...
        matlab.net.http.HeaderField('content-type', 'application/json')];

    % Prepare request body
    % CRITICAL: messages must be a cell array to encode as JSON array
    % Using struct() in a cell creates a struct, not a cell array!
    % Solution: Create the message struct separately, then wrap in cell
    message = struct('role', 'user', 'content', prompt);

    body = struct(...
        'model', 'claude-sonnet-4-20250514', ...  % Updated to Claude Sonnet 4
        'max_tokens', 4096, ...
        'messages', {{message}});  % Double braces to keep as cell array!

    % Make the request
    try
        options = weboptions(...
            'HeaderFields', headers, ...
            'ContentType', 'json', ...
            'Timeout', 30);

        % Pass struct directly - webwrite will encode it as JSON
        result = webwrite(url, body, options);

        % Extract content from response
        if isfield(result, 'content') && ~isempty(result.content)
            % Handle both cell array and struct array formats
            if iscell(result.content)
                response = result.content{1}.text;
            elseif isstruct(result.content)
                if isfield(result.content, 'text')
                    response = result.content(1).text;
                else
                    error('Unexpected content structure');
                end
            else
                error('Unexpected content type: %s', class(result.content));
            end
        else
            error('Unexpected API response structure');
        end

    catch ME
        if contains(ME.message, '401')
            error('Authentication failed. Check your ANTHROPIC_API_KEY.');
        elseif contains(ME.message, '429')
            error('Rate limit exceeded. Please wait and try again.');
        else
            error('API call failed: %s', ME.message);
        end
    end
end


function response = callOpenAIAPI(prompt)
    % Call OpenAI API (GPT-4)

    % Get API key from environment
    apiKey = getenv('OPENAI_API_KEY');
    if isempty(apiKey)
        error(['OPENAI_API_KEY not set. Please set it:\n', ...
               'setenv(''OPENAI_API_KEY'', ''your-api-key-here'')']);
    end

    % API endpoint
    url = 'https://api.openai.com/v1/chat/completions';

    % Prepare headers
    headers = [...
        matlab.net.http.HeaderField('Authorization', ['Bearer ', apiKey]), ...
        matlab.net.http.HeaderField('content-type', 'application/json')];

    % Prepare request body
    % CRITICAL: messages must be a cell array to encode as JSON array
    msg1 = struct('role', 'system', 'content', 'You are an expert EEG data analyst. Respond only with valid JSON.');
    msg2 = struct('role', 'user', 'content', prompt);

    body = struct(...
        'model', 'gpt-4-turbo-preview', ...
        'messages', {{msg1, msg2}}, ...  % Double braces to keep as cell array!
        'temperature', 0.3, ...
        'response_format', struct('type', 'json_object'));

    % Make the request
    try
        options = weboptions(...
            'HeaderFields', headers, ...
            'ContentType', 'json', ...
            'Timeout', 30);

        % Pass struct directly - webwrite will encode it as JSON
        result = webwrite(url, body, options);

        % Extract content from response
        if isfield(result, 'choices') && ~isempty(result.choices)
            response = result.choices{1}.message.content;
        else
            error('Unexpected API response structure');
        end

    catch ME
        if contains(ME.message, '401')
            error('Authentication failed. Check your OPENAI_API_KEY.');
        elseif contains(ME.message, '429')
            error('Rate limit exceeded. Please wait and try again.');
        else
            error('API call failed: %s', ME.message);
        end
    end
end
