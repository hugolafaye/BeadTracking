function SaveDetectionSettableParameters(dspFullFile,dsp)
% Save the detection settable parameters in a file.
%
% INPUT ARGUMENTS:
%  dspFullFile: full file where to save the detection settable parameters.
%  dsp        : structure containing the detection settable parameters.
%
% Copyright (c) 2019, Hugo Lafaye de Micheaux, Thomas Gautrais, Université
% Jean Monnet, CNRS, Irstea
% All rights reserved.
%
% This source code is part of the BeadTracking package
% <https://github.com/hugolafaye/BeadTracking> and it is licensed under the
% BSD-style license found in the LICENSE file in the root directory of this
% source tree.

fid=fopen(dspFullFile,'w');
fprintf(fid,'pathImages = %s\n',dsp.pathImages);
fprintf(fid,'pathResults = %s\n',dsp.pathResults);
fprintf(fid,'seqParamFile = %s\n',dsp.seqParamFile);
fprintf(fid,'baseMaskFile = %s\n',dsp.baseMaskFile);
fprintf(fid,'templateTransBeadFile = %s\n',dsp.templateTransBeadFile);
fprintf(fid,'detectDataFilePrefix = %s\n',dsp.detectDataFilePrefix);
fprintf(fid,'detectSettableParamFileSuffix = %s\n',dsp.detectSettableParamFileSuffix);
fprintf(fid,'boolRemoveBase = %d\n',dsp.boolRemoveBase);
fprintf(fid,'boolBlackBeadDetect = %d\n',dsp.boolBlackBeadDetect);
fprintf(fid,'boolTransBeadDetect = %d\n',dsp.boolTransBeadDetect);
fprintf(fid,'boolTransBeadDetectConf = %d\n',dsp.boolTransBeadDetectConf);
fprintf(fid,'boolWaterLineDetect = %d\n',dsp.boolWaterLineDetect);
fprintf(fid,'boolComputeParallel = %d\n',dsp.boolComputeParallel);
fprintf(fid,'boolVisualizeDetections = %d\n',dsp.boolVisualizeDetections);
fprintf(fid,'threshBlackBeadDetect = %d\n',dsp.threshBlackBeadDetect);
fprintf(fid,'threshTransBeadDetect = %g\n',dsp.threshTransBeadDetect);
fprintf(fid,'threshTransBeadDetectConf = %g\n',dsp.threshTransBeadDetectConf);
fprintf(fid,'threshWaterLineStd = %g\n',dsp.threshWaterLineStd);
fprintf(fid,'transBeadDetectHMax = %d\n',dsp.transBeadDetectHMax);
fprintf(fid,'transBeadDetectRadFilt = %d\n',dsp.transBeadDetectRadFilt);
fprintf(fid,'transBeadDetectNbFilt = %d\n',dsp.transBeadDetectNbFilt);
fclose(fid);

end