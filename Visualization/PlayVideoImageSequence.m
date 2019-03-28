function PlayVideoImageSequence(varargin)
% Visualize a sequence of images through a video and save it into a file.
%
% Several ways to call the function:
%
% PlayVideoImageSequence() or PlayVideoImageSequence(videoFullFile,...)
%   Ask user to choose how to select the sequence of images to play, create 
%   the video of images and save it into the output file or create an automatic
%   file name. Selection choices:
%     - 'Previous video' to select and play a video already created.
%     - 'Directory' to select a directory of images and play the sequence of 
%                   all images that are in the directory.
%     - 'List of images' to select and play a list of images.
%
% PlayVideoImageSequence(videoFullFile)
%   Play a video already created from a video file.
%
% PlayVideoImageSequence(frameRate) or PlayVideoImageSequence(~,frameRate)
%   Impose a frame rate for the video (default 130).
%
% Hugo Lafaye de Micheaux, 2019

if nargin>=1 && ischar(varargin{1}) && exist(varargin{1},'file')
    videoFullFile=varargin{1};
    videoObj=VideoReader(videoFullFile);
    c=onCleanup(@()Play(videoObj,videoFullFile));
    return;
else
    answer=questdlg('How to select the sequence of images to play?',...
        'Select mode','Previous video','Directory','List of images','Directory');
    switch answer
        case 'Previous video'
            [videoFile,pathVideo]=uigetfile('*.avi','Select a video');
            videoFullFile=fullfile(pathVideo,videoFile);
            videoObj=VideoReader(videoFullFile);
            c=onCleanup(@()Play(videoObj,videoFullFile));
            return;
        case 'Directory'
            pathVideo=uigetdir('Select the folder of a sequence of images');
            imageFullFiles=struct2cell(dir(fullfile(pathVideo,'*.tif')));
            imageFullFiles=SortImageFullFiles(imageFullFiles(1,:));
            imageFullFiles=fullfile(pathVideo,imageFullFiles);
            [~,folder,~]=fileparts(pathVideo);
            videoFile=[folder,'all.avi'];
        case 'List of images'
            [imageFiles,pathVideo]=uigetfile('*.tif',...
                'MultiSelect','on','Select the images');
            imageFullFiles=fullfile(pathVideo,imageFiles);
            imStartNum=char(regexp(...
                regexprep(imageFullFiles{1},'.tif$',''),'w*\d+$','match'));
            imEndNum=char(regexp(regexprep(...
                imageFullFiles{end},'.tif$',''),'w*\d+$','match'));
            [~,folder,~]=fileparts(pathVideo(1:end-1));%remove / or \ at the end
            videoFile=[folder,'_from',imStartNum,'to',imEndNum,'.avi'];
    end
end

%set name of the output file
if nargin>=1 && ischar(varargin{1})
    videoFullFile=varargin{1};
else
    videoFullFile=fullfile(pathVideo,videoFile);
end

%get frame rate if given in input, otherwise set it to 130 (default)
frameRate=130;
if nargin==2
    frameRate=varargin{2};
elseif nargin==1 && ~ischar(varargin{1})
    frameRate=varargin{1};
elseif exist(fullfile(pathVideo,'sequence_param.txt'),'file')
    sp=LoadSequenceParameters(fullfile(pathVideo,'sequence_param.txt'));
    frameRate=sp.acqFreq;
end

%create the video of the sequence frame by frame
videoObj=VideoWriter(videoFullFile);
videoObj.FrameRate=frameRate;
open(videoObj);
hf=figure('visible','off','name','images','paperpositionmode','auto');
c=onCleanup(@()CleanupAndPlay(videoObj,videoFullFile));
t=now;
ParforProgress(t,length(imageFullFiles));
for im=1:length(imageFullFiles)
    PlotImage(imread(imageFullFiles{im}),hf);
	if exist('hardcopy','builtin') image=hardcopy(gca,'-dzbuffer','-r0');
	else                           image=print('-RGBImage','-r0');
	end
    writeVideo(videoObj,image);
    clf(hf);
    ParforProgress(t,0,im);
end
ParforProgress(t,0);

end



function CleanupAndPlay(videoObj,videoFullFile)
    close(videoObj);
    close(findobj('type','figure','name','images'));
    Play(videoObj,videoFullFile);
end



function Play(videoObj,videoFullFile)
    implay(videoFullFile);
    screenSize=get(0,'screensize');
    objAll=findall(0,'tag','spcui_scope_framework');
    pos=get(objAll(1),'position');
    pos(3:4)=[videoObj.Width videoObj.Height+28]; %28 is height of the menu bar
    pos(1:2)=[(screenSize(3)-pos(3))/2 (screenSize(4)-pos(4))/2];
    set(objAll(1),'position',pos,'name',videoFullFile);
end