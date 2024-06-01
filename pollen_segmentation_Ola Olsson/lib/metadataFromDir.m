function tileStruct = metadataFromDir(srcPath)
    % Check if the source path exists
    if exist(srcPath, 'dir') ~= 7
        error('Source path does not exist or is not a directory.');
    end

    % Get a list of all files and folders in the source path
    dirInfo = dir(srcPath);

    % Initialize cell array to store image filenames
    fileNames = {};

    pattern = '^.*X(\d+)_Y(\d+)_Z(-?\d+).*\.jpg$';

    % Loop through each entry in the directory
    for i = 1:numel(dirInfo)
        % Skip directories and special entries
        if dirInfo(i).isdir || startsWith(dirInfo(i).name, '.')
            continue;
        end

        % Check if the filename matches the expected format for images
        if ~isempty(regexp(dirInfo(i).name, pattern, 'once'))
            fileNames{end+1} = dirInfo(i).name;
        end
    end

    % Initialize struct to store filenames by x_y position
    tileStruct = struct();

    % Loop through each image filename
    for i = 1:numel(fileNames)
        fileName = fileNames{i};
        tokens = regexp(fileNames{i}, pattern, 'tokens');

        % Extract x_y position from the filename
        xPosition = str2double(tokens{1}{1});  % Assuming x position is second part
        yPosition = str2double(tokens{1}{2}); % Assuming y position is third part
        zPosition = str2double(tokens{1}{3});
        zsFieldName = ['Z', num2str(zPosition)];
        cellName = ['X' num2str(xPosition) '_Y' num2str(yPosition)];

        % Create or update struct field for x_y position
        if isfield(tileStruct, cellName)
            % Append filename to existing struct field
            tileStruct.(cellName).filenames.(zsFieldName) = {fileName};
        else
            % Create new struct field and add filename
            tileStruct.(cellName).filenames.(zsFieldName) = {fileName};
            tileStruct.(cellName).bboxes = [];
            tileStruct.(cellName).stackedImg = "";
        end
    end
endfunction
