function [detectData,waterData,detectConfData] = ComputeDetection(...
    imageFullFiles,dp)
% Compute the detection of black and transparent beads and water lines in a  
% sequence of images. Compute the detector confidence of transparent beads if
% needed.
%
% INPUT ARGUMENTS:
%  imageFullFiles: cell array of image full files.
%  dp            : structure containing the detection parameters.
%
% OUTPUT ARGUMENTS:
%  detectData    : cell array of detection matrices. One detection matrix for
%                  each image of the sequence. A detection matrix has 3 infos
%                  (col) for each detection (row) of the image:
%                    1. x-coordinate of the detection
%                    2. y-coordinate of the detection
%                    3. category of the detection ('0' for black bead, '1' for
%                       transparent bead)
%  waterData     : cell array of water lines. One water line for each image of
%                  the sequence, ie. a vector of the y-positions of the water
%                  line for each x-position. (returned empty if water lines not
%                  needed).
%  detectConfData: cell array of detector confidence matrices for transparent
%                  beads. One detector confidence matrix for each image of the
%                  sequence. A detector confidence matrix has 3 infos (col) for
%                  each detection (row) of the image:
%                    1. x-coordinate of the detection
%                    2. y-coordinate of the detection
%                    3. correlation value with the transparent bead template
%                  (returned empty if detector confidences not needed)
%
% Copyright (c) 2019, Hugo Lafaye de Micheaux, Thomas Gautrais, Université
% Jean Monnet, CNRS, Irstea
% All rights reserved.
%
% This source code is part of the BeadTracking package
% <https://github.com/hugolafaye/BeadTracking> and it is licensed under the
% BSD-style license found in the LICENSE file in the root directory of this
% source tree.

%load base mask if needed
baseMask=[];
if dp.boolRemoveBase
    baseMask=imread(fullfile(dp.pathImages,dp.baseMaskFile));
end

%load transparent bead template if needed
templateTransBead=[];
if dp.boolTransBeadDetect
    templateTransBead=load(fullfile(dp.pathImages,dp.templateTransBeadFile));
    templateTransBead=templateTransBead.templateTransBead;
end

%initialize detection matrices
detectData=cell(1,dp.nbImages);
waterData=cell(1,dp.nbImages);
detectConfData=cell(1,dp.nbImages);

%compute detection
nbW=0;
v=ver;
if dp.boolComputeParallel && find(ismember({v.Name},'Parallel Computing Toolbox'))
    p=parcluster(parallel.defaultClusterProfile);
    nbW=p.NumWorkers;
    if isempty(gcp('nocreate')) && nbW~=0, parpool(nbW); end
end
t=now;
ParforProgress(t,dp.nbImages);
parfor(im=1:dp.nbImages,nbW)
    [detectData{im},waterData{im},detectConfData{im}]=...
        DetectBeadsWaterLines(imread(imageFullFiles{im}),dp,baseMask,...
            templateTransBead);
    ParforProgress(t,0,im);
end
ParforProgress(t,0);
delete(gcp('nocreate'));

%if the detection of water lines and/or the computing of detector confidences
%are not requested, return empty cells instead of cell arrays of empty matrices
%(for memory matters)
if ~dp.boolWaterLineDetect, waterData={}; end
if ~dp.boolTransBeadDetectConf, detectConfData={}; end

end