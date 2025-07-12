%% load
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
EEG = pop_loadset('filename','preprocessed.set','filepath','C:\\Users\\CUHK-ARHOME-054\\Desktop\\EEG-Emotion-Study\\all_data\\test4\\eeg\\');
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );

all_event_types = {EEG.event.type};

% Handle cases where type is numeric or string
% Convert numeric types to strings for consistent comparison
for i = 1:length(all_event_types)
    if isnumeric(all_event_types{i})
        all_event_types{i} = num2str(all_event_types{i});
    end
end

%% ONLY VIDEOS
markerStart_idx = find(strcmp(all_event_types, 'v1start'));
markerEnd_idx = find(strcmp(all_event_types, 'v7end'));

start_time_ms = EEG.event(markerStart_idx).latency;
end_time_ms = EEG.event(markerEnd_idx).latency; 

rej_segments = [0 start_time_ms; end_time_ms EEG.pnts];

EEG = eeg_eegrej( EEG, rej_segments);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname','time','gui','off')

%% ONLY BASELINE 1
markerStart_idx = find(strcmp(all_event_types, 'b1start'));
markerEnd_idx = find(strcmp(all_event_types, 'b1end'));

start_time_ms = EEG.event(markerStart_idx).latency;
end_time_ms = EEG.event(markerEnd_idx).latency; 

rej_segments = [0 start_time_ms; end_time_ms EEG.pnts];

EEG = eeg_eegrej( EEG, rej_segments);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname','time','gui','off')

%% ONLY BASELINE 2
markerStart_idx = find(strcmp(all_event_types, 'b2start'));
markerEnd_idx = find(strcmp(all_event_types, 'b2end'));

start_time_ms = EEG.event(markerStart_idx).latency;
end_time_ms = EEG.event(markerEnd_idx).latency; 

rej_segments = [0 start_time_ms; end_time_ms EEG.pnts];

EEG = eeg_eegrej( EEG, rej_segments);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname','time','gui','off')

%% 2. SPECTRAL ANALYSIS - Calculate Power Spectral Density
% Using EEGLAB's spectopo function with Welch's method
% Define frequency bands
alpha_range = [8 13];    % Standard alpha band for FAA

% Calculate power spectral density for all channels
[spectra, freqs] = spectopo(EEG.data, 0, EEG.srate, 'plot', 'off');

% Find frequency indices for alpha band
alpha_idx = find(freqs >= alpha_range(1) & freqs <= alpha_range(2));

% Convert spectra from dB to absolute power
% spectopo returns power in dB (10*log10(power))
spectra_abs = 10.^(spectra/10);

%% 3. EXTRACT ALPHA POWER FOR FRONTAL CHANNELS
% Find channel indices for frontal electrodes
F3_idx = find(strcmp({EEG.chanlocs.labels}, 'F3'));
F4_idx = find(strcmp({EEG.chanlocs.labels}, 'F4'));

% Alternative: Use multiple frontal channels (recommended for robustness)
left_frontal_channels = {'F3', 'F7', 'AF3'}; % Add more if available
right_frontal_channels = {'F4', 'F8', 'AF4'}; % Add more if available

%% 4. CALCULATE FAA SCORE
% Method 1: F3/F4 pair (most common)
if ~isempty(F3_idx) && ~isempty(F4_idx)
    [spectra_F3, freqs_F3] = spectopo(EEG.data(F3_idx, :), 0, EEG.srate, 'plot', 'off');
    [spectra_F4, freqs_F4] = spectopo(EEG.data(F4_idx, :), 0, EEG.srate, 'plot', 'off');
    
    alpha_idx_F3 = find(freqs_F3 >= alpha_range(1) & freqs_F3 <= alpha_range(2));
    alpha_idx_F4 = find(freqs_F4 >= alpha_range(1) & freqs_F4 <= alpha_range(2));
    
    F3_avg = mean(10.^(spectra_F3(alpha_idx_F3)/10));
    F4_avg = mean(10.^(spectra_F4(alpha_idx_F4)/10));
    
    % Calculate FAA for F3/F4 pair
    FAA_F3F4 = log(F4_avg) - log(F3_avg);
end

%% 5. DISPLAY RESULTS
fprintf('\n=== FRONTAL ALPHA ASYMMETRY RESULTS ===\n');
fprintf('Alpha frequency range: %.1f - %.1f Hz\n', alpha_range(1), alpha_range(2));
fprintf('F3/F4 FAA score: %.4f\n', FAA_F3F4);

fprintf('\nInterpretation:\n');
if FAA_F3F4 > 0
    fprintf('Positive FAA: Relatively greater left frontal activity (approach motivation)\n');
elseif FAA_F3F4 < 0
    fprintf('Negative FAA: Relatively greater right frontal activity (withdrawal motivation)\n');
else
    fprintf('Balanced frontal activity\n');
end
