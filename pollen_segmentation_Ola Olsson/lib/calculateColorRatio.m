function ratio = calculateColorRatio(img, targetColor)

    % Convert RGB image to a matrix (3D array)
    imgMatrix = double(img);

    % Extract the dimensions of the image
    [rows, cols, ~] = size(imgMatrix);

    % Reshape the image matrix to a 2D matrix for easier manipulation
    imgMatrix2D = reshape(imgMatrix, rows * cols, 3);

    % Convert the target color to double for comparison
    targetColor = double(targetColor);

    % Calculate the Euclidean distance between each pixel color and the target color
    distances = sqrt(sum((imgMatrix2D - targetColor) .^ 2, 2));

    % Count the number of pixels that match the target color
    matchingPixels = sum(distances <= 75);

    % Calculate the ratio of matching pixels to total pixels
    totalPixels = rows * cols;
    ratio = matchingPixels / totalPixels;
end


