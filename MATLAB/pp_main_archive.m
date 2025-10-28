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


%%

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