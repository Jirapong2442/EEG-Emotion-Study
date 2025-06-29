config; % load this file once directly, then no need in future
vars;
convenient_buttons;

[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

% === CHANGE HERE =========================================================
subject_ID = 'test2';
% =========================================================================

file_name = 'markers_renamed.set';
file_dir = fullfile(dir.eeg_data, subject_ID);

EEG = pop_loadset('filename',file_name,'filepath',file_dir);
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );

%% remove unused time data - time

all_event_types = {EEG.event.type};

% Handle cases where type is numeric or string
% Convert numeric types to strings for consistent comparison
for i = 1:length(all_event_types)
    if isnumeric(all_event_types{i})
        all_event_types{i} = num2str(all_event_types{i});
    end
end

marker21start_idx = find(strcmp(all_event_types, '21'));
marker22end_idx = find(strcmp(all_event_types, '22'));

start_time_ms = EEG.event(marker21start_idx).latency - 1; % don't completely remove marker 21
end_time_ms = EEG.event(marker22end_idx).latency;
% end_time_ms = EEG.event(marker12_idx).latency + 2 * 60 * EEG.srate;

rej = [0 start_time_ms; end_time_ms EEG.pnts];

EEG = eeg_eegrej( EEG, rej);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname','time','gui','off'); 


%% remove unused channels - channels

EEG = pop_select( EEG, 'channel',used_channels);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname','channels','gui','off');


%% resampling - resampled

EEG = pop_resample( EEG, 250);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname','resampled','gui','off'); 


%% band filtering - filtered

EEG = pop_eegfiltnew(EEG, 'locutoff',48,'hicutoff',52,'revfilt',1);
EEG = pop_eegfiltnew(EEG, 'locutoff',0.5);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname','filtered','gui','off'); 


%% reject bad channels - bad chans

try
    % found and get bad channels
    vars;
    temp = ['bad_channels_' subject_ID];
    bad_channels = pp.(temp);
    % reject bad channels
    EEG = pop_select( EEG, 'rmchannel',bad_channels);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'gui','off');

catch
    % bad channels were not defined in the past
    pop_eegplot( EEG, 1, 1, 1);
    open vars.m
    fprintf("\n##### Re-run this right after\n")
end


%% manually reject segments - reject segments

try
    % found and get bad channels
    vars;
    temp = ['reject_segments_' subject_ID];
    reject_segments = pp.(temp);
    % reject bad channels
    EEG = eeg_eegrej( EEG, reject_segments);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'gui','off');

catch
    % bad channels were not defined in the past
    pop_eegplot( EEG, 1, 1, 1);
    open vars.m
    fprintf("\n##### no need re-running. type 'eegh' and put rejected segments in var\n")
end


%% ICA

EEG = pop_runica(EEG, 'icatype', 'runica', 'extended',1,'rndreset','yes','interrupt','on');
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
eeglab redraw

fprintf("\n##### Then, try plotting ADJUST, then normal one")
fprintf("\n##### Manually proceed by rejecting selected ICs")

%% channel interpolation - chan interpolated

% get bad channels indices 
temp = ['bad_channels_' subject_ID];
bad_channels = pp.(temp);
bad_channels_idx = find(ismember(used_channels, bad_channels));

% load channel location reference set for EEGLAB
% it requires a direct dataset for reference
current_set_idx = CURRENTSET;
EEG = pop_loadset('filename','chan_loc_only_ref.set','filepath',dir.scripts);
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
ref_set_idx = CURRENTSET;

% jump back to current set after loading the reference set
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, ref_set_idx,'retrieve',current_set_idx,'study',0);

% interpolate chans
EEG = pop_interp(EEG, ALLEEG(ref_set_idx).chanlocs(bad_channels_idx), 'spherical');
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'gui','off'); 