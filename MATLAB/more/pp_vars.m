function [bad_channels, reject_segments] = pp_vars(index)

    index = char(lower(index)); 
    switch index
        case 'g2p_1'
            bad_channels = {1};
            reject_segments = [1];
    end

    fprintf('## pp_vars.m loaded\n');
    % TODO: Add a detection thing, if no vars is detected, add it here, and
    % also see how I should include this thing
end