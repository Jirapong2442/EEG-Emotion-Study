%% IMPORTANT: Add new indices in struct if missing markers (RERUN HOW MANY TIMES NEEDED)

fields = fieldnames(EEG.event); % get field names
newindex = length(EEG.event) + 1; % new index location

% Create a struct with all fields empty
emptyStruct = struct();
for i = 1:numel(fields)
    emptyStruct.(fields{i}) = [];
end

% assign empty struct back to EEG.event
EEG.event(newindex) = emptyStruct;

% REASON
%   No need this script, only MATLAB ver. 2025b need this. The current one I'm
%   using is ver. 2024b


%% 

% remove unused time data (that's entirely outside of the experimental time frame)
%   NOTE: get first and last type (starting and ending time point for baselines)
start_idx = 1;
end_idx = numel(EEG.event);
%   Set some margin
sample_margin = 200; % in ms (cuz now in 1000 Hz, so it's just ms)
start_time_ms = EEG.event(start_idx).latency - sample_margin;
end_time_ms = EEG.event(end_idx).latency + sample_margin;
%   rej
rej = [0 start_time_ms; end_time_ms EEG.pnts];
EEG = eeg_eegrej( EEG, rej);

% REASON
%   Just extract the necessary eeg data, exclude all in-between sessions.
%   After that give a custom time channel 

%%

fprintf("\n[>] check if: no. of rows = 4 (baseline) + no. of vids\n");
fprintf("[>] rename 'type' (marker names) and fill in 'durationInMs (in seconds)'\n");
fprintf("[>] marker names: %s\n",config.marker_names);
fprintf("[>]               Remember to put '' as like 'gb1'\n")

%%
% % XX CHECK IF SESSIONS OVERLAP
% % -----------------------------------------------------------------
% 
% % NOTE: initialize this struct by clearing it, so that duplicating first row is valid
% clear tt_overlap;
% new_idx = 1;
% 
% for i = 1:numel(temp_EEG_event)
%     if temp_EEG_event(i).durationInMs ~= 0
%         % First entry: append 'start' to type
%         tt_overlap(new_idx) = temp_EEG_event(i);
%         tt_overlap(new_idx).type = [char(temp_EEG_event(i).type) '_start'];
%         tt_overlap(new_idx).urevent = new_idx;
%         new_idx = new_idx + 1;
% 
%         % Second entry: append 'end' to type and adjust latency
%         tt_overlap(new_idx) = temp_EEG_event(i);
%         tt_overlap(new_idx).type = [char(temp_EEG_event(i).type) '_end'];
%         tt_overlap(new_idx).latency = temp_EEG_event(i).latency + temp_EEG_event(i).durationInMs;
%         tt_overlap(new_idx).durationInMs = [];
%         tt_overlap(new_idx).urevent = new_idx;
%         new_idx = new_idx + 1;
%     else
%         % Just copy as-is
%         tt_overlap(new_idx) = temp_EEG_event(i);
%         tt_overlap(new_idx).urevent = new_idx;
%         new_idx = new_idx + 1;
%     end
% end

% % ---- test if latency values are correctly sorted (sessions don't overlap)
% latency_values = [tt_overlap.latency];
% isSorted = issorted(latency_values, 'ascend');
% if isSorted
%     fprintf("\n[i] Latency is fine, safe to proceed.\n")
% else
%     errordlg('Sessions seem to overlap each other','Error','modal');
%     fprintf('\nWARNING: Sessions seem to overlap each other\n')
%     l = [tt_overlap.latency];
%     for i = 1:length(l)-1
%         if l(i+1) < l(i)
%             fprintf('index %i and %i\n',i,i+1)
%         end
%     end
% end

% open tt_overlap

% REASON
%   used a new script to put them in a check_EEG_event to better inspect