function datasource = updateDriveInfo()
    %Import Python Module for downloading Log File metadata
    import py.ConnectGoogleDrive.*

    % Only request new files from google if missing
    persistent newFile
    if isempty(newFile)
        fprintf('Polling Google Drive for new files...')
        newFile = cell(py.ConnectGoogleDrive.getFileList());
        fprintf('done\n')
    end
    files = newFile;
    
    %Convert from py.dict to struct
    files = cellfun(@struct,files,'UniformOutput',false);
    
    %Convert py.str to char
    files = cellfun(@(x) structfun(@char,x,'UniformOutput',false),...
        files,'UniformOutput',false);
    
    %Remove items without all fields present
    fields = {'id','name','md5Checksum'};
    index = cellfun(@(x) all(isfield(x,fields)),files); %Find cells missing parameters
    files = [files{index}]; %Only keep the ones with everything
    
    %Enumerate File type
    fileType = zeros(1,length(files));
    ft.ld = 1;  ft.ldx = 2;
        
    %Loop over files
    for i = 1:length(files)
        %% Identify File Type
        if strcmp(files(i).name(end-2:end),'.ld')
            fileType(i) = ft.ld;
        elseif strcmp(files(i).name(end-3:end),'.ldx')
            fileType(i) = ft.ldx;
        end
        
        %Drop extension from name
        [~,name] = fileparts(files(i).name);
        files(i).name = name;
    end
    
    %Drop files that are not log files
    files(~fileType) = []; fileType(~fileType) =[];
    
    %Sort by createdTime: Oldest First
    [~,index] = sortrows({files.createdTime}');
    files = files(index); fileType = fileType(index);
    
    %Find all unique .ld files pick the oldest one as real
    ldIndex = find(fileType==ft.ld);
    [~,ldIndexUnique] = unique({files(ldIndex).md5Checksum},'first');
    ldIndex = ldIndex(ldIndexUnique);
    
    %Match each .ld file to its .ldx file
    ldxIndex = find(fileType==ft.ldx);
    [~,ldxTemp,ldTemp] = intersect({files(ldxIndex).name},{files(ldIndex).name});
    ldIndex = ldIndex(ldTemp); ldxIndex = ldxIndex(ldxTemp);
    
    %Consolidate datasources into a paired array
    datasource = struct('OriginHash',{},'ld',{},'ldx',{},'name',{});
    
    %Start at i = length(ldIndex) to set datasource length
    for i = length(ldIndex):-1:1
        % Populate Fields in datasource
        datasource(i).OriginHash = ...
            [files(ldIndex(i)).md5Checksum files(ldxIndex(i)).md5Checksum];
        datasource(i).ld = files(ldIndex(i)).id;
        datasource(i).ldx = files(ldxIndex(i)).id;
        datasource(i).name = files(ldIndex(i)).name;
    end
  
    
    