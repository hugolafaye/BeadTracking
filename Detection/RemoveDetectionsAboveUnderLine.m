function detectMatOut = RemoveDetectionsAboveUnderLine(detectMat,line,imSize,...
    flagAboveUnder)
% Remove false detections being above or under a line.
%
% INPUT ARGUMENTS:
%  detectMat     : matrix of detected beads.
%  line          : vector of y-positions of a line for each x-position.
%  imSize        : size of the source image.
%  flagAboveUnder: 'above' for removing above line, 'under' for under line.
%
% OUTPUT ARGUMENTS:
%  detectMatOut: matrix of detected beads - updated.
%
% Copyright (c) 2019, Hugo Lafaye de Micheaux, Thomas Gautrais, Université
% Jean Monnet, CNRS, Irstea
% All rights reserved.
%
% This source code is part of the BeadTracking package
% <https://github.com/hugolafaye/BeadTracking> and it is licensed under the
% BSD-style license found in the LICENSE file in the root directory of this
% source tree.

if isempty(line)
    detectMatOut=detectMat;
    return;
end

%create a mask of detections from detection matrix
maskDetections=zeros(imSize,'uint8');
maskDetections(sub2ind(imSize,round(detectMat(:,2)),round(detectMat(:,1))))=1;

%create a mask above/under a line ('0' remove, '1' keep)
if strcmp(flagAboveUnder,'above')
    maskAboveUnderLine=uint8(cell2mat(cellfun(@(x)...
        cat(1,zeros(x,1),ones(imSize(1)-x,1)),num2cell(line),'uni',0)));
elseif strcmp(flagAboveUnder,'under')
    maskAboveUnderLine=uint8(cell2mat(cellfun(@(x)...
        cat(1,ones(x,1),zeros(imSize(1)-x,1)),num2cell(line),'uni',0)));
else
    error('Invalid string for flagAboveUnder. Should be "above" or "under".');
end

%apply the above/under mask on the detections
maskDetections=maskAboveUnderLine.*maskDetections;

%re-create a detection matrix without the false detections
[posY,posX]=find(maskDetections);
detectMat2=round(detectMat(:,1:2));
detectIdx=arrayfun(@(x,y)find(detectMat2(:,1)==x & detectMat2(:,2)==y),...
    posX,posY);
detectMatOut=detectMat(detectIdx,:);

end