function imageNoBBeads = RemoveBlackBeadsFromDetectMat(image,detectMat,radBBeads)
% Remove detected black beads from the image by changing them into closing.
%
% INPUT ARGUMENTS:
%  image    : source image.
%  detectMat: 2-columns array with x- and y-coordinates of the detected beads.
%  radBBeads: radius of the black beads (in px).
%
% OUTPUT ARGUMENTS:
%  imageNoBBeads: image without black beads.
%
% Hugo Lafaye de Micheaux, 2019

maskBBeads=zeros(size(image),'uint8');
maskBBeads(sub2ind(size(image),detectMat(:,2),detectMat(:,1)))=1;
maskBBeads=imdilate(maskBBeads,strel('disk',radBBeads,8));
imageClosing=imclose(image,strel('disk',floor(3/2*radBBeads),8));
imageNoBBeads=maskBBeads.*imageClosing+(1-maskBBeads).*image;

end