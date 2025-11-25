%% ----- Add custom time chan
tmp_EEG_chanlocs = EEG.chanlocs;

[num_channels, num_timepoints] = size(EEG.data); % Get dimensions

% init with all 0
new_channel = zeros(1, num_timepoints);

% fill in time data
% [i] sample_margin = 200
new_margin = 50; % = sample_margin x 0.25 (1000Hz -> 250Hz = ~ x 0.25)
if num_timepoints >= new_margin % NOTE: margin x 0.25 is close to 3
    new_channel(new_margin:end) = (0:(num_timepoints - new_margin)) * 1;
end

% Put it to EEG.data
EEG.data = [EEG.data; new_channel];


%% bad channel interpolation

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


%%
  % go back to the unfiltered, unre-referenced dataset
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,'retrieve',ori_dataset_idx,'study',0); 


%% add custom time channel

% REASON
%   now does not use 'boundary' types to segmentate sessions. Instead, use
%   the event types themselves and also duration to look up the sessions.
%   Now also added a idx channel

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


% REASON
%   Simply just messy and variable classes are changed in the new script

%%%% MODIFY Add custom time channel
% CONTINUE

temp_EEG_chanlocs = EEG.chanlocs; % temp save

% find boundary latency values
eventTypes = {EEG.event.type};
boundaryIdx = find(strcmp(eventTypes, 'boundary'));
boundaryLatencies = [EEG.event(boundaryIdx).latency];

% find session periods (boundary are always in-between 2 Ms like 1000.5ms / 1.0005s)
boundary_floor = floor(boundaryLatencies);
boundary_ceil = ceil(boundaryLatencies);
session_periods = [boundary_ceil(1:end-1); boundary_floor(2:end)]';

% init time channel
[chans, pnts] = size(EEG.data); % Basically EEG.nbchan and EEG.pnts
time_channel = zeros(1, pnts);

% fill in time channel values (increment by 4)
% 1 4 9 ... (Ms)
for s_idx = 1:size(session_periods,1) % no. of rows
    start = session_periods(s_idx,1);
    stop = session_periods(s_idx,2);
    session_pnts = (stop - start) + 1;
    time_channel(:,start:stop) = 1:4:(1+ 4*(session_pnts-1));
end

% Put it to EEG.data
EEG.data = [EEG.data; time_channel];


% CORRECTING WORKSPACE VARS
%--------------------------------------------------------------------
% add 'TIMEMS' chan name
EEG.nbchan = EEG.nbchan + 1;
EEG.chanlocs = temp_EEG_chanlocs;
EEG.chanlocs(end+1).labels = 'TIMEMS';

% % XX Does nothing
% EEG.chanlocs(end).type = '';
% EEG.chanlocs(end).ref = '';

% necessary so that creating new set won't break chanlocs
ALLEEG(end).chanlocs = EEG.chanlocs;
ALLEEG(end).nbchan = EEG.nbchan;


[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname','custom time chan','gui','off'); 





%% reject bad channels
% Full on automated channel rejections

% NOTE >>
% matlab does not allow you to manually edit workspace vars unless everything is
% closed, re-running this session to proceed is required after updating bad channel
% indices

% try load pp_vars, init if fields don't exist
try
    load(fullfile(subject_dir,pp_vars_file));
catch
    disp('INFO: pp_vars not found, init it 1st time')
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
    msg = sprintf('Save %s.bad_channels? (It will replace the old file!!!)',subject_idx);
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
            save(fullfile(subject_dir,'pp_vars.mat'),'pp_vars');
        
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


%%

% REASON
%   Absolutely no need this method, can just directly import chanlocs .mat
%   file


% channel interpolation - chan interpolated
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
bad_chans = preprocess_vars.bad_channels;
[tf, bad_chans_idx] = ismember(bad_chans, chans);
if ~all(tf) % emergency err handle
    err('Somehow channels that need to be interpolated are not found in the ref dataset')
end

EEG = pop_interp(EEG, ALLEEG(ref_dataset_idx).chanlocs(bad_chans_idx), 'spherical');
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 4,'setname','chan interpolated','gui','off'); 
eeglab redraw

