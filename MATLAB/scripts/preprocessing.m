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

baseline1_start_name = [baseline1_type_name, 'start'];
baseline2_end_name = [baseline2_type_name, 'end'];

baseline1_start_idx = find(strcmp(all_event_types, baseline1_start_name));
baseline2_end_idx = find(strcmp(all_event_types, baseline2_end_name));

start_time_ms = EEG.event(baseline1_start_idx).latency - 1; % don't completely remove marker 21
end_time_ms = EEG.event(baseline2_end_idx).latency;
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

%% add back rejected markers (within rejected segments earlier)

% identify missing markers (CHECKME)
event_type = string({EEG.event.type});
urevent_type = string({EEG.urevent.type});

missing_markers_temp = setdiff(urevent_type,event_type);
missing_markers_idx = ismember(urevent_type,missing_markers_temp);
missing_markers = EEG.urevent(missing_markers_idx);

% Add original latency to EEG.event (UGLY)
n = numel(EEG.event);
original_latency = zeros(n,1);
duration_sum = 0;

for i = 1:n
    if i == 1
        original_latency(i) = EEG.event(i).latency;
    else
        original_latency(i) = EEG.event(i).latency + duration_sum;
    end
    duration_sum = duration_sum + EEG.event(i).duration;
end

% Add new field to struct array
for i = 1:n
    EEG.event(i).original_latency = original_latency(i);
end

% Replace boundary with missing markers
all_event_types = {EEG.event.type};

% Handle cases where type is numeric or string
% Convert numeric types to strings for consistent comparison
for i = 1:length(all_event_types)
    if isnumeric(all_event_types{i})
        all_event_types{i} = num2str(all_event_types{i});
    end
end

[EEG.event.replaced] = deal(0);

for i = 1:length(missing_markers)
    missing_latency = missing_markers(i).latency;
    missing_type = missing_markers(i).type;
    
    for j = 1:length(EEG.event)
        if ischar(EEG.event(j).type) && strcmp(EEG.event(j).type, 'boundary')
            range_start = EEG.event(j).original_latency;
            range_end = EEG.event(j).original_latency + EEG.event(j).duration;
            
            if missing_latency >= range_start && missing_latency <= range_end
                EEG.event(j).type = num2str(missing_type);
                EEG.event(j).replaced = 1; % Mark as replaced
            end
        end
    end
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