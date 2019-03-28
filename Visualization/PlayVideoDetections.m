function PlayVideoDetections(varargin)
% Visualize the results of the detection of the black and transparent beads and 
% water lines on a sequence of images through a video and save it into a file.
%
% Several ways to call the function:
%
% PlayVideoDetections()
%   Ask user to select and play a video already created.
%
% PlayVideoDetections(videoFullFile)
%   Play a video already created from a video file.
%
% PlayVideoDetections(videoFullFile,detectDataFullFile,...)
%   Load the detection results from a file, create a video and save it into a
%   file. If detectDataFullFile='ui', ask user to select the detection results 
%   file.
%
% PlayVideoDetections(videoFullFile,imageFullFiles,detectData,waterData,...)
%   Get the detection results directly in the inputs, create a video and 
%   save it into a file.
%
% PlayVideoDetections(~,~,frameRate) or PlayVideoDetections(~,~,~,~,frameRate)
%   Impose a frame rate for the video (default 130).
%
% Hugo Lafaye de Micheaux, 2019

%play an - input or selected - already created video
if nargin==0
    [videoFile,pathVideo]=uigetfile('*.avi','Select a video file');
    videoFullFile=fullfile(pathVideo,videoFile);
else
    videoFullFile=varargin{1};
end
if nargin<2
    videoObj=VideoReader(videoFullFile);
    c=onCleanup(@()Play(videoObj,videoFullFile));
    return;
end

%load variables if 2nd input is a file
if nargin<4
    detectDataFullFile=varargin{2};
    if strcmp(detectDataFullFile,'ui')
        [pathData,~,~]=fileparts(videoFullFile);
        [detectDataFile,pathData]=uigetfile(fullfile(pathData,'*.mat'),...
            'Select a file of detection results');
        detectDataFullFile=fullfile(pathData,detectDataFile);
    end
    myDetectVars={'imageFullFiles','detectData','waterData'};
    s=load(detectDataFullFile,myDetectVars{:});
    imageFullFiles=s.imageFullFiles;
    detectData=s.detectData;
    waterData=s.waterData;
    clear('s');
end

%get variables if given in input
if nargin>=4
    imageFullFiles=varargin{2};
    detectData=varargin{3};
    waterData=varargin{4};
end

%get frame rate if given in input, otherwise set it to 130 (default)
frameRate=130;
if nargin==3 || nargin==5, frameRate=varargin{nargin}; end

%create video of detections frame by frame
videoObj=VideoWriter(videoFullFile);
videoObj.FrameRate=frameRate;
open(videoObj);
hf=figure('visible','off','name','detections','paperpositionmode','auto');
c=onCleanup(@()CleanupAndPlay(videoObj,videoFullFile));
t=now;
ParforProgress(t,length(imageFullFiles));
for im=1:length(imageFullFiles)
    PlotDetectMat(imread(imageFullFiles{im}),detectData{im},hf);
    hold on;
    if ~isempty(waterData), plot(waterData{im},'c'); end
	if exist('hardcopy','builtin') image=hardcopy(gca,'-dzbuffer','-r0');
	else                           image=print('-RGBImage','-r0');
	end
    writeVideo(videoObj,image);
    clf(hf);
    ParforProgress(t,0,im);
end
ParforProgress(t,0);

end



function CleanupAndPlay(videoObj,videoFile)
    close(videoObj);
    close(findobj('type','figure','name','detections'));
    Play(videoObj,videoFile);
end



function Play(videoObj,videoFile)
    implay(videoFile);
    screenSize=get(0,'screensize');
    objAll=findall(0,'tag','spcui_scope_framework');
    pos=get(objAll(1),'position');
    pos(3:4)=[videoObj.Width videoObj.Height+28]; %28 is height of the menu bar
    pos(1:2)=[(screenSize(3)-pos(3))/2 (screenSize(4)-pos(4))/2];
    set(objAll(1),'position',pos,'name',videoFile);
end