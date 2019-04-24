function [tsp,flagError] = LoadTrackingSettableParameters(tspFullFile)
% Load the settable parameters of a previous tracking from its file.
%
% INPUT ARGUMENTS:
%  tspFullFile: full file containing the tracking settable parameters.
%
% OUTPUT ARGUMENTS:
%  tsp      : structure containing the tracking settable parameters.
%  flagError: boolean saying if an error occured.
%
% Copyright (c) 2019, Hugo Lafaye de Micheaux, Thomas Gautrais, Université
% Jean Monnet, CNRS, Irstea
% All rights reserved.
%
% This source code is part of the BeadTracking package
% <https://github.com/hugolafaye/BeadTracking> and it is licensed under the
% BSD-style license found in the LICENSE file in the root directory of this
% source tree.

tsp=[];
flagError=false;
try
    fid=fopen(tspFullFile);
    C=textscan(fid,'%s = %s');
    fclose(fid);
    for p=1:length(C{1})
        tsp.(C{1}{p})=C{2}(p);
    end
catch
    warning(['Execution stopped: Inexistent or uncorrect file of tracking ',...
        'settable parameters.']);
    flagError=true;
    return;
end
tsp.pathImages=char(tsp.pathImages);
tsp.pathResults=char(tsp.pathResults);
tsp.seqParamFile=char(tsp.seqParamFile);
tsp.detectDataFile=char(tsp.detectDataFile);
tsp.trackDataFilePrefix=char(tsp.trackDataFilePrefix);
tsp.trackSettableParamFileSuffix=char(tsp.trackSettableParamFileSuffix);
tsp.boolBlackBeadTrack=logical(str2double(tsp.boolBlackBeadTrack));
tsp.boolTransBeadTrack=logical(str2double(tsp.boolTransBeadTrack));
tsp.boolComputeMotionStates=logical(str2double(tsp.boolComputeMotionStates));
tsp.boolVisualizeTrajectories=logical(str2double(tsp.boolVisualizeTrajectories));
tsp.msVeloRest=str2double(tsp.msVeloRest);
tsp.msVeloSalt=str2double(tsp.msVeloSalt);
tsp.msFactNeigh=str2double(tsp.msFactNeigh);

end