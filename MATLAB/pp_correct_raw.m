
cfg = config();
cd(cfg.dir.all_data);
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

fprintf("\n[>] Import Curry EEG data / raw.set\n")

%% manually filter markers 

% ---- set new 'keep' field
% create it
for i = 1:numel(EEG.event)
    EEG.event(i).keep = 0;
end
EEG.event = orderfields(EEG.event, [4,1:3]); % reorder it to 1st column/

open EEG
fprintf("\n[>] Go EEG.event")
fprintf("\n[>] Keep markers by setting 'keep' to 1 for corresponding rows, then proceed\n")

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


%% remove unkept ,, manually rename markers and set duration

% ---- reorder markers based on 'latency'
values = [EEG.event.latency]; % get latency values
[~, order] = sort(values, 'ascend'); % get the order index
EEG.event = EEG.event(order); % sort it

% ---- rid markers that won't be kept
EEG.event = EEG.event([EEG.event.keep] ~= 0);
EEG.event = rmfield(EEG.event, 'keep');

% update 'urevent'
for i = 1:numel(EEG.event)
    EEG.event(i).urevent = i;
end

% ---- set new 'duration' field
% create it
for i = 1:numel(EEG.event)
    EEG.event(i).duration = 0;
end
EEG.event = orderfields(EEG.event, [1:2,4,3]); % reorder it to 1st column

fprintf("\n[>] check if: rows = vids + 2 (baselines)\n");
fprintf("[>] rename 'type' (markers) and fill in 'duration'\n");
fprintf("[>] marker names: %s\n",cfg.marker_names);

%% check if EEG.event is good to go

% NOTE: initialize this struct by clearing it, so that duplicating first row is valid

clear new_EEG_event;
new_idx = 1;

for i = 1:numel(EEG.event)
    if EEG.event(i).duration ~= 0
        % First entry: append 'start' to type
        new_EEG_event(new_idx) = EEG.event(i);
        new_EEG_event(new_idx).type = [num2str(EEG.event(i).type) '_start'];
        new_EEG_event(new_idx).urevent = new_idx;
        new_idx = new_idx + 1;

        % Second entry: append 'end' to type and adjust latency
        new_EEG_event(new_idx) = EEG.event(i);
        new_EEG_event(new_idx).type = [num2str(EEG.event(i).type) '_end'];
        new_EEG_event(new_idx).latency = EEG.event(i).latency + EEG.event(i).duration * EEG.srate;
        new_EEG_event(new_idx).urevent = new_idx;
        new_idx = new_idx + 1;
    else
        % Just copy as-is
        new_EEG_event(new_idx) = EEG.event(i);
        new_EEG_event(new_idx).urevent = new_idx;
        new_idx = new_idx + 1;
    end
end

% ---- test if latency values are correctly sorted (sessions don't overlap)
latency_values = [new_EEG_event.latency];
isSorted = issorted(latency_values, 'ascend');
if isSorted
    fprintf("\n[i] Latency is fine.\n")
else
    fprintf("\n[!] WARNING: sessions seem to overlap on top of each other\n")
    open new_EEG_event
end

%% tidy up data ,, remove unused data

new_EEG_event = rmfield(new_EEG_event, 'duration'); % remove 'duration' field

% copy back to EEG.event
EEG.event = new_EEG_event;

% copy back to EEG.urevent
EEG.urevent = EEG.event; % direct copy
EEG.urevent = rmfield(EEG.urevent, 'urevent'); % remove 'urevent' field in EEG.urevent

% all_event_types = {EEG.event.type};
% % Handle cases where type is numeric or string
% % Convert numeric types to strings for consistent comparison
% for i = 1:length(all_event_types)
%     if isnumeric(all_event_types{i})
%         all_event_types{i} = num2str(all_event_types{i});
%     end
% end
% 
% baseline1_start_idx = find(strcmp(all_event_types, 'b1'));
% baseline2_end_idx = find(strcmp(all_event_types, 'b2'));


% ---- remove unused time data
% get first and last type (starting and ending time point for baselines)
start_idx = 1;
end_idx = numel(EEG.event);

sample_margin = 200; % -200 , +200 -> don't completely remove the original markers
start_time_ms = EEG.event(start_idx).latency - sample_margin; % set start
end_time_ms = EEG.event(end_idx).latency + sample_margin; % set end

rej = [0 start_time_ms; end_time_ms EEG.pnts]; % set rej segments
EEG = eeg_eegrej( EEG, rej); % rej

fprintf("\n## rejected unused time data\n")

% ---- remove unused data channels
EEG = pop_select( EEG, 'channel',cfg.used_channels);

fprintf("\n## removed unused data channels\n")


%% manually save data

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2, 'setname', 'corrected raw', 'gui','off');
eeglab redraw;

fprintf("\n[>] save dataset as: corrected_raw.set\n")


