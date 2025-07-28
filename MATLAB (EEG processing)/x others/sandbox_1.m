pop_eegplot( EEG, 1, 1, 1);
EEG = eeg_eegrej( EEG, [647097 667200] );
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'gui','off'); 

%%
all_event_types = {EEG.event.type};

% Handle cases where type is numeric or string
% Convert numeric types to strings for consistent comparison
for i = 1:length(all_event_types)
    if isnumeric(all_event_types{i})
        all_event_types{i} = num2str(all_event_types{i});
    end
end

baseline1_start_name = [baseline1_type_name, 'start'];
baseline2_end_name = [baseline2_type_name, 'end'];

baseline1_start_idx = find(strcmp(all_event_types, baseline1_start_name));
baseline2_end_idx = find(strcmp(all_event_types, baseline2_end_name));

start_time_ms = EEG.event(baseline1_start_idx).latency - 1000; 
end_time_ms = EEG.event(baseline2_end_idx).latency + 1000;
% (-100 , +100 = don't completely remove the original markers)

rej = [0 start_time_ms; end_time_ms EEG.pnts];