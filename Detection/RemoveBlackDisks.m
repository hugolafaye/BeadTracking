function imageNoBDisks = RemoveBlackDisks(image,threshBDisks,radBDisks)
% Remove black disks from the image by changing them into closing.
%
% INPUT ARGUMENTS:
%  image       : source image.
%  threshBDisks: threshold separating black pixels from the rest (in gray
%                intensity).
%  radBDisks   : radius of the black disks (in px).
%
% OUTPUT ARGUMENTS:
%  imageNoBDisks: image without black disks.
%
% Copyright (c) 2019, Hugo Lafaye de Micheaux, Thomas Gautrais, Université
% Jean Monnet, CNRS, Irstea
% All rights reserved.
%
% This source code is part of the BeadTracking package
% <https://github.com/hugolafaye/BeadTracking> and it is licensed under the
% BSD-style license found in the LICENSE file in the root directory of this
% source tree.

maskBDisks=uint8(imdilate(image<=threshBDisks,strel('disk',1)));
imageClosing=imclose(image,strel('disk',floor(3/2*radBDisks),8));
imageNoBDisks=maskBDisks.*imageClosing+(1-maskBDisks).*image;

end