function PlayVideoTrajectories(varargin)
% Visualize the results of the tracking on a sequence of images through a video 
% and save it into a file. If they are given in the tracking data, the motion
% states are plotted with different colors.
%
% Several ways to call the function:
%
% PlayVideoTrajectories()
%   Ask user to select and play a video already created.
%
% PlayVideoTrajectories(videoFullFile)
%   Play a video already created from a video file.
%
% PlayVideoTrajectories(videoFullFile,trackDataFullFile,...)
%   Load the tracking results from a file, create a video and save it into a
%   file. If trackDataFullFile='ui', ask user to select the tracking results
%   file.
%
% PlayVideoTrajectories(videoFullFile,imageFullFiles,trackData,trackInfo,...)
%   Get the tracking results directly in the inputs, create a video and 
%   save it into a file.
%
% PlayVideoTrajectories(~,~,frameRate) or PlayVideoTrajectories(~,~,~,~,frameRate)
%   Impose a frame rate for the video (default 130).
%
% Copyright (c) 2019, Hugo Lafaye de Micheaux, Thomas Gautrais, Université
% Jean Monnet, CNRS, Irstea
% All rights reserved.
%
% This source code is part of the BeadTracking package
% <https://github.com/hugolafaye/BeadTracking> and it is licensed under the
% BSD-style license found in the LICENSE file in the root directory of this
% source tree.

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
    trackDataFullFile=varargin{2};
    if strcmp(trackDataFullFile,'ui')
        [pathData,~,~]=fileparts(videoFullFile);
        [trackDataFile,pathData]=uigetfile(fullfile(pathData,'*.mat'),...
            'Select a file of tracking results');
        trackDataFullFile=fullfile(pathData,trackDataFile);
    end
    detectVars={'imageFullFiles'};
    trackVars={'trackParam','trackData','trackInfo'};
    st=load(trackDataFullFile,trackVars{:});
    trackParam=st.trackParam;
    trackData=st.trackData;
    trackInfo=st.trackInfo;
    sd=load(fullfile(trackParam.folderResults,trackParam.detectDataFile),...
        detectVars{:});
    imageFullFiles=sd.imageFullFiles;
    clear('st','sd');
end

%get variables if given in input
if nargin>=4
    imageFullFiles=varargin{2};
    trackData=varargin{3};
    trackInfo=varargin{4};
end

%get frame rate if given in input, otherwise set it to 130 (default)
frameRate=130;
if nargin==3 || nargin==5, frameRate=varargin{nargin}; end

%prepare color variables
palette(:,:,1)=[0,50,0;0,150,0;0,255,0]/255;%color map
palette(:,:,2)=[50,0,0;100,0,0;255,0,0]/255;
ms=3;
if size(trackData{1},2)==9, boolMS=true;
else                        boolMS=false;
end

%create video of trajectories frame by frame
videoObj=VideoWriter(videoFullFile);
videoObj.FrameRate=frameRate;
open(videoObj);
hf=figure('visible','off','name','trajectories','paperpositionmode','auto');
c=onCleanup(@()CleanupAndPlay(videoObj,videoFullFile));
t=now;
ParforProgress(t,length(imageFullFiles));
for im=1:length(imageFullFiles)
    PlotDetectMat(imread(imageFullFiles{im}),trackData{im},hf);
    if im>1
        for b=1:size(trackData{im},1)
            tr=trackData{im}(b,4);
            if isnan(tr) || tr==0, continue; end
            imFirst=trackInfo(tr,1);
            b2=find(trackData{imFirst}(:,4)==tr);
            for im1=imFirst:im-1
                im2=im1+1;
                b1=b2;
                b2=trackData{im1}(b1,8);
                if boolMS, ms=min(trackData{im2}(b2,9)+1,3); end
                hold on; plot(gca(hf),...
                    [trackData{im1}(b1,1),trackData{im2}(b2,1)],...
                    [trackData{im1}(b1,2),trackData{im2}(b2,2)],...
                    'linewidth',1,'color',...
                    palette(ms,:,trackData{im1}(b1,3)+1));
            end
        end
    end
	if exist('hardcopy','builtin'), image=hardcopy(gca,'-dzbuffer','-r0');
    else                            image=print('-RGBImage','-r0');
	end
    writeVideo(videoObj,image);
    clf(hf);
    ParforProgress(t,0,im);
end
ParforProgress(t,0);

end



function CleanupAndPlay(videoObj,videoFile)
    close(videoObj);
    close(findobj('type','figure','name','trajectories'));
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