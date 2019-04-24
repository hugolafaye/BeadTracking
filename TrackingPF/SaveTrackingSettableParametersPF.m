function SaveTrackingSettableParametersPF(tsppfFullFile,tsppf)
% Save the settable parameters of a particle filter-based tracking in a file.
%
% INPUT ARGUMENTS:
%  tsppfFullFile: full file where to save the settable parameters of a particle
%                 filter-based tracking.
%  tsppf        : structure containing the settable parameters of a particle
%                 filter-based tracking.
%
% Copyright (c) 2019, Hugo Lafaye de Micheaux, Thomas Gautrais, Université
% Jean Monnet, CNRS, Irstea
% All rights reserved.
%
% This source code is part of the BeadTracking package
% <https://github.com/hugolafaye/BeadTracking> and it is licensed under the
% BSD-style license found in the LICENSE file in the root directory of this
% source tree.

fid=fopen(tsppfFullFile,'w');
fprintf(fid,'pathImages = %s\n',tsppf.pathImages);
fprintf(fid,'pathResults = %s\n',tsppf.pathResults);
fprintf(fid,'seqParamFile = %s\n',tsppf.seqParamFile);
fprintf(fid,'detectDataFile = %s\n',tsppf.detectDataFile);
fprintf(fid,'trackDataFilePrefix = %s\n',tsppf.trackDataFilePrefix);
fprintf(fid,'trackSettableParamFileSuffix = %s\n',...
    tsppf.trackSettableParamFileSuffix);
fprintf(fid,'boolBlackBeadTrack = %d\n',tsppf.boolBlackBeadTrack);
fprintf(fid,'boolTransBeadTrack = %d\n',tsppf.boolTransBeadTrack);
fprintf(fid,'boolVisualizeTrajectories = %d\n',tsppf.boolVisualizeTrajectories);
fprintf(fid,'pfNbParticles = %d\n',tsppf.pfNbParticles);
fprintf(fid,'pfXYCovRest = %s\n',...
    strrep(num2str(tsppf.pfXYCovRest(:)','%.2f,'),' ',''));
fprintf(fid,'pfXYCovRoll = %s\n',...
    strrep(num2str(tsppf.pfXYCovRoll(:)','%.2f,'),' ',''));
fprintf(fid,'pfXYCovSalt = %s\n',...
    strrep(num2str(tsppf.pfXYCovSalt(:)','%.2f,'),' ',''));
fprintf(fid,'pfZXYCov = %s\n',...
    strrep(num2str(tsppf.pfZXYCov(:)','%.2f,'),' ',''));
fprintf(fid,'pfGammaCoef = %g\n',tsppf.pfGammaCoef);
fprintf(fid,'dcDeltaCoef = %g\n',tsppf.dcDeltaCoef);
fprintf(fid,'newTrackLength = %d\n',tsppf.newTrackLength);
fprintf(fid,'newTrackCovCoef = %g\n',tsppf.newTrackCovCoef);
fprintf(fid,'lengthEstimRest = %d\n',tsppf.lengthEstimRest);
fprintf(fid,'lengthEstimRoll = %d\n',tsppf.lengthEstimRoll);
fprintf(fid,'lengthEstimSalt = %d\n',tsppf.lengthEstimSalt);
fprintf(fid,'veloRest = %g\n',tsppf.veloRest);
fprintf(fid,'veloSalt = %g\n',tsppf.veloSalt);
fprintf(fid,'factNeigh = %g\n',tsppf.factNeigh);
fprintf(fid,'nbNeighRest = %d\n',tsppf.nbNeighRest);
fprintf(fid,'nbNeighSalt = %d\n',tsppf.nbNeighSalt);
fprintf(fid,'transitionProbabilities = %s\n',...
    strrep(num2str(tsppf.transitionProbabilities(:)','%.2f,'),' ',''));
fclose(fid);

end