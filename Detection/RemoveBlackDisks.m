function imageNoBDisks = RemoveBlackDisks(image,threshBDisks,radBDisks)
% Remove black disks from the image by changing them into closing.
%
% INPUT ARGUMENTS:
%  image       : source image.
%  threshBDisks: threshold separating black pixels from the rest.
%  radBDisks   : radius of the black disks (in px).
%
% OUTPUT ARGUMENTS:
%  imageNoBDisks: image without black disks.
%
% Hugo Lafaye de Micheaux, 2019

maskBDisks=uint8(imdilate(image<=threshBDisks,strel('disk',1)));
imageClosing=imclose(image,strel('disk',floor(3/2*radBDisks),8));
imageNoBDisks=maskBDisks.*imageClosing+(1-maskBDisks).*image;

end