test = temp_EEG_event

%%


% NOTE: initialize this struct my clearing it, so that duplicating first row is valid

clear test_new;
new_idx = 1;

for i = 1:numel(EEG.event)
    if test(i).myDurSeconds ~= 0
        % First entry: append 'start' to type
        test_new(new_idx) = test(i);
        test_new(new_idx).type = [num2str(test(i).type) 'start'];
        new_idx = new_idx + 1;

        % Second entry: append 'end' to type and adjust latency
        test_new(new_idx) = test(i);
        test_new(new_idx).type = [num2str(test(i).type) 'end'];
        test_new(new_idx).latency = test(i).latency + test(i).myDurSeconds * EEG.srate;
        new_idx = new_idx + 1;
    else
        % Just copy as-is
        test_new(new_idx) = test(i);
        new_idx = new_idx + 1;
    end
end
test_new = rmfield(test_new, 'urevent');
open test_new
