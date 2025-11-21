%% Load data

%   
%   
%       
%   
%   
%   
%   
%   

clc; clear; close all;

% CHANGE (rmb UPPERCASES)
subject_index = 'G2P_1';

config = config_fn(); % MAKE SURE TO INCLUDE THIS IN EVERY SCRIPT -> DETECT SUBFOLDER FUNCTIONS AND SCRIPTS
dev_buttons();

[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

% file vars
file_dir = fullfile(config.dir.all_data, subject_index);
eeg_file = 'corrected_raw.set';
pp_vars_file = 'pp_vars';

% load eeg
EEG = pop_loadset('filename',eeg_file,'filepath',file_dir);
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );

% resample to 500 Hz
EEG = pop_resample( EEG, 500);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname','resampled','gui','off'); 

% band filtering
EEG = pop_eegfiltnew(EEG, 'locutoff',48,'hicutoff',52,'revfilt',1); % notch 48-52 Hz
EEG = pop_eegfiltnew(EEG, 'locutoff',1,'hicutoff',98); % band pass 1-98 Hz 
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname','band filtered','gui','off'); 

eeglab redraw;

%% reject bad channels

% NOTE:
%
% matlab does not allow you to manually edit workspace vars unless everything is
% closed, re-running this session to proceed is required after updating bad channel
% indices


% try load pp_vars, init if fields don't exist
try
    load(fullfile(file_dir,pp_vars_file));
catch
    dis('info', 'pp_vars not found, initializing it the first time', 'n')
end 

if ~isfield(pp_vars, 'bad_channels')
    pp_vars.bad_channels = {};
end

% ori_bad_chans, mod_bad_chans -> easy comparison and modification
ori_bad_chans = string(pp_vars.bad_channels);
if ~exist('mod_bad_chans','var') % don't replace manual inputs while re-running
    mod_bad_chans = string(pp_vars.bad_channels);
end
open mod_bad_chans

% ASK TO SAVE THE UPDATED pp_vars IF MODIFICATION IS DETECTED
% --------------------------------------------------------
if ~isequal(ori_bad_chans,mod_bad_chans) % ~strcmp(ori_bad_chans,mod_bad_chans) -> only compare string by string, not the entire var % 'isequal' -> compare sets
    msg = sprintf('Save %s.bad_channels? (It will replace the old file!!!)',subject_index);
    choice = questdlg(msg, ...
        'Save pp_vars', ... % gui title
        'Yes','No','Revert changes','Yes'); % the 2nd 'No' here is the default option, press enter to select this default
    switch choice
        case 'Yes' % yes saving
            % test if can convert string back to cell and save
            try
                pp_vars.bad_channels = cellstr(mod_bad_chans);
            catch
                err('mod_bad_chans contain invalid values!', 'Change to proceed')
            end
            save(fullfile(file_dir,'pp_vars.mat'),'pp_vars');
        
        case 'No' % no saving
            fprintf('\n[i] No Saving...\n')
        case 'Revert changes'
            mod_bad_chans = ori_bad_chans;
    end
end



if ~all(cellfun(@isempty, pp_vars.bad_channels)) % if not empty
    dis('info', ['Bad channels include: ', string(pp_vars.bad_channels)],'n')
else
    dis('info', 'No marked bad channels.','n')
end


% Ask to proceed / inspect
proceed = false;
if isempty(pp_vars.bad_channels)
    proceed = true;
else
    msg = sprintf('Proceed to removing bad channels?');
    choice = questdlg(msg, ...
        'Confirm proceed', ... % gui title
        'Yes','No (inspect)','No (exit)','Yes'); % the 2nd 'No' here is the default option, press enter to select this default
    switch choice
        case 'Yes'
            proceed = true;
        case 'No (inspect)'
            proceed = false;
        case 'No (exit)'
            proceed = 'exit';
    end
end


% Need to inspect
if proceed == false % while no proceed (doesn't loop if proceed = 'exit')
    
    open mod_bad_chans
    pop_eegplot( EEG, 1, 1, 1);

    dis('act', 'Inspect bad channels','n');
    dis('act', 'Update pp_vars.bad_channels before closing scroll window to save it')
    

    % STOP IF SCROLL WINDOW IS STILL OPEN
    % --------------------------------------------------------
    % AI-generated
    while true
        figs = findall(0, 'Type', 'figure');
        found = false;
        for i = 1:length(figs)
            winName = get(figs(i), 'Name');
            if strncmp(winName, 'Scroll channel activities', length('Scroll channel activities'))
                waitfor(figs(i));
                found = true;
                break; % Exit for-loop and re-check in case window is reopened
            end
        end
        if ~found
            break; % No such window open, exit while-loop
        end
    end

    
    % ASK TO PROCEED TO REMOVE BAD CHANNELS
    % --------------------------------------------------------
    msg = sprintf('Proceed to removing bad channels?');
    choice = questdlg(msg, ...
        'Confirm proceed', ... % gui title
        'Yes','Need to update bad channels / Exit','Yes'); % the 2nd 'No' here is the default option, press enter to select this default
    switch choice
        case 'Yes'
            proceed = true;
        case 'Need to update bad channels / Exit'
            proceed = 'exit';
    end
end


% yes proceed
if proceed == true
    % test if marked chan names are valid to be removed
    try
        % proceed to remove the bad channels, skip if no bad channels
        if isfield(pp_vars, 'bad_channels') && ~all(cellfun(@isempty, pp_vars.bad_channels)) % if exist
            EEG = pop_select( EEG, 'rmchannel',pp_vars.bad_channels);
            [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname','rej bad chans','gui','off');
            eeglab redraw
        else
            dis('info', 'No marked bad channels, skipping...','n');
        end
    catch
        err('Unable to remove channels!', 'Defined bad channels may have already been removed / does not exist')
    end
elseif ~proceed
    dis('info', 'Not proceeding...', 'n');
end

%% re-reference (with CAR)
    
EEG = pop_reref( EEG, []);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'setname','re-referenced','gui','off'); 


%% channel interpolation - chan interpolated

current_dataset_idx = CURRENTSET;

% load ref dataset
ref_dataset_file = 'chanlocs_ref_set.set';
EEG = pop_loadset('filename',ref_dataset_file,'filepath',config.dir.MATLAB);
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0);
ref_dataset_idx = CURRENTSET;
chans = {EEG.chanlocs.labels};

% go back to current original dataset
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, ref_dataset_idx,'retrieve',current_dataset_idx,'study',0);  %from -> to

% find bad channels idx using ref dataset 
chans = {EEG.chanlocs.labels};
bad_chans = pp_vars.bad_channels;
[tf, bad_chans_idx] = ismember(bad_chans, chans);
if ~all(tf) % emergency err handle
    err('Somehow channels that need to be interpolated are not found in the ref dataset')
end

EEG = pop_interp(EEG, ALLEEG(ref_dataset_idx).chanlocs(bad_chans_idx), 'spherical');
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 4,'setname','chan interpolated','gui','off'); 
eeglab redraw

%% ICA

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 4,'setname','before_ICA_rej','gui','off'); 

EEG = pop_runica(EEG, 'icatype', 'runica', 'extended',1,'rndreset','yes','interrupt','on');
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);

dis('act', 'Now reject ICs, rmb better not to reject more than 4')
dis('act', 'Noisy signals can be rejected manually afterwards')

eeglab redraw

%%

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 4,'setname','after_ICA','gui','off'); 


%% Add custom time and index channels

temp_chanlocs = EEG.chanlocs;

% find boundary latency values
% event_types = {EEG.event.type}
% real_idx = find(not(strcmp(event_types, 'boundary')))

% init time channel
[chans, pnts] = size(EEG.data); % Basically EEG.nbchan and EEG.pnts
time_channel = zeros(1, pnts);
idx_channel = zeros(1,pnts);

for i = 1:length(EEG.event)
    type = EEG.event(i).type;
    if ~strcmp(type,'boundary')
        latency = EEG.event(i).latency;
        finalDuration = EEG.event(i).finalDuration; % measured in ms (with 1000 Hz)
        
        % NOTE: used floor() instead of round() to prevent going off-bounds
        % (exceeding EEG.data time size)
        start_pt = floor(latency);
        stop_pt = start_pt + floor(finalDuration / 2); %... 1000 -> 500 Hz (divide by 2)
        session_pts = (stop_pt - start_pt) + 1;

        time_channel(start_pt:stop_pt) = 1:2:(1+2*(session_pts-1)); %... 1st_val + leap*(session_pts - 1)
        idx_channel(start_pt:stop_pt) = EEG.event(i).idx;
    end
end

% Put it to EEG.data
EEG.data = [EEG.data; time_channel; idx_channel];


% CORRECTING WORKSPACE VARS
%--------------------------------------------------------------------
% add 'TIMEMS' chan name
EEG.nbchan = EEG.nbchan + 2;
EEG.chanlocs = temp_chanlocs;
EEG.chanlocs(end+1).labels = 'TIMEMS';
EEG.chanlocs(end+1).labels = 'IDX';

% necessary so that creating new set won't break chanlocs
ALLEEG(end).chanlocs = EEG.chanlocs;
ALLEEG(end).nbchan = EEG.nbchan;

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname','custom time idx channels','gui','off'); 





















%% MODIFY manually reject segments - reject segments

% CONTINUE


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


%% MODIFY refill back rejected markers (within rejected segments earlier)
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

