[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
EEG = pop_loadset('filename','temp.set','filepath','C:\\Users\\RaymondTeam\\Desktop\\EEE\\ALL_DATA\\movement_test\\temp\\');
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );

eeglab redraw;

