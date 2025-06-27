% Define variables
localFolder = 'C:\Users\CUHK-ARHOME-054\Desktop\Follow up Wonjis FYP';
remoteURL = 'https://github.com/Jirapong2442/EEG-Emotion-Study/EEG_scripts.git';
branchName = 'main'; % Change if your branch is not 'main'

% Change directory to your folder
cd(localFolder);

% Remove existing 'origin' if it exists (ignore error)
system('git remote remove origin');

% Add the new remote
system(['git remote add origin ', remoteURL]);

% Initialize git repository if not present
if ~isfolder(fullfile(localFolder, '.git'))
    repo = gitrepo(localFolder);
else
    repo = gitrepo(localFolder);
end

% % Try to add remote, ignore error if it already exists
% try
%     addRemote(repo, "origin", remoteURL);
% catch
%     % Remote probably already exists; ignore
% end

% % Stage all files in the main folder and subfolders, excluding .git directory

ONLY_THIS_FOLDER = 'C:\Users\CUHK-ARHOME-054\Desktop\Follow up Wonjis FYP\MATLAB\scripts';

folderToAdd = ONLY_THIS_FOLDER; % Specify the folder you want to add
allFiles = dir(fullfile(folderToAdd, '**', '*'));
allFiles = allFiles(~[allFiles.isdir]); % Exclude directories
for k = 1:length(allFiles)
    % Exclude files in the .git directory
    if ~contains(allFiles(k).folder, fullfile(localFolder, '.git'))
        add(repo, fullfile(allFiles(k).folder, allFiles(k).name));
    end
end

disp('Staged all files in the main folder and subfolders (excluding .git).')

% remove .git in this current directory
% rmdir('.git', 's')