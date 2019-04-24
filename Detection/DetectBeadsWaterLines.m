function [detectMat,waterLine,detectMatTransBeadsConf] = ...
    DetectBeadsWaterLines(image,dp,baseMask,templateTransBead)
% Detect the black and transparent beads and the water line in an image. Compute
% the detector confidence of transparent beads if needed.
%
% INPUT ARGUMENTS:
%  image   : source image.
%  dp      : structure containing the detection parameters.
%  baseMask: mask of the base of the flume.
%
% OUTPUT ARGUMENTS:
%  detectMat              : matrix of black and transparent bead detections with
%                           3 infos (col) for each detection (row):
%                             1. x-coordinate of the detection
%                             2. y-coordinate of the detection
%                             3. category of the detection ('0' for black bead,
%                                '1' for transparent bead)
%  waterLine              : vector of the y-positions of the water line for each
%                           x-position. (returned empty if water lines not
%                           needed)
%  detectMatTransBeadsConf: matrix of detector confidences for transparent beads
%                           with 3 infos (col) for each detection (row):
%                             1. x-coordinate of the detection
%                             2. y-coordinate of the detection
%                             3. correlation value with the transparent bead
%                                template
%                           (returned empty if detector confidences not needed)
%
% Copyright (c) 2019, Hugo Lafaye de Micheaux, Thomas Gautrais, Université
% Jean Monnet, CNRS, Irstea
% All rights reserved.
%
% This source code is part of the BeadTracking package
% <https://github.com/hugolafaye/BeadTracking> and it is licensed under the
% BSD-style license found in the LICENSE file in the root directory of this
% source tree.

%initialize variables
image2=image;
waterLine=[];
detectMatBlackBeads=[];
detectMatTransBeads=[];
detectMatTransBeadsConf=[];

%remove the base of the flume
if dp.boolRemoveBase
    image2=RemoveBaseFromMask(image,baseMask,2*dp.radBlackBeadPx);
end

%detect black beads
if dp.boolBlackBeadDetect
    detectMatBlackBeads=DetectBlackBeads(image2,dp.threshBlackBeadDetect,...
        dp.radBlackBeadPx);
end

%detect and remove the water line with the help of the black bead detections
if dp.boolWaterLineDetect
    waterLine=DetectWaterLine(image2,detectMatBlackBeads,dp.radBlackBeadPx,...
        dp.threshWaterLineStd);
    image2=RemoveWaterLine(image2,waterLine);
end

%remove false black bead detections using the water line
%and then change true black bead detections into closing
if dp.boolBlackBeadDetect
    detectMatBlackBeads=RemoveDetectionsAboveUnderLine(detectMatBlackBeads,...
        waterLine,dp.imSize,'above');
    if dp.boolTransBeadDetect
        image2=RemoveBlackBeadsFromDetectMat(image2,detectMatBlackBeads,...
            dp.radBlackBeadPx);
    end
end

%detect transparent beads
if dp.boolTransBeadDetect
    %remove residual black disks (ie. the cropped ones or all of them if black
    %beads not detected)
    image2=RemoveBlackDisks(image2,dp.threshBlackBeadDetect,dp.radBlackBeadPx);

    %detect transparent beads and compute detector confidence if needed
    [detectMatTransBeads,detectMatTransBeadsConf]=DetectTransBeads(image2,...
        dp.radBlackBeadPx,dp.transBeadDetectHMax,templateTransBead,...
        dp.transBeadDetectRadFilt,dp.transBeadDetectNbFilt,...
        dp.threshTransBeadDetect,dp.threshTransBeadDetectConf);

    %remove false transparent bead detections using the water line
    %and the pixel intensities
    detectMatTransBeads=RemoveDetectionsAboveUnderLine(detectMatTransBeads,...
        waterLine,dp.imSize,'above');
    detectMatTransBeads=RemoveTransBeadDetectionsOnBlackPixels(image,...
        detectMatTransBeads,2*dp.threshBlackBeadDetect);
    if dp.boolTransBeadDetectConf
        detectMatTransBeadsConf=RemoveDetectionsAboveUnderLine(...
            detectMatTransBeadsConf,waterLine,dp.imSize,'above');
        detectMatTransBeadsConf=RemoveTransBeadDetectionsOnBlackPixels(image,...
            detectMatTransBeadsConf,2*dp.threshBlackBeadDetect);
    end
end

%put both detection type matrices together, with '0' for black beads
%and '1' for transparent beads
flagDetectBlackBeads=zeros(size(detectMatBlackBeads,1),1,'single');
flagDetectTransBeads=ones(size(detectMatTransBeads,1),1,'single');
detectMat=[[detectMatBlackBeads;detectMatTransBeads],...
    [flagDetectBlackBeads;flagDetectTransBeads]];

end