function detectMat = RemoveTransBeadDetectionOnBlackPixels(image,detectMat,...
    threshBlack)
% Remove detected transparent beads having a pixel intensity under a threshold.
%
% INPUT ARGUMENTS:
%  image      : source image.
%  detectMat  : 2-columns array with x- and y-coordinates of the detected beads.
%  threshBlack: threshold to separate black and the rest.
%
% OUTPUT ARGUMENTS:
%  detectMat: detection matrix updated.
%
% Hugo Lafaye de Micheaux, 2019

for b=size(detectMat,1):-1:1
    if image(detectMat(b,2),detectMat(b,1))<=threshBlack
        detectMat(b,:)=[];
    end
end

end