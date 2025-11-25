
clc; clear; close all;
CONFIG;
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
pop_editoptions( 'option_storedisk', 1);

% =========================================================================
subject_idxes = {
    'G2P_1','P2G_1'
};
% =========================================================================


set_mat = 1:1:length(subject_idxes);

for subject_idx = subject_idxes
    subject_idx = char(subject_idx);
    subject_dir = fullfile(cfg.dir.all_data, subject_idx);
    EEG = pop_loadset('filename','corrected_raw.set','filepath',subject_dir);
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
end
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'retrieve',set_mat ,'study',0); 

%%
% resample to 500 Hz
EEG = pop_resample( EEG, 500);

% band filtering
EEG = pop_eegfiltnew(EEG, 'locutoff',48,'hicutoff',52,'revfilt',1); % notch 48-52 Hz
EEG = pop_eegfiltnew(EEG, 'locutoff',1,'hicutoff',98); % band pass 1-98 Hz 

% re-reference (with CAR)
EEG = pop_reref( EEG, []);

