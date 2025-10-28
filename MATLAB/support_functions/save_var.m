function save_var(var)
    %% doesn't work
    config = config();
    folder = uigetdir('config.dir.root');
    filePath = fullfile('folder','var');
    save('config.dir.root','var')
end

