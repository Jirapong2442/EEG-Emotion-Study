%% temp load EEG data

EEG = pop_loadset('filename','temp_add_markers_from_face_and_subtitles.set','filepath','C:\\Users\\CUHK-ARHOME-054\\Desktop\\EEG-Emotion-Study\\MATLAB\\eeg_data\\test2\\');
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );

%% 
% set error flag -- if empty markers
% try
%     event_types = string({EEG.event.type});
%     dev.empty_markers = false;
% catch
%     dev.empty_markers = true;
%     error("##### Detected empty marker") % check error flag
% end

% % set error flag -- if duplicate markers
% if numel(event_types) ~= numel(unique(event_types))
%     dev.dup_markers = true;
%     error("##### Markers contain duplicates."); % check error flag
% else
%     dev.dup_markers = false;
% end





% identify missing markers
% CHECK: [] type
event_type = string({EEG.event.type});
urevent_type = string({EEG.urevent.type});

missing_markers_temp = setdiff(urevent_type,event_type);
missing_markers_idx = ismember(urevent_type,missing_markers_temp);
missing_markers = EEG.urevent(missing_markers_idx);

% Add original latency to EEG.event (UGLY)
n = numel(EEG.event);
original_latency = zeros(n,1);
duration_sum = 0;

for i = 1:n
    if i == 1
        original_latency(i) = EEG.event(i).latency;
    else
        original_latency(i) = EEG.event(i).latency + duration_sum;
    end
    duration_sum = duration_sum + EEG.event(i).duration;
end

% Add new field to struct array
for i = 1:n
    EEG.event(i).original_latency = original_latency(i);
end

% Replace boundary with missing markers
all_event_types = {EEG.event.type};

% Handle cases where type is numeric or string
% Convert numeric types to strings for consistent comparison
for i = 1:length(all_event_types)
    if isnumeric(all_event_types{i})
        all_event_types{i} = num2str(all_event_types{i});
    end
end

[EEG.event.replaced] = deal(0);

for i = 1:length(missing_markers)
    missing_latency = missing_markers(i).latency;
    missing_type = missing_markers(i).type;
    
    for j = 1:length(EEG.event)
        if ischar(EEG.event(j).type) && strcmp(EEG.event(j).type, 'boundary')
            range_start = EEG.event(j).original_latency;
            range_end = EEG.event(j).original_latency + EEG.event(j).duration;
            
            if missing_latency >= range_start && missing_latency <= range_end
                EEG.event(j).type = num2str(missing_type);
                EEG.event(j).replaced = 1; % Mark as replaced
            end
        end
    end
end




% %% Then, assuming only 'boundary' types contain the missing markers
% all_event_types = {EEG.event.type};
% 
% % Handle cases where type is numeric or string
% % Convert numeric types to strings for consistent comparison
% for i = 1:length(all_event_types)
%     if isnumeric(all_event_types{i})
%         all_event_types{i} = num2str(all_event_types{i});
%     end
% end
% 
% marker_boundary_idx = find(strcmp(all_event_types, 'boundary'));
% boundary_events = [];
% for i = 1:length(marker_boundary_idx)
%     idx = marker_boundary_idx(i);
%     boundary_events(i,1) = idx;
%     boundary_events(i,2) = EEG.event(idx).original_latency;
%     boundary_events(i,3) = EEG.event(idx).original_latency + EEG.event(idx).original_latency;
%     disp(i);
% end
