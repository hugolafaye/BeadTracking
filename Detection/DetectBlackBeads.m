function detectMat = DetectBlackBeads(image,threshBBeads,radBBeads)
% Detect the black beads in an image using the connected component labelling
% method.
%
% INPUT ARGUMENTS:
%  image       : source image.
%  threshBBeads: threshold separating black pixels from the rest (in gray
%                intensity).
%  radBBeads   : radius of the black beads (in px).
%
% OUTPUT ARGUMENTS:
%  detectMat: 2-columns matrix with x- and y-coordinates of the detected black
%             beads.
%
% Copyright (c) 2019, Hugo Lafaye de Micheaux, Thomas Gautrais, Université
% Jean Monnet, CNRS, Irstea
% All rights reserved.
%
% This source code is part of the BeadTracking package
% <https://github.com/hugolafaye/BeadTracking> and it is licensed under the
% BSD-style license found in the LICENSE file in the root directory of this
% source tree.

maskBBeads=image<=threshBBeads;
maskBBeads=imerode(maskBBeads,strel('disk',ceil(1/2*radBBeads),8));
stats=regionprops(maskBBeads,'basic');
detectMat=reshape([stats.Centroid],2,length(stats))';
detectMat=single(detectMat([stats.Area]<=pi*(ceil(1/2*radBBeads)+1)^2,:));

end