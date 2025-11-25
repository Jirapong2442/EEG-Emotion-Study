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
CONFIG; dev_buttons();

% =========================================================================
subject_idx = 'G2P_1';
% =========================================================================

[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

subject_dir = fullfile(cfg.dir.all_data, subject_idx);
cd(subject_dir);
EEG = pop_loadset('filename','corrected_raw.set','filepath',subject_dir);


% resample to 500 Hz
EEG = pop_resample( EEG, 500);

% band filtering
EEG = pop_eegfiltnew(EEG, 'locutoff',48,'hicutoff',52,'revfilt',1); % notch 48-52 Hz
EEG = pop_eegfiltnew(EEG, 'locutoff',1,'hicutoff',98); % band pass 1-98 Hz 

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname','rs-filt','gui','off'); 
eeglab redraw;

%% reject bad channels

% NOTE >>
%   1. matlab does not allow you to manually edit workspace vars unless everything is
%   closed, re-running this session is required to proceed after updating bad channel
%   indices
% 
%   2. Trying to remove the same chans again will not cause error in eeglab


% try load preprocess_vars, init if certain field doesn't exist
if ~exist('bad_chans_init', 'var') bad_chans_init = false; end 
if ~bad_chans_init
    try
        load(fullfile(subject_dir,'preprocess_vars'));
    catch
        preprocess_vars = struct();
        disp('INFO: preprocess_vars not found, init it 1st time')
    end 
    if ~isfield(preprocess_vars, 'bad_channels')
        preprocess_vars.bad_channels = {};
    end

    %easy comparison and modification
    ori_bad_chans = string(preprocess_vars.bad_channels);
    edit_bad_chans = string(preprocess_vars.bad_channels);

    bad_chans_init = true;
end




% display marked bad chans
open edit_bad_chans

% properly format it
tem = reshape(edit_bad_chans, 1, []);
tem = tem(strlength(tem)>0);
edit_bad_chans = tem;

if ~all(cellfun(@isempty, edit_bad_chans)) %all() used ones for 1D cell array
    fprintf("INFO: bad channels include: %s\n", strjoin(edit_bad_chans, ', '))
else
    disp('INFO: no marked bad channels')
end

% Ask to proceed / inspect
% -------------------------------------------------------------------------
proceed = false;

msg = sprintf('Proceed to removing bad channels (if marked)?');
choice = questdlg(msg, ...
    'Confirm proceed', ... % gui title
    'Yes','No (inspect)','No (exit)','Yes'); % the 2nd 'No' here is the default option, press enter to select this default
switch choice
    case 'Yes'
        proceed = true;
    case 'No (inspect)'
        proceed = false;
    case 'No (exit)'
        return;
end
% -------------------------------------------------------------------------


% if inspect
% -------------------------------------------------------------------------
if ~proceed % while no proceed (doesn't loop if proceed = 'exit')
    
    open edit_bad_chans
    pop_eegplot( EEG, 1, 1, 1);

    disp("ACTION >> inspect bad channels")
    disp("update preprocess_vars.bad_channels after closing scroll EEG window")
    
    % % stop if scroll window is still open (temp AI-gen)
    % while true
    %     figs = findall(0, 'Type', 'figure');
    %     found = false;
    %     for i = 1:length(figs)
    %         winName = get(figs(i), 'Name');
    %         if strncmp(winName, 'Scroll channel activities', length('Scroll channel activities'))
    %             waitfor(figs(i));
    %             found = true;
    %             break; % Exit for-loop and re-check in case window is reopened
    %         end
    %     end
    %     if ~found
    %         break; % No such window open, exit while-loop
    %     end
    % end

    % % GUI: ask to proceed removing bad chans
    % msg = sprintf('Proceed to removing bad channels?');
    % choice = questdlg(msg, ...
    %     'Confirm proceed', ... % gui title
    %     'Yes','No (Edit bad chans / exit)','Yes'); % the 2nd 'No' here is the default option, press enter to select this default
    % switch choice
    %     case 'Yes'
    %         proceed = true;
    %     case 'No (Edit bad chans / exit)'
    %         disp('not proceeding...')
    %         return
    % end
end
% -------------------------------------------------------------------------



% if proceed
% -------------------------------------------------------------------------
if proceed
    % 1. convert back to cell array
    try
        preprocess_vars.bad_channels = cellstr(edit_bad_chans);
    catch
        err("edit_bad_chans can't convert back to cell array!")
    end

    % 2. remove bad chans
    try
        % proceed to remove the bad channels, skip if no bad channels
        if isfield(preprocess_vars, 'bad_channels') && ~all(cellfun(@isempty, preprocess_vars.bad_channels)) % if exist
            EEG = pop_select( EEG, 'rmchannel',preprocess_vars.bad_channels);
            [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname','rej_bad_chan','gui','off');
            eeglab redraw
        else
            disp("INFO: no marked bad channels, skipping...")
        end
    catch
        % WARNING: eeglab won't reach this
        err('Unable to remove channels!', 'Defined bad channels may have already been removed / does not exist')
    end

    % 2. GUI: ask to save preprocess_vars
    if ~isequal(ori_bad_chans,edit_bad_chans)
        msg = sprintf('Save %s.bad_channels? (It will replace the old file!!!)',subject_idx);
        choice = questdlg(msg, ...
            'Save preprocess_vars', ... % gui title
            'Yes','No','Revert changes','Yes'); % the 2nd 'No' here is the default option, press enter to select this default
        switch choice
            case 'Yes'
                save(fullfile(subject_dir,'preprocess_vars.mat'),'preprocess_vars');
                bad_chans_init = false;
            case 'No'
                disp('INFO: not saving...')
            case 'Revert changes'
                edit_bad_chans = ori_bad_chans;
        end
    end

end
% -------------------------------------------------------------------------

    

%% 

% re-reference (with CAR)
EEG = pop_reref( EEG, []);

% interpolate bad chans
chanlocs_ref_path = fullfile(cfg.dir.matlab, 'chanlocs_ref.mat');
load(chanlocs_ref_path);

chans = {chanlocs_ref.labels};
bad_chans = preprocess_vars.bad_channels;
[tf, bad_chans_idx] = ismember(bad_chans, chans);
if ~all(tf) % emergency err handle
    err('Somehow channels that need to be interpolated are not found in the ref dataset')
end

EEG = pop_interp(EEG, chanlocs_ref(bad_chans_idx), 'spherical');
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 4,'setname','reref-chan_interpol','gui','off'); 
eeglab redraw

%% ICA

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 4,'setname','before_ICA_rej','gui','off'); 

EEG = pop_runica(EEG, 'icatype', 'runica', 'extended',1,'rndreset','yes','interrupt','on');
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);

disp('ACTION >> now reject ICs, rmb not to reject more than 4')
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

