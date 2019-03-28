function [detectMat,waterLine] = DetectBeadsWaterLines(image,dp,baseMask,...
    templateTransBead)
% Detect the black and transparent beads and the water line in an image.
%
% INPUT ARGUMENTS:
%  image   : source image.
%  dp      : structure containing the detection parameters.
%  baseMask: mask of the base of the flume.
%
% OUTPUT ARGUMENTS:
%  detectMat: matrix of black and transparent bead detections with 3 infos (col)
%             for each detection (row):
%               1. x-coordinate of the detection
%               2. y-coordinate of the detection
%               3. category of the detection ('0' for black bead, '1' for
%                  transparent bead)
%  waterLine: vector of the y-positions of the water line for each x-position.
%             (returned empty if water lines not needed)
%
% Hugo Lafaye de Micheaux, 2019

%initialize variables
image2=image;
waterLine=[];
detectMatBlackBeads=[];
detectMatTransBeads=[];

%remove the base of the flume
if dp.boolRemoveBase
    image2=RemoveBaseFromMask(image,baseMask,2*dp.radBlackBeadPx);
end

%detect black beads
if dp.boolBlackBeadDetect
    detectMatBlackBeads=DetectBlackBeads(image2,dp.threshBlackBeadDetect,...
        dp.radBlackBeadPx);
end

%detect and remove the water line with the help of the black bead detections
if dp.boolWaterLineDetect
    waterLine=DetectWaterLine(image2,detectMatBlackBeads,dp.radBlackBeadPx,...
        dp.threshWaterLineStd);
    image2=RemoveWaterLine(image2,waterLine);
end

%remove false black bead detections using the water line
%and then change true black bead detections into closing
if dp.boolBlackBeadDetect
    detectMatBlackBeads=RemoveDetectionAboveUnderLine(detectMatBlackBeads,...
        waterLine,dp.imSize,'above');
    if dp.boolTransBeadDetect
        image2=RemoveBlackBeadsFromDetectMat(image2,detectMatBlackBeads,...
            dp.radBlackBeadPx);
    end
end

%detect transparent beads
if dp.boolTransBeadDetect
    %remove residual black disks (eg. the ones entering and not yet detected)
    image2=RemoveBlackDisks(image2,dp.threshBlackBeadDetect,dp.radBlackBeadPx);

    %detect transparents beads
    detectMatTransBeads=DetectTransBeads(image2,dp.radBlackBeadPx,...
        dp.transBeadDetectHMax,templateTransBead,dp.transBeadDetectRadFilt,...
        dp.transBeadDetectNbFilt,dp.threshTransBeadDetect);

    %remove false transparent bead detections using the water line
    %and the pixel intensities
    detectMatTransBeads=RemoveDetectionAboveUnderLine(detectMatTransBeads,...
        waterLine,dp.imSize,'above');
    detectMatTransBeads=RemoveTransBeadDetectionOnBlackPixels(image,...
        detectMatTransBeads,2*dp.threshBlackBeadDetect);
end

%put both detection type matrices together, with '0' for black beads
%and '1' for transparent beads
flagDetectBlackBeads=zeros(size(detectMatBlackBeads,1),1,'uint16');
flagDetectTransBeads=ones(size(detectMatTransBeads,1),1,'uint16');
detectMat=[[detectMatBlackBeads;detectMatTransBeads],...
    [flagDetectBlackBeads;flagDetectTransBeads]];

end