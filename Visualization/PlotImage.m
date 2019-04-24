function hf = PlotImage(image,hf,boolPos)
% Plot an image with a gray scale.
%
% INPUT ARGUMENTS:
%  image  : image to plot.
%  hf     : handle to the figure object. ('0' means new figure, default 
%           current figure).
%  boolPos: if true, position the figure in the middle of the screen (default).
%           if false, don't position the figure, useful when using subfigure.
%
% OUTPUT ARGUMENTS:
%  hf: handle to the figure object.
%
% Copyright (c) 2019, Hugo Lafaye de Micheaux, Thomas Gautrais, Université
% Jean Monnet, CNRS, Irstea
% All rights reserved.
%
% This source code is part of the BeadTracking package
% <https://github.com/hugolafaye/BeadTracking> and it is licensed under the
% BSD-style license found in the LICENSE file in the root directory of this
% source tree.

if nargin<3, boolPos=true; end
if nargin<2, hf=gcf; end
if hf==0,    hf=figure; end
if boolPos
    pos=get(hf,'position');
    pos(3:4)=fliplr(size(image));
    set(hf,'position',pos);
    set(gca(hf),'units','normalized','position',[0,0,1,1]);
end
if islogical(image), imshow(image);
else                 imshow(image,[min(image(:)),max(image(:))]);
end

end