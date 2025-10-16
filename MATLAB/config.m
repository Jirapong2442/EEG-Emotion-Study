function cfg = config()
    % ---------------------- FILES AND DIRECTORIES ----------------------------
    
    % CHANGE
    cfg.dir.root = 'C:\Users\RaymondTeam\Desktop\EEE';
    
    cfg.dir.all_data = fullfile(cfg.dir.root, 'ALL_DATA');
    cfg.dir.git = fullfile(cfg.dir.root, 'EEG-Emotion-Study');

    cfg.dir.MATLAB = fullfile(cfg.dir.git, 'MATLAB');
    
    addpath(genpath(cfg.dir.root)) % Add with all subfolders
    % savepath; % save for next session too
    

    % ------------------------------- EEG -------------------------------------
    cfg.used_channels = { ...
    'FP1', 'FP2', ...
    'AF7', 'AF3', 'AFZ', 'AF4', 'AF8', ...
    'F7', 'F5', 'F3', 'F1', 'FZ', 'F2', 'F4', 'F6', 'F8', ...
    'FT9', 'FT7', 'FC5', 'FC3', 'FC1', 'FCZ', 'FC2', 'FC4', 'FC6', 'FT8', 'FT10', ...
    'T7', 'C5', 'C3', 'C1', 'CZ', 'C2', 'C4', 'C6', 'T8', ...
    'TP7', 'CP5', 'CP3', 'CP1', 'CPZ', 'CP2', 'CP4', 'CP6', 'TP8', ...
    'P9', 'P7', 'P5', 'P3', 'P1', 'PZ', 'P2', 'P4', 'P6', 'P8', 'P10', ...
    'PO7', 'PO3', 'POZ', 'PO4', 'PO8', ...
    'O1', 'OZ', 'O2' ...
    'VEO','HEO' ...
    };
    
    %_ {'CBZ','VEO','HEO','EMG1','EMG2','EMG3','EMG4','EMG5','EMG6','TRIGGER'}
    
    

    % -------------------------- EEG others -----------------------------------
    
    % Just to show devs how to rename the markers
    cfg.marker_names = "gb1, gb2, pb1, pb2, g1, g2, ... p1, p2, ...";
    
    fprintf('## config.m loaded\n');
end