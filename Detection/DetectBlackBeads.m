function detectMat = DetectBlackBeads(image,threshBBeads,radBBeads)
% Detect the black beads in an image using the connected component labelling
% method.
%
% INPUT ARGUMENTS:
%  image       : source image.
%  threshBBeads: threshold separating black pixels from the rest.
%  radBBeads   : radius of the black beads (in px).
%
% OUTPUT ARGUMENTS:
%  detectMat: 2-columns array with x- and y-coordinates of the detected beads.
%
% Hugo Lafaye de Micheaux, 2019

maskBBeads=image<=threshBBeads;
maskBBeads=imerode(maskBBeads,strel('disk',ceil(1/2*radBBeads),8));
stats=regionprops(maskBBeads,'basic');
detectMat=reshape([stats.Centroid],2,length(stats))';
detectMat=uint16(detectMat([stats.Area]<=pi*(ceil(1/2*radBBeads)+1)^2,:));

end