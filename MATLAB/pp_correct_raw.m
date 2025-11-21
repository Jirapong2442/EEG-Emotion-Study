clc; clear; close all

config = config_fn();
cd(config.dir.all_data);
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

dis('act', 'Import Curry EEG data / raw.set','n')

%% Load video csv  >>  manually see which marker is real ones 

% LOAD VIDEO DURATION CSV
[file, dir] = uigetfile('*.csv'); % only show csv
cd(dir);
pv = readtable(file);

% CSV -> TABLE OF ALL SESSION DURATIONS
% remove unused 'var1' column
pv = removevars(pv, "Var1");

% Sort video index properly
video_idx = str2double(erase(pv.video, 'v'));
pv.idx = video_idx;
pv = sortrows(pv, 'idx', 'ascend');
pv = removevars(pv, "idx");

% Rename index as 'p1' 'p2' ...
for i = 1:size(pv,1)
    pv.video{i} = ['p' num2str(i)];
end

% Make the generalized video table
gvd_video = {'g1';'g2';'g3';'g4';'g5';'g6';'g7';'g8';'g9';'g10';'g11';'g12';'g13'};
gvd_durations = [47230; 37500; 31130; 34700; 62630; 62670; 29730; 60000; 61170; 39270; 53900; 44970; 41400];
gv = table(gvd_video, gvd_durations, 'VariableNames', {'video', 'duration_ms_'});

% Make the baseline tables
gb1 = table({'gb1'},180000,'VariableNames',{'video', 'duration_ms_'});
gb2 = table({'gb2'},180000,'VariableNames',{'video', 'duration_ms_'});
pb1 = table({'pb1'},180000,'VariableNames',{'video', 'duration_ms_'});
pb2 = table({'pb2'},180000,'VariableNames',{'video', 'duration_ms_'});

% classify experiment group g2p / p2g
group = upper(file(1:3));

% Make the final table
if strcmp(group,'G2P')
    session_durations = [gb1;gv;gb2; pb1;pv;pb2];
elseif strcmp(group,'P2G')
    session_durations = [pb1;pv;pb2; gb1;gv;gb2];
end
session_durations = renamevars(session_durations, 'duration_ms_','durationInMs');


% COPY EEG.EVENT and ADD COLUMN 'KEEP' 'calDuration' 'refDuration'
% ---------------------------------------------------------------
modify_this_EEG_event = EEG.event;

% add 'keep' field
for i = 1:numel(modify_this_EEG_event)
    modify_this_EEG_event(i).keep = 1;
end
modify_this_EEG_event = orderfields(modify_this_EEG_event, [4,1:3]);

% add 'calDurations' field
calDurations = diff([modify_this_EEG_event.latency]);
calDurations = [calDurations 0]; % no next one for last label
calDurations = num2cell(calDurations);
[modify_this_EEG_event.calDuration] = calDurations{:};

% add 'refDurations' field
duration = session_durations.durationInMs;
for i = 1:size(session_durations,1)
    modify_this_EEG_event(i).refDuration = duration(i);
end

open modify_this_EEG_event
dis('act', "Keep markers by setting 'keep' to 1 for corresponding rows then proceed", 'n')
video_rows = size(session_durations,1);
dis('act', ['No. of markers to be kept = ', string(video_rows)])


%% copy modify_this_EEG_event and check no. of rows is correct  >>  fill in everything  >>  check if sessions overlap

% COPY modify_this_EEG_event and TEST IF NO. OF ROWS IS CORRECT
% -------------------------------------------------------------------------
check_EEG_event = modify_this_EEG_event;

video_rows = size(session_durations,1);
keep_rows = sum([check_EEG_event.keep]==1);

if keep_rows == video_rows
    dis('info', 'Correct no. of markers, proceeding...', 'n')
else
    err('Incorrect no. of markers!')
end

% FILL IN EVERYTHING
% -------------------------------------------------------------------------

% reorder markers based on 'latency'
values = [check_EEG_event.latency];
[~, order] = sort(values, 'ascend');
check_EEG_event = check_EEG_event(order);

% rid markers that won't be kept
check_EEG_event = check_EEG_event([check_EEG_event.keep] ~= 0); 
check_EEG_event = rmfield(check_EEG_event, 'keep');

% update 'urevent'
for i = 1:numel(check_EEG_event)
    check_EEG_event(i).urevent = i;
end

% refill 'calDurations' field
calDurations = diff([check_EEG_event.latency]);
calDurations = [calDurations 0]; % no next one for last label
calDurations = num2cell(calDurations);
[check_EEG_event.calDuration] = calDurations{:};

% add 'type' and refill 'refDurations' field
duration = session_durations.durationInMs;
label = session_durations.video;
for i = 1:size(session_durations,1)
    check_EEG_event(i).type = char(label(i));
    check_EEG_event(i).refDuration = duration(i);
end


% add 'continune field
rows = length(check_EEG_event);
col_continue = num2cell(ones(rows,1));
[check_EEG_event.continue] = col_continue{:};

col_type = {check_EEG_event.type};
col_type = string(col_type);
gb1_idx = find(strcmp(col_type,'gb1'));
gb2_idx = find(strcmp(col_type,'gb2'));
pb1_idx = find(strcmp(col_type,'pb1'));
pb2_idx = find(strcmp(col_type,'pb2'));

check_EEG_event(gb1_idx).continue = 0;
check_EEG_event(gb2_idx-1).continue = 0;
check_EEG_event(gb2_idx).continue = 0;
check_EEG_event(pb1_idx).continue = 0;
check_EEG_event(pb2_idx-1).continue = 0;
check_EEG_event(pb2_idx).continue = 0;



% MARK SESSION OVERLAP
% -------------------------------------------------------------------------

for i = 1:length(check_EEG_event)
    check_EEG_event(i).overlaps_next = '                    ';
end

for i = 1:length(check_EEG_event)-1
    this_lat = check_EEG_event(i).latency;
    next_lat = check_EEG_event(i+1).latency;
    this_dur = check_EEG_event(i).refDuration;
    if this_lat + this_dur > next_lat
        check_EEG_event(i).overlaps_next = '-------';
    end
end

dis('act','Updated the structure with inputs, check if ok','n');

open check_EEG_event


%% generate a final_EEG_event

final_EEG_event = check_EEG_event;

% add 'finalDuration' and 'idx' field
for i = 1:length(final_EEG_event)
    continueVal = final_EEG_event(i).continue;
    if continueVal == 1
        final_EEG_event(i).finalDuration = final_EEG_event(i).calDuration - 1;
    elseif continueVal == 0
        final_EEG_event(i).finalDuration = final_EEG_event(i).refDuration;
    else
        errordlg('Continue field contains invalid values!','Error','modal');
        error('>> Continue field contains invalid values')
    end

    final_EEG_event(i).idx = i;
end


% FINAL CHECK IF SESSION OVERLAPS
% -------------------------------------------------------------------------
for i = 1:length(final_EEG_event)
    final_EEG_event(i).overlaps_next = '                    ';
end

for i = 1:length(final_EEG_event)-1
    this_lat = final_EEG_event(i).latency;
    next_lat = final_EEG_event(i+1).latency;
    this_dur = final_EEG_event(i).finalDuration;
    if this_lat + this_dur > next_lat
        final_EEG_event(i).overlaps_next = '-------';
    end
end

dis('act', 'Do a final check, proceed if ok','n');

open final_EEG_event

%% tidy up data  >>  remove unused channels >>  trim start-end  >> manually save data

temp_EEG_event = final_EEG_event;

% remove 'calDuration', 'refDuration', 'continue', 'overlaps_next' fields
temp_EEG_event = rmfield(temp_EEG_event, {'calDuration', 'refDuration', 'continue', 'overlaps_next'});

% copy back to EEG.event
EEG.event = temp_EEG_event;

% copy back to EEG.urevent
EEG.urevent = EEG.event;
EEG.urevent = rmfield(EEG.urevent, 'urevent'); %... EEG.urevent doens't have 'urevent' field

% save it as csv
all_sessions = struct2table(EEG.urevent);

if isfile('all_sessions.csv')
    msg = sprintf('File already exist, proceed to replacing the old one?');
    choice = questdlg(msg, ...
        'Confirm proceed', ...
        'Yes','NO'); 
    switch choice
        case 'Yes'
            proceed = true;
        case 'NO'
            proceed = false;
    end
else
    proceed = true;
end

if proceed
    writetable(all_sessions, 'all_sessions.csv');  
end


% remove unused channels
EEG = pop_select( EEG, 'channel',config.used_channels);

% trim start-end CONTINUE
start_idx = 1;
end_idx = length(EEG.event);
start_pt = EEG.event(start_idx).latency;
end_pt = EEG.event(end_idx).latency + EEG.event(end_idx).finalDuration;
keep_data = [start_pt, end_pt];
EEG = pop_select( EEG, 'point',keep_data );
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 5,'gui','off');

% Manually save data
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2, 'setname', 'corrected raw', 'gui','off');
eeglab redraw;

dis('act','Save dataset as: corrected_raw.set','n')



