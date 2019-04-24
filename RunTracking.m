function RunTracking(tspIn,boolGui,boolAssign)
% Main function to track black and transparent beads in a sequence of images 
% starting from a file of detection results.
%
% The function can have from 0 to 3 input parameters, all are not mandatory,
% they are set to default values if absent. Several ways to call the function:
%
% RunTracking(0,0)
%   Set default tracking settable parameters and ask user to select valid 
%   paths and files.
%
% RunTracking('',...)
%   Ask user to select a file of tracking settable parameters and load its
%   parameters.
%
% RunTracking(tspFullFile,...)
%   Load the tracking settable parameters of a TSP file.
%
% RunTracking(tspStruct,...)
%   Load the tracking settable parameters of a TSP structure.
%
% RunTracking(~,1,...)
%   Launch a GUI to set the tracking settable parameters by hand.
%
% RunTracking(~,~,0)
%   Do not export the tracking result variables to the matlab workspace.
%
% INPUT ARGUMENTS:
%  tspIn     : tracking settable parameters, can be 0, empty, a full file or a
%              structure (default 0).
%  boolGui   : boolean for using a user interface to set the tracking settable
%              parameters (default true).
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



fprintf('-----------------------------------------\n');
fprintf(' TRACKING OF BLACK AND TRANSPARENT BEADS \n');
fprintf('-----------------------------------------\n');



%-------------------------------------------------------------------------------
% SET DEFAULT PARAMETERS
%-------------------------------------------------------------------------------

%set path to package (add it to matlab path) and path to data
pathPackage=fileparts(mfilename('fullpath'));%addpath(genpath(pathPackage));
pathData=fullfile(pathPackage,'Data');
if ~exist(pathData,'dir')
    warning(['Execution continue: Inexistent or uncorrect folder of the ',...
            'data, please select a valid one. For futur use, set pathData ',...
            'at the beginning of RunTracking.m']);
    pathData=uigetdir('','Select the folder of data');
end

%set default parameters
folderImages                 = 'BaumerBimAmont20'; %folder of images
folderResults                = 'Results'; %folder where to store the results
seqParamFile                 = 'sequence_param.txt'; %sequence parameters file
detectDataFile               = ''; %detection results file
trackDataFilePrefix          = 'trackdata_det'; %prefix of the output file
trackSettableParamFileSuffix = 'settable_param'; %suffix of the parameter file
boolBlackBeadTrack           = true; %boolean for tracking black beads
boolTransBeadTrack           = true; %boolean for tracking transparent beads
boolComputeMotionStates      = true; %boolean for computing motion states
boolVisualizeTrajectories    = true; %boolean for visualizing trajectories
msVeloRest                   = 0.005; %[0,+Inf] threshold for resting velocity (in m/s)
msVeloSalt                   = 0.28; %[0,+Inf] threshold for saltating velocity (in m/s) -> vMax/3
msFactNeigh                  = 1.07; %[0,+Inf] threshold of distance between neighbors



%-------------------------------------------------------------------------------
% SET TRACKING SETTABLE PARAMETERS (ALSO CALLED TSP)
%-------------------------------------------------------------------------------

%set default settings according to inputs
if nargin<3, boolAssign=true; end
if nargin<2, boolGui=true; end
if nargin<1, tspIn=0; end
boolOverwrite=false;

%set the TSP according to inputs
%in case no input or 1st input is 0, use default values and select paths/files
%by hand if no GUI is asked
if isnumeric(tspIn) && tspIn==0
    
    %set path to images
    tsp.pathImages=fullfile(pathData,folderImages);
    if ~boolGui && ~exist(tsp.pathImages,'dir')
        warning(['Execution continue: Inexistent or uncorrect folder of ',...
            'images, please select a valid one.']);
        tsp.pathImages=uigetdir(pathData,'Select the folder of a sequence');
    end
    
    %set path to results
    tsp.pathResults=fullfile(tsp.pathImages,folderResults);
    if ~boolGui && ~exist(tsp.pathResults,'dir')
        warning(['Execution continue: Inexistent or uncorrect folder of ',...
            'detection results, please select a valid one.']);
        tsp.pathResults=uigetdir(pathImages,...
            'Select the folder where to store the results');
    end
    
    %set file of sequence parameters
    tsp.seqParamFile=seqParamFile;
    if ~boolGui && exist(fullfile(tsp.pathImages,tsp.seqParamFile),'file')~=2
        warning(['Execution continue: Inexistent or uncorrect file of ',...
            'sequence parameters, please select a valid one.']);
        [tsp.seqParamFile,~]=uigetfile(fullfile(tsp.pathImages,'*.txt'),...
            'Select the file of sequence parameters');
    end
    
    %set file of detection results
    tsp.detectDataFile=detectDataFile;
    if ~boolGui && exist(fullfile(tsp.pathResults,tsp.detectDataFile),'file')~=2
        warning(['Execution continue: Inexistent or uncorrect file of ',...
            'detection results, please select a valid one.']);
        [tsp.detectDataFile,tsp.pathResults]=uigetfile(...
            fullfile(tsp.pathImages,'*.mat'),...
            'Select a file of detection results');
        tsp.pathImages=fileparts(tsp.pathResults(1:end-1));
        if ~boolGui, boolOverwrite=true; end
    end
    
    %set other tracking settable parameters
    tsp.trackDataFilePrefix=trackDataFilePrefix;
    tsp.trackSettableParamFileSuffix=trackSettableParamFileSuffix;
    tsp.boolBlackBeadTrack=boolBlackBeadTrack;
    tsp.boolTransBeadTrack=boolTransBeadTrack;
    tsp.boolComputeMotionStates=boolComputeMotionStates;
    tsp.boolVisualizeTrajectories=boolVisualizeTrajectories;
    tsp.msVeloRest=msVeloRest;
    tsp.msVeloSalt=msVeloSalt;
    tsp.msFactNeigh=msFactNeigh;
    
%in case 1st input is empty, select a TSP file by hand and load its parameters
elseif isempty(tspIn)
    [tspFile,pathTsp]=uigetfile(fullfile(pathData,'*_settable_param.txt'),...
        'Select a file with the settable parameters of a previous tracking');
    [tsp,flagError]=LoadTrackingSettableParameters(fullfile(pathTsp,tspFile));
    if flagError, return; end
    if nargin<2, boolGui=false; end
    if ~boolGui, boolOverwrite=true; end

%in case 1st input is a TSP file, load its parameters
elseif ischar(tspIn) && exist(tspIn,'file')==2
    [tsp,flagError]=LoadTrackingSettableParameters(tspIn);
    if flagError, return; end
    if nargin<2, boolGui=false; end
    if ~boolGui, boolOverwrite=true; end
    
%in case 1st input is a TSP structure, use its parameters
elseif isstruct(tspIn)
    tsp=tspIn;
    if nargin<2, boolGui=false; end
    if ~boolGui, boolOverwrite=true; end

%in other cases, stop execution and rise an error
else
    warning(['Execution stopped: 1st input should be 0, empty, an existing ',...
        'TSP file or a TSP structure.']);
    return;
end

%launch a GUI to edit the TSP
if boolGui
    [tsp,guiRun]=TrackingGui(tsp);
    if ~guiRun
        warning(['Execution stopped: GUI has been closed by the CANCEL ',...
            'button or by the close figure button.']);
        return;
    end
end



%-------------------------------------------------------------------------------
% SET OTHER TRACKING PARAMETERS FROM THE SETTABLE ONES
%-------------------------------------------------------------------------------

fprintf('Sequence ''%s''\n',tsp.pathImages);
fprintf('Setting parameters...\n');

%get the detection results
if exist(fullfile(tsp.pathResults,tsp.detectDataFile),'file')==2
    load(fullfile(tsp.pathResults,tsp.detectDataFile),...
        'imageFullFiles','detectParam','detectData');
else
    warning(['Execution stopped: Inexistent or uncorrect file of ',...
        'detection results.']);
    return;
end
if ~tsp.boolBlackBeadTrack
    detectData=cellfun(@(x)x(x(:,3)~=0,:),detectData,'uni',0);
end
if ~tsp.boolTransBeadTrack
    detectData=cellfun(@(x)x(x(:,3)~=1,:),detectData,'uni',0);
end

%set the tracking parameters
[trackParam,flagError]=SetTrackingParameters(tsp,detectParam);
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
    if ~boolOverwrite
        warning(['Execution stopped: A file of tracking results already ',...
            'exists with the same name.']);
        return;
    else
        warning(['Execution continue: A file of tracking results already ',...
            'exists with the same name, it will be overwritten.']);
    end
end

%save the TSP in a txt file
tspFile=[trackDataFile,'_',trackParam.trackSettableParamFileSuffix,'.txt'];
SaveTrackingSettableParameters(fullfile(trackParam.pathResults,tspFile),...
    trackParam);



%-------------------------------------------------------------------------------
% COMPUTE TRACKING
%-------------------------------------------------------------------------------

%track black and transparent beads in the sequence of images
fprintf('Tracking beads...\n');
%profile on -history -historysize 100000000 -timer 'real'
[trackData,trackInfo]=ComputeTracking(detectData,trackParam);
%profile viewer

%save the tracking results and parameters into a file
fprintf('Saving results...\n');
save(fullfile(trackParam.pathResults,[trackDataFile,'.mat']),'tsp',...
    'trackParam','trackData','trackInfo');

%export the variables to the matlab workspace if needed
if boolAssign
    assignin('base','imageFullFiles',imageFullFiles);
    assignin('base','detectParam',detectParam);
    assignin('base','tsp',tsp);
    assignin('base','trackParam',trackParam);
    assignin('base','trackData',trackData);
    assignin('base','trackInfo',trackInfo);
end



%-------------------------------------------------------------------------------
% COMPUTE MOTION STATES
%-------------------------------------------------------------------------------

%compute the motion states
if trackParam.boolComputeMotionStates
    fprintf('Computing motion states...\n');
    nbTargets=size(trackInfo,1);
    [trackData,trackNbMS]=ComputeMotionStates(trackData,trackParam,nbTargets);
    
    %save the tracking results updated with the motion states
    %and the parameters into a file
    fprintf('Saving results...\n');
    save(fullfile(trackParam.pathResults,[trackDataFile,'.mat']),'tsp',...
        'trackParam','trackData','trackInfo','trackNbMS');
    
    %export the variables to the matlab workspace if needed
    if boolAssign
        assignin('base','trackData',trackData);
        assignin('base','trackNbMS',trackNbMS);
    end
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