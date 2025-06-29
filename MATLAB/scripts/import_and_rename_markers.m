%% Load file
% =========================================================================

config;
cd(dir.eeg_data);
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab
fprintf("\n##### Import Curry EEG data\n")

%% filter markers
for i = 1:numel(EEG.event)
    EEG.event(i).keep = 0;
end
EEG.event = orderfields(EEG.event, [4,1:3]);

open EEG

fprintf("\n##### Go EEG.event\n")
fprintf("##### Keep markers by setting 'keep' to 1 for corresponding rows, then proceed\n")


%% rename markers
% TODO: after adding the myDurSeconds, automatically add more markers
% indicating the end of each section
EEG.urevent = EEG.urevent([EEG.event.keep] == 1);
EEG.event = EEG.event([EEG.event.keep] == 1);
for i = 1:numel(EEG.event)
    EEG.event(i).urevent = i;
end
EEG.event = rmfield(EEG.event, 'keep');

for i = 1:numel(EEG.event)
    EEG.event(i).myDurSeconds = 0;
end

fprintf("\n##### Rename 'type' (markers) and fill in 'myDurSeconds', then proceed\n")
% 11, 12 = start, end baseline
% 1,2,3,4,5,6 = reel sessions

%% TEST
EEG = pop_loadset('filename','test_add_dur_markers.set','filepath','C:\\Users\\CUHK-ARHOME-054\\Desktop\\EEG-Emotion-Study\\MATLAB\\eeg_data\\test2\\');
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );


%% save dataset

% NOTE: initialize this struct my clearing it, so that duplicating first row is valid

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

% copy back to EEG.event and EEG.urevent
new_EEG_event = rmfield(new_EEG_event, 'myDurSeconds');
EEG.event = new_EEG_event;


EEG.urevent = EEG.event; % direct copy
EEG.urevent = rmfield(EEG.urevent, 'urevent');

%%
% for i = 1:numel(EEG.event)
%     EEG.urevent(i).type = EEG.event(i).type;
%     EEG.urevent(i).myDurSeconds = EEG.event(i).myDurSeconds;
% end

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2, 'setname', 'markers renamed', 'gui','off');
eeglab redraw;

fprintf("\n##### Markers renamed!\n")
fprintf("!!!!! save dataset -> markers_renamed\n")