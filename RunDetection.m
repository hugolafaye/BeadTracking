function RunDetection(dspIn,boolGui,boolAssign)
% Main function to detect black and transparent beads and water lines in a  
% sequence of images.
%
% The function can have from 0 to 3 input parameters, all are not mandatory,
% they are set to default values if absent. Several ways to call the function:
%
% RunDetection(0,0)
%   Set default detection settable parameters and ask user to select valid 
%   paths and files.
%
% RunDetection('',...)
%   Ask user to select a file of detection settable parameters and load its
%   parameters.
%
% RunDetection(dspFullFile,...)
%   Load the detection settable parameters of a DSP file.
%
% RunDetection(dspStruct,...)
%   Load the detection settable parameters of a DSP structure.
%
% RunDetection(~,1,...)
%   Launch a GUI to set the detection settable parameters by hand.
%
% RunDetection(~,~,0)
%   Do not export the detection result variables in the matlab workspace.
%
% INPUT ARGUMENTS:
%  dspIn     : detection settable parameters, can be 0, empty, a full file or a
%              structure (default 0).
%  boolGui   : boolean for using a user interface to set the detection 
%              parameters (default true).
%  boolAssign: boolean for exporting the detection results in the matlab 
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



fprintf('-----------------------------------------------------------\n');
fprintf(' DETECTION OF BLACK AND TRANSPARENT BEADS, AND WATER LINES \n');
fprintf('-----------------------------------------------------------\n');



%-------------------------------------------------------------------------------
% SET DEFAULT PARAMETERS
%-------------------------------------------------------------------------------

%set path to package (add it to matlab path) and path to data
pathPackage=fileparts(mfilename('fullpath'));%addpath(genpath(pathPackage));
pathData=fullfile(pathPackage,'Data');
if ~exist(pathData,'dir')
    warning(['Execution continue: Inexistent or uncorrect folder of the ',...
            'data, please select a valid one. For futur use, set pathData ',...
            'at the beginning of RunDetection.m']);
    pathData=uigetdir('','Select the folder of data');
end

%set default parameters
folderImages                  = 'BaumerBimAmont20'; %folder of images
folderResults                 = 'Results'; %folder where to store the results
seqParamFile                  = 'sequence_param.txt'; %sequence parameters file
baseMaskFile                  = 'sequence_base_mask.tif'; %base mask file
templateTransBeadFile         = 'template_transparent_bead_rOut10_rIn6.mat'; %template file
detectDataFilePrefix          = 'detectdata'; %prefix of the output file
detectSettableParamFileSuffix = 'settable_param'; %suffix of the parameter file
boolRemoveBase                = true; %boolean for removing the base of the flume
boolBlackBeadDetect           = true; %boolean for detecting black beads
boolTransBeadDetect           = true; %boolean for detecting transparent beads
boolTransBeadDetectConf       = true; %boolean for computing detector confidence of trans beads
boolWaterLineDetect           = true; %boolean for detecting water lines
boolComputeParallel           = false; %boolean for using parallel computing
boolVisualizeDetections       = true; %boolean for visualizing detections
threshBlackBeadDetect         = -1; %[0,255] if negative, is set automatically from histogram
threshTransBeadDetect         = 0.23; %[0,1] if negative, is set to 0.25
threshTransBeadDetectConf     = 0.20; %[0,1] if negative, is set to 0.20
threshWaterLineStd            = 0.25; %[0,1] if negative, is set to 0.25
transBeadDetectHMax           = 44; %[0,255] in TB detect: value of the heigh hMax
transBeadDetectRadFilt        = 1; %[0,+Inf] in TB detect: radius of mean filter (0=no filter)
transBeadDetectNbFilt         = 2; %[1,+Inf] in TB detect: nb of iterations of the mean filter



%-------------------------------------------------------------------------------
% SET DETECTION SETTABLE PARAMETERS (ALSO CALLED DSP)
%-------------------------------------------------------------------------------

%set default settings according to inputs
if nargin<3, boolAssign=true; end
if nargin<2, boolGui=true; end
if nargin<1, dspIn=0; end
boolOverwrite=false;

%set the DSP according to inputs
%in case no input or 1st input is 0, use default values and select paths/files
%by hand if no GUI is asked
if isnumeric(dspIn) && dspIn==0
    
    %set path to images
    dsp.pathImages=fullfile(pathData,folderImages);
    if ~boolGui && ~exist(dsp.pathImages,'dir')
        warning(['Execution continue: Inexistent or uncorrect folder of ',...
            'images, please select a valid one.']);
        dsp.pathImages=uigetdir(pathData,'Select the folder of a sequence');
    end
    
    %set path to results
    dsp.pathResults=fullfile(dsp.pathImages,folderResults);
    if ~boolGui && ~exist(dsp.pathResults,'dir')
        warning(['Execution continue: Inexistent or uncorrect folder of ',...
            'detection results, please select a valid one.']);
        dsp.pathResults=uigetdir(pathImages,...
            'Select the folder where to store the results');
    end
    
    %set file of sequence parameters
    dsp.seqParamFile=seqParamFile;
    if ~boolGui && exist(fullfile(dsp.pathImages,dsp.seqParamFile),'file')~=2
        warning(['Execution continue: Inexistent or uncorrect file of ',...
            'sequence parameters, please select a valid one.']);
        [dsp.seqParamFile,~]=uigetfile(fullfile(dsp.pathImages,'*.txt'),...
            'Select the file of sequence parameters');
    end
    
    %set file of base mask
    dsp.baseMaskFile=baseMaskFile;
    if ~boolGui && exist(fullfile(dsp.pathImages,dsp.baseMaskFile),'file')~=2
        warning(['Execution continue: Inexistent or uncorrect file of ',...
            'base mask, please select a valid one.']);
        [dsp.baseMaskFile,~]=uigetfile(fullfile(dsp.pathImages,'*.tif'),...
            'Select the file of base mask');
    end
    
    %set file of transparent bead template
    dsp.templateTransBeadFile=templateTransBeadFile;
    if ~boolGui && ...
            exist(fullfile(dsp.pathImages,dsp.templateTransBeadFile),'file')~=2
        warning(['Execution continue: Inexistent or uncorrect file of ',...
            'transparent bead template, please select a valid one.']);
        [dsp.templateTransBeadFile,~]=uigetfile(fullfile(dsp.pathImages,'*.mat'),...
            'Select the file of transparent bead template');
    end
    
    %set other detection settable parameters
    dsp.detectDataFilePrefix=detectDataFilePrefix;
    dsp.detectSettableParamFileSuffix=detectSettableParamFileSuffix;
    dsp.boolRemoveBase=boolRemoveBase;
    dsp.boolBlackBeadDetect=boolBlackBeadDetect;
    dsp.boolTransBeadDetect=boolTransBeadDetect;
    dsp.boolTransBeadDetectConf=boolTransBeadDetectConf;
    dsp.boolWaterLineDetect=boolWaterLineDetect;
    dsp.boolComputeParallel=boolComputeParallel;
    dsp.boolVisualizeDetections=boolVisualizeDetections;
    dsp.threshBlackBeadDetect=threshBlackBeadDetect;
    dsp.threshTransBeadDetect=threshTransBeadDetect;
    dsp.threshTransBeadDetectConf=threshTransBeadDetectConf;
    dsp.threshWaterLineStd=threshWaterLineStd;
    dsp.transBeadDetectHMax=transBeadDetectHMax;
    dsp.transBeadDetectRadFilt=transBeadDetectRadFilt;
    dsp.transBeadDetectNbFilt=transBeadDetectNbFilt;
    
%in case 1st input is empty, select a DSP file by hand and load its parameters
elseif isempty(dspIn)
    [dspFile,pathDsp]=uigetfile(fullfile(pathData,'*_settable_param.txt'),...
        'Select a file with the settable parameters of a previous detection');
    [dsp,flagError]=LoadDetectionSettableParameters(fullfile(pathDsp,dspFile));
    if flagError, return; end
    if nargin<2, boolGui=false; end
    if ~boolGui, boolOverwrite=true; end
    
%in case 1st input is a DSP file, load its parameters
elseif ischar(dspIn) && exist(dspIn,'file')==2
    [dsp,flagError]=LoadDetectionSettableParameters(dspIn);
    if flagError, return; end
    if nargin<2, boolGui=false; end
    if ~boolGui, boolOverwrite=true; end
    
%in case 1st input is a DSP structure, use its parameters
elseif isstruct(dspIn)
    dsp=dspIn;
    if nargin<2, boolGui=false; end
    if ~boolGui, boolOverwrite=true; end

%in other cases, stop execution and rise an error
else
    warning(['Execution stopped: 1st input should be 0, empty, an existing ',...
        'DSP file or a DSP structure.']);
    return;
end

%launch a GUI to edit the DSP
if boolGui
    [dsp,guiRun]=DetectionGui(dsp);
    if ~guiRun
        warning(['Execution stopped: GUI has been closed by the CANCEL ',...
            'button or by the close figure button.']);
        return;
    end
end



%-------------------------------------------------------------------------------
% SET OTHER DETECTION PARAMETERS FROM THE SETTABLE ONES
%-------------------------------------------------------------------------------

fprintf('Sequence ''%s''\n',dsp.pathImages);
fprintf('Setting parameters...\n');

%get the file name of each image of the sequence
imageFullFiles=struct2cell(dir(fullfile(dsp.pathImages,'*.tif')));
imageFullFiles=SortImageFullFiles(imageFullFiles(1,:));
imageFullFiles=fullfile(dsp.pathImages,imageFullFiles);
if isempty(imageFullFiles)
    warning(['Execution stopped: Inexistent or uncorrect folder of images, ',...
        'or no images in the folder.']);
    return;
end

%set the detection parameters
[detectParam,flagError]=SetDetectionParameters(dsp,imageFullFiles);
if flagError, return; end

%set the file name of the detection results
fileSuffixBlack=[];
fileSuffixTrans=[];
fileSuffixDetConf=[];
if detectParam.boolBlackBeadDetect
    fileSuffixBlack=['_thBb',num2str(detectParam.threshBlackBeadDetect)];
end
if detectParam.boolTransBeadDetect
    fileSuffixTrans=['_thTb',num2str(detectParam.threshTransBeadDetect)];
end
if detectParam.boolTransBeadDetectConf
    fileSuffixDetConf=['_thDc',num2str(detectParam.threshTransBeadDetectConf)];
end
detectDataFile=[detectParam.detectDataFilePrefix,...
    fileSuffixBlack,fileSuffixTrans,fileSuffixDetConf];
if exist(fullfile(detectParam.pathResults,[detectDataFile,'.mat']),'file')==2
    if ~boolOverwrite
        warning(['Execution stopped: A file of detection results already ',...
            'exists with the same name.']);
        return;
    else
        warning(['Execution continue: A file of detection results already ',...
            'exists with the same name, it will be overwritten.']);
    end
end

%save the DSP in a txt file
dspFile=[detectDataFile,'_',detectParam.detectSettableParamFileSuffix,'.txt'];
SaveDetectionSettableParameters(fullfile(detectParam.pathResults,dspFile),...
    detectParam);



%-------------------------------------------------------------------------------
% COMPUTE DETECTION
%-------------------------------------------------------------------------------

%detect black and transparent beads and water lines in the sequence of images
fprintf('Detecting beads and water lines...\n');
%profile on -history -historysize 100000000 -timer 'real'
[detectData,waterData,detectConfData]=ComputeDetection(imageFullFiles,...
    detectParam);
%profile viewer

%save the detection results and parameters into a file
fprintf('Saving results...\n');
save(fullfile(detectParam.pathResults,[detectDataFile,'.mat']),'dsp',...
    'detectParam','imageFullFiles','detectData','waterData','detectConfData');

%export the variables to the matlab workspace if needed
if boolAssign
    assignin('base','dsp',dsp);
    assignin('base','imageFullFiles',imageFullFiles);
    assignin('base','detectParam',detectParam);
    assignin('base','detectData',detectData);
    assignin('base','waterData',waterData);
    assignin('base','detectConfData',detectConfData);
end



%-------------------------------------------------------------------------------
% COMPUTE VISUALIZATION
%-------------------------------------------------------------------------------

%visualize the sequence of detections in a video and save it into an .avi file
if detectParam.boolVisualizeDetections
    fprintf('Visualizing detections...\n');
    sp=LoadSequenceParameters(fullfile(detectParam.pathImages,...
        detectParam.seqParamFile));
    PlayVideoDetections(...
        fullfile(detectParam.pathResults,[detectDataFile,'.avi']),...
        imageFullFiles,detectData,waterData,sp.acqFreq);
    %or
    %PlayVideoDetections(...
    %    fullfile(detectParam.pathResults,[detectDataFile,'.avi']),...
    %    fullfile(detectParam.pathResults,[detectDataFile,'.mat']),...
    %    sp.acqFreq);
end

end