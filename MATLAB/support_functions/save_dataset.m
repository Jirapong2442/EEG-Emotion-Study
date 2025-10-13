function save_dataset(name)
    global ALLEEG EEG CURRENTSET
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname',name,'gui','off'); 
end