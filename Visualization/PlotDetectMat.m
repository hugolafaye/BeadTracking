function hf = PlotDetectMat(image,detectMat,hf)
% Plot detected points on a source image.
%
% INPUT ARGUMENTS:
%  image    : source image.
%  detectMat: matrix of black and transparent bead detections, 1st and 2nd 
%             columns are the x- and y-coordinates, 3rd column is the flag '0'
%             for black beads and '1' for transparent beads,
%             4th column (optionnal) contains the target identities (used to
%             not plot unvalid targets)
%  hf       : handle to the figure object ('0' means new figure).
%
% OUTPUT ARGUMENTS:
%  hf: handle to the figure object.
%
% Hugo Lafaye de Micheaux, 2019

if size(detectMat,2)>=4
    detectMat(isnan(detectMat(:,4)) | detectMat(:,4)==0,:)=[];
end
hf=PlotImage(image,hf,true);
hold on;
if size(detectMat,2)>=3 && any(detectMat(:,3)==0|detectMat(:,3)==1)
    posBlack=detectMat(:,3)==0;
    posTrans=detectMat(:,3)==1;
    plot(gca(hf),detectMat(posBlack,1),detectMat(posBlack,2),'+g',...
        'markersize',4);
    plot(gca(hf),detectMat(posTrans,1),detectMat(posTrans,2),'+r',...
        'markersize',4);
else
    plot(gca(hf),detectMat(:,1),detectMat(:,2),'+r','markersize',4);
end
hold off;

end