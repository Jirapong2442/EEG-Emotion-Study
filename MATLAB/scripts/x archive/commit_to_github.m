% Define variables
localFolder = 'C:\Users\CUHK-ARHOME-054\Desktop\Follow up Wonjis FYP\MATLAB';
remoteURL = 'https://github.com/Jirapong2442/EEG-Emotion-Study.git';
branchName = 'main'; % Change if your branch is not 'main'

% Change directory to your folder
cd(localFolder);

% Initialize git repository if not present
if ~isfolder(fullfile(remoteURL, '.git'))
    repo = gitrepo(remoteURL);
else
    repo = gitrepo(remoteURL);
end


% Try to add remote, ignore error if it already exists
try
    addRemote(repo, "origin", remoteURL);
catch
    % Remote probably already exists; ignore
end


% Stage all files
add(repo, ".");
