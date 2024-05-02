
srcDir = 'sample_stacking'; % Update this with your src Directory
dstDir = 'TEST_OUTPUT';
meta = 'sample_metadata.mat'; %If images do not contain X,Y,Z coordinates in their filename, a metadata file in .mat format is required.

metadata = analysis(srcDir, dstDir, meta, true);

