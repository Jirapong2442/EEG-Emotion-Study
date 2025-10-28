function [bad_channels, reject_segments] = pp_vars(index)

    % XX index = char(lower(index));

    switch index
        case 'G2P_1'
            bad_channels = {1};
            reject_segments = [1];
        otherwise
            fprintf('')
    end

    fprintf('## pp_vars.m loaded\n');
    % TODO: Add a detection thing, if no vars is detected, add it here, and
    % also see how I should include this thing
end


%%

% try load pp_vars
try
    load(fullfile('file_dir','pp_vars'));
catch
    fprintf('\n[i] pp_vars not found, skipping..\n')
end