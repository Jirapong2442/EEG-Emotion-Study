

[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
EEG = pop_loadset('filename','preprocessed.set','filepath','C:\\Users\\CUHK-ARHOME-054\\Desktop\\EEG-Emotion-Study\\MATLAB\\eeg_data\\test2\\');
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
marker1_idx = find(strcmp(all_event_types, '1'));
marker6_idx = find(strcmp(all_event_types, '6'));

start_time_ms = EEG.event(marker1_idx).latency;
end_time_ms = EEG.event(marker6_idx).latency; % in the real one it has to trim at the end of this instead.

rej = [0 start_time_ms; end_time_ms EEG.pnts];

EEG = eeg_eegrej( EEG, rej);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname','time','gui','off')

%% ONLY BASELINE 1
marker11_idx = find(strcmp(all_event_types, '11'));

% start_time_ms = 0;
end_time_ms = EEG.event(marker6_idx).latency + 2*60*EEG.srate; % in the real one it has to trim at the end of this instead.

rej = [end_time_ms EEG.pnts];

EEG = eeg_eegrej( EEG, rej);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname','time','gui','off')

%% ONLY BASELINE 2
marker12_idx = find(strcmp(all_event_types, '12'));

start_time_ms = EEG.event(marker12_idx).latency;
% end_time_ms = EEG.pnts; 

rej = [0 start_time_ms];

EEG = eeg_eegrej( EEG, rej);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname','time','gui','off')

%% relative band power scalp maps

% Define frequency bands
bands = struct();
bands.delta = [1 4];
bands.theta = [4 8];
bands.alpha = [8 13];
bands.beta = [13 30];
bands.gamma = [30 50];

% Set parameters for Welch method
srate = EEG.srate;
window_length = 2 * srate; % 2-second windows
overlap = window_length / 2; % 50% overlap
nfft = window_length;

% Initialize arrays
num_channels = size(EEG.data, 1);
band_names = fieldnames(bands);
relative_power = struct();

% Compute PSD for each channel
for ch = 1:num_channels
    % Use pwelch to compute PSD
    [pxx, freqs] = pwelch(EEG.data(ch, :), window_length, overlap, nfft, srate);
    
    % Compute absolute power for each frequency band
    total_power = 0;
    abs_power = struct();
    
    for b = 1:length(band_names)
        band_name = band_names{b};
        freq_range = bands.(band_name);
        
        % Find frequency indices
        freq_idx = freqs >= freq_range(1) & freqs <= freq_range(2);
        
        % Compute absolute power (integrate PSD over frequency range)
        abs_power.(band_name) = trapz(freqs(freq_idx), pxx(freq_idx));
        total_power = total_power + abs_power.(band_name);
    end
    
    % Compute relative power for each band
    for b = 1:length(band_names)
        band_name = band_names{b};
        if ~isfield(relative_power, band_name)
            relative_power.(band_name) = zeros(1, num_channels);
        end
        relative_power.(band_name)(ch) = abs_power.(band_name) / total_power;
    end
end


%/%

% Create figure with subplots for each frequency band
figure('Position', [100, 100, 1200, 300]);

for b = 1:length(band_names)
    band_name = band_names{b};
    
    subplot(1, length(band_names), b);
    
    % Use EEGLAB's topoplot function
    topoplot(relative_power.(band_name), EEG.chanlocs, ...
        'maplimits', [min(relative_power.(band_name)) max(relative_power.(band_name))], ...
        'electrodes', 'on', ...
        'colormap', jet);
    
    % Add title and colorbar
    title([upper(band_name(1)) band_name(2:end) ' Band Relative Power'], 'FontSize', 12);
    colorbar;
end

% Adjust subplot spacing
sgtitle('EEG Relative Band Power Distribution', 'FontSize', 14, 'FontWeight', 'bold');
%% PLV
% Define frequency bands and labels
freq_bands = [1 4; 4 8; 8 12; 13 30; 30 45];
band_labels = {'Delta', 'Theta', 'Alpha', 'Beta', 'Gamma'};

% Define channel pairs (using your existing structure)
channel_pairs = {'F3', 'F4'; 'F7', 'F8'; 'AF3', 'AF4';
                 'P3', 'P4'; 'P7', 'P8';
                 'T7', 'T8';
                 'O1', 'O2';
                 'F3', 'T7'; 'F4', 'T8'; 'F7', 'T7'; 'F8', 'T8';
                 'F3', 'P3'; 'F4', 'P4';
                 'F3', 'O1'; 'F4', 'O2';
                 'F3', 'O1'; 'F4', 'O2';
                 'T7', 'O1'; 'T8', 'O2';
                 'Fz', 'Cz'; 'Cz', 'Pz'; 'Pz', 'Oz'};

% Get sampling rate
fs = EEG.srate;
num_pairs = size(channel_pairs, 1);
num_bands = size(freq_bands, 1);

% Initialize PLV results matrix
PLV_data = zeros(num_pairs, num_bands);

% Calculate PLV for each frequency band and channel pair
for b = 1:num_bands
    band = freq_bands(b, :);
    fprintf('Processing %s band (%.1f-%.1f Hz)...\n', band_labels{b}, band(1), band(2));
    
    % Design bandpass filter
    nyquist = fs/2;
    [b_coeff, a_coeff] = butter(4, [band(1)/nyquist, band(2)/nyquist], 'bandpass');
    
    for p = 1:num_pairs
        ch1 = channel_pairs{p,1}; 
        ch2 = channel_pairs{p,2};
        
        % Find channel indices
        idx1 = find(strcmp({EEG.chanlocs.labels}, ch1));
        idx2 = find(strcmp({EEG.chanlocs.labels}, ch2));
        
        if isempty(idx1) || isempty(idx2)
            continue; % Skip if channels not found
        end
        
        % Extract and filter signals
        sig1 = EEG.data(idx1, :);
        sig2 = EEG.data(idx2, :);
        
        % Apply bandpass filter
        filt1 = filtfilt(b_coeff, a_coeff, double(sig1));
        filt2 = filtfilt(a_coeff, a_coeff, double(sig2));
        
        % Compute instantaneous phases using Hilbert transform
        phase1 = angle(hilbert(filt1));
        phase2 = angle(hilbert(filt2));
        
        % Calculate phase difference
        phase_diff = phase1 - phase2;
        
        % Compute PLV
        PLV_data(p, b) = abs(mean(exp(1i * phase_diff)));
    end
end

% Display results
fprintf('\nPLV Results Summary:\n');
fprintf('Band\t\tMean PLV\tStd PLV\n');
for b = 1:num_bands
    fprintf('%s\t\t%.3f\t\t%.3f\n', band_labels{b}, mean(PLV_data(:,b)), std(PLV_data(:,b)));
end

%/% Create PLV Connectivity Matrices
% Create full connectivity matrices for each band
num_channels = EEG.nbchan;
PLV_matrices = zeros(num_channels, num_channels, num_bands);

for b = 1:num_bands
    band = freq_bands(b, :);
    
    % Design bandpass filter
    nyquist = fs/2;
    [b_coeff, a_coeff] = butter(4, [band(1)/nyquist, band(2)/nyquist], 'bandpass');
    
    % Calculate PLV for all channel pairs
    for ch1 = 1:num_channels
        for ch2 = (ch1+1):num_channels
            % Extract and filter signals
            sig1 = EEG.data(ch1, :);
            sig2 = EEG.data(ch2, :);
            
            filt1 = filtfilt(b_coeff, a_coeff, double(sig1));
            filt2 = filtfilt(b_coeff, a_coeff, double(sig2));
            
            % Compute phases and PLV
            phase1 = angle(hilbert(filt1));
            phase2 = angle(hilbert(filt2));
            phase_diff = phase1 - phase2;
            
            plv_val = abs(mean(exp(1i * phase_diff)));
            PLV_matrices(ch1, ch2, b) = plv_val;
            PLV_matrices(ch2, ch1, b) = plv_val; % Symmetric matrix
        end
    end
    
    % Set diagonal to 1 (self-connectivity)
    PLV_matrices(:, :, b) = PLV_matrices(:, :, b) + eye(num_channels);
end

%% 2D plot
% Create (2D, not 3D) 3D brain plots for each frequency band
figure('Position', [100, 100, 1500, 900]);

for b = 1:num_bands
    subplot(2, 3, b);
    
    % Extract PLV matrix for current band
    current_PLV = PLV_matrices(:, :, b);
    
    % Create 3D brain connectivity plot
    if exist('topoplot', 'file') % If you have EEGLAB
        % Use EEGLAB's topoplot for 2D visualization
        mean_connectivity = mean(current_PLV, 2);
        topoplot(mean_connectivity, EEG.chanlocs, ...
            'maplimits', [min(mean_connectivity) max(mean_connectivity)], ...
            'electrodes', 'on', ...
            'colormap', jet);
        title([band_labels{b} ' Band PLV']);
        colorbar;
    else
        % Alternative: Use imagesc for matrix visualization
        imagesc(current_PLV);
        colormap(jet);
        colorbar;
        title([band_labels{b} ' Band PLV Matrix']);
        xlabel('Channel Index');
        ylabel('Channel Index');
    end
end

sgtitle('PLV Connectivity Across Frequency Bands', 'FontSize', 14, 'FontWeight', 'bold');

%% advanced 3D

% Create 3D brain network plots showing strongest connections
figure('Position', [100, 100, 1500, 600]);

for b = 1:num_bands
    subplot(1, 5, b);
    
    % Get channel locations
    if isfield(EEG.chanlocs, 'X') && isfield(EEG.chanlocs, 'Y') && isfield(EEG.chanlocs, 'Z')
        % Use 3D coordinates if available
        x = [EEG.chanlocs.X];
        y = [EEG.chanlocs.Y];
        z = [EEG.chanlocs.Z];
    else
        % Use 2D coordinates and add z=0
        x = [EEG.chanlocs.X];
        y = [EEG.chanlocs.Y];
        z = zeros(size(x));
    end
    
    % Plot brain nodes
    scatter3(x, y, z, 100, 'filled', 'MarkerFaceColor', 'red');
    hold on;
    
    % Plot strongest connections (top 10% PLV values)
    current_PLV = PLV_matrices(:, :, b);
    threshold = prctile(current_PLV(:), 90); % Top 10%
    
    [row, col] = find(current_PLV > threshold & current_PLV < 1);
    
    for i = 1:length(row)
        if row(i) < col(i) % Avoid duplicate lines
            line([x(row(i)) x(col(i))], [y(row(i)) y(col(i))], [z(row(i)) z(col(i))], ...
                'Color', 'blue', 'LineWidth', current_PLV(row(i), col(i))*3);
        end
    end
    
    title([band_labels{b} ' PLV Network']);
    xlabel('X'); ylabel('Y'); zlabel('Z');
    view(3);
    axis equal;
    grid on;
end

sgtitle('3D Brain PLV Networks (Top 10% Connections)', 'FontSize', 14);

%% summary
% Create summary plots
figure('Position', [100, 100, 1200, 800]);

% Plot 1: PLV by frequency band
subplot(2, 2, 1);
mean_PLV = squeeze(mean(mean(PLV_matrices, 1), 2));
bar(mean_PLV);
set(gca, 'XTickLabel', band_labels);
ylabel('Mean PLV');
title('Average PLV by Frequency Band');
grid on;

% Plot 2: PLV distribution
subplot(2, 2, 2);
boxplot(PLV_data, 'Labels', band_labels);
ylabel('PLV Values');
title('PLV Distribution Across Channel Pairs');
grid on;

% Plot 3: Network density by band
subplot(2, 2, 3);
threshold = 0.3; % PLV threshold for connectivity
network_density = zeros(num_bands, 1);
for b = 1:num_bands
    connections = PLV_matrices(:, :, b) > threshold & PLV_matrices(:, :, b) < 1;
    network_density(b) = sum(connections(:)) / (num_channels * (num_channels - 1));
end
bar(network_density);
set(gca, 'XTickLabel', band_labels);
ylabel('Network Density');
title('Brain Network Density (PLV > 0.3)');
grid on;

% Plot 4: Heatmap of all PLV values
subplot(2, 2, 4);
imagesc(PLV_data');
colormap(jet);
colorbar;
xlabel('Channel Pair Index');
ylabel('Frequency Band');
set(gca, 'YTick', 1:num_bands, 'YTickLabel', band_labels);
title('PLV Heatmap: All Pairs × All Bands');

sgtitle('PLV Analysis Summary', 'FontSize', 14, 'FontWeight', 'bold');
