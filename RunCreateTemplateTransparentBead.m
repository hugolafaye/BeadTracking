function RunCreateTemplateTransparentBead(radTransBeadPx,...
    radTransBeadPxInside,outputFolder)
% Function to create and save the ring shaped template of a generic transparent
% bead.
%
% INPUT ARGUMENTS:
%  radTransBeadPx      : radius of the outside ring shaped template (in px).
%  radTransBeadPxInside: radius of the inside ring shaped template (in px).
%  outputFolder        : forder where to store the created template, ask user to
%                        select one if absent.
%
% Copyright (c) 2019, Hugo Lafaye de Micheaux, Thomas Gautrais, Université
% Jean Monnet, CNRS, Irstea
% All rights reserved.
%
% This source code is part of the BeadTracking package
% <https://github.com/hugolafaye/BeadTracking> and it is licensed under the
% BSD-style license found in the LICENSE file in the root directory of this
% source tree.

%radTransBeadPx=11;
%radTransBeadPxInside=8;

%create template
templateSize=2*radTransBeadPx+1;
center=ceil(templateSize/2);
templateTransBead1=CreateDisk(templateSize,radTransBeadPx,center);
templateTransBead2=CreateDisk(templateSize,radTransBeadPxInside,center);
templateTransBead=templateTransBead1+templateTransBead2;

%change values at 4 cardinal points to better look like a disk
linInd1=sub2ind(size(templateTransBead),...
    [center-radTransBeadPx,center-radTransBeadPx,...
    center-1,center-1,center+1,center+1,...
    center+radTransBeadPx,center+radTransBeadPx],...
    [center-1,center+1,center-radTransBeadPx,center+radTransBeadPx,...
    center-radTransBeadPx,center+radTransBeadPx,center-1,center+1]);
linInd2=sub2ind(size(templateTransBead),...
    [center-radTransBeadPxInside,center-radTransBeadPxInside,...
    center-1,center-1,center+1,center+1,...
    center+radTransBeadPxInside,center+radTransBeadPxInside],...
    [center-1,center+1,center-radTransBeadPxInside,center+radTransBeadPxInside,...
    center-radTransBeadPxInside,center+radTransBeadPxInside,center-1,center+1]);
templateTransBead(linInd1)=1;
templateTransBead(linInd2)=2;

%normalize
n1=sum(sum(templateTransBead==1));
n2=sum(sum(templateTransBead==2));
templateTransBead(templateTransBead==1)=-n2/n1;
templateTransBead(templateTransBead~=-n2/n1)=1;

%save template
if nargin<3 || ~exist(outputFolder,'dir')
    outputFolder=uigetdir('','Select the folder where to store the template');
end
outputFile=['template_transparent_bead_rOut',num2str(radTransBeadPx),...
    '_rIn',num2str(radTransBeadPxInside),'.mat'];
save(fullfile(outputFolder,outputFile),'templateTransBead');

%plot template
PlotImage(templateTransBead,0);impixelinfo;
hold on;
plot(center,center,'r+','markersize',50);

end



function imDisk = CreateDisk(imSize,radius,center)
% Create a logical image of a disk, '1' inside and '0' outside.
%
% INPUT ARGUMENTS:
%  imSize: scalar size of the image.
%  radius: radius of the disk.
%  center: pixel in the center of the image.
%
% OUTPUT ARGUMENTS:
%  imDisk: logical image of a disk in a matrix.

[mat1,mat2]=ndgrid(1:imSize,1:imSize);
imDisk=double((mat1-center).^2+(mat2-center).^2<=radius^2);

end