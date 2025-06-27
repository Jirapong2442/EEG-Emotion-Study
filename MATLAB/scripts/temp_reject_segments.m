
% test2
EEG = eeg_eegrej( EEG, [5363 5542;5666 6050;6319 7338;7856 8438;56399 56818;72004 72373;82418 83094;88048 88454;91904 92905;93009 93562]);
EEG = pop_select( EEG, 'rmchannel',{'FC3','P4'});
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname','rej','gui','off'); 
