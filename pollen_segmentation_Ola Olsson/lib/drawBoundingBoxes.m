function img_with_boxes = drawBoundingBoxes(image, bboxes, lwd)
    pkg load image;
    img_with_boxes = image;
    color = [255,0,0];

    fieldNames = fieldnames(bboxes);
    for i = 1:length(fieldNames)
        xField = fieldNames{i};
        boxObject = bboxes.(xField);
        bbox = boxObject.bbox;
        y1 = bbox(1);
        y2 = bbox(2);
        x1 = bbox(3);
        x2 = bbox(4);
        boxLabel = boxObject.label;
        centroid = boxObject.centroid;


        % Draw top line
        img_with_boxes(y1:y1+lwd, x1:x2, 2:3) = 0;
        img_with_boxes(y1:y1+lwd, x1:x2, 1) = 255;
        % Draw bottom line
        img_with_boxes(y2-lwd:y2, x1:x2, 2:3) = 0;
        img_with_boxes(y2-lwd:y2, x1:x2, 1) = 255;
        % Draw left line
        img_with_boxes(y1:y2, x1:x1+lwd, 2:3) = 0;
        img_with_boxes(y1:y2, x1:x1+lwd, 1) = 255;
        % Draw right line
        img_with_boxes(y1:y2, x2-lwd:x2, 2:3) = 0;
        img_with_boxes(y1:y2, x2-lwd:x2, 1) = 255;

         % TODO: Add labelling.
    end
end
