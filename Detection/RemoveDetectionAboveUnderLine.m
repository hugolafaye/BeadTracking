function detectMat2 = RemoveDetectionAboveUnderLine(detectMat,line,imSize,...
    flagAboveUnder)
% Remove false detections being above or under a line.
%
% INPUT ARGUMENTS:
%  detectMat     : 2-columns array with x- and y-coordinates of detected beads.
%  line          : vector of y-positions of a line for each x-position.
%  imSize        : size of the source image.
%  flagAboveUnder: 'above' for removing above line, 'under' for under line.
%
% OUTPUT ARGUMENTS:
%  detectMat2: detection matrix updated.
%
% Hugo Lafaye de Micheaux, 2019

if isempty(line)
    detectMat2=detectMat;
    return;
end

%create a mask of detections from detection matrix
maskDetections=zeros(imSize,'uint8');
maskDetections(sub2ind(imSize,detectMat(:,2),detectMat(:,1)))=1;
if size(detectMat,2)==3
    maskDetections(sub2ind(imSize,detectMat(:,2),detectMat(:,1)))=detectMat(:,3);
end

%create a mask above/under a line ('0' remove, '1' keep)
if strcmp(flagAboveUnder,'above')
    maskAboveUnderLine=uint8(cell2mat(cellfun(@(x)...
        cat(1,zeros(x,1),ones(imSize(1)-x,1)),num2cell(line),'uni',0)));
elseif strcmp(flagAboveUnder,'under')
    maskAboveUnderLine=uint8(cell2mat(cellfun(@(x)...
        cat(1,ones(x,1),zeros(imSize(1)-x,1)),num2cell(line),'uni',0)));
else
    error('Invalid string for flagAboveUnder. Should be "above" or "under".');
end

%apply the above/under mask on the detections
maskDetections=maskAboveUnderLine.*maskDetections;

%re-create a detection matrix without the false detections
[posYDetect,posXDetect]=find(maskDetections);
detectMat2=[posXDetect,posYDetect];
if size(detectMat,2)==3
    detectMat2=[detectMat2,maskDetections(sub2ind(imSize,posYDetect,posXDetect))];
end

end