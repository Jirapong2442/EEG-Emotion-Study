%% Add idx back to EEG.event and EEG.urevent

temp = EEG.event;
idx = 1;
for i = 1:length(temp)
    type = temp(i).type;
    if ~strcmp(type,'boundary')
        temp(i).idx = idx;
        idx = idx + 1;
    end
end
open temp
EEG.event = temp;

temp = EEG.urevent;
idx = 1;
for i = 1:length(temp)
    type = temp(i).type;
    if ~strcmp(type,'boundary')
        temp(i).idx = idx;
        idx = idx + 1;
    end
end
open temp
EEG.urevent = temp;

eeglab redraw