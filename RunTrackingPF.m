function RunTrackingPF(tsppfIn,boolAssign)
% Main function to track by multi-model particle filtering black and transparent
% beads in a sequence of images starting from a file of detection results.
%
% The function can have from 0 to 2 input parameters, all are not mandatory,
% they are set to default values if absent. Several ways to call the function:
%
% RunTrackingPF(0)
%   Set default settable parameters of a particle filter-based tracking and ask
%   user to select valid paths and files.
%
% RunTrackingPF('',...)
%   Ask user to select a file of settable parameters of a particle filter-based
%   tracking and load its parameters.
%
% RunTrackingPF(tsppfFullFile,...)
%   Load the settable parameters of a particle filter-based tracking of a TSPPF
%   file.
%
% RunTrackingPF(tsppfStruct,...)
%   Load the settable parameters of a particle filter-based tracking of a TSPPF
%   structure.
%
% RunTrackingPF(~,0)
%   Do not export the tracking result variables to the matlab workspace.
%
% INPUT ARGUMENTS:
%  tsppfIn   : settable parameters of a particle filter-based tracking, can be 0,
%              empty, a full file or a structure (default 0).
%  boolAssign: boolean for exporting the tracking results in the matlab 
%              workspace (default true).
%
% Copyright (c) 2019, Hugo Lafaye de Micheaux, Thomas Gautrais, Université
% Jean Monnet, CNRS, Irstea
% All rights reserved.
%
% This source code is part of the BeadTracking package
% <https://github.com/hugolafaye/BeadTracking> and it is licensed under the
% BSD-style license found in the LICENSE file in the root directory of this
% source tree.



fprintf('---------------------------------------------------------------\n');
fprintf(' TRACKING OF BLACK AND TRANSPARENT BEADS BY PARTICLE FILTERING \n');
fprintf('---------------------------------------------------------------\n');



%reset the random number generation
rng default



%-------------------------------------------------------------------------------
% SET DEFAULT PARAMETERS
%-------------------------------------------------------------------------------

%set path to package (add it to matlab path) and path to data
pathPackage=fileparts(mfilename('fullpath'));%addpath(genpath(pathPackage));
pathData=fullfile(pathPackage,'Data');
if ~exist(pathData,'dir')
    warning(['Execution continue: Inexistent or uncorrect folder of the ',...
            'data, please select a valid one. For futur use, set pathData ',...
            'at the beginning of RunTrackingPF.m']);
    pathData=uigetdir('','Select the folder of data');
end

%set default parameters
folderImages                 = 'BaumerBimAmont20'; %folder of images
folderResults                = 'Results'; %folder where to store the results
seqParamFile                 = 'sequence_param.txt'; %sequence parameters file
detectDataFile               = ''; %detection results file
trackDataFilePrefix          = 'trackdata_pf'; %prefix of the output file
trackSettableParamFileSuffix = 'settable_param'; %suffix of the parameter file
boolBlackBeadTrack           = true; %boolean for tracking black beads
boolTransBeadTrack           = true; %boolean for tracking transparent beads
boolVisualizeTrajectories    = true; %boolean for visualizing trajectories
pfNbParticles                = 100; %number of particles for the particle filter
pfXYCovRest                  = [0.25,0;0,0.25]; %noise covariances of estimated position for resting
pfXYCovRoll                  = 4*[0.76,0.01;0.01,0.55]; %noise covariances of estimated position for rolling
pfXYCovSalt                  = 4*[5.04,-3.25;-3.25,5.13]; %%noise covariances of estimated position for saltating
pfZXYCov                     = [3,0;0,3]; %covariance of likehood in particle weights computing
pfGammaCoef                  = 0.67; %reward coef for correct motion state estimations
dcDeltaCoef                  = 1; %decreasing exponential coef of detector confidence
newTrackLength               = 3; %length of tracks considered as new
newTrackCovCoef              = 1.5; %coef multiplying noise covariances of new tracks
lengthEstimRest              = 100; %max nb of estimations without detections for resting
lengthEstimRoll              = 10; %max nb of estimations without detections for rolling
lengthEstimSalt              = 5; %max nb of estimations without detections for saltating
veloRest                     = 0.015; %[0,+Inf] threshold for resting velocity (in m/s)
veloSalt                     = 0.25; %[0,+Inf] threshold for saltating velocity (in m/s)
factNeigh                    = 1.07; %[0,+Inf] threshold of distance between neighbors
nbNeighRest                  = 5; %nb of neighbors at resting state
nbNeighSalt                  = 0; %nb of neighbors at saltating state
transitionProbabilities      = [0.80,0.15,0.05;...%proba rest to (rest,roll,salt)
                                0.10,0.80,0.10;...%proba roll to (rest,roll,salt)
                                0.05,0.15,0.80;...%proba salt to (rest,roll,salt)
                                0.33,0.33,0.34];  %proba unknown to (rest,roll,salt)



%------------------------------------------------------------------------------------
% SET THE SETTABLE PARAMETERS OF A PARTICLE FILTER-BASED TRACKING (ALSO CALLED TSPPF)
%------------------------------------------------------------------------------------

%set default settings according to inputs
if nargin<2, boolAssign=true; end
if nargin<1, tsppfIn=0; end

%set the TSPPF according to inputs
%in case no input or 1st input is 0, use default values and select paths/files
%by hand
if isnumeric(tsppfIn) && tsppfIn==0
    
    %set path to images
    tsppf.pathImages=fullfile(pathData,folderImages);
    if ~exist(tsppf.pathImages,'dir')
        warning(['Execution continue: Inexistent or uncorrect folder of ',...
            'images, please select a valid one.']);
        tsppf.pathImages=uigetdir(pathData,'Select the folder of a sequence');
    end
    
    %set path to results
    tsppf.pathResults=fullfile(tsppf.pathImages,folderResults);
    if ~exist(tsppf.pathResults,'dir')
        warning(['Execution continue: Inexistent or uncorrect folder of ',...
            'detection results, please select a valid one.']);
        tsppf.pathResults=uigetdir(pathImages,...
            'Select the folder where to store the results');
    end
    
    %set file of sequence parameters
    tsppf.seqParamFile=seqParamFile;
    if exist(fullfile(tsppf.pathImages,tsppf.seqParamFile),'file')~=2
        warning(['Execution continue: Inexistent or uncorrect file of ',...
            'sequence parameters, please select a valid one.']);
        [tsppf.seqParamFile,~]=uigetfile(fullfile(tsppf.pathImages,'*.txt'),...
            'Select the file of sequence parameters');
    end
    
    %set file of detection results
    tsppf.detectDataFile=detectDataFile;
    if exist(fullfile(tsppf.pathResults,tsppf.detectDataFile),'file')~=2
        warning(['Execution continue: Inexistent or uncorrect file of ',...
            'detection results, please select a valid one.']);
        [tsppf.detectDataFile,tsppf.pathResults]=uigetfile(...
            fullfile(tsppf.pathImages,'*.mat'),...
            'Select a file of detection results');
        tsppf.pathImages=fileparts(tsppf.pathResults(1:end-1));
    end
    
    %set other settable parameters of the particle filter-based tracking
    tsppf.trackDataFilePrefix=trackDataFilePrefix;
    tsppf.trackSettableParamFileSuffix=trackSettableParamFileSuffix;
    tsppf.boolBlackBeadTrack=boolBlackBeadTrack;
    tsppf.boolTransBeadTrack=boolTransBeadTrack;
    tsppf.boolVisualizeTrajectories=boolVisualizeTrajectories;
    tsppf.pfNbParticles=pfNbParticles;
    tsppf.pfXYCovRest=pfXYCovRest;
    tsppf.pfXYCovRoll=pfXYCovRoll;
    tsppf.pfXYCovSalt=pfXYCovSalt;
    tsppf.pfZXYCov=pfZXYCov;
    tsppf.pfGammaCoef=pfGammaCoef;
    tsppf.dcDeltaCoef=dcDeltaCoef;
    tsppf.newTrackLength=newTrackLength;
    tsppf.newTrackCovCoef=newTrackCovCoef;
    tsppf.lengthEstimRest=lengthEstimRest;
    tsppf.lengthEstimRoll=lengthEstimRoll;
    tsppf.lengthEstimSalt=lengthEstimSalt;
    tsppf.veloRest=veloRest;
    tsppf.veloSalt=veloSalt;
    tsppf.factNeigh=factNeigh;
    tsppf.nbNeighRest=nbNeighRest;
    tsppf.nbNeighSalt=nbNeighSalt;
    tsppf.transitionProbabilities=transitionProbabilities;
    
%in case 1st input is empty, select a TSPPF file by hand and load its parameters
elseif isempty(tsppfIn)
    [tsppfFile,pathTsppf]=uigetfile(fullfile(pathData,'*_settable_param.txt'),...
        ['Select a file with the settable parameters of a previous particle ',...
        'filter tracking']);
    [tsppf,flagError]=LoadTrackingSettableParametersPF(...
        fullfile(pathTsppf,tsppfFile));
    if flagError, return; end

%in case 1st input is a TSPPF file, load its parameters
elseif ischar(tsppfIn) && exist(tsppfIn,'file')==2
    [tsppf,flagError]=LoadTrackingSettableParametersPF(tsppfIn);
    if flagError, return; end
    
%in case 1st input is a TSPPF structure, use its parameters
elseif isstruct(tsppfIn)
    tsppf=tsppfIn;

%in other cases, stop execution and rise an error
else
    warning(['Execution stopped: 1st input should be 0, empty, an existing ',...
        'TSP file or a TSP structure.']);
    return;
end



%----------------------------------------------------------------------------------
% SET OTHER PARAMETERS OF THE PARTICLE FILTER-BASED TRACKING FROM THE SETTABLE ONES
%----------------------------------------------------------------------------------

fprintf('Sequence ''%s''\n',tsppf.pathImages);
fprintf('Setting parameters...\n');

%get the detection results
if exist(fullfile(tsppf.pathResults,tsppf.detectDataFile),'file')==2
    load(fullfile(tsppf.pathResults,tsppf.detectDataFile),...
        'imageFullFiles','detectParam','detectData','detectConfData');
else
    warning(['Execution stopped: Inexistent or uncorrect file of ',...
        'detection results.']);
    return;
end
if ~tsppf.boolBlackBeadTrack
    detectData=cellfun(@(x)x(x(:,3)~=0,:),detectData,'uni',0);
end
if ~tsppf.boolTransBeadTrack
    detectData=cellfun(@(x)x(x(:,3)~=1,:),detectData,'uni',0);
end

%set the tracking parameters
[trackParam,flagError]=SetTrackingParametersPF(tsppf,detectParam);
if flagError, return; end

%set the file name of the tracking results
fileSuffixBlack=[];
fileSuffixTrans=[];
if ~trackParam.boolBlackBeadTrack, fileSuffixBlack='_noBb'; end
if ~trackParam.boolTransBeadTrack, fileSuffixTrans='_noTb'; end
[~,detectDataFileNoExt,~]=fileparts(trackParam.detectDataFile);
trackDataFile=[strrep(detectDataFileNoExt,detectParam.detectDataFilePrefix,...
    trackParam.trackDataFilePrefix),fileSuffixBlack,fileSuffixTrans];
if exist(fullfile(trackParam.pathResults,[trackDataFile,'.mat']),'file')==2
    warning(['Execution continue: A file of tracking results already ',...
            'exists with the same name, it will be overwritten.']);
end

%save the TSP in a txt file
tsppfFile=[trackDataFile,'_',trackParam.trackSettableParamFileSuffix,'.txt'];
SaveTrackingSettableParametersPF(fullfile(trackParam.pathResults,tsppfFile),...
    trackParam);



%-------------------------------------------------------------------------------
% COMPUTE PARTICLE FILTER-BASED TRACKING
%-------------------------------------------------------------------------------

%track by particle filtering black and transparent beads in the sequence of
%images
fprintf('Tracking beads...\n');
%profile on -history -historysize 100000000 -timer 'real'
[trackData,trackInfo,trackNbMS]=ComputeTrackingPF(detectData,trackParam,...
    detectConfData);
%profile viewer

%save the tracking results and parameters into a file
fprintf('Saving results...\n');
save(fullfile(trackParam.pathResults,[trackDataFile,'.mat']),'tsppf',...
    'trackParam','trackData','trackInfo','trackNbMS');

%export the variables to the matlab workspace if needed
if boolAssign
    assignin('base','imageFullFiles',imageFullFiles);
    assignin('base','detectParam',detectParam);
    assignin('base','tsppf',tsppf);
    assignin('base','trackParam',trackParam);
    assignin('base','trackData',trackData);
    assignin('base','trackInfo',trackInfo);
    assignin('base','trackNbMS',trackNbMS);
end



%-------------------------------------------------------------------------------
% COMPUTE VISUALIZATION
%-------------------------------------------------------------------------------

%visualize the sequence of trajectories in a video and save it into an .avi file
if trackParam.boolVisualizeTrajectories
    fprintf('Visualizing trajectories...\n');
    PlayVideoTrajectories(...
        fullfile(trackParam.pathResults,[trackDataFile,'.avi']),...
        imageFullFiles,trackData,trackInfo,trackParam.acqFreq);
    %or
    %PlayVideoTrajectories(...
    %    fullfile(trackParam.pathResults,[trackDataFile,'.avi']),...
    %    fullfile(trackParam.pathResults,[trackDataFile,'.mat']),...
    %    trackParam.acqFreq);
end

end