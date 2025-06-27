function add_savepoint(field_name)
    % Get backup from base workspace or create new one
    if evalin('base', 'exist(''savepoint'', ''var'')')
        savepoint = evalin('base', 'savepoint');
    else
        savepoint = struct();
    end
    
    if ~isfield(savepoint, field_name)
        % Get EEG from base workspace
        EEG = evalin('base', 'EEG');
        savepoint.(field_name) = EEG;
        % Save backup back to base workspace
        assignin('base', 'savepoint', savepoint);
        fprintf('## %s savepoint added!\n', field_name);
    else
        % fprintf('Sackup already exists: backup.%s\n', field_name);
    end
end

