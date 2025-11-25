%%

config = config_fn();
eeglab
EEG = pop_loadset('filename','after_ICA.set','filepath','D:\\EEE\\ALL_DATA\\G2P_1\\');
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );


%% Epoching the EEG.data, 1 second / 500 pt (500 Hz) per epoch
EEG = pop_loadset('filename','after_ICA.set','filepath','D:\\EEE\\ALL_DATA\\G2P_1\\');
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );

srate = EEG.srate;
pnts = EEG.pnts;
nbchan = EEG.nbchan;

epochs = ceil(pnts/srate);

% epoched_data = zeros(nbchan, srate, epochs);

temp_EEG_data = EEG.data;
more_pnts = (epochs * srate) - pnts;
pnts_array = zeros(nbchan, more_pnts);
temp_EEG_data = [temp_EEG_data, pnts_array];

epoched_data = reshape(temp_EEG_data, nbchan, srate, epochs);
load('chanlocs_ref.mat');
EEG = pop_importdata('setname','epoched data', 'data','epoched_data', 'dataformat','array', 'chanlocs', 'chanlocs_ref', 'srate', srate, 'pnts', srate);
    % ^ Simply use pop_importdata() to put the epoched data in, everything
    % else will be adjusted. It's better than forcibly subbing the
    % epoched_data to EEG.data, use their own functions for it to adjust
    % workspace vars manually.

eeglab redraw


%% TBT
% Link:
%   https://github.com/mattansb/TBT

load('chanlocs_ref.mat');

EEG = pop_eegmaxmin(EEG,[1:66],[0 5996.0938],100,5996.0938,1,0);
EEG =pop_TBT(EEG,EEG.reject.rejmaxminE,4,0.3,0); %setting the fifth parameter to zero would avoid the confirmation pop-up!