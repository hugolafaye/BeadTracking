function [tp,flagError] = SetTrackingParameters(tsp,dp)
% Set the tracking parameters from the settable ones.
%
% INPUT ARGUMENTS:
%  tsp: structure containing the tracking settable parameters.
%  dp : structure containing the detection parameters.
%
% OUTPUT ARGUMENTS:
%  tp       : structure containing the tracking parameters.
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

%copy the tracking settable parameters
tp=tsp;

%update the tracking settable parameters according to booleans
if ~tp.boolComputeMotionStates
    tp.msVeloRest=[];
    tp.msVeloSalt=[];
    tp.msFactNeigh=[];
end

%additionnal parameters needed for the tracking
%image size, nb images, pixel size in meter, search radius in pixel for the
%association step and some distances in pixel for the motion states computation
[sp,flagError]=LoadSequenceParameters(fullfile(dp.pathImages,tsp.seqParamFile));
if flagError, return; end
tp.imSize=dp.imSize;
tp.nbImages=dp.nbImages;
tp.mByPx=sp.mByPx;
tp.acqFreq=sp.acqFreq;
tp.radSearch=sp.vMax/sp.mByPx/sp.acqFreq;
if tp.boolComputeMotionStates
    tp.msDistNeighBBeads=sp.diamBlackBead/sp.mByPx;
    tp.msDistNeighTBeads=sp.diamTransBead/sp.mByPx;
    tp.msDistNeighBTBeads=mean([sp.diamBlackBead,sp.diamTransBead])/sp.mByPx;
else
    tp.msDistNeighBBeads=[];
    tp.msDistNeighTBeads=[];
    tp.msDistNeighBTBeads=[];
end

end