function sav(dir, var, ext)
arguments
    dir char = ''
    var char = ''
    ext char = ''
end
    if isempty(ext)
        error('Unknown file extension!');
    end

    file_path = fullfile(dir, [var, '.', ext]);
    disp(file_path)
    
    proceed = false;
    if isfile(file_path)
        msg = sprintf('File already exist, proceed to replacing the old one?');
        choice = questdlg(msg, ...
            'Confirm proceed', ... % gui title
            'Yes','NO'); % the 2nd 'No' here is the default option, press enter to select this default
        switch choice
            case 'Yes'
                proceed = true;
            case 'NO'
                proceed = false;
        end
    else
        proceed = true;
    end

    if proceed
        save(file_path,var);
    end
        
end