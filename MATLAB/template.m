% yes/no cleaner command window
dev.temp_script_name = "HERE";
if ~isfield(dev, 'clean')|| ~dev.clean
    fprintf('\n## %s.m loaded\n', dev.temp_script_name);
end

%%
fprintf("\n## HERE \n")





















% doesn't seem to work for multi-line ones


tempCopy = "";
clipboard('copy', tempCopy);

%% backupEEG
tempCopy = "if exist('backupEEG') == 1 EEG = backupEEG; end " +...
    "backupEEG = EEG;";
clipboard('copy', tempCopy);


%% using only EEG electrode channels

tempEEG = EEG;
% only keep EEG channels and put locations
EEG = pop_select( EEG, 'channel',{'AF3','F7','F3','FC5','T7','P7','O1','O2','P8','T8','FC6','F4','F8','AF4'});
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 4, 'setname', 'temp', 'gui','off'); 
EEG=pop_chanedit(EEG, {'lookup','C:\\Users\\CUHK-ARHOME-054\\AppData\\Roaming\\MathWorks\\MATLAB Add-Ons\\Collections\\EEGLAB\\plugins\\dipfit5.4\\standard_BEM\\elec\\standard_1005.elc'});
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);

!:: others

tempEEG2 = EEG;
EEG = tempEEG;
EEG.data(5:18,:) = tempEEG2.data;
