function topSharpnessFiles = rankedFocusPlanes(imageFiles, x)
    numImages = numel(imageFiles);
    sharpnessValues = zeros(numImages, 1);

    % Calculate sharpness values for each image
    for i = 1:numImages
        % Load image
        img = imread(imageFiles{i});

        % Convert to grayscale if needed
        if size(img, 3) > 1
            img = rgb2gray(img);
        end

        % Apply Sobel filter
        sobelImg = edge(img, 'Sobel');

        % Calculate sharpness as the sum of Sobel values
        sharpnessValues(i) = sum(sobelImg(:));
    end

    % Sort filenames based on sharpness values
    [~, sortedIndices] = sort(sharpnessValues, 'descend');
    topIndices = sortedIndices(1:min(x, numImages)); % Select top x or all if fewer

    % Get top x filenames
    topSharpnessFiles = imageFiles(topIndices);
end

