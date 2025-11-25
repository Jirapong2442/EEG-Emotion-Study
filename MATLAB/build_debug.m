txt = "ASD123hhh";
disp(lower(txt))

%%
config();

[bad_channels, reject_segments] = pp_vars('g2p_1');
disp(reject_segments)

%%

test = "asdasd ,asdasd";
disp(string(test))
disp(class(char(test)))

%%

caller.my_var = 'asd';
disp(evalin('caller','my_var'))

%%
numel(EEG.event)
%%
fprintf('test')
disp('hey')


%%
EEG.event = orderfields(EEG.event, [4,1:3]); % reorder 'keep' field to 1st column
disp('hone')


%%
% Example structure array
S(1).value = 3;
S(2).value = 5;
S(3).value = 9;
S(4).value = 15;

% Check if the field 'value' is sorted in ascending order
values = [S.value];
isSorted = issorted(values, 'ascend');

if isSorted
    disp('The field is sorted in ascending order.');
else
    disp('The field is NOT sorted in ascending order.');
end

%%

disp('[>] test')


%%

[num_channels, num_timepoints] = size(EEG.data);
disp(num_channels)
disp(num_timepoints)


%% JUST ADD NEW LINE IN STRUCT

% CHANGE HERE
struct_name = ALLEEG(3).chanlocs

fields = fieldnames(struct_name); % get field names
newindex = length(struct_name) + 1; % new index location

% Create a struct with all fields empty
emptyStruct = struct();
for i = 1:numel(fields)
    emptyStruct.(fields{i}) = [];
end

% assign empty struct back
struct_name(newindex) = emptyStruct;
disp('done')


%%
fields = fieldnames(ALLEEG(3).chanlocs);
for i = 1:length(fields)
    ALLEEG(3).chanlocs(end+1).(fields{i}) = [];
end

%% JUST INSERT ONE MORE LINE AT THE END OF A STRUCTURE...

struct_name = ALLEEG(3).chanlocs;

fields = fieldnames(ALLEEG(3).struct_name);
ALLEEG(3).struct_name(end+1).(fields{1}) = [];

%%

str = 'test_start';
disp(contains(str, 'start', 'IgnoreCase', true));

%%

%%

EEG_event_temp = EEG.event;
save_var('EEG_event_type');

%%


latency = [EEG.event.latency];
durationInMs = [EEG.event.durationInMs];
keep = [latency; latency+durationInMs]';


%%
for i = 1:length(EEG.event)
    EEG.event(i).durationInMs = EEG.event(i).durationInMs * 1000
end

%%

% Get a cell array of all 'type' values
eventTypes = {EEG.event.type};

% Find indices where the type is exactly 'boundary'
boundaryIdx = find(strcmp(eventTypes, 'boundary'));

% Extract the 'latency' values at those indices
boundaryLatencies = [EEG.event(boundaryIdx).latency];

lower = floor(boundaryLatencies);
upper = ceil(boundaryLatencies);

session_periods = [upper(1:end-1); lower(2:end)]';



%%

disp(EEG.data(end,1:200))

%%
EEG = pop_loadset('filename','tt_rej_segments.set','filepath','C:\\Users\\RaymondTeam\\Desktop\\EEE\\ALL_DATA\\G2P_1\\');
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );

%%

EEG = pop_select( EEG, 'channel',{'F5','FZ', 'AF4'});

%%

review = '';
if isempty(pp_vars.bad_channels)
    review = 'no';
else
    msg = sprintf('%s.bad_channels already exist, need review?',subject_index);
    choice = questdlg(msg, ...
        'Confirm', ...
        'Yes','No','No'); % the 2nd 'No' here is the default option, press enter to select this default
    switch choice
        case 'Yes'
            review = 'yes';
        case 'No'
            review = 'no';
    end
end

if strcmp(review,'yes')
    disp('hi')
else % no review
end


%%

pop_eegplot( EEG, 1, 1, 1);

%% tt_rej_bad_chans

EEG = pop_loadset('filename','tt_rej_bad_chans.set','filepath','C:\\Users\\RaymondTeam\\Desktop\\EEE\\ALL_DATA\\G2P_1\\');
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );

%%

ch = ["a", "b"];       % 'ab'
cellCh = cellstr(ch) % {'a';'b'}

c = {'a','b'};
str = string(c)
str = char(c)

disp('hh')
%%

a = 'a';
if a == true
    disp('yes')
else
    disp('no')
end

%% NOTE

~isequal(pp_vars.bad_channels,ori_bad_chans) % compare sets 'isequal'

%% NOTE
errordlg('An error occurred!','Error','modal');

%%

errordlg('mod_bad_chans contain invalid values! Change to proceed','Error','modal');

%%

a = [EEG.event.latency]
b = floor(diff(a)/1000)


%%

config = config_fn();
dir = fullfile(config.dir.all_data,'G2P_1','g2p_1_vid_duration.csv');
T = readtable('dir');

%%

[file, dir] = uigetfile('*.csv'); % only show csv
cd(dir);
pv = readtable(file);

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
gb1 = table({'gb1'},18000,'VariableNames',{'video', 'duration_ms_'});
gb2 = table({'gb2'},18000,'VariableNames',{'video', 'duration_ms_'});
pb1 = table({'pb1'},18000,'VariableNames',{'video', 'duration_ms_'});
pb2 = table({'pb2'},18000,'VariableNames',{'video', 'duration_ms_'});

% classify experiment group g2p / p2g
group = upper(file(1:3));

if strcmp(group,'G2P')
    v = [gb1;gv;gb2; pb1;pv;pb2];
elseif strcmp(group,'P2G')
    v = [pb1;pv;pb2; gb1;gv;gb2];
end



%%

for i = 1:size(pv,1)
    pv.video{i} = ['p' num2str(i)];
end

%%

a = 123;
b = num2str(a)
c = string(a)

% bruh...


%%

size(EEG.event,2) % 2 -> count row in structure (1 -> table)

%%
length(EEG.event)

helpdlg('Incorrect row no.','error');

%%

disp('hi')
error('hi')

%%

error
disp('hi')

%%

fprintf("\n[>] Go EEG.event\n")
fprintf("[>] Keep markers by setting 'keep' to 1 for corresponding rows, then proceed\n")
fprintf("[>] No. of markers to be kept = %d\n",video_rows)

%%

keep_sum = sum([EEG.event.keep]==1)

%%

label = video_durations.video
duration = video_durations.duration_ms_
for i = 1:length({temp_EEG_event.type})
    temp_EEG_event(i).type = label(i)
    temp_EEG_event(i).durationInMs = duration(i)
end


%%

for i = 1:length(temp_EEG_event)
    temp_EEG_event(i).overlaps_next = '                    '
end

overlap = false;
for i = 1:length(temp_EEG_event)-1
    this_lat = temp_EEG_event(i).latency
    next_lat = temp_EEG_event(i+1).latency
    this_dur = temp_EEG_event(i).durationInMs
    if this_lat + this_dur > next_lat
        temp_EEG_event(i).overlaps_next = '-------';
        overlap = true;
    end
end

disp(overlap)

%%

% fill in 'calDurations'
calDurations = diff([temp_EEG_event.latency])
calDurations = [calDurations 0] % no next one for last label
calDurations = num2cell(calDurations)
[temp_EEG_event.calDuration] = calDurations{:}

% fill in 'refDurations'
duration = video_durations.duration_ms_;
for i = 1:size(video_durations,1)
    temp_EEG_event(i).refDuration = duration(i);
end

%%

rows = length(check_EEG_event);
col_continue = num2cell(ones(rows,1));
[check_EEG_event.continue] = col_continue{:};

col_type = {check_EEG_event.type}
col_type = string(col_type)
gb2_idx = find(strcmp(col_type,'gb2'))
pb2_idx = find(strcmp(col_type,'pb2'))

check_EEG_event(gb2_idx-1).continue = 0
check_EEG_event(gb2_idx).continue = 0
check_EEG_event(pb2_idx-1).continue = 0
check_EEG_event(pb2_idx).continue = 0


%%
modify_this_EEG_event.keep

duration = video_durations.duration_ms_;
label = video_durations.video;
for i = 1:size(video_durations,1)
    modify_this_EEG_event(i).type = label(i);
end

%% FOR LATER

% Segmentate 
latency = [EEG.event.latency];
finalDuration = [EEG.event.finalDuration];
keep = [latency; latency+finalDuration]';

EEG = pop_select( EEG, 'point',keep);


%%

if isempty(ori_bad_chans)
    ori_bad_chans = "None";
else
    ori_bad_chans = string(pp_vars.bad_channels);
end


ori_bad_chans = string(pp_vars.bad_channels);
mod_bad_chans = string(pp_vars.bad_channels); 


%%

~exist('pp_vars','var')


%%

dev_buttons()

%%

reject = false;
if isfield(pp_vars, 'bad_channels') % if exist
    if ~all(cellfun(@isempty, pp_vars.bad_channels)) % if not empty
        
    end
end

result = all(cellfun(@isempty, pp_vars.bad_channels))


%%
err('mod_bad_chans contain invalid values!', 'Change to proceed')

%%

msg = 'hey';
msg = ['>> ', msg];
ME = MException('custom:Error', msg);
throwAsCaller(ME)



%%
msg = 'hey'


%%

dis('act','hey','n')
dis('act', 'asdadaasdasd')

%%

a = 'aa';
dis('',a)


%%

video_rows = 3
dis('act',['asdasdasd ', string(video_rows)])


%%
video_rows
a = ['No. of markers to be kept = ', video_rows]
a = string(a)

%%
err('Incorrect no. of markers!')


%%

start_idx = 1
end_idx = length(EEG.event)

start_pt = EEG.event(start_idx).latency
end_pt = EEG.event(end_idx).latency + EEG.event(end_idx).finalDuration


%%

repelem()

%%

current_dataset_idx = CURRENTSET;

% load ref dataset
ref_dataset_file = 'chan_ref_only.set'
EEG = pop_loadset('filename',ref_dataset_file,'filepath',config.dir.MATLAB);
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0);
ref_dataset_idx = CURRENTSET;
chans = {EEG.chanlocs.labels}

% go back to current original dataset
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, ref_dataset_idx,'retrieve',current_dataset_idx,'study',0);  %from -> to

% find bad channels idx using ref dataset
chans = {EEG.chanlocs.labels}
bad_chans = pp_vars.bad_channels
[tf, bad_chans_idx] = ismember(chans,bad_chans)
if ~all(tf) % emergency err handle
    err('Somehow channels that need to be interpolated are not found in the ref dataset')
end

EEG = pop_interp(EEG, ALLEEG(ref_dataset_idx).chanlocs(bad_chans_idx), 'spherical');
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 4,'setname','chan interpolated','gui','off'); 


%%

chans = {EEG.chanlocs.labels}
bad_chans = pp_vars.bad_channels
[tf, bad_chans_idx] = ismember(chans,bad_chans)
if ~all(tf)
    err('Somehow channels that need to be interpolated are not found in the ref dataset')
end


%%

A = {'apple', 'banana', 'pear'};
B = {'pear', 'grape', 'apple', 'pear', 'banana'};
[tf, idx] = ismember(A, B)

%%

[tf, bad_chans_idx] = ismember(bad_chans, chans);
bad_chans_idx


%%


temp_chanlocs = EEG.chanlocs;

% find boundary latency values
% event_types = {EEG.event.type}
% real_idx = find(not(strcmp(event_types, 'boundary')))

% init time channel
[chans, pnts] = size(EEG.data); % Basically EEG.nbchan and EEG.pnts
time_channel = zeros(1, pnts);
idx_channel = zeros(1,pnts);

for i = 1:length(EEG.event)
    type = EEG.event(i).type;
    if ~strcmp(type,'boundary')
        latency = EEG.event(i).latency;
        finalDuration = EEG.event(i).finalDuration; % measured in ms (with 1000 Hz)
        
        % NOTE: used floor() instead of round() to prevent going off-bounds
        % (exceeding EEG.data time size)
        start_pt = floor(latency);
        stop_pt = start_pt + floor(finalDuration / 2); %... 1000 -> 500 Hz (divide by 2)
        session_pts = (stop_pt - start_pt) + 1;

        time_channel(start_pt:stop_pt) = 1:2:(1+2*(session_pts-1)); %... 1st_val + leap*(session_pts - 1)
        idx_channel(start_pt:stop_pt) = EEG.event(i).idx;
    end
end

% Put it to EEG.data
EEG.data = [EEG.data; time_channel; idx_channel];


% CORRECTING WORKSPACE VARS
%--------------------------------------------------------------------
% add 'TIMEMS' chan name
EEG.nbchan = EEG.nbchan + 2;
EEG.chanlocs = temp_chanlocs;
EEG.chanlocs(end+1).labels = 'TIMEMS';
EEG.chanlocs(end+1).labels = 'IDX';

% necessary so that creating new set won't break chanlocs
ALLEEG(end).chanlocs = EEG.chanlocs;
ALLEEG(end).nbchan = EEG.nbchan;

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname','custom time idx channels','gui','off'); 


%%

a = [1,2;3,4]

a(:,1) = [3,4]


%%
session_durations = renamevars(session_durations, 'duration_ms_','durationInMs')
rows = size(session_durations,1)
idxs = linspace(1,rows,rows)
idxs = idxs' %... row -> column
session_durations = addvars(session_durations, idxs, 'NewVariableNames', 'Idx');



%%

% add 'finalDuration' and 'Idx' field
for i = 1:length(final_EEG_event)
    final_EEG_event(i).Idx = i;
end

%%

file_path = "C:\Users\RaymondTeam\Desktop\EEE\EEG-Emotion-Study\MATLAB\support_functions\a.mat"
isfile(file_path)

% ASK TO PROCEED TO REMOVE BAD CHANNELS
% --------------------------------------------------------
msg = sprintf('File already exist, proceed to replacing the old one?');
choice = questdlg(msg, ...
    'Confirm proceed', ... % gui title
    'Yes','No'); % the 2nd 'No' here is the default option, press enter to select this default
switch choice
    case 'Yes'
        proceed = true;
    case 'No'
        proceed = 'exit';
end

%%

dir = 'C:\Users\RaymondTeam\Desktop\EEE\EEG-Emotion-Study\MATLAB\support_functions';
sav(dir,'a','mat')

% save([dir, 'a.mat'],'a')
% disp('hi')


%%


for i = 1:length(EEG.urevent)
    continueVal = final_EEG_event(i).continue;
    if continueVal == 1
        final_EEG_event(i).finalDuration = final_EEG_event(i).calDuration - 1;
    elseif continueVal == 0
        final_EEG_event(i).finalDuration = final_EEG_event(i).refDuration;
    else
        errordlg('Continue field contains invalid values!','Error','modal');
        error('>> Continue field contains invalid values')
    end

    final_EEG_event(i).Idx = i;
end


%%


temp = EEG.urevent

idx = 1
for i = 1:length(temp)
    type = temp(i).type
    if ~strcmp(type,'boundary')
        temp(i).idx = idx
        idx = idx + 1;
    end
end
open temp

%%
EEG.urevent = temp


%%

EEG = pop_loadset('filename','after_ICA.set','filepath','D:\\EEE\\ALL_DATA\\G2P_1\\');
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );

srate = EEG.srate;
pnts = EEG.pnts;
nbchan = EEG.nbchan;

epochs = ceil(pnts/srate);

epoched_data = zeros(nbchan, srate, epochs);

temp_EEG_data = EEG.data;
more_pnts = (epochs * srate) - pnts;
pnts_array = zeros(nbchan, more_pnts);
temp_EEG_data = [temp_EEG_data, pnts_array];

epoched_data = reshape(temp_EEG_data, nbchan, srate, epochs);
EEG = pop_importdata('setname','epoched data', 'data','epoched_data', 'dataformat','array');
    % ^ Simply use pop_importdata() to put the epoched data in, everything
    % else will be adjusted. It's better than forcibly subbing the
    % epoched_data to EEG.data, use their own functions for it to adjust
    % workspace vars manually.

eeglab redraw








%%
% epoched_data = reshape(temp_EEG_data, 66, 500, 1973)

EEG.data = epoched_data;

% reorganize workspace vars
EEG.epoch = struct()
for i = 1:epochs
    EEG.epoch(i).event = i;
    EEG.epoch(i).eventtype = 'none';
    EEG.epoch(i).eventlatency = 0;
    EEG.epoch(i).eventurevent = -1;
    EEG.epoch(i).eventduration = 0;
    % disp(['EEG.epoch updated to ', num2str(i)])
end

eeglab redraw


%%