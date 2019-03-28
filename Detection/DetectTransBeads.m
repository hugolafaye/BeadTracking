function detectMat = DetectTransBeads(image,radBBeads,hMax,templateTBead,...
    radFilt,nbFilt,threshTBeadDetect)
% Detect the transparent beads in an image using template matching.
%
% INPUT ARGUMENTS:
%  image            : source image.
%  radBBeads        : radius of the black beads (in px).
%  hMax             : value of the heigh hMax.
%  templateTBead    : ring shaped template of a generic transparent bead.
%  radFilt          : half-size of mean filter (in px), if '0' no filtering.
%  nbFilt           : number of iterations of the mean filter.
%  threshTBeadDetect: threshold to detect transparent beads.
%
% OUTPUT ARGUMENTS:
%  detectMat: 2-columns array with x- and y-coordinates of the detected beads.
%
% Hugo Lafaye de Micheaux, 2019

%background correction (black top hat)
imageTopHat=imclose(image,strel('disk',floor(3/2*radBBeads),8))-image;

%H-Concave transform: high peak detection
imageHConcave=imhmin(imageTopHat,hMax)-imageTopHat;

%correlate transparent bead template in the image
imageCorr=FindTemplate(imageHConcave,templateTBead,radFilt,nbFilt);

%keep only detections above the threshold
imageDiskMax=imageCorr.*imregionalmax(imageCorr,8);
[posYDetect,posXDetect]=find(imageDiskMax>=threshTBeadDetect);
detectMat=uint16([posXDetect,posYDetect]);

end