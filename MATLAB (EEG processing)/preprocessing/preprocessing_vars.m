
param.bad_channels_test2 = {'FC3', 'P4'};
param.reject_segments_test2 = [5363 5542;5666 6050;6319 7338;7856 8438;56399 56818;72004 72373;82418 83094;88048 88454;91904 92905;93009 93562];

param.bad_channels_test4 = {'F7', 'AF8'};
param.bad_channels_no_interp_test4 = {'VEO'};
param.reject_segments_test4 = [3752 4635;5690 5918;6362 6583;28161 29375;33009 33577;34278 35139;41738 42813;44495 45301;47576 48199;70308 70964;86839 87206;129176 129919];

% param.bad_channels_
% param.reject_segments_
% 
% param.bad_channels_
% param.reject_segments_
% 
% param.bad_channels_
% param.reject_segments_
% 
% param.bad_channels_
% param.reject_segments_
% 
% param.bad_channels_
% param.reject_segments_







%% DEV
% cleaner cmd window
dev.temp_script_name = "vars";
if ~isfield(dev, 'clean')|| ~dev.clean
    fprintf('\n## %s.m loaded\n', dev.temp_script_name);
end