function [detectData,waterData] = ComputeDetection(imageFullFiles,dp)
% Compute the detection of black and transparent beads and water lines in a  
% sequence of images.
%
% INPUT ARGUMENTS:
%  imageFullFiles: cell array of image full files.
%  dp            : structure containing the detection parameters.
%
% OUTPUT ARGUMENTS:
%  detectData: cell array of detection matrices. One detection matrix for each
%              image of the sequence. A detection matrix has 3 infos (col) for
%              each detection (row) of the image:
%                1. x-coordinate of the detection
%                2. y-coordinate of the detection
%                3. category of the detection ('0' for black bead, '1' for
%                   transparent bead)
%  waterData : cell array of water lines. One water line for each image of the
%              sequence, ie. a vector of the y-positions of the water line for
%              each x-position. (returned empty if water lines not needed)
%
% Hugo Lafaye de Micheaux, 2019

%load base mask if needed
baseMask=[];
if dp.boolRemoveBase
    baseMask=imread(fullfile(dp.pathImages,dp.baseMaskFile));
end

%load template transparent bead if needed
templateTransBead=[];
if dp.boolTransBeadDetect
    templateTransBead=load(fullfile(dp.pathImages,dp.templateTransBeadFile));
    templateTransBead=templateTransBead.templateTransBead;
end

%prepare empty detection matrices
detectData=cell(1,dp.nbImages);
waterData=cell(1,dp.nbImages);

%compute detection
if dp.boolComputeParallel
    if isempty(gcp('nocreate')), parpool; end
    t=now;
    ParforProgress(t,dp.nbImages);
    parfor im=1:dp.nbImages
        [detectData{im},waterData{im}]=...
            DetectBeadsWaterLines(imread(imageFullFiles{im}),dp,baseMask,...
                templateTransBead);
        ParforProgress(t,0,im);
    end
    ParforProgress(t,0);
else
    t=now;
    ParforProgress(t,dp.nbImages);
    for im=1:dp.nbImages
        [detectData{im},waterData{im}]=...
            DetectBeadsWaterLines(imread(imageFullFiles{im}),dp,baseMask,...
                templateTransBead);
        ParforProgress(t,0,im);
    end
    ParforProgress(t,0);
end

%if the detection of water lines is not requested, return an empty cell
%instead of a cell array of empty matrices (for memory matters)
if ~dp.boolWaterLineDetect, waterData={}; end

end