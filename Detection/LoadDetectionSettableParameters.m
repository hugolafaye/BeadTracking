function [dsp,flagError] = LoadDetectionSettableParameters(dspFullFile)
% Load the settable parameters of a previous detection from its file.
%
% INPUT ARGUMENTS:
%  dspFullFile: full file containing the detection settable parameters.
%
% OUTPUT ARGUMENTS:
%  dsp      : structure containing the detection settable parameters.
%  flagError: boolean saying if an error occured.
%
% Hugo Lafaye de Micheaux, 2019

dsp=[];
flagError=false;
try
    fid=fopen(dspFullFile);
    C=textscan(fid,'%s = %s');
    fclose(fid);
    for p=1:length(C{1})
        dsp.(C{1}{p})=C{2}(p);
    end
catch
    warning(['Execution stopped: Inexistent or uncorrect file of detection ',...
        'settable parameters.']);
    flagError=true;
    return;
end
dsp.pathImages=char(dsp.pathImages);
dsp.pathResults=char(dsp.pathResults);
dsp.seqParamFile=char(dsp.seqParamFile);
dsp.baseMaskFile=char(dsp.baseMaskFile);
dsp.templateTransBeadFile=char(dsp.templateTransBeadFile);
dsp.detectDataFilePrefix=char(dsp.detectDataFilePrefix);
dsp.detectSettableParamFileSuffix=char(dsp.detectSettableParamFileSuffix);
dsp.boolRemoveBase=logical(str2double(dsp.boolRemoveBase));
dsp.boolBlackBeadDetect=logical(str2double(dsp.boolBlackBeadDetect));
dsp.boolTransBeadDetect=logical(str2double(dsp.boolTransBeadDetect));
dsp.boolWaterLineDetect=logical(str2double(dsp.boolWaterLineDetect));
dsp.boolComputeParallel=logical(str2double(dsp.boolComputeParallel));
dsp.boolVisualizeDetections=logical(str2double(dsp.boolVisualizeDetections));
dsp.threshBlackBeadDetect=str2double(dsp.threshBlackBeadDetect);
dsp.threshTransBeadDetect=str2double(dsp.threshTransBeadDetect);
dsp.threshWaterLineStd=str2double(dsp.threshWaterLineStd);
dsp.transBeadDetectHMax=str2double(dsp.transBeadDetectHMax);
dsp.transBeadDetectRadFilt=str2double(dsp.transBeadDetectRadFilt);
dsp.transBeadDetectNbFilt=str2double(dsp.transBeadDetectNbFilt);

end