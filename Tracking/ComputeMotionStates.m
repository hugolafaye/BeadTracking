function [trackDataOut,trackNbMS] = ComputeMotionStates(trackData,tp,nbTargets)
% Compute the motion state for each target at each time step. Tracking has to be
% executed first.
%
% INPUT ARGUMENTS:
%  trackData: cell array of tracking matrices. One tracking matrix for each
%             image of the sequence. A tracking matrix has 8 infos (col) for
%             each target (row) of the image:
%               1. x-coordinate of the target
%               2. y-coordinate of the target
%               3. category of the target ('0' for black bead, '1' for
%                  transparent bead)
%               4. target identity
%               5. x-velocity of the target
%               6. y-velocity of the target
%               7. row of the target in previous tracking matrix
%               8. row of the target in next tracking matrix
%  tp       : structure containing the tracking parameters.
%  nbTargets: total number of targets.
%
% OUTPUT ARGUMENTS:
%  trackDataOut: cell array of tracking matrices. One tracking matrix for each
%                image of the sequence. A tracking matrix has 9 infos (col) for
%                each target (row) of the image:
%                  1. x-coordinate of the target
%                  2. y-coordinate of the target
%                  3. category of the target ('0' for black bead, '1' for
%                     transparent bead)
%                  4. target identity
%                  5. x-velocity of the target
%                  6. y-velocity of the target
%                  7. row of the target in previous tracking matrix
%                  8. row of the target in next tracking matrix
%                  9. motion state of the target ('0' for resting, '1' for 
%                     rolling, '2' for saltating, '3' for unknown)
%  trackNbMS   : matrix with the number of each 4 motion states (col) for each
%                target (row).
%
% Copyright (c) 2019, Hugo Lafaye de Micheaux, Thomas Gautrais, Université
% Jean Monnet, CNRS, Irstea
% All rights reserved.
%
% This source code is part of the BeadTracking package
% <https://github.com/hugolafaye/BeadTracking> and it is licensed under the
% BSD-style license found in the LICENSE file in the root directory of this
% source tree.



%init variables
winSize=5;%size of the moving average window
boolComputeParallel=1;
halfWin=floor(winSize/2);
veloRestPx=tp.msVeloRest/tp.mByPx/tp.acqFreq;
veloSaltPx=tp.msVeloSalt/tp.mByPx/tp.acqFreq;
trackDataOut=cellfun(@(x)[x,2*ones(size(x,1),1,'single')],trackData,'uni',0);



%------------------------------------------------------------------------------%
%set motion state
%------------------------------------------------------------------------------%
nbW=0;
v=ver;
if boolComputeParallel && find(ismember({v.Name},'Parallel Computing Toolbox'))
    p=parcluster(parallel.defaultClusterProfile);
    nbW=p.NumWorkers;
    if isempty(gcp('nocreate')) && nbW~=0, parpool(nbW); end
end
fprintf('Step #1: local state computation\n');
t=now;
ParforProgress(t,tp.nbImages);
parfor(im=1:tp.nbImages,nbW)
    nbBeads=size(trackData{im},1);
    for b=1:nbBeads
        %----------------------------------------------------------------------%
        %set motion state to rest using absolute speed calculted on window
        %----------------------------------------------------------------------%
        %get 1st bead of the moving window rounding bead b
        im1=im;
        b1=b;
        vSumPx=hypot(trackData{im1}(b,5),trackData{im1}(b,6));
        while trackData{im1}(b1,7)~=0 && im-im1<halfWin
            b1=trackData{im1}(b1,7);
            im1=im1-1;
            vSumPx=vSumPx+hypot(trackData{im1}(b1,5),trackData{im1}(b1,6));
        end
        
        %get last bead of the moving window rounding bead b
        im2=im;
        b2=b;
        while trackData{im2}(b2,8)~=0 && im2-im<halfWin && im2<tp.nbImages
            b2=trackData{im2}(b2,8);
            im2=im2+1;
            vSumPx=vSumPx+hypot(trackData{im2}(b2,5),trackData{im2}(b2,6));
        end
        
        %compute absolute speed and set resting if needed
        if vSumPx/(im2-im1+1)<=veloRestPx, trackDataOut{im}(b,9)=0; end
        
        
        %----------------------------------------------------------------------%
        %set motion state of beads to rolling/saltating using probability
        %----------------------------------------------------------------------%
        if trackDataOut{im}(b,9)~=0
            %set high speed to saltation
            if hypot(trackData{im}(b,5),trackData{im}(b,6))>=veloSaltPx
                trackDataOut{im}(b,9)=2;
            else
                %set neighbor normalization depending on bead category
                dNeigh=zeros(nbBeads,1);
                if trackData{im}(b,3)==0
                    dNeigh(trackData{im}(:,3)==0)=tp.msDistNeighBBeads;
                elseif trackData{im}(b,3)==1
                    dNeigh(trackData{im}(:,3)==1)=tp.msDistNeighTBeads;
                end
                dNeigh(trackData{im}(:,3)~=trackData{im}(b,3))=...
                    tp.msDistNeighBTBeads;
                dNeigh(b)=NaN;

                %keep the value of the closest bead
                trackDataOut{im}(b,9)=min(hypot(...
                    trackData{im}(b,1)-trackData{im}(:,1),...
                    trackData{im}(b,2)-trackData{im}(:,2))./dNeigh);
            end
        end     
    end
    
    ParforProgress(t,0,im);
end
ParforProgress(t,0);


%------------------------------------------------------------------------------%
%post-processing to correct motion states according to average moving window
%------------------------------------------------------------------------------%
%first correct states with a parallel loop
fprintf('Step #2: window motion state correction\n');
trackMS=cell(1,nbTargets);
t=now;
ParforProgress(t,nbTargets);
parfor(tr=1:nbTargets,nbW)
    trImages=cell2mat(cellfun(@(x)sum(x(:,4)==tr),trackDataOut,'uni',0));
    trLength=sum(trImages);
    if trLength>=halfWin
        %re-set motion states using moving average
        trackMS{tr}=cell2mat(cellfun(@(x)x(x(:,4)==tr,9),...
            trackDataOut(trImages==1),'uni',0));
        movAvgMS=MovingAverageFilter(trackMS{tr},winSize);
        trackMS{tr}(:)=1;
        trackMS{tr}(movAvgMS<0.5)=0;
        trackMS{tr}(movAvgMS>tp.msFactNeigh)=2;
        trackMS{tr}(1)=3;
        
        %triplet correction
        trackMS{tr}(strfind(trackMS{tr},[0,1,0])+1)=0;        
        trackMS{tr}(strfind(trackMS{tr},[0,2,0])+1)=0;
        trackMS{tr}(strfind(trackMS{tr},[0,2,1])+1)=1;
        trackMS{tr}(strfind(trackMS{tr},[1,0,1])+1)=1;
        trackMS{tr}(strfind(trackMS{tr},[1,0,2])+1)=1;
        trackMS{tr}(strfind(trackMS{tr},[1,2,1])+1)=1;
        trackMS{tr}(strfind(trackMS{tr},[2,0,1])+1)=1;
        trackMS{tr}(strfind(trackMS{tr},[2,0,2])+1)=2;
        trackMS{tr}(strfind(trackMS{tr},[2,1,2])+1)=2;
    else
        trackMS{tr}(1:trLength)=3;
    end
    
    ParforProgress(t,0,tr);
end
ParforProgress(t,0);
delete(gcp('nocreate'));

%then store new motion states in track data with a normal loop and compute
%the number of each motion state for each target
fprintf('Step #3: storage\n');
trackNbMS=zeros(nbTargets,4);
t=now;
ParforProgress(t,nbTargets);
for tr=1:nbTargets
    trImages=cell2mat(cellfun(@(x)sum(x(:,4)==tr),trackDataOut,'uni',0));
    im1=find(trImages,1);
    for im=im1:im1+sum(trImages)-1
        trackDataOut{im}(trackDataOut{im}(:,4)==tr,9)=trackMS{tr}(im-im1+1);
    end
    
    %compute number of motion states
    trackNbMS(tr,:)=uint32([sum(trackMS{tr}==0),sum(trackMS{tr}==1),...
        sum(trackMS{tr}==2),sum(trackMS{tr}==3)]);
    
    ParforProgress(t,0,tr);
end
ParforProgress(t,0);

end



function xfilt = MovingAverageFilter(x,winSize)
% Function to compute a moving average filter on a vector.
%
% INPUT ARGUMENTS:
%  x      : vector to filter.
%  winSize: size of the window.
%
% OUTPUT ARGUMENTS:
%  xfilt: filtered vector.

halfWin=floor(winSize/2);
xfilt=filter(ones(1,winSize)/winSize,1,x);
xfilt=circshift(xfilt',[-halfWin,0])';
xfilt(1)=x(1);
xfilt(end)=x(end);
if length(x)<=2, return; end
xflip=fliplr(x);
for i=2:min(halfWin,ceil(length(x)/2))
    nb=i*2-1;
    xfilt(i)=sum(x(1:nb))/nb;
    xfilt(end-i+1)=sum(xflip(1:nb))/nb;
end

end