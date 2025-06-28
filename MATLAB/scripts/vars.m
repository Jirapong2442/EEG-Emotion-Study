
pp.bad_channels_test2 = {'FC3', 'P4'};
pp.reject_segments_test2 = [5363 5542;5666 6050;6319 7338;7856 8438;56399 56818;72004 72373;82418 83094;88048 88454;91904 92905;93009 93562];

% pp.bad_channels_
% pp.reject_segments_

% pp.bad_channels_
% pp.reject_segments_

% pp.bad_channels_
% pp.reject_segments_

% pp.bad_channels_
% pp.reject_segments_

% pp.bad_channels_
% pp.reject_segments_

% pp.bad_channels_
% pp.reject_segments_







%% DEV
% cleaner cmd window
dev.temp_script_name = "vars";
if ~isfield(dev, 'clean')|| ~dev.clean
    fprintf('\n## %s.m loaded\n', dev.temp_script_name);
end