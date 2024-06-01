function [OID_counter, bboxes] = segmentPollen(input, opts)

  % This code requires the Image Processing package "image" version 2.14.0
  %
  % DESCRIPTION:
  %   This function will use different image visualization tools and mathematical filters
  %   to identify possible objects of interest and return the bounding box coordinates.
  %
  %   TODO: in future this function should segment rather than detect!
  %
  % OUTPUTS:
  %   bboxes,     a struct containing the label of the object, as well as the coordinates.
  %
  % INPUTS:
  %   input,      Either a char representing the full path to a locally stored image file
  %               or the matrix representation of that image.
  % VARARGINS:
  %   se_size,    A scalar to set size of the strel used in imerode and imdilate function.
  %   min_size,   A scalar defining the minimal ratio an object of interest should cover
  %   max_size,   A scalar defining the maximal ratio an object of interest should cover
  %   checkColor, A bool value defining whether color ratio should be used to filter pollen
  %   color,      A matrix to define the exact RGB colour [255, 175, 175] for red dyed pollen.
  %   colorRatio, A scalar which defines what ratio of pixels on the image should be close to the defined color.
  %
  % For further details see:
  %   Olsson O, Karlsson M, Persson AS, et al. Efficient, automated and robust pollen analysis
  %   using deep learning. Methods Ecol Evol. 2021; 12: 850–862. https://doi.org/10.1111/2041-210X.13575
  %

  % Determine image size and type:
  OID_counter = opts.OID_counter;
  if ischar(input)
    I = imread(input); % Load image

  elseif strcmp(typeinfo(input), "uint8 matrix")
    I = input;
  endif

  area = opts.size(1)*opts.size(2);
  se = strel("disk", opts.se_size, 0); % Filter to use for dilation and eroding.
  IMG = rgb2gray(I); % Transform into grayscale
  IMG = edge(IMG, "Sobel", 0.02); % Use edge detection to amplify regions of interest
  IMG = imdilate(IMG, se); % Dilate these edges in order to circumvent the loss of weak edges.
  IMG = imfill(IMG, "holes"); % Fill the hole between edges to get areas of interest.
  IMG = imerode(IMG, se); % remove small artifacts that most likely are not pollen or NPP

  IMG = bwareafilt(IMG, [area*opts.min_size area*opts.max_size]); % The remaining areas should be between 1500 px. and 1000000 px. large. These value may need to be adapted based on the image size.
  #TODO: change the above limits based on percentages of the image.
  BW = IMG; % Use BW to create the binary mask.
  D = -bwdist(~IMG); % Create a distance matrix which calculates the distance of every pixel to the edge of an object.
  D = imhmin(D,10); % Remove shallow slopes that may exist.
  DL = watershed(D); % Use a watershed transform that creates different basins for pollen.
  labels = bwlabel(DL); % Use the watershed analysis to create individual labels of different objects.
  binary_mask = BW == 1; % Create a binary mask of where points are 1, based on the above image processing steps.
  labels(repmat(~binary_mask, [1,1])) = 0; %Overlay the labels with the mask such that black areas remain black.
  stats = regionprops(labels, "Centroid", "MajorAxisLength", "MinorAxisLength"); % Summarize the position and size of objects.

  bboxes = struct();

  % Iterate through each object
  for i = 1:size(stats, 1)
      x = stats(i).Centroid(1); % X coordinate of the center
      y = stats(i).Centroid(2); % Y coordinate of the center
      w = stats(i).MajorAxisLength;    % Width of the bounding box
      h = stats(i).MajorAxisLength;   % Height of the bounding box

      if or(w >= opts.size(1) * 0.8 , h >= opts.size(2)*0.8)
        continue
      endif

      x1 = x - w/2;
      y1 = y - h/2;

      [at_edge bbox] = edgeBox(x1, y1, w, h, opts.size(1), opts.size(2));

      if opts.checkColor
        colorContent = calculateColorRatio(I(bbox(1):bbox(2),bbox(3):bbox(4),:),opts.color);
        if  colorContent < opts.colorRatio
          continue
        endif
      endif
      bboxes.(num2str(OID_counter)).centroid = [x y];
      bboxes.(num2str(OID_counter)).at_edge = at_edge;
      bboxes.(num2str(OID_counter)).label = strcat("Object_", num2str(OID_counter));
      bboxes.(num2str(OID_counter)).minorAxis = stats(i).MinorAxisLength;
      bboxes.(num2str(OID_counter)).majorAxis = stats(i).MajorAxisLength;
      bboxes.(num2str(OID_counter)).bbox = bbox;
      OID_counter = OID_counter+1;
  endfor


  function [at_edge bbox] = edgeBox(x1, y1, w, h, xabs, yabs)

      x2 = x1+w;
      y2 = y1+h;
      at_edge = false;

      if x1 < 1
          x1 = 1;
          x2 = w;
          at_edge = true;
      endif

      if x2 > xabs
          x2 = xabs;
          x1 = xabs - w;
          at_edge = true;
      endif

      if y1 < 1
          y1 = 1;
          y2 = h;
          at_edge = true;
      endif

      if y2 > yabs
          y2 = yabs;
          y1 = yabs - h;
          at_edge = true;
      endif

      bbox = round([y1, y2, x1, x2]);

  endfunction


endfunction

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%









