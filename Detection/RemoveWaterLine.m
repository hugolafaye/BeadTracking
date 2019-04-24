function imageNoWaterLine = RemoveWaterLine(image,waterLine)
% Detect and remove the water line in an image.
%
% INPUT ARGUMENTS:
%  image     : source image.
%  waterLine : vector of water line.
%
% OUTPUT ARGUMENTS:
%  imageNoWaterLine: image without the water line.
%
% Copyright (c) 2019, Hugo Lafaye de Micheaux, Thomas Gautrais, Université
% Jean Monnet, CNRS, Irstea
% All rights reserved.
%
% This source code is part of the BeadTracking package
% <https://github.com/hugolafaye/BeadTracking> and it is licensed under the
% BSD-style license found in the LICENSE file in the root directory of this
% source tree.

[nrow,ncol]=size(image);

%compute water thickness by first detecting the top of the water line and then
%by deducting the water thickness as being twice the water line minus the top 
%water line
maskMarkers=zeros(nrow,ncol,'uint8');
maskMarkers(1,:)=1;
waterLineTemp=waterLine;
waterLineTemp(waterLine<=2)=3;%to deal with water line touching top of image
maskMarkers(sub2ind([nrow,ncol],waterLineTemp,1:ncol))=1;
waterLineTop=watershed(imimposemin(imgradient(image),maskMarkers))==0;
waterLineTop=bwmorph(waterLineTop,'thin',Inf);
[row,col]=find(waterLineTop);
[~,icol,~]=unique(col,'stable');
waterLineTop=uint16(row(icol)');
waterThickness=2*ceil(mean(waterLine-waterLineTop));

%create a mask with only the water line on its whole thickness
maskWaterLine=zeros(nrow,ncol,'uint8');
maskWaterLine(sub2ind([nrow,ncol],waterLine,1:ncol))=1;
maskWaterLine=imdilate(maskWaterLine,strel('line',waterThickness,90));

%compute closing of the source image to get the background
imageClosing=imclose(image,strel('disk',2*waterThickness,8));

%change the water line by background values
imageNoWaterLine=maskWaterLine.*imageClosing+(1-maskWaterLine).*image;

end