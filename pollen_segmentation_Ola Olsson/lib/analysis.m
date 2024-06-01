% This Tool was developed as part of the NEPal - Project ()
% -----------------------------------------------------------
% Preferred citation:
%
% DESCRIPTION:
%  This algorithm will automatically extract objects of interest based on the
%  focus stacking algorithm by and segmentation algorithm by Ola Olsson et al.
%  For more information, please contact: robinvonallmen@hotmail.com
%
% SYNTAX:
% meta = analysis(srcDir, dstDir, metadataFile, save_stacked, ...)
% meta = analysis(srcDir, dstDir, metadataFile, save_stacked, opts1, val1, opts2, val2,...)
%
% INPUTS:
% srcDir:       PathLike string to the directory containing individual image tiles.
% dstDir:       PathLike string to the output directory where individual pollen grains will be stored.
% metadataFile: PathLIke string to the .mat file containing XYZ-Positions etc. (see sample_metadata.mat).
% save_stacked: bool value to store stacked images with bounding boxes of objects.
%
% --- Optional parameters-----
% drawBoxes:    bool value to draw bounding boxes on stacked img.
%
% alpha:        Size of focus measure window (9).
% focus:        Vector with the focus of each frame.
% nhsize:       A scalar in (0,1]. Default is 0.2. See [1] for details.
% sth:          A scalar. Default is 13. See [1] for details.
%
% ranks:        How many images from the image list should be stacked onto each other.
% se_size:      integer value defining the size of the strel used in image dilation and eroding.
% min_size:     float value between s0 and 1 defining the min area ratio an object of interest will cover.
% max_size:     float value between 0 and 1 defining the max area ratio an object of interest will cover.
% checkColor:   bool to wheter detected objects will be evaluated based on color spectra. (This is a new funciton that helped to refine pollen from NPP, but
%               it's accuracy is not tested yet).
% color:        A 3-dimensional (3x1) cell array containing the RGB value representation of the color that the image should contain.
% colorRatio:   A float value between 0 and 1 defining what ratio of pixels should be similar to the color defined above.
%
%


function metadata = analysis(srcDir, dstDir, metadataFile, save_stacked, varargin)
  pkg load image;

  opts = parseInputs(srcDir, dstDir, metadataFile, save_stacked, varargin{:});

% Loop through each X/Y position combination
  fprintf('Segmentation\n') %Process bar
  fieldNames = fieldnames(opts.metadata);
  for xIdx = 1:numel(fieldNames)
      xField = fieldNames{xIdx};
      batch = opts.metadata.(xField).filenames;% Loads the different z-planes

      % Function to handle scalar or vector outputs
      % Function to handle scalar or vector outputs
      getValues = @(x) ifelse(numel(batch.(x)) > 1, {batch.(x){1}}, batch.(x));

      % Apply the function using cellfun
      filenames = cellfun(getValues, fieldnames(batch), 'UniformOutput', false);
      filenames = fullfile(srcDir, [filenames{:}]);% full path to file

      try

        if and(opts.stacked == 1, not(opts.stackImages))
          filename = fullfile(srcDir, opts.metadata.(xField).stackedImg);
          stacked = imread(filename);
          [OID_counter, bboxes] = segmentPollen(stacked, opts);
        else
          rankedFiles = rankedFocusPlanes(filenames, opts.ranks);
          stacked = fstack(rankedFiles, opts); % Stacks images using fstack algorithm by S. Perutz (2016)
          stackedName = strcat("stacked/", xField, "_Z-STACKED.jpg");
          imwrite(stacked, fullfile(dstDir, stackedName));
          opts.metadata.(xField).stacked = stackedName;
          [OID_counter, bboxes] = segmentPollen(stacked, opts); % Extracts image labels based on Ola Olsson et al. (2021)
        endif


        opts.OID_counter = OID_counter;
        if (length(fieldnames(bboxes)) >= 1)
          if opts.savePollenImages
            saveImageArea(bboxes, filenames, dstDir); % Saves individual pollen grains on all z-planes.
          endif
          opts.metadata.(xField).bboxes = bboxes; % Stores bounding boxes in metadata

          if opts.drawBoxes
            stacked = drawBoundingBoxes(stacked, bboxes, 10); %Draws bounding boxes onto the stacked img.
          endif
        endif

        if save_stacked % Saves the stacked img with drawn bounding_boxes.
          disp("savestacked");
          imwrite(stacked, fullfile(opts.macroPath, strcat("OD_", xField,".jpg")), 'Quality', 30); % Stores focus stacked image.
        endif


        %Update Processbar:
        fprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b[%.6d/%.6d]',xIdx, numel(fieldNames));

      catch
        metadata = opts;
        fprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b[%.6d/%.6d]',xIdx, numel(fieldNames));
        break
      end_try_catch



  endfor

  metadata = opts;

  function options = parseInputs(srcDir, dstDir, meta, save_stacked, varargin)
    addpath("./lib/");
    macroPath = strcat(dstDir, "/macro");

    % Create the destination directory if it does not exist
    if ~exist(dstDir, 'dir')
        mkdir(dstDir);
    end

    if ~exist(macroPath, 'dir')
        mkdir(macroPath);
    end

    if ~exist(strcat(dstDir, "/edge"))
        mkdir(strcat(dstDir, "/edge"));
    endif


    % Determine image size and type:
    % TODO add as fields in metadata.
    options.size = [2028, 2028, 10];

    options.macroPath = macroPath;
    options.OID_counter = 0;

    input_data = inputParser();
    input_data.CaseSensitive = false;
    input_data.StructExpand = true;

    %Options for settings:
    input_data.addParameter('useFilename', false, @(x) isbool(x));
    input_data.addParameter('savePollenImages', true, @(x) isbool(x));
    input_data.addParameter('stackImages', false, @(x) isbool(x));


    %Options for fstacking algorithm:
    input_data.addParameter('alpha', 0.2, @(x) isnumeric(x) && isscalar(x) && (x>0) && (x<=1));
    input_data.addParameter('focus', 1:10, @(x) isnumeric(x) && isvector(x));
    input_data.addParameter('nhsize', 9, @(x) isnumeric(x) && isscalar(x));
    input_data.addParameter('sth', 13, @(x) isnumeric(x) && isscalar(x));
    input_data.addParameter('drawBoxes', true, @(x) isbool(x));

    %Options for object detection algorithm:
    input_data.addParameter('ranks', 10, @(x) isnumeric(x) && isscalar(x) && (x>0));
    input_data.addParameter('se_size', 7, @(x) isnumeric(x) && isscalar(x));
    input_data.addParameter('min_size', 0.001, @(x) isnumeric(x) && isvector(x)&& (x>0) && (x<=1));
    input_data.addParameter('max_size', 0.5, @(x) isnumeric(x) && isscalar(x) && (x>0) && (x<=1));
    input_data.addParameter('checkColor', true, @(x) isbool(x));
    input_data.addParameter('color', [220, 100, 150], @(x) ismatrix(x) && all(isscalar(x)) && (size(x == 3)));
    input_data.addParameter('colorRatio', 0.01, @(x) isnumeric(x) && isscalar(x) && (x>0) && (x<=1));


    %Parsing optional parameters.
    parse(input_data, varargin{:});

    options.savePollenImages = input_data.Results.savePollenImages;
    options.stackImages = input_data.Results.stackImages;
    options.alpha = input_data.Results.alpha;
    options.focus = input_data.Results.focus;
    options.nhsize = input_data.Results.nhsize;
    options.sth = input_data.Results.sth;
    options.drawBoxes = input_data.Results.drawBoxes;
    options.ranks = input_data.Results.ranks;
    options.se_size = input_data.Results.se_size;
    options.min_size = input_data.Results.min_size;
    options.max_size = input_data.Results.max_size;
    options.checkColor = input_data.Results.checkColor;
    options.color = input_data.Results.color;
    options.colorRatio = input_data.Results.colorRatio;
    options.useFilename = input_data.Results.useFilename;

    %TODO this should be read by the first image.
    options.RGB = true;

    %Parse metadata:
    if not(options.useFilename)
      meta = load(metadataFile);
      meta = struct2cell(meta){1};
      options.metadata = meta.imageFiles;
      options.info = meta.info;
      options.stacked = length(struct2cell(options.metadata){2}.stackedImg) ~= 0;
    else
      if ~exist(strcat(dstDir, "/stacked"))
        mkdir(strcat(dstDir, "/stacked"));
      endif
      options.metadata = metadataFromDir(srcDir);
      options.stacked = length(struct2cell(options.metadata){1}.stackedImg) ~= 0;
    endif


  endfunction


endfunction

%analysis(argv(){1}, argv(){2}, argv(){3}, argv(){4}, argv(){5:end});
