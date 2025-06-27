config;
vars;
convenient_buttons;
savepoint = struct();

[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

%% remove unused time data - time

all_event_types = {EEG.event.type};

% Handle cases where type is numeric or string
% Convert numeric types to strings for consistent comparison
for i = 1:length(all_event_types)
    if isnumeric(all_event_types{i})
        all_event_types{i} = num2str(all_event_types{i});
    end
end

marker11_idx = find(strcmp(all_event_types, '11'));
marker12_idx = find(strcmp(all_event_types, '12'));

start_time_ms = EEG.event(marker11_idx).latency - 1;
end_time_ms = EEG.event(marker12_idx).latency + 2 * 60 * EEG.srate;

rej = [0 start_time_ms; end_time_ms EEG.pnts];

EEG = eeg_eegrej( EEG, rej);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname','time','gui','off'); 

add_savepoint('time');

%% remove unused channels - channels

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
'CBZ','VEO','HEO','EMG1','EMG2','EMG3','EMG4','EMG5','EMG6' ...
};


%{'CBZ','VEO','HEO','EMG1','EMG2','EMG3','EMG4','EMG5','EMG6','TRIGGER'}

EEG = pop_select( EEG, 'channel',used_channels);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname','channels','gui','off');

add_savepoint('channels');

%% resampling - resampled

EEG = pop_resample( EEG, 250);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname','resampled','gui','off'); 

add_savepoint('resampled');

%% band filtering - filtered

EEG = pop_eegfiltnew(EEG, 'locutoff',48,'hicutoff',52,'revfilt',1,'plotfreqz',1);
EEG = pop_eegfiltnew(EEG, 'locutoff',0.5,'plotfreqz',1);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname','filtered','gui','off'); 

add_savepoint('filtered')

%% manually reject segments - reject_segments

open temp_reject_segments.m

%% ICA


%% channel interpolation - chan_interpolated


