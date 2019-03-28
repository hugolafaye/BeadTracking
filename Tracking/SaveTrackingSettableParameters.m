function SaveTrackingSettableParameters(tspFullFile,tsp)
% Save the tracking settable parameters in a file.
%
% INPUT ARGUMENTS:
%  tspFullFile: full file where to save the tracking settable parameters.
%  tsp        : structure containing the tracking settable parameters.
%
% Hugo Lafaye de Micheaux, 2019

fid=fopen(tspFullFile,'w');
fprintf(fid,'pathImages = %s\n',tsp.pathImages);
fprintf(fid,'pathResults = %s\n',tsp.pathResults);
fprintf(fid,'seqParamFile = %s\n',tsp.seqParamFile);
fprintf(fid,'detectDataFile = %s\n',tsp.detectDataFile);
fprintf(fid,'trackDataFilePrefix = %s\n',tsp.trackDataFilePrefix);
fprintf(fid,'trackSettableParamFileSuffix = %s\n',tsp.trackSettableParamFileSuffix);
fprintf(fid,'boolBlackBeadTrack = %d\n',tsp.boolBlackBeadTrack);
fprintf(fid,'boolTransBeadTrack = %d\n',tsp.boolTransBeadTrack);
fprintf(fid,'boolComputeMotionStates = %d\n',tsp.boolComputeMotionStates);
fprintf(fid,'boolVisualizeTrajectories = %d\n',tsp.boolVisualizeTrajectories);
fprintf(fid,'msVeloRest = %g\n',tsp.msVeloRest);
fprintf(fid,'msVeloSalt = %g\n',tsp.msVeloSalt);
fprintf(fid,'msFactNeigh = %g\n',tsp.msFactNeigh);
fclose(fid);

end