function waterLine = DetectWaterLine(image,detectMatBBeads,radBBeads,...
    threshStdWl)
% Detect the water line in an image using watershed transform.
% The algorithm deals with the problem of black beads touching the water line
% by removing the pre-computed detected black beads.
%
% INPUT ARGUMENTS:
%  image          : source image.
%  detectMatBBeads: 2-columns matrix with the x- and y-coordinates of the
%                   detected black beads (can be empty).
%  radBBeads      : radius of the black beads (in px).
%  threshStdWl    : threshold of standard deviation to validate water line.
%
% OUTPUT ARGUMENTS:
%  waterLine: vector of the y-positions of the water line for each x-position.
%
% Copyright (c) 2019, Hugo Lafaye de Micheaux, Thomas Gautrais, Université
% Jean Monnet, CNRS, Irstea
% All rights reserved.
%
% This source code is part of the BeadTracking package
% <https://github.com/hugolafaye/BeadTracking> and it is licensed under the
% BSD-style license found in the LICENSE file in the root directory of this
% source tree.

%default variables
threshBlack=50;
threshJumpOk=15;

%initialize variables
imSize=size(image);
imageNoBBeads=image;

%remove black beads (if any)
if ~isempty(detectMatBBeads)
    maskBBeads=zeros(imSize,'uint8');
    maskBBeads(sub2ind(imSize,round(detectMatBBeads(:,2)),...
        round(detectMatBBeads(:,1))))=1;
    maskBBeads=imdilate(maskBBeads,strel('disk',radBBeads,8));
    imageClosing=imclose(image,strel('disk',radBBeads,8));
    imageNoBBeads=maskBBeads.*imageClosing+(1-maskBBeads).*image;
end

%amplify water line (black top hat)
imageTopHat=imclose(imageNoBBeads,strel('line',floor(3/2*radBBeads),90))-...
    imageNoBBeads;

%apply the watershed transform to get the water line
maskMarkers=[ones(1,imSize(2));zeros(imSize(1)-2,imSize(2));ones(1,imSize(2))];
imageWaterLine=watershed(imimposemin(imageTopHat,maskMarkers))==0;
imageWaterLine=bwmorph(imageWaterLine,'thin',Inf);
[row,col]=find(imageWaterLine);
[~,icol,~]=unique(col,'stable');
waterLine=uint16(row(icol)');

%check if the water line is likely and use another detecting method if not
if mean(stdfilt(waterLine))>threshStdWl
    waterLine=DetectWaterLineByMorph(image,threshBlack,radBBeads);
end

%post-processing to detect/correct bad detections due to water line occlusions
waterLine=CorrectWaterLineJump(waterLine,threshJumpOk);

end



function waterLine = DetectWaterLineByMorph(image,threshBlack,radClosing,bedLine)
% Detect the water line in an image using several morphological operations.
%
% INPUT ARGUMENTS:
%  image      : source image.
%  threshBlack: threshold separating black pixels from the rest.
%  radClosing : radius of the disk used for the closing to detect water line.
%  bedLine    : vector of the bed line (optionnal).
%
% OUTPUT ARGUMENTS:
%  waterLine: vector of the y-positions of the water line for each x-position

%some morphological operations
maskBlack=image<=threshBlack;
maskBEroded=imerode(maskBlack,strel('disk',radClosing,8));
maskBErodedDilated=imdilate(maskBEroded,strel('disk',radClosing+2,8));
maskBErodedDilated=(~maskBErodedDilated).*255;
imageWaterLine=maskBlack&maskBErodedDilated;
imageWaterLine=bwmorph(imageWaterLine,'thin',Inf);

%get first element of each column, NaN if none
[row,col]=find(cumsum(cumsum(imageWaterLine))==1);
waterLine=NaN(1,size(imageWaterLine,2));
waterLine(col)=row;

%remove isolated points: under bed line or above 2 standard deviations
if nargin==4
    waterLine(waterLine>=bedLine)=NaN;
else
    waterLine(waterLine>=(mean(waterLine(~isnan(waterLine)))+...
        2*std(waterLine(~isnan(waterLine)))))=NaN;
end

%interpolate and extrapolate the NaN points
t=1:length(waterLine);
nans=isnan(waterLine); 
if sum(nans)>0
    waterLine(nans)=interp1(t(~nans),waterLine(~nans),t(nans),'linear');
    nans=isnan(waterLine);
    if sum(nans)>0
        waterLine(nans)=interp1(t(~nans),waterLine(~nans),t(nans),...
            'nearest','extrap');
    end
end

waterLine=uint16(waterLine);

end



function waterLine = CorrectWaterLineJump(waterLine,threshJumpOk)
% Post-processing to detect/correct bad detections due to water line occlusions.
% This method is based on the derivative of the water line and detect negative
% and positve peaks.
%
% INPUT ARGUMENTS:
%  waterLine   : vector of the y-positions of the water line for each x-position.
%  threshJumpOk: threshold to consider a jump as too high
%
% OUTPUT ARGUMENTS:
%  waterLine: vector of the corrected water line

waterDiff=diff(waterLine);
waterDiffMaxInd=find(abs(waterDiff)>threshJumpOk);

if isempty(waterDiffMaxInd), return; end

waterDiffMax=waterDiff(waterDiffMaxInd);

if waterDiffMax(1)<0
    waterLine(1:waterDiffMaxInd(1))=waterLine(waterDiffMaxInd(1)+1);
    waterDiffMaxInd=waterDiffMaxInd(2:end);
end

if waterDiffMax(end)>0
    waterLine(waterDiffMaxInd(end):end)=waterLine(waterDiffMaxInd(end));
    waterDiffMaxInd=waterDiffMaxInd(1:end-1);
end

for i=1:2:length(waterDiffMaxInd)-1
    i1=waterDiffMaxInd(i); i2=waterDiffMaxInd(i+1)+1;
    waterLine(i1:i2)=uint16(...
        linspace(single(waterLine(i1)),single(waterLine(i2)),i2-i1+1));
end

end