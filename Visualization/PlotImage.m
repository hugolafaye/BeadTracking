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
% Hugo Lafaye de Micheaux, 2019

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