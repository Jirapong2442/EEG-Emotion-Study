function pp_vars = load_pp_vars(index)

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