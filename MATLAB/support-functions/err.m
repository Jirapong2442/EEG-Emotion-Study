function err(msg, msg2, modal)
arguments
    msg char
    msg2 char = ''
    modal char = 'modal'
end
    if strcmp(modal, 'modal') % turn char to string, then compare. If comparing char, then it's element-wise, a lot of true, true, false etc.
        errordlg(msg, 'Error','modal')
    elseif strcmp(modal, 'non-modal')
        errordlg(msg, 'Error','non-modal')
    else
        error('Incorrect modal type')
    end
    
    if isempty(msg2)
        long_msg = ['WARNING >> ', msg];
    else
        long_msg = ['WARNING >> ', msg, ' ', msg2];
    end

    ME = MException('custom:Error', long_msg);
    throwAsCaller(ME)
end