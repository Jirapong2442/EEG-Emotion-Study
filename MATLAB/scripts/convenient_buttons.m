% --- Configurable Button Definitions ---
% Add or edit buttons here: each struct has a 'name' and 'code' field.
buttons = {
    struct('name', 'eeglab redraw', 'code', 'eeglab redraw'),
    struct('name', 'load savepoint', 'code', ...
        ['temp.backup_name = input(''Enter the field name: '', ''s'');' ...
        'if isfield(savepoint, temp.backup_name),' ...
        'EEG = savepoint.(temp.backup_name);' ...
        'disp([''## EEG assigned from backup.'' temp.backup_name]);' ...
        'else,' ...
        'error([''Field "'' temp.backup_name ''" does not exist in backup.'']);' ...
        'end'])
};

% EXAMPLES:
% buttons = {
%     struct('name', 'Say Hello', 'code', 'disp("Hello, world!")'),
%     struct('name', 'Show Date', 'code', 'disp(datestr(now))'),
%     struct('name', 'Run Script', 'code', 'run("notes/notes_analysis.m")'),
%     struct('name', 'Plot Example', 'code', ['x = 0:0.1:2*pi;\n', ...
%         'plot(x, sin(x));\n', ...
%         'title("Sine Wave")']),
%     struct('name', 'Message Box', 'code', 'msgbox("Button pressed!")'),
%     struct('name', 'Another Button', 'code', 'disp("Another action")'),
%     struct('name', 'More', 'code', 'disp("More code here")'),
%     struct('name', 'Custom', 'code', ['a = 5;\nb = 10;\ndisp(a+b)']),
% };

% --- Configurable Minimum Window Size ---
min_fig_width = 300;  % Minimum width in pixels
min_fig_height = 100; % Minimum height in pixels

% --- GUI Layout Parameters ---
buttons_per_col = 5;
button_width = 120;
button_height = 40;
button_gap = 10;

num_buttons = numel(buttons);
num_cols = ceil(num_buttons / buttons_per_col);
num_rows = min(buttons_per_col, num_buttons);

fig_width = num_cols * (button_width + button_gap) + button_gap;
fig_height = num_rows * (button_height + button_gap) + button_gap;

fig_width = max(fig_width, min_fig_width);
fig_height = max(fig_height, min_fig_height);

hFig = findall(0, 'Type', 'figure', 'Tag', 'QuickButtonLauncher');
if ~isempty(hFig)
    figure(hFig); % Bring existing GUI to front
    return;       % Do not create a new one
end

hFig = figure('Name', 'Quick Button Launcher', 'Tag', 'QuickButtonLauncher', ...
    'MenuBar', 'none', 'ToolBar', 'none', 'Position', [300 300 fig_width fig_height], ...
    'Resize', 'on', 'ResizeFcn', @(src,evt)set(src, 'Position', enforceMinSize(src.Position, min_fig_width, min_fig_height)));

for i = 1:num_buttons
    col = floor((i-1)/buttons_per_col);
    row = mod((i-1), buttons_per_col);
    xpos = button_gap + col * (button_width + button_gap);
    ypos = fig_height - button_gap - button_height - row*(button_height + button_gap);
    uicontrol('Style', 'pushbutton', 'String', buttons{i}.name, ...
        'Position', [xpos ypos button_width button_height], ...
        'FontSize', 12, ...
        'Callback', @(src,evt)evalin('base', buttons{i}.code));
end

function pos = enforceMinSize(pos, minW, minH)
    pos(3) = max(pos(3), minW);
    pos(4) = max(pos(4), minH);
end

% --- Instructions ---
% To add a button, add a new struct to the 'buttons' cell array above.
% The 'code' field can be any MATLAB code (single or multiline, or a script/function call).
% Multiline code can be separated by '\n' or by using [ ... ] to concatenate lines.





% DEV
% cleaner cmd window
dev.temp_script_name = "convenient_buttons";
if ~isfield(dev, 'clean')|| ~dev.clean
    fprintf('\n## %s.m loaded\n', dev.temp_script_name);
end