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
    
    % Mode flags
    editMode = false;
    deleteMode = false;

    % --- GUI Layout Parameters ---
    button_width = 120;
    button_height = 40;
    button_gap = 10;
    
    % Grid layout: 2 columns for code buttons
    buttons_per_row = 2;
    num_buttons = numel(buttons);
    
    % Calculate grid positions
    num_rows_of_buttons = ceil(num_buttons / buttons_per_row);
    
    % Calculate figure size
    min_fig_width = 300;
    min_fig_height = 150;
    
    % Width: 2 columns of buttons + gaps
    fig_width = 2 * button_width + 3 * button_gap; 
    
    % Height: Control row + button rows + gaps
    fig_height = (1 + num_rows_of_buttons) * (button_height + button_gap) + button_gap;
    
    fig_width = max(fig_width, min_fig_width);
    fig_height = max(fig_height, min_fig_height);
    
    % Check if figure already exists
    hFig = findall(0, 'Type', 'figure', 'Tag', 'EditableButtonLauncher');
    if ~isempty(hFig)
        figure(hFig); % Bring existing GUI to front
        % Update the existing figure with current data
        setappdata(hFig, 'buttons', buttons);
        setappdata(hFig, 'editMode', editMode);
        setappdata(hFig, 'deleteMode', deleteMode);
        updateInterface(hFig);
        return;
    end
    
    % Create figure
    hFig = figure('Name', 'Editable Button Launcher', 'Tag', 'EditableButtonLauncher', ...
        'MenuBar', 'none', 'ToolBar', 'none', 'Position', [300 300 fig_width fig_height], ...
        'Resize', 'on', 'ResizeFcn', @(src,evt)resizeFigureCallback(src, evt));
    
    % Store variables in figure's application data
    setappdata(hFig, 'buttons', buttons);
    setappdata(hFig, 'editMode', editMode);
    setappdata(hFig, 'deleteMode', deleteMode);
    setappdata(hFig, 'configFile', configFile);
    
    % Create UI components
    createUIComponents(hFig);
    
    % Create buttons
    createCodeButtons(hFig);
end

function createUIComponents(hFig)
    % Create all UI components and store their handles
    
    % Get figure dimensions
    fig_pos = get(hFig, 'Position');
    fig_width = fig_pos(3);
    fig_height = fig_pos(4);
    
    % Get stored data
    editMode = getappdata(hFig, 'editMode');
    deleteMode = getappdata(hFig, 'deleteMode');
    
    button_width = 120;
    button_height = 40;
    button_gap = 10;
    
    % Position control buttons in first row (Add, Edit, Delete)
    % Each button takes 1/3 of the control width
    individual_control_width = (fig_width - 4 * button_gap) / 3;
    
    % Add Button
    addBtn = uicontrol('Style', 'pushbutton', 'String', 'Add Button', ...
        'Position', [button_gap, fig_height - button_height - button_gap, individual_control_width, button_height], ...
        'FontSize', 10, 'FontWeight', 'bold', 'Tag', 'controlButton', ...
        'Callback', @(src,evt)addNewButton(hFig));
    
    % Edit Button
    editBtn = uicontrol('Style', 'pushbutton', 'String', 'Edit OFF', ...
        'Position', [2 * button_gap + individual_control_width, fig_height - button_height - button_gap, individual_control_width, button_height], ...
        'FontSize', 10, 'FontWeight', 'bold', 'Tag', 'controlButton', ...
        'Callback', @(src,evt)toggleEditMode(hFig, src));
    
    % Delete Button
    deleteBtn = uicontrol('Style', 'pushbutton', 'String', 'Delete OFF', ...
        'Position', [3 * button_gap + 2 * individual_control_width, fig_height - button_height - button_gap, individual_control_width, button_height], ...
        'FontSize', 10, 'FontWeight', 'bold', 'Tag', 'controlButton', ...
        'Callback', @(src,evt)toggleDeleteMode(hFig, src));
    
    % Store button handles
    setappdata(hFig, 'addButton', addBtn);
    setappdata(hFig, 'editButton', editBtn);
    setappdata(hFig, 'deleteButton', deleteBtn);
    
    % Update button appearances based on modes
    if editMode
        set(editBtn, 'String', 'Edit ON', 'BackgroundColor', [1 0.8 0.8]);
    else
        set(editBtn, 'String', 'Edit OFF', 'BackgroundColor', [0.9 0.9 0.9]);
    end
    
    if deleteMode
        set(deleteBtn, 'String', 'Delete ON', 'BackgroundColor', [1 0.8 0.8]);
    else
        set(deleteBtn, 'String', 'Delete OFF', 'BackgroundColor', [0.9 0.9 0.9]);
    end
end

function createCodeButtons(hFig)
    % Create only the code buttons (not control buttons)
    
    % Get stored data
    buttons = getappdata(hFig, 'buttons');
    editMode = getappdata(hFig, 'editMode');
    deleteMode = getappdata(hFig, 'deleteMode');
    
    % Clear existing code buttons only (preserve control buttons)
    childHandles = get(hFig, 'Children');
    codeButtonHandles = childHandles(arrayfun(@(h) isequal(get(h, 'Tag'), 'codeButton'), childHandles));
    delete(codeButtonHandles);
    
    % GUI layout parameters
    button_width = 120;
    button_height = 40;
    button_gap = 10;
    buttons_per_row = 2;
    
    num_buttons = numel(buttons);
    fig_pos = get(hFig, 'Position');
    fig_width = fig_pos(3);
    fig_height = fig_pos(4);
    
    % Create buttons in 2-column grid
    % Starting below the control buttons row
    for i = 1:num_buttons
        % Calculate grid position
        row = floor((i-1) / buttons_per_row);
        col = mod(i-1, buttons_per_row);
        
        % Position buttons starting from second row
        xpos = button_gap + col * (button_width + button_gap);
        ypos = fig_height - (2 * button_height + 2 * button_gap) - row * (button_height + button_gap);
        
        if editMode || deleteMode
            if deleteMode
                callback = @(src,evt)deleteButton(hFig, i);
            else
                callback = @(src,evt)editButtonCode(hFig, i);
            end
        else
            callback = @(src,evt)evalin('base', buttons{i}.code);
        end
        
        uicontrol('Style', 'pushbutton', 'String', buttons{i}.name, ...
            'Position', [xpos ypos button_width button_height], ...
            'FontSize', 12, 'Tag', 'codeButton', ...
            'Callback', callback);
    end
end

function updateInterface(hFig)
    % Update the entire interface without recreating the figure
    % Update control buttons
    updateControlButtons(hFig);
    
    % Update code buttons
    createCodeButtons(hFig);
    
    % Resize figure to fit content
    resizeFigureToFitButtons(hFig);
end

function updateControlButtons(hFig)
    % Update only the control buttons (don't recreate them)
    
    % Get stored data
    editMode = getappdata(hFig, 'editMode');
    deleteMode = getappdata(hFig, 'deleteMode');
    
    % Get button handles
    editBtn = getappdata(hFig, 'editButton');
    deleteBtn = getappdata(hFig, 'deleteButton');
    
    % Update button appearances based on modes
    if editMode
        set(editBtn, 'String', 'Edit ON', 'BackgroundColor', [1 0.8 0.8]);
    else
        set(editBtn, 'String', 'Edit OFF', 'BackgroundColor', [0.9 0.9 0.9]);
    end
    
    if deleteMode
        set(deleteBtn, 'String', 'Delete ON', 'BackgroundColor', [1 0.8 0.8]);
    else
        set(deleteBtn, 'String', 'Delete OFF', 'BackgroundColor', [0.9 0.9 0.9]);
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
    
    % Recreate code buttons with new callbacks
    createCodeButtons(hFig);
end

function toggleDeleteMode(hFig, deleteBtn)
    % Toggle delete mode
    deleteMode = getappdata(hFig, 'deleteMode');
    deleteMode = ~deleteMode;
    setappdata(hFig, 'deleteMode', deleteMode);
    
    % Update button label
    if deleteMode
        set(deleteBtn, 'String', 'Delete ON', 'BackgroundColor', [1 0.8 0.8]);
    else
        set(deleteBtn, 'String', 'Delete OFF', 'BackgroundColor', [0.9 0.9 0.9]);
    end
    
    % Recreate code buttons with new callbacks
    createCodeButtons(hFig);
end

function addNewButton(hFig)
    % Open dialog to add new button
    % Create edit dialog with empty fields
    dlgFig = figure('Name', 'Add New Button', ...
        'MenuBar', 'none', 'ToolBar', 'none', ...
        'Position', [400 400 500 400], 'Resize', 'on');
    
    % Input fields for name and code
    uicontrol('Style', 'text', 'String', 'Button Name:', ...
        'Position', [20 360 100 20], 'FontSize', 12);
    
    nameEdit = uicontrol('Style', 'edit', 'String', '', ...
        'Position', [130 360 350 20], 'FontSize', 12);
    
    uicontrol('Style', 'text', 'String', 'Button Code:', ...
        'Position', [20 330 100 20], 'FontSize', 12);
    
    codeEdit = uicontrol('Style', 'edit', 'String', '', ...
        'Position', [20 80 460 240], 'FontSize', 12, ...
        'Max', 100000, 'HorizontalAlignment', 'left', ...
        'BackgroundColor', [1 1 0.9]);
    
    % Confirm button
    confirmBtn = uicontrol('Style', 'pushbutton', 'String', 'Confirm', ...
        'Position', [200 30 100 30], 'FontSize', 12, ...
        'Callback', @(src,evt)saveNewButton(dlgFig, hFig, nameEdit, codeEdit));
    
    % Cancel button
    cancelBtn = uicontrol('Style', 'pushbutton', 'String', 'Cancel', ...
        'Position', [320 30 100 30], 'FontSize', 12, ...
        'Callback', @(src,evt)close(dlgFig));
end

function saveNewButton(dlgFig, hFig, nameEdit, codeEdit)
    % Save new button
    newName = get(nameEdit, 'String');
    newCode = get(codeEdit, 'String');
    
    % Validate input
    if isempty(newName) || isempty(newCode)
        questdlg('Both name and code are required!', 'Validation Error', 'OK');
        return;
    end
    
    % Add new button to array
    buttons = getappdata(hFig, 'buttons');
    newButton = struct('name', newName, 'code', newCode);
    buttons{end+1} = newButton;
    
    % Save to config file
    configFile = getappdata(hFig, 'configFile');
    save(configFile, 'buttons');
    
    % Update stored buttons
    setappdata(hFig, 'buttons', buttons);
    
    % Close dialog
    close(dlgFig);
    
    % Update interface
    updateInterface(hFig);
end

function deleteButton(hFig, buttonIndex)
    % Confirm deletion
    buttons = getappdata(hFig, 'buttons');
    buttonName = buttons{buttonIndex}.name;
    
    response = questdlg(['Are you sure you want to delete button "' buttonName '"?'], ...
        'Confirm Deletion', 'Yes', 'No', 'No');
    
    if strcmp(response, 'Yes')
        % Remove button from array
        buttons(buttonIndex) = [];
        
        % Save to config file
        configFile = getappdata(hFig, 'configFile');
        save(configFile, 'buttons');
        
        % Update stored buttons
        setappdata(hFig, 'buttons', buttons);
        
        % Update interface
        updateInterface(hFig);
    end
end

function resizeFigureToFitButtons(hFig)
    % Resize the figure to fit all buttons properly
    buttons = getappdata(hFig, 'buttons');
    num_buttons = numel(buttons);
    
    % GUI layout parameters
    button_width = 120;
    button_height = 40;
    button_gap = 10;
    buttons_per_row = 2;
    
    % Calculate grid positions
    num_rows_of_buttons = ceil(num_buttons / buttons_per_row);
    
    % Calculate figure size
    min_fig_width = 300;
    min_fig_height = 150;
    
    % Width: 2 columns of buttons + gaps
    fig_width = 2 * button_width + 3 * button_gap; 
    
    % Height: Control row + button rows + gaps
    fig_height = (1 + num_rows_of_buttons) * (button_height + button_gap) + button_gap;
    
    fig_width = max(fig_width, min_fig_width);
    fig_height = max(fig_height, min_fig_height);
    
    % Get current position and update size
    current_pos = get(hFig, 'Position');
    new_pos = [current_pos(1), current_pos(2), fig_width, fig_height];
    set(hFig, 'Position', new_pos);
end

function resizeFigureCallback(src, evt)
    % Handle figure resize events
    % Reposition control buttons when figure is resized
    hFig = src;
    
    % Get new figure dimensions
    fig_pos = get(hFig, 'Position');
    fig_width = fig_pos(3);
    fig_height = fig_pos(4);
    
    % Get control button handles
    addBtn = getappdata(hFig, 'addButton');
    editBtn = getappdata(hFig, 'editButton');
    deleteBtn = getappdata(hFig, 'deleteButton');
    
    % Reposition control buttons
    button_height = 40;
    button_gap = 10;
    
    % Position control buttons in first row (Add, Edit, Delete)
    individual_control_width = (fig_width - 4 * button_gap) / 3;
    
    % Add Button
    set(addBtn, 'Position', [button_gap, fig_height - button_height - button_gap, individual_control_width, button_height]);
    
    % Edit Button
    set(editBtn, 'Position', [2 * button_gap + individual_control_width, fig_height - button_height - button_gap, individual_control_width, button_height]);
    
    % Delete Button
    set(deleteBtn, 'Position', [3 * button_gap + 2 * individual_control_width, fig_height - button_height - button_gap, individual_control_width, button_height]);
    
    % Recreate code buttons to adjust their positions
    createCodeButtons(hFig);
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
    
    % Validate input
    if isempty(newName) || isempty(newCode)
        questdlg('Both name and code are required!', 'Validation Error', 'OK');
        return;
    end
    
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
    
    % Update interface
    updateInterface(hFig);
end