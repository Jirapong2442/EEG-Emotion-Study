%% Load data

%{

1. For any operations that affect 'TIMEMS' channel, rmb to tmp save and put it
back after the operaetion.

%}


% CHANGE (rmb UPPERCASES)
subject_index = 'G2P_1';


cfg = config(); % MAKE SURE TO INCLUDE THIS IN EVERY SCRIPT -> DETECT SUBFOLDER FUNCTIONS AND SCRIPTS
editable_buttons();

[bad_channels, reject_segments] = pp_vars(subject_index);

[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

% file vars
file_name = 'corrected_raw.set';
file_dir = fullfile(cfg.dir.all_data, subject_index);

% load it
EEG = pop_loadset('filename',file_name,'filepath',file_dir);
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );


%% Resampling to 250 Hz

EEG = pop_resample( EEG, 250);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname','resampled','gui','off'); 

%% Add custom time chan

tmp_EEG_chanlocs = EEG.chanlocs;

[num_channels, num_timepoints] = size(EEG.data); % Get dimensions

% init with all 0
new_channel = zeros(1, num_timepoints);

% fill in time data
% [i] sample_margin = 200
new_margin = 50; % = sample_margin x 0.25 (1000Hz -> 250Hz = ~ x 0.25)
if num_timepoints >= new_margin % NOTE: margin x 0.25 is close to 3
    new_channel(new_margin:end) = 4 * (0:(num_timepoints - new_margin));
end

% Put it to EEG.data
EEG.data = [EEG.data; new_channel];

%%

% --- Correct the workspace vars
EEG.nbchan = EEG.nbchan + 1;
EEG.chanlocs = tmp_EEG_chanlocs;
EEG.chanlocs(end+1).labels = 'TIMEMS';

% % Does nothing
% EEG.chanlocs(end).type = '';
% EEG.chanlocs(end).ref = '';

% necessary so that creating new set won't break chanlocs
ALLEEG(end).chanlocs = EEG.chanlocs;
ALLEEG(end).nbchan = EEG.nbchan;


[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname','custom time chan','gui','off'); 

%% band filtering - filtered

% EEG = pop_eegfiltnew(EEG, 'locutoff',48,'hicutoff',52,'revfilt',1);
% EEG = pop_eegfiltnew(EEG, 'locutoff',0.5);
% EEG = pop_eegfiltnew(EEG, 0.5, 45, [], 0, [], 0, [], 4, 'design', 'butter');

EEG = pop_eegfiltnew(EEG, 'locutoff',1,'hicutoff',45); % simple 1-45 Hz band pass

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname','frq band filtered','gui','off'); 


%% reject bad channels - bad chans

% CONT

try
    % found and get bad channels
    vars;
    temp = ['bad_channels_' subject_ID];
    bad_channels = param.(temp);
    % reject bad channels
    EEG = pop_select( EEG, 'rmchannel',bad_channels);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname','rej bad chans','gui','off'); 
    try
        temp = ['bad_channels_no_interp_' subject_ID];
        bad_channels_no_interp = param.(temp);
        % reject bad channels without interpolation
        EEG = pop_select( EEG, 'rmchannel',bad_channels_no_interp);
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname','rej bad chans (without interp)','gui','off'); 
    catch
    end

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
    reject_segments = param.(temp);
    % reject bad channels
    EEG = eeg_eegrej( EEG, reject_segments);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname','rej segments','gui','off'); 

catch
    % bad channels were not defined in the past
    pop_eegplot( EEG, 1, 1, 1);
    open vars.m
    fprintf("\n##### no need re-running. type 'eegh' and put rejected segments in var\n")
end

%% refill back rejected markers (within rejected segments earlier)
% TODO: if more than 1 marker are rejected in the same boundary segment,
% add back all of them. 

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
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname','refill rej markers (if any)','gui','off'); 

%% ICA

EEG = pop_runica(EEG, 'icatype', 'runica', 'extended',1,'rndreset','yes','interrupt','on');
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
eeglab redraw

fprintf("\n##### Then, try plotting ADJUST, then normal one")
fprintf("\n##### Manually proceed by rejecting selected ICs")

%% channel interpolation - chan interpolated


temp = ['bad_channels_' subject_ID];
bad_channels = param.(temp);
bad_channels = strjoin(bad_channels, ' ');

% load channel location reference set for EEGLAB
% it requires a direct dataset for reference
current_set_idx = CURRENTSET;
EEG = pop_loadset('filename','chan_loc_only_ref.set','filepath',dir.scripts);
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
ref_set_idx = CURRENTSET;

% jump back to current set after loading the reference set
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, ref_set_idx,'retrieve',current_set_idx,'study',0);

eeglab redraw;
% do manually cuz order might be different each time
fprintf("\n##### Click 'Use specific channels of other dataset'");
fprintf("\n##### %i -> Dataset Index", ref_set_idx);
fprintf("\n##### %s -> Channels to be interpolated\n", bad_channels);

% x ARCHIVE

% % get bad channels indices 
% temp = ['bad_channels_' subject_ID];
% bad_channels = param.(temp);
% bad_channels_idx = find(ismember(used_channels, bad_channels));
% 
% % load channel location reference set for EEGLAB
% % it requires a direct dataset for reference
% current_set_idx = CURRENTSET;
% EEG = pop_loadset('filename','chan_loc_only_ref.set','filepath',dir.scripts);
% [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
% ref_set_idx = CURRENTSET;
% 
% % jump back to current set after loading the reference set
% [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, ref_set_idx,'retrieve',current_set_idx,'study',0);
% 
% % interpolate chans
% EEG = pop_interp(EEG, ALLEEG(ref_set_idx).chanlocs(bad_channels_idx), 'spherical');
% [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'gui','off'); 

%% Re-referencing

EEG = pop_reref( EEG, []);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname','re-referenced','gui','off'); 

fprintf("\n!!!!! save dataset -> preprocessed\n")