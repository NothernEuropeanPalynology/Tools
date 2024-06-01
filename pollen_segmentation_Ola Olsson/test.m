addpath("./lib/");

% Example for Object Detection without a fitting .mat file works by
% creating a metadata table throught filenames. All images must be named
% with the same pattern: X_Y_Z, for example: X1_Y1_Z3.jpg.
srcDir = './sample_Object Detection - With filenames/'; % Update this with your src Directory
dstDir = './Output_OD with filename/';
meta = '';

metadata = analysis(srcDir, dstDir, meta, true, "useFilename", true);
save([dstDir "metadata.mat"], "metadata");

% Example for Object Detection with an existing metadata file. In order to
% conserve additional metadata about a scan, we have constructed a MATLAB
% app, which we use internally to analyze scanned slides. For comparison,
% this should be a demonstrative example.
srcDir = './sample_Object Detection/'; % Update this with your src Directory
dstDir = './Output_OD with mat file/';
meta = './sample_Object Detection/meta.mat'; %If images do not contain X,Y,Z coordinates in their filename, a metadata file in .mat format is required.

%metadata = analysis(srcDir, dstDir, meta, true);
%save([dstDir "metadata.mat"], "metadata", "-mat7-binary");


% There are many different parameters which can be adjusted: Here an
% overview and an example of how to set a parameter:

metadata = analysis(srcDir, dstDir, meta, true, "checkColor", false);
dstDir = './Output_OD without colour Method/';
save([dstDir "metadata.mat"], "metadata");

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
