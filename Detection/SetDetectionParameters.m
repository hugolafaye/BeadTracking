function [dp,flagError] = SetDetectionParameters(dsp,imageFullFiles)
% Set the detection parameters from the settable ones.
%
% INPUT ARGUMENTS:
%  dsp           : structure containing the detection settable parameters.
%  imageFullFiles: cell array of image full files.
%
% OUTPUT ARGUMENTS:
%  dp       : structure containing the detection parameters.
%  flagError: boolean saying if an error occured.
%
% Hugo Lafaye de Micheaux, 2019

%default values
threshBlackBeadDetectMin=25; %min black threshold in case is set automatically  
threshTransBeadDetect=0.25; %transparent bead detection threshold
threshWaterLineStd=0.25; %threshold of standard deviation to validate water line

%copy the detection settable parameters
dp=dsp;

%update the detection settable parameters according to booleans
if dp.boolRemoveBase && ~exist(fullfile(dp.pathImages,dp.baseMaskFile),'file')
    warning('Execution stopped: Inexistent or uncorrect file of base mask.');
    flagError=true;
    return;
elseif ~dp.boolRemoveBase
    dp.baseMaskFile=[];
end
if (dp.boolBlackBeadDetect && dp.threshBlackBeadDetect<0) || ...
        ~dp.boolBlackBeadDetect
    dp.threshBlackBeadDetect=max(ComputeAutomaticBlackThreshold(...
        imread(imageFullFiles{1})),threshBlackBeadDetectMin);
end
if dp.boolTransBeadDetect && ...
        ~exist(fullfile(dp.pathImages,dp.templateTransBeadFile),'file')
    warning(['Execution stopped: Inexistent or uncorrect file of ',...
        'transparent bead template.']);
    flagError=true;
    return;
elseif dp.boolTransBeadDetect && dp.threshTransBeadDetect<0
    dp.threshTransBeadDetect=threshTransBeadDetect;
elseif ~dp.boolTransBeadDetect
    dp.templateTransBeadFile=[];
    dp.threshTransBeadDetect=[];
    dp.transBeadDetectHMax=[];
    dp.transBeadDetectRadFilt=[];
    dp.transBeadDetectNbFilt=[];
end
if dp.boolWaterLineDetect && dp.threshWaterLineStd<0
    dp.threshWaterLineStd=threshWaterLineStd;
elseif ~dp.boolWaterLineDetect
    dp.threshWaterLineStd=[];
end

%additionnal parameters needed for the detection
%image size, nb images and bead radiuses in pixel
[sp,flagError]=LoadSequenceParameters(fullfile(dp.pathImages,dp.seqParamFile));
if flagError, return; end
dp.imSize=size(imread(imageFullFiles{1}));
dp.nbImages=length(imageFullFiles);
dp.radBlackBeadPx=round(round(sp.diamBlackBead/sp.mByPx)/2);
dp.radTransBeadPx=round(round(sp.diamTransBead/sp.mByPx)/2);
dp.radTransBeadPxInside=round(round(sp.diamTransBead/sp.mByPx)*...
    sp.rateDiamTransBeadInside/2);

end



function threshBlack = ComputeAutomaticBlackThreshold(image)
% Set automatically the threshold of black pixels according to 
% gray intensity distribution.
%
% INPUT ARGUMENTS:
%  image: grayscale image.
%
% OUTPUT ARGUMENTS:
%  threshBlack: threshold separating black pixels from the rest.

[nelements,centers]=hist(single(image(:)),50);
localPeakIdx=imregionalmax(nelements);
localPeakThresh=centers(localPeakIdx);
threshBlack=localPeakThresh(1);

end