function imageCorr = FindTemplate(image,template,radFilt,nbFilt)
% Find objects by normalized correlation with a template.
% A mean filter smoothing is applied after correlation.
%
% INPUT ARGUMENTS:
%  image   : source image.
%  template: template to correlate.
%  radFilt : half-size of mean filter (in px), if '0' no filtering.
%  nbFilt  : number of iterations of the mean filter.
%
% OUTPUT ARGUMENTS:
%  imageCorr: image of the results of correlation with the template.
%
% Copyright (c) 2019, Hugo Lafaye de Micheaux, Thomas Gautrais, Université
% Jean Monnet, CNRS, Irstea
% All rights reserved.
%
% This source code is part of the BeadTracking package
% <https://github.com/hugolafaye/BeadTracking> and it is licensed under the
% BSD-style license found in the LICENSE file in the root directory of this
% source tree.

tempSz=size(template);
imageCorr=normxcorr2(template,padarray(image,ceil(tempSz/2),0));
imageCorr=imageCorr(tempSz(1)+1:end-tempSz(1),tempSz(2)+1:end-tempSz(2));
if radFilt>0, imageCorr=MeanFilter(imageCorr,radFilt,nbFilt); end

end



function imageSmoothed = MeanFilter(image,radius,nbIter)
% Smoothing of the image with a mean filter.
%
% INPUT ARGUMENTS:
%  image : source image.
%  radius: half-size of the filter (i.e. a square of size 2*r+1) (in px).
%  nbIter: number of iteration of the filter.
%
% OUTPUT ARGUMENTS:
%  imageSmoothed: image obtained after smoothing.

hSize=radius*2+1;
h=fspecial('average',hSize);
imageSmoothed=image;
for n=1:nbIter
    imageSmoothed=imfilter(imageSmoothed,h);
end

end