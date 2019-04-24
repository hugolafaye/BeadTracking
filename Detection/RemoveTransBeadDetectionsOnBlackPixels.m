function detectMat = RemoveTransBeadDetectionsOnBlackPixels(image,detectMat,...
    threshBlack)
% Remove detected transparent beads having a pixel intensity under a threshold.
%
% INPUT ARGUMENTS:
%  image      : source image.
%  detectMat  : matrix of detected transparent beads.
%  threshBlack: threshold to separate black pixels from the rest (in gray
%               intensity).
%
% OUTPUT ARGUMENTS:
%  detectMat: matrix of detected transparent beads - updated.
%
% Copyright (c) 2019, Hugo Lafaye de Micheaux, Thomas Gautrais, Université
% Jean Monnet, CNRS, Irstea
% All rights reserved.
%
% This source code is part of the BeadTracking package
% <https://github.com/hugolafaye/BeadTracking> and it is licensed under the
% BSD-style license found in the LICENSE file in the root directory of this
% source tree.

for b=size(detectMat,1):-1:1
    if image(round(detectMat(b,2)),round(detectMat(b,1)))<=threshBlack
        detectMat(b,:)=[];
    end
end

end