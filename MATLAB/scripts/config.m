paths.root = 'C:/Users/CUHK-ARHOME-054/Desktop/Follow up Wonjis FYP/MATLAB';
paths.scripts = fullfile(paths.root, 'scripts');
paths.data = fullfile(paths.root, 'eeg_data');

% Add with all sub_folders
addpath(genpath(paths.scripts))
savepath; % NOTE save for next session too

% DEV
% cleaner cmd window
dev.temp_script_name = "config";
if ~isfield(dev, 'clean')|| ~dev.clean
    fprintf('\n## %s.m loaded\n', dev.temp_script_name);
end

%test