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
% alpha:
% focus:
% nhsize:
% sth:
%
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
  addpath("./lib/");
  pkg load image;

  opts = parseInputs(srcDir, dstDir, metadataFile, save_stacked, varargin{:});


% Loop through each X/Y position combination
  fprintf('Segmentation\n') %Process bar
  fieldNames = fieldnames(opts.metadata);
  for xIdx = 236:numel(fieldNames)
      xField = fieldNames{xIdx};
      batch = opts.metadata.(xField).filenames;% Loads the different z-planes
      filenames = cellfun(@(x)(batch.(x)),fieldnames(batch));% extracts all filenames
      filenames = fullfile(srcDir, filenames);% full path to file

      try
        if opts.stacked
          filename = fullfile(srcDir, opts.metadata.(xField).stackedImg);
          stacked = imread(filename);
          [OID_counter, bboxes] = segmentPollen(stacked, opts.OID_counter, opts.size, opts.se_size, opts.min_size,
            opts.max_size, opts.checkColor, opts.color, opts.colorRatio);
        else
          rankedFiles = rankedFocusPlanes(filenames, 5); %TODO: add this paramater as function input
          stacked = fstack(rankedFiles); % Stacks images using fstack algorithm by S. Perutz (2016)
          [OID_counter, bboxes] = segmentPollen(stacked, opts.OID_counter, opts.size, opts.se_size, opts.min_size,
            opts.max_size, opts.checkColor, opts.color, opts.colorRatio); % Extracts image labels based on Ola Olsson et al. (2021)
        endif

        opts.OID_counter = OID_counter;

        if (length(fieldnames(bboxes)) >= 1)
          saveImageArea(bboxes, filenames, dstDir); % Saves individual pollen grains on all z-planes.
          opts.metadata.(xField).bboxes = bboxes;
          stacked = drawBoundingBoxes(stacked, bboxes, 10);
        endif

        if save_stacked
          imwrite(stacked, fullfile(opts.macroPath, strcat("OD_", xField,".jpg")), 'Quality', 30); % Stores focus stacked image.
        endif


        %Update Processbar:
        fprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b[%.6d/%.6d]',xIdx, numel(fieldNames));

      catch
        metadata = opts.metadata;
      end_try_catch



  endfor

  metadata = opts.metadata;

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


    if meta
      %Parse metadata:
      options.metadata = load(metadataFile);
      options.metadata = struct2cell(options.metadata){1};
      options.stacked = length(struct2cell(options.metadata){1}.stackedImg) ~= 0;
    else
      options.metadata = struct();
    endif


    % Determine image size and type:
    % TODO add as fields in metadata.
    options.size = [2028, 2028, 5];

    options.macroPath = macroPath;
    options.OID_counter = 0;

    input_data = inputParser;
    input_data.CaseSensitive = false;
    input_data.StructExpand = true;

    %Options for fstacking algorithm:
    input_data.addOptional('alpha', 0.2, @(x) isnumeric(x) && isscalar(x) && (x>0) && (x<=1));
    input_data.addOptional('focus', 1:5, @(x) isnumeric(x) && isvector(x));
    input_data.addOptional('nhsize', 9, @(x) isnumeric(x) && isscalar(x));
    input_data.addOptional('sth', 13, @(x) isnumeric(x) && isscalar(x));

    %Options for object detection algorithm:
    input_data.addOptional('se_size', 7, @(x) isnumeric(x) && isscalar(x));
    input_data.addOptional('min_size', 0.001, @(x) isnumeric(x) && isvector(x)&& (x>0) && (x<=1));
    input_data.addOptional('max_size', 0.5, @(x) isnumeric(x) && isscalar(x) && (x>0) && (x<=1));
    input_data.addOptional('checkColor', true, @(x) isbool(x));
    input_data.addOptional('color', [220, 100, 150], @(x) ismatrix(x) && all(isscalar(x)) && (size(x == 3)));
    input_data.addOptional('colorRatio', 0.01, @(x) isnumeric(x) && isscalar(x) && (x>0) && (x<=1));
    parse(input_data, varargin{:});
    options.alpha = input_data.Results.alpha;
    options.focus = input_data.Results.focus;
    options.nhsize = input_data.Results.nhsize;
    options.sth = input_data.Results.sth;
    options.se_size = input_data.Results.se_size;
    options.min_size = input_data.Results.min_size;
    options.max_size = input_data.Results.max_size;
    options.checkColor = input_data.Results.checkColor;
    options.color = input_data.Results.color;
    options.colorRatio = input_data.Results.colorRatio;

  endfunction


endfunction

%analysis(argv(){1}, argv(){2}, argv(){3}, argv(){4}, argv(){5:end});
