%% Load file
% =========================================================================

file_navigation;
cd(paths.data);
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
EEG.urevent = EEG.urevent([EEG.event.keep] == 1);
EEG.event = EEG.event([EEG.event.keep] == 1);
for i = 1:numel(EEG.event)
    EEG.event(i).urevent = i;
end
EEG.event = rmfield(EEG.event, 'keep');

fprintf("\n##### Rename 'type' (markers), then proceed\n")
% 11, 12 = start, end baseline
% 1,2,3,4,5,6 = reel sessions

%% save dataset
for i = 1:numel(EEG.event)
    EEG.urevent(i).type = EEG.event(i).type;
end

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2, 'setname', 'markers renamed', 'gui','off');
eeglab redraw;

fprintf("\n##### Markers renamed!\n")
fprintf("!!!!! save dataset -> markers_renamed\n")