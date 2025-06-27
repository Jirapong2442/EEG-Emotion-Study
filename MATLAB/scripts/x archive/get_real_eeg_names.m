% AI

function all_folders = get_real_eeg_names(real_data_folder)
%GET_REAL_EEG_NAMES Returns sorted g* and p* folder names in the given directory
%   all_folders = get_real_eeg_names(real_data_folder)
%   Prints the names if no output is requested.

% Get all folders in the specified directory
folder_info = dir(real_data_folder);

% Filter for directories only, excluding . and ..
is_dir = [folder_info.isdir] & ~ismember({folder_info.name}, {'.', '..'});
folder_names = {folder_info(is_dir).name};

% Find g* and p* folders with numbers
g_folders = regexp(folder_names, '^g(\d+)$', 'tokens');
p_folders = regexp(folder_names, '^p(\d+)$', 'tokens');

% Extract numbers and sort
g_nums = cellfun(@(x) str2double(x{1}), g_folders(~cellfun('isempty',g_folders)));
p_nums = cellfun(@(x) str2double(x{1}), p_folders(~cellfun('isempty',p_folders)));
g_sorted = sort(g_nums);
p_sorted = sort(p_nums);

% Combine sorted folder names into a single variable
all_folders = [arrayfun(@(x) sprintf('g%d', x), g_sorted, 'UniformOutput', false), ...
               arrayfun(@(x) sprintf('p%d', x), p_sorted, 'UniformOutput', false)];

% Print all folder names if no output is requested
if nargout == 0
    for i = 1:length(all_folders)
        fprintf('%s\n', all_folders{i});
    end
    disp('done')
end

end