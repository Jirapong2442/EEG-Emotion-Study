%% Load file
% =========================================================================

config;
cd(dir.eeg_data);
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab
fprintf("\n##### Import Curry EEG data\n")

%% ----------------------- filter markers ---------------------------------


for i = 1:numel(EEG.event)
    EEG.event(i).keep = 0;
end

EEG.event = orderfields(EEG.event, [4,1:3]);
open EEG
fprintf("\n##### Go EEG.event\n")
fprintf("##### Keep markers by setting 'keep' to 1 for corresponding rows, then proceed\n")


%% --------------------- rename markers -----------------------------------


EEG.event = EEG.event([EEG.event.keep] == 1);
for i = 1:numel(EEG.event)
    EEG.event(i).urevent = i;
end
EEG.event = rmfield(EEG.event, 'keep');

for i = 1:numel(EEG.event)
    EEG.event(i).myDurSeconds = 0;
end

fprintf("\n##### check if: no. of rows = no. of vids + 2");
fprintf("\n##### Then, rename 'type' (markers) and fill in 'myDurSeconds', and proceed");
fprintf("\n-> Baseline1 type name: %s\n-> Baseline2 type name: %s\n-> Video type names: %s\n",baseline1_type_name,baseline2_type_name,video_type_names);
% 11, 12 = start, end baseline
% 1,2,3,4,5,6 = reel sessions

%% ------------------------- save dataset ---------------------------------


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

fprintf("\n##### Markers renamed!\n")
fprintf("!!!!! save dataset -> markers_renamed\n")


