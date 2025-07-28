%% Load file
% =========================================================================

config;
cd(dir.all_data);
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab

fprintf("## -> Import Curry EEG data\n")

%% ----------------- manually filter markers ------------------------------


for i = 1:numel(EEG.event)
    EEG.event(i).keep = 0;
end

EEG.event = orderfields(EEG.event, [4,1:3]);
open EEG
fprintf("## -> Go EEG.event\n")
fprintf("## -> Keep markers by setting 'keep' to 1 for corresponding rows, then proceed\n")


%% ---------------- manually rename markers ------------------------------


EEG.event = EEG.event([EEG.event.keep] == 1);
for i = 1:numel(EEG.event)
    EEG.event(i).urevent = i;
end
EEG.event = rmfield(EEG.event, 'keep');

for i = 1:numel(EEG.event)
    EEG.event(i).myDurSeconds = 0;
end

fprintf("\n## -> check if: rows = vids + 2 (baselines)");
fprintf("\n## -> rename 'type' (markers) and fill in 'myDurSeconds'");
fprintf("\n-> Baseline1 type name: %s\n-> Baseline2 type name: %s\n-> Video type names: %s\n",baseline1_type_name,baseline2_type_name,video_type_names);

%% -------------------- manually save dataset -----------------------------


% NOTE: initialize this struct by clearing it, so that duplicating first row is valid

clear new_EEG_event;
new_idx = 1;

for i = 1:numel(EEG.event)
    if EEG.event(i).myDurSeconds ~= 0
        % First entry: append 'start' to type
        new_EEG_event(new_idx) = EEG.event(i);
        new_EEG_event(new_idx).type = [num2str(EEG.event(i).type) 'start'];
        new_EEG_event(new_idx).urevent = new_idx;
        new_idx = new_idx + 1;

        % Second entry: append 'end' to type and adjust latency
        new_EEG_event(new_idx) = EEG.event(i);
        new_EEG_event(new_idx).type = [num2str(EEG.event(i).type) 'end'];
        new_EEG_event(new_idx).latency = EEG.event(i).latency + EEG.event(i).myDurSeconds * EEG.srate;
        new_EEG_event(new_idx).urevent = new_idx;
        new_idx = new_idx + 1;
    else
        % Just copy as-is
        new_EEG_event(new_idx) = EEG.event(i);
        new_EEG_event(new_idx).urevent = new_idx;
        new_idx = new_idx + 1;
    end
end

% copy back -> EEG.event
new_EEG_event = rmfield(new_EEG_event, 'myDurSeconds');
EEG.event = new_EEG_event;

% copy back -> EEG.urevent
EEG.urevent = EEG.event; % direct copy
EEG.urevent = rmfield(EEG.urevent, 'urevent');

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2, 'setname', 'markers renamed', 'gui','off');
eeglab redraw;

fprintf("## -> save dataset as: markers_renamed\n")


