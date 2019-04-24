function imageNoBBeads = RemoveBlackBeadsFromDetectMat(image,detectMat,...
    radBBeads)
% Remove detected black beads from the image by changing them into closing.
%
% INPUT ARGUMENTS:
%  image    : source image.
%  detectMat: matrix of detected black beads.
%  radBBeads: radius of the black beads (in px).
%
% OUTPUT ARGUMENTS:
%  imageNoBBeads: image without black beads.
%
% Copyright (c) 2019, Hugo Lafaye de Micheaux, Thomas Gautrais, Université
% Jean Monnet, CNRS, Irstea
% All rights reserved.
%
% This source code is part of the BeadTracking package
% <https://github.com/hugolafaye/BeadTracking> and it is licensed under the
% BSD-style license found in the LICENSE file in the root directory of this
% source tree.

maskBBeads=zeros(size(image),'uint8');
maskBBeads(sub2ind(size(image),round(detectMat(:,2)),round(detectMat(:,1))))=1;
maskBBeads=imdilate(maskBBeads,strel('disk',radBBeads,8));
imageClosing=imclose(image,strel('disk',floor(3/2*radBBeads),8));
imageNoBBeads=maskBBeads.*imageClosing+(1-maskBBeads).*image;

end