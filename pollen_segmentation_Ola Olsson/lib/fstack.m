
function im = fstack(imlist, opts)
  % Focus stacking.
  % This script is adapted from the implementation in MATLAB.
  % Please check this code for further information:
  % https://se.mathworks.com/matlabcentral/fileexchange/55115-extended-depth-of-field
  %
  % SINTAX:
  %   im = fstack(imlist)
  %   im = fstack(imlist, opt1, val1, opt2, val2,...)
  %
  % DESCRIPTION:
  % Generate extended depth-of-field image from focus sequence
  % using noise-robust selective all-in-focus algorithm [1].
  % Input images may be grayscale or color. For color images,
  % the algorithm is applied to each color plane independently
  %
  % OUTPUTS:
  % im,       is a MxN matrix with the all-in-focus (AIF) image.
  %
  % INPUTS:
  % images,   is a cell array where each cell is a string with the
  %           path of an image.
  %
  % Options and their values (default in perenthesis) may be any of
  % the following:
  %   'nhsize',     Size of focus measure window (9).
  %   'focus',      Vector with the focus of each frame.
  %   'alpha',      A scalar in (0,1]. Default is 0.2. See [1] for details.
  %   'sth',        A scalar. Default is 13. See [1] for details.
  %
  %For further details, see:
  % [1] Pertuz et. al. "Generation of all-in-focus images by
  %   noise-robust selective fusion of limited depth-of-field
  %   images" IEEE Trans. Image Process, 22(3):1242 - 1251, 2013.
  %
  %S. Pertuz
  %Jan/2016
  %Parse inputs:

  M = opts.size(1);
  N = opts.size(2);
  P = opts.size(3);
  %********* Read images and compute fmeasure **********
  %Initialize:
  fm = zeros(opts.size);

  if opts.RGB
      imagesR = zeros(M, N);
      imagesG = zeros(M, N);
      imagesB = zeros(M, N);
  else
      imagesG = zeros(M, N);
  end
  %Read:
  for p = 1:P
      im = imread(imlist{p});
      if opts.RGB
          imagesR(:,:,p) = im(:,:,1);
          imagesG(:,:,p) = im(:,:,2);
          imagesB(:,:,p) = im(:,:,3);
          im = rgb2gray(im);
      else
          imagesG(:,:,p) = im;
      end
      fm(:,:,p) = gfocus(im2double(im), opts.nhsize);
  end

  %********** Compute Smeasure ******************

  [u, s, A, fmax] = gauss3P(opts.focus, fm);
  %Aprox. RMS of error signal as sum|Signal-Noise|
  %instead of sqrt(sum(Signal-noise)^2):
  err = zeros(M, N);
  for p = 1:P
      err = err + abs( fm(:,:,p) - ...
          A.*exp(-(opts.focus(p)-u).^2./(2*s.^2)));
      fm(:,:,p) = fm(:,:,p)./fmax;
  end
  h = fspecial('average', opts.nhsize);
  inv_psnr = imfilter(err./(P*fmax), h, 'replicate');
  S = 20*log10(1./inv_psnr);
  S(isnan(S))=min(S(:));
  phi = 0.5*(1+tanh(opts.alpha*(S-opts.sth)))/...
     opts.alpha;
  phi = medfilt2(phi, [3 3]);

  %********** Compute weights: ********************

  fun = @(phi,fm) 0.5 + 0.5*tanh(phi.*(fm-1));
  for p = 1:P
      fm(:,:,p) = feval(fun, phi, fm(:,:,p));
  end

  %********* Fuse images: *****************
  fmn = sum(fm,3); %(Normalization factor)
  if opts.RGB
      im(:,:,1) = uint8(sum((imagesR.*fm), 3)./fmn);
      im(:,:,2) = uint8(sum((imagesG.*fm), 3)./fmn);
      im(:,:,3) = uint8(sum((imagesB.*fm), 3)./fmn);
  else
      im = uint8(sum((imagesG.*fm), 3)./fmn);
  end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [u, s, A, Ymax] = gauss3P(x, Y)
  % Fast 3-point gaussian interpolation
  STEP = 2; % Internal parameter
  [M,N,P] = size(Y);
  [Ymax, I] = max(Y,[ ], 3);
  [IN,IM] = meshgrid(1:N,1:M);
  Ic = I(:);
  Ic(Ic<=STEP)=STEP+1;
  Ic(Ic>=P-STEP)=P-STEP;
  Index1 = sub2ind([M,N,P], IM(:), IN(:), Ic-STEP);
  Index2 = sub2ind([M,N,P], IM(:), IN(:), Ic);
  Index3 = sub2ind([M,N,P], IM(:), IN(:), Ic+STEP);
  Index1(I(:)<=STEP) = Index3(I(:)<=STEP);
  Index3(I(:)>=STEP) = Index1(I(:)>=STEP);
  x1 = reshape(x(Ic(:)-STEP),M,N);
  x2 = reshape(x(Ic(:)),M,N);
  x3 = reshape(x(Ic(:)+STEP),M,N);
  y1 = reshape(log(Y(Index1)),M,N);
  y2 = reshape(log(Y(Index2)),M,N);
  y3 = reshape(log(Y(Index3)),M,N);
  c = ( (y1-y2).*(x2-x3)-(y2-y3).*(x1-x2) )./...
      ( (x1.^2-x2.^2).*(x2-x3)-(x2.^2-x3.^2).*(x1-x2) );
  b = ( (y2-y3)-c.*(x2-x3).*(x2+x3) )./(x2-x3);
  s = sqrt(-1./(2*c));
  u = b.*s.^2;
  a = y1 - b.*x1 - c.*x1.^2;
  A = exp(a + u.^2./(2*s.^2));
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function FM = gfocus(im, WSize)
  % Compute focus measure using graylevel local variance
  MEANF = fspecial('average',[WSize WSize]);
  U = imfilter(im, MEANF, 'replicate');
  FM = (im-U).^2;
  FM = imfilter(FM, MEANF, 'replicate');
end





