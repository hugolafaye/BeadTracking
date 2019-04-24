function [tppf,flagError] = SetTrackingParametersPF(tsppf,dp)
% Set the parameters of a particle filter-based tracking from the settable ones.
%
% INPUT ARGUMENTS:
%  tsppf: structure containing the settable parameters of a particle
%         filter-based tracking.
%  dp   : structure containing the detection parameters.
%
% OUTPUT ARGUMENTS:
%  tppf     : structure containing the parameters of the particle filter-based
%             tracking.
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

%copy the settable parameters of the particle filter-based tracking
tppf=tsppf;

%update the settable parameters of the particle filter-based tracking according
%to booleans
if ~tppf.boolTransBeadTrack
    tppf.dcDeltaCoef=[];
end

%additionnal parameters needed for the tracking
%image size, nb images, pixel size in meter, search radius in pixel for the
%association step and some distances in pixel for the motion states computation
[sp,flagError]=LoadSequenceParameters(fullfile(dp.pathImages,...
    tsppf.seqParamFile));
if flagError, return; end
tppf.flumeDirection=sp.flumeDirection;
tppf.imSize=dp.imSize;
tppf.nbImages=dp.nbImages;
tppf.mByPx=sp.mByPx;
tppf.acqFreq=sp.acqFreq;
tppf.radBlackBeadPx=dp.radBlackBeadPx;
tppf.radTransBeadPx=dp.radTransBeadPx;
tppf.radSearch=sp.vMax/sp.mByPx/sp.acqFreq;
tppf.threshTransBeadDetectConf=dp.threshTransBeadDetectConf;
tppf.veloSaltInit=sp.flumeDirection*(sp.vMax/sp.mByPx/sp.acqFreq/2);
tppf.distNeighBBeads=sp.diamBlackBead/sp.mByPx;
tppf.distNeighTBeads=sp.diamTransBead/sp.mByPx;
tppf.distNeighBTBeads=mean([sp.diamBlackBead,sp.diamTransBead])/sp.mByPx;


end