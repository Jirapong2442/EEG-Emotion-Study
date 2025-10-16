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

