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

% REASON
%   now does not use 'boundary' types to segmentate sessions. Instead, use
%   the event types themselves and also duration to look up the sessions.
%   Now also added a idx channel