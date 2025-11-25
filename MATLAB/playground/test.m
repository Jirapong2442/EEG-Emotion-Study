
%% Symbols for disp()
disp('ACTION >> Do this please')
disp('INFO: This data contains ... ')
disp('WARNING >> Contains error...')

%%

hey = true;
if hey disp('hey'); end


%%
a = string([check_EEG_event.type]);
disp('done')
open a

%%

% a = {1,2,3; 'text', 'asd','1,23'};
open a
isempty(a)
b = all(cellfun(@isempty, a))

%%

disp('a');
return
disp('b');

%%

a = edit_bad_chans
b = reshape(a, 1, []);                        % Make into 1D row
c = b(strlength(b) > 0);                    % Remove empty strings
c

%%

C = {'Monday','Tuesday','Wednesday'};
A = cellfun(@(x) x(1:3), C, 'UniformOutput', false);
A

%%
