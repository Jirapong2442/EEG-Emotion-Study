% https://nigelrogasch.gitbook.io/tesa-user-manual/example_pipelines

% Use eegh to output function syntax
% Type eegh in to the command line and press enter. The following will be returned in the command window. This is a list of all of the functions run by EEGLAB during the preceeding analysis. These functions can be copied and pasted in to a script, which allows the user to repeat the analysis without using the EEGLAB interface. Under 'Home' press 'New Script' to open the editor and paste these functions in to the script. This script can now be saved for future use.

[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

EEG = pop_loadset('filename','example_data.set','filepath','H:\TESA_example_data\test_TESA\');

[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );

EEG=pop_chanedit(EEG, 'lookup','C:\Program Files\MATLAB\eeglab13_5_4b\plugins\dipfit2.3\standard_BESA\standard-10-5-cap385.elp');

[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

EEG = eeg_checkset( EEG );

EEG = pop_select( EEG,'nochannel',{'31' '32'});

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'gui','off');

EEG = eeg_checkset( EEG );

EEG = pop_rejchan(EEG, 'elec',[1:62] ,'threshold',5,'norm','on','measure','kurt');

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'gui','off');

EEG = eeg_checkset( EEG );

EEG = pop_epoch( EEG, { 'R128' }, [-1 1], 'epochinfo', 'yes');

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 3,'gui','off');

EEG = eeg_checkset( EEG );

EEG = pop_rmbase( EEG, [-1000 1000]);

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 4,'gui','off');

EEG = pop_tesa_removedata( EEG, [-2 10] );

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 5,'gui','off');

EEG = pop_tesa_interpdata( EEG, 'cubic', [1 1] );

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 6,'gui','off');

EEG = eeg_checkset( EEG );

EEG = pop_resample( EEG, 1000);

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 7,'gui','off');

EEG = eeg_checkset( EEG );

EEG = pop_jointprob(EEG,1,[1:59] ,5,5,0,0);

EEG = pop_tesa_removedata( EEG, [-2 10] );

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 8,'gui','off');

EEG = pop_tesa_fastica( EEG, 'approach', 'symm', 'g', 'tanh', 'stabilization', 'off' );

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 9,'gui','off');

EEG = pop_tesa_compselect( EEG,'compCheck',on,'comps',15,'figSize','small','plotTimeX',[-200 500],'plotFreqX',[1 100],'tmsMuscle','on','tmsMuscleThresh',8,'tmsMuscleWin',[11 30],'tmsMuscleFeedback','off','blink','off','blinkThresh',2.5,'blinkElecs',{'Fp1','Fp2'},'blinkFeedback','off','move','off','moveThresh',2,'moveElecs',{'F7','F8'},'moveFeedback','off','muscle','off','muscleThresh',0.6,'muscleFreqWin',[30 100],'muscleFeedback','off','elecNoise','off','elecNoiseThresh',4,'elecNoiseFeedback','off' );

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 10,'gui','off');

EEG = pop_tesa_removedata( EEG, [-2 15] );

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 11,'gui','off');

EEG = pop_tesa_interpdata( EEG, 'cubic', [5 5] );

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 12,'gui','off');

EEG = pop_tesa_filtbutter( EEG, 1, 100, 4, 'bandpass' );

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 13,'gui','off');

EEG = pop_tesa_filtbutter( EEG, 48, 52, 4, 'bandstop' );

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 14,'gui','off');

EEG = pop_tesa_removedata( EEG, [-2 15] );

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 15,'gui','off');

EEG = pop_tesa_fastica( EEG, 'approach', 'symm', 'g', 'tanh', 'stabilization', 'off' );

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 16,'gui','off');
EEG = pop_tesa_compselect( EEG,'compCheck','on','comps',[],'figSize','small','plotTimeX',[-200 500],'plotFreqX',[1 100],'tmsMuscle','on','tmsMuscleThresh',8,'tmsMuscleWin',[11 30],'tmsMuscleFeedback','off','blink','on','blinkThresh',2.5,'blinkElecs',{'Fp1','Fp2'},'blinkFeedback','off','move','on','moveThresh',2,'moveElecs',{'F7','F8'},'moveFeedback','off','muscle','on','muscleThresh',0.6,'muscleFreqWin',[30 100],'muscleFeedback','off','elecNoise','on','elecNoiseThresh',4,'elecNoiseFeedback','off' );

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 17,'gui','off');

EEG = pop_tesa_interpdata( EEG, 'cubic', [5 5] );

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 18,'gui','off');

EEG = eeg_checkset( EEG );

EEG = pop_interp(EEG, ALLEEG(2).chanlocs, 'spherical');

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 19,'gui','off');

EEG = eeg_checkset( EEG );

EEG = pop_reref( EEG, []);

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 20,'gui','off');

EEG = pop_tesa_tepextract( EEG, 'ROI', 'elecs', {'P3','CP1','P1','CP3'}, 'tepName', 'Parietal' );

EEG = pop_tesa_peakanalysis( EEG, 'ROI', 'positive', [40 80 200], [30 50;70 90;180 220], 'method', 'largest', 'samples', 5 );

EEG = pop_tesa_peakanalysis( EEG, 'ROI', 'negative', [20 60 100], [10 30;50 70;90 110], 'method', 'largest', 'samples', 5 );

output = pop_tesa_peakoutput( EEG, 'tepName', 'Parietal', 'calcType', 'amplitude', 'winType', 'individual', 'averageWin', 5, 'fixedPeak', [], 'tablePlot', 'on' );

pop_tesa_plot( EEG, 'tepType', 'ROI', 'tepName', 'Parietal', 'xlim', [-100 500], 'ylim', [], 'CI','off','plotPeak','on' );