% Get dimensions
[num_channels, num_timepoints] = size(EEG.data);

% Create new channel with vectorized operations
new_channel = zeros(1, num_timepoints);
if num_timepoints >= 11
    new_channel(11:end) = 0.004 * (0:(num_timepoints-11));
end

% Add to EEG.data
EEG.data = [EEG.data; new_channel];
EEG.nbchan = EEG.nbchan + 1;
