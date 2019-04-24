function [tsppf,flagError] = LoadTrackingSettableParametersPF(tsppfFullFile)
% Load the settable parameters of a previous particle filter-based tracking from
% its file.
%
% INPUT ARGUMENTS:
%  tsppfFullFile: full file containing the settable parameters of a particle
%                 filter-based tracking.
%
% OUTPUT ARGUMENTS:
%  tsppf    : structure containing the settable parameters of the particle
%             filter-based tracking.
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

tsppf=[];
flagError=false;
try
    fid=fopen(tsppfFullFile);
    C=textscan(fid,'%s = %s');
    fclose(fid);
    for p=1:length(C{1})
        tsppf.(C{1}{p})=C{2}(p);
    end
catch
    warning(['Execution stopped: Inexistent or uncorrect file of settable ',...
        'parameters of a particle filter-based tracking.']);
    flagError=true;
    return;
end
tsppf.pathImages=char(tsppf.pathImages);
tsppf.pathResults=char(tsppf.pathResults);
tsppf.seqParamFile=char(tsppf.seqParamFile);
tsppf.detectDataFile=char(tsppf.detectDataFile);
tsppf.trackDataFilePrefix=char(tsppf.trackDataFilePrefix);
tsppf.trackSettableParamFileSuffix=char(tsppf.trackSettableParamFileSuffix);
tsppf.boolBlackBeadTrack=logical(str2double(tsppf.boolBlackBeadTrack));
tsppf.boolTransBeadTrack=logical(str2double(tsppf.boolTransBeadTrack));
tsppf.boolVisualizeTrajectories=...
    logical(str2double(tsppf.boolVisualizeTrajectories));
tsppf.pfNbParticles=str2double(tsppf.pfNbParticles);
tsppf.pfXYCovRest=reshape(sscanf(cell2mat(tsppf.pfXYCovRest),'%g,'),[2,2]);
tsppf.pfXYCovRoll=reshape(sscanf(cell2mat(tsppf.pfXYCovRoll),'%g,'),[2,2]);
tsppf.pfXYCovSalt=reshape(sscanf(cell2mat(tsppf.pfXYCovSalt),'%g,'),[2,2]);
tsppf.pfZXYCov=reshape(sscanf(cell2mat(tsppf.pfZXYCov),'%g,'),[2,2]);
tsppf.pfGammaCoef=str2double(tsppf.pfGammaCoef);
tsppf.dcDeltaCoef=str2double(tsppf.dcDeltaCoef);
tsppf.newTrackLength=str2double(tsppf.newTrackLength);
tsppf.newTrackCovCoef=str2double(tsppf.newTrackCovCoef);
tsppf.lengthEstimRest=str2double(tsppf.lengthEstimRest);
tsppf.lengthEstimRoll=str2double(tsppf.lengthEstimRoll);
tsppf.lengthEstimSalt=str2double(tsppf.lengthEstimSalt);
tsppf.veloRest=str2double(tsppf.veloRest);
tsppf.veloSalt=str2double(tsppf.veloSalt);
tsppf.factNeigh=str2double(tsppf.factNeigh);
tsppf.nbNeighRest=str2double(tsppf.nbNeighRest);
tsppf.nbNeighSalt=str2double(tsppf.nbNeighSalt);
tsppf.transitionProbabilities=...
    reshape(sscanf(cell2mat(tsppf.transitionProbabilities),'%g,'),[4,3]);

end