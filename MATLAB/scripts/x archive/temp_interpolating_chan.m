
% test2
EEG = pop_interp(EEG, ALLEEG(5).chanlocs([15  45]), 'spherical');
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 6,'setname','chan_interpolated','gui','off'); 