function dis(icon, msg, new_line)
arguments
    icon char = ''
    msg char = ''
    new_line char = ''
end

    % try
    %     msg = char(msg);
    % catch
    % end
    
    if strcmp(icon, 'info')
        i_symbol = '[i] ';
    elseif strcmp(icon, 'action') || strcmp(icon, 'act')
        i_symbol = '[>] ';
    else
        i_symbol = '';
    end

    if strcmp(new_line,'n')
        fprintf('\n%s%s\n',i_symbol,msg)
    else
        fprintf('%s%s\n',i_symbol,msg)
    end
end