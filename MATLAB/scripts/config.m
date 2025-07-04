
% ---------------------- FILES AND DIRECTORIES ----------------------------
dir.root = 'C:\Users\CUHK-ARHOME-054\Desktop\EEG-Emotion-Study\MATLAB';
dir.scripts = fullfile(dir.root, 'scripts');
dir.eeg_data = fullfile(dir.root, 'eeg_data');

addpath(genpath(dir.scripts)) % Add with all sub_folders
savepath; % NOTE save for next session too


% ------------------------------- EEG -------------------------------------
used_channels = { ...
'FP1', 'FP2', ...
'AF7', 'AF3', 'AFZ', 'AF4', 'AF8', ...
'F7', 'F5', 'F3', 'F1', 'FZ', 'F2', 'F4', 'F6', 'F8', ...
'FT9', 'FT7', 'FC5', 'FC3', 'FC1', 'FCZ', 'FC2', 'FC4', 'FC6', 'FT8', 'FT10', ...
'T7', 'C5', 'C3', 'C1', 'CZ', 'C2', 'C4', 'C6', 'T8', ...
'TP7', 'CP5', 'CP3', 'CP1', 'CPZ', 'CP2', 'CP4', 'CP6', 'TP8', ...
'P9', 'P7', 'P5', 'P3', 'P1', 'PZ', 'P2', 'P4', 'P6', 'P8', 'P10', ...
'PO7', 'PO3', 'POZ', 'PO4', 'PO8', ...
'O1', 'OZ', 'O2' ...
'CBZ','VEO','HEO' ...
};

%{'CBZ','VEO','HEO','EMG1','EMG2','EMG3','EMG4','EMG5','EMG6','TRIGGER'}


% -------------------------- EEG others -----------------------------------
baseline1_type_name = "b1";
baseline2_type_name = "b2";
video_type_names = "v1 / v2 / v3 ...";




% DEV
% cleaner cmd window
dev.temp_script_name = "config";
if ~isfield(dev, 'clean')|| ~dev.clean
    fprintf('\n## %s.m loaded\n', dev.temp_script_name);
end

%test