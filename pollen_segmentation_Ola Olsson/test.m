
srcDir = 'E:/Naturhistoriska Riksmuseet/References/Chenopodium sp (Chenopodiaceae) 14 layers 40x'; % Update this with your src Directory
dstDir = 'E:/Naturhistoriska Riksmuseet/References/Chenopodium sp (Chenopodiaceae) 14 layers 40x/OD';
meta = 'OD_chenopodium.mat';

metadata = analysis(srcDir, dstDir, meta, true);

