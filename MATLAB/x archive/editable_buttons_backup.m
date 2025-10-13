function editable_buttons()
    % EDITABLE BUTTON LAUNCHER
    % This script creates a GUI with buttons that can be edited at runtime.
    % In edit mode, clicking a button opens a code editor.
    % In normal mode, clicking a button executes its code.

    % --- Configurable Button Definitions ---
    % Load button configurations from file or use defaults
    configFile = 'button_config.mat';
    if exist(configFile, 'file')
        load(configFile, 'buttons');
    else
        % Default buttons
        buttons = {
            struct('name', 'eeglab redraw', 'code', 'eeglab redraw'),
            struct('name', 'clear all', 'code', 'clear all; close all; clc;'),
            struct('name', 'show date', 'code', 'disp(datestr(now))')
        };
        % Save default configuration
        save(configFile, 'buttons');
    end
    
    % Edit mode flag
    editMode = false;

    % --- GUI Layout Parameters ---
    buttons_per_col = 5;
    button_width = 120;
    button_height = 40;
    button_gap = 10;
    edit_button_width = 60;
    
    num_buttons = numel(buttons);
    num_cols = ceil(num_buttons / buttons_per_col);
    num_rows = min(buttons_per_col, num_buttons);
    
    % Calculate figure size
    min_fig_width = 300;
    min_fig_height = 150;
    fig_width = num_cols * (button_width + button_gap) + button_gap + edit_button_width + button_gap;
    fig_height = num_rows * (button_height + button_gap) + button_gap + 50; % Extra space for edit button
    
    fig_width = max(fig_width, min_fig_width);
    fig_height = max(fig_height, min_fig_height);
    
    % Check if figure already exists
    hFig = findall(0, 'Type', 'figure', 'Tag', 'EditableButtonLauncher');
    if ~isempty(hFig)
        figure(hFig); % Bring existing GUI to front
        return;       % Do not create a new one
    end
    
    % Create figure
    hFig = figure('Name', 'Editable Button Launcher', 'Tag', 'EditableButtonLauncher', ...
        'MenuBar', 'none', 'ToolBar', 'none', 'Position', [300 300 fig_width fig_height], ...
        'Resize', 'on', 'ResizeFcn', @(src,evt)set(src, 'Position', enforceMinSize(src.Position, min_fig_width, min_fig_height)));
    
    % Store variables in figure's application data
    setappdata(hFig, 'buttons', buttons);
    setappdata(hFig, 'editMode', editMode);
    setappdata(hFig, 'configFile', configFile);
    
    % Create edit toggle button
    editBtn = uicontrol('Style', 'pushbutton', 'String', 'Edit OFF', ...
        'Position', [fig_width - edit_button_width - button_gap, fig_height - 50 edit_button_width 40], ...
        'FontSize', 10, 'FontWeight', 'bold', ...
        'Callback', @(src,evt)toggleEditMode(hFig, src));
    
    % Store edit button handle
    setappdata(hFig, 'editButton', editBtn);
    
    % Create buttons
    createButtons(hFig);
end

function createButtons(hFig)
    % Get stored data
    buttons = getappdata(hFig, 'buttons');
    editMode = getappdata(hFig, 'editMode');
    
    % Clear existing buttons (if any)
    childHandles = get(hFig, 'Children');
    buttonHandles = childHandles(arrayfun(@(h) isequal(get(h, 'Tag'), 'customButton'), childHandles));
    delete(buttonHandles);
    
    % GUI layout parameters
    buttons_per_col = 5;
    button_width = 120;
    button_height = 40;
    button_gap = 10;
    
    num_buttons = numel(buttons);
    fig_pos = get(hFig, 'Position');
    fig_width = fig_pos(3);
    fig_height = fig_pos(4);
    
    % Create buttons
    for i = 1:num_buttons
        col = floor((i-1)/buttons_per_col);
        row = mod((i-1), buttons_per_col);
        xpos = button_gap + col * (button_width + button_gap);
        ypos = fig_height - button_gap - button_height - row*(button_height + button_gap) - 50; % Adjust for edit button
        
        if editMode
            callback = @(src,evt)editButtonCode(hFig, i);
        else
            callback = @(src,evt)evalin('base', buttons{i}.code);
        end
        
        uicontrol('Style', 'pushbutton', 'String', buttons{i}.name, ...
            'Position', [xpos ypos button_width button_height], ...
            'FontSize', 12, 'Tag', 'customButton', ...
            'Callback', callback);
    end
end

function toggleEditMode(hFig, editBtn)
    % Toggle edit mode
    editMode = getappdata(hFig, 'editMode');
    editMode = ~editMode;
    setappdata(hFig, 'editMode', editMode);
    
    % Update button label
    if editMode
        set(editBtn, 'String', 'Edit ON', 'BackgroundColor', [1 0.8 0.8]);
    else
        set(editBtn, 'String', 'Edit OFF', 'BackgroundColor', [0.9 0.9 0.9]);
    end
    
    % Recreate buttons with new callbacks
    createButtons(hFig);
end

function editButtonCode(hFig, buttonIndex)
    % Open dialog to edit button code
    buttons = getappdata(hFig, 'buttons');
    button = buttons{buttonIndex};
    
    % Create edit dialog
    dlgFig = figure('Name', ['Edit Button: ' button.name], ...
        'MenuBar', 'none', 'ToolBar', 'none', ...
        'Position', [400 400 500 400], 'Resize', 'on');
    
    % Input fields for name and code
    uicontrol('Style', 'text', 'String', 'Button Name:', ...
        'Position', [20 360 100 20], 'FontSize', 12);
    
    nameEdit = uicontrol('Style', 'edit', 'String', button.name, ...
        'Position', [130 360 350 20], 'FontSize', 12);
    
    uicontrol('Style', 'text', 'String', 'Button Code:', ...
        'Position', [20 330 100 20], 'FontSize', 12);
    
    codeEdit = uicontrol('Style', 'edit', 'String', button.code, ...
        'Position', [20 80 460 240], 'FontSize', 12, ...
        'Max', 100000, 'HorizontalAlignment', 'left', ...
        'BackgroundColor', [1 1 0.9]);
    
    % Confirm button
    confirmBtn = uicontrol('Style', 'pushbutton', 'String', 'Confirm', ...
        'Position', [200 30 100 30], 'FontSize', 12, ...
        'Callback', @(src,evt)saveButtonChanges(dlgFig, hFig, buttonIndex, nameEdit, codeEdit));
    
    % Cancel button
    cancelBtn = uicontrol('Style', 'pushbutton', 'String', 'Cancel', ...
        'Position', [320 30 100 30], 'FontSize', 12, ...
        'Callback', @(src,evt)close(dlgFig));
end

function saveButtonChanges(dlgFig, hFig, buttonIndex, nameEdit, codeEdit)
    % Save button changes
    newName = get(nameEdit, 'String');
    newCode = get(codeEdit, 'String');
    
    % Update buttons array
    buttons = getappdata(hFig, 'buttons');
    buttons{buttonIndex}.name = newName;
    buttons{buttonIndex}.code = newCode;
    
    % Save to config file
    configFile = getappdata(hFig, 'configFile');
    save(configFile, 'buttons');
    
    % Update stored buttons
    setappdata(hFig, 'buttons', buttons);
    
    % Close dialog
    close(dlgFig);
    
    % Recreate buttons
    createButtons(hFig);
end

function pos = enforceMinSize(pos, minW, minH)
    pos(3) = max(pos(3), minW);
    pos(4) = max(pos(4), minH);
end