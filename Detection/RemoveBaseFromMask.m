function imageNoBase = RemoveBaseFromMask(image,maskBase,radClosing)
% Remove the base of the flume in an image from its mask by changing it with
% values of closing.
%
% INPUT ARGUMENTS:
%  image     : source image.
%  maskBase  : mask of the base of the flume.
%  radClosing: radius of the disk for the closing of the image that will replace
%              the base (in px).
%
% OUTPUT ARGUMENTS:
%  imageNoBase: image without the base.
%
% Copyright (c) 2019, Hugo Lafaye de Micheaux, Thomas Gautrais, Université
% Jean Monnet, CNRS, Irstea
% All rights reserved.
%
% This source code is part of the BeadTracking package
% <https://github.com/hugolafaye/BeadTracking> and it is licensed under the
% BSD-style license found in the LICENSE file in the root directory of this
% source tree.

imageClosing=imclose(image,strel('disk',radClosing,8));
imageNoBase=uint8(maskBase).*imageClosing+uint8(~maskBase).*image;

end