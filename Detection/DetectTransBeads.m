function [detectMat,detectMatConf] = DetectTransBeads(image,radBBeads,hMax,...
    templateTBead,radFilt,nbFilt,threshTBeadDetect,threshTBeadDetectConf)
% Detect the transparent beads in an image using template matching. Compute the
% detector confidence of transparent beads if needed.
%
% INPUT ARGUMENTS:
%  image                : source image.
%  radBBeads            : radius of the black beads (in px).
%  hMax                 : value of the heigh hMax (in gray intensity).
%  templateTBead        : ring shaped template of a generic transparent bead.
%  radFilt              : half-size of mean filter (in px), if '0' no filtering.
%  nbFilt               : number of iterations of the mean filter.
%  threshTBeadDetect    : threshold to detect transparent beads.
%  threshTBeadDetectConf: threshold of detector confidence to detect transparent
%                         beads, smaller than threshTBeadDetect (optionnal).
%
% OUTPUT ARGUMENTS:
%  detectMat    : 2-columns matrix with the x- and y-coordinates of the detected
%                 transparent beads.
%  detectMatConf: matrix of detector confidences for transparent beads with 3
%                 infos (col) for each detection (row):
%                   1. x-coordinate of the detection
%                   2. y-coordinate of the detection
%                   3. correlation value with the transparent bead template
%                 (returned empty if detector confidences not needed)
%
% Copyright (c) 2019, Hugo Lafaye de Micheaux, Thomas Gautrais, Université
% Jean Monnet, CNRS, Irstea
% All rights reserved.
%
% This source code is part of the BeadTracking package
% <https://github.com/hugolafaye/BeadTracking> and it is licensed under the
% BSD-style license found in the LICENSE file in the root directory of this
% source tree.

%background correction (black top hat)
imageTopHat=imclose(image,strel('disk',floor(3/2*radBBeads),8))-image;

%H-Concave transform: high peak detection
imageHConcave=imhmin(imageTopHat,hMax)-imageTopHat;

%correlate transparent bead template in the image
imageCorr=FindTemplate(imageHConcave,templateTBead,radFilt,nbFilt);

%keep only detections above the threshold
imageDiskMax=imageCorr.*imregionalmax(imageCorr,8);
[posY,posX]=find(imageDiskMax>=threshTBeadDetect);
detectMat=single([posX,posY]);

%compute detector confidence of transparent beads if needed
if nargin==8 && ~isempty(threshTBeadDetectConf)
    [posYConf,posXConf]=find(imageDiskMax>=threshTBeadDetectConf);
    detectMatConf=single([posXConf,posYConf,...
        imageDiskMax(sub2ind(size(image),posYConf,posXConf))]);
else
    detectMatConf=[];
end

end