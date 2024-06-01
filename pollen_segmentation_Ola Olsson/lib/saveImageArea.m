function saveImageArea(bboxes, files, dst)

    % Loop through each image file
    for i = 1:numel(files)
        % Get the current filename
        filename = files{i};

        % Read the image
        img = imread(filename);

        % Extract file parts
        [~, name, ext] = fileparts(filename);

        % Loop through each bounding box and label

        fieldNames = fieldnames(bboxes);
        for j = 1:length(fieldNames)
            xField = fieldNames{j};
            bbox = bboxes.(xField).bbox;
            boxLabel = bboxes.(xField).label;

            % Extract the region of interest (ROI) from the image
            try
               roi = img(bbox(1):bbox(2), bbox(3):bbox(4), :);
               % Construct the output filename

               if bboxes.(xField).at_edge == 1
                 output_filename = fullfile(dst, "edge/",strcat("E_", boxLabel,'_', name, ext));
               else
                 output_filename = fullfile(dst, strcat(boxLabel,'_', name, ext));
               endif

               % Write the ROI to the output file
               imwrite(roi, output_filename);

            catch
               fprintf(['IndexError when trying to segment: ' repmat(' %1.0f ',1,numel(bbox)) '\n'],bbox);
            end
        end
    end
end
