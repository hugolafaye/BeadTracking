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
% Hugo Lafaye de Micheaux, 2019

imageClosing=imclose(image,strel('disk',radClosing,8));
imageNoBase=uint8(maskBase).*imageClosing+uint8(~maskBase).*image;

end