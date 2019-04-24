function [trackData,trackInfo,trackNbMS] = ComputeTrackingPF(detectData,tp,...
    detectConfData)
% Compute the tracking of black and transparent beads in a sequence of images 
% using particle filter.
% From beads in an image, look for the most likely beads in the next image
% (using a circle of search). Take into account the previous velocity. Choose
% the best associations according to distance and speed (slow beads preferred).
% Use particle filtering to gain precision and deal with false negatives, with
% the help of some detector confidence values and positions.
%
% INPUT ARGUMENTS:
%  detectData    : cell array of detection matrices. One detection matrix for
%                  each image of the sequence. A detection matrix has 3 infos
%                  (col) for each detection (row) of the image:
%                    1. x-coordinate of the detection
%                    2. y-coordinate of the detection
%                    3. category of the detection ('0' for black bead, '1' for
%                       transparent bead)
%  tp            : structure containing the parameters of a particle
%                  filter-based tracking.
%  detectConfData: cell array of detector confidence matrices for transparent
%                  beads. One detector confidence matrix for each image of the
%                  sequence. A detector confidence matrix has 3 infos (col) for
%                  each detection (row) of the image:
%                    1. x-coordinate of the detection
%                    2. y-coordinate of the detection
%                    3. correlation value with the transparent bead template
%
% OUTPUT ARGUMENTS:
%  trackData: cell array of tracking matrices. One tracking matrix for each
%             image of the sequence. A tracking matrix has 9 infos (col) for
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
%               9. motion state of the target ('0' for resting, '1' for rolling,
%                  '2' for saltating, '3' for unknown)
%  trackInfo: matrix of target information, a target (row) has 3 infos (col):
%               1. image number where the target starts
%               2. length of the target
%               3. nb of effective detections of the target along its trajectory
%  trackNbMS: matrix with the number of each 4 motion states (col) for each
%             target (row).
%
% Copyright (c) 2019, Hugo Lafaye de Micheaux, Thomas Gautrais, Université
% Jean Monnet, CNRS, Irstea
% All rights reserved.
%
% This source code is part of the BeadTracking package
% <https://github.com/hugolafaye/BeadTracking> and it is licensed under the
% BSD-style license found in the LICENSE file in the root directory of this
% source tree.

%initialize variables
trackData=cellfun(@(x)[single(x),zeros(size(x,1),5,'single'),...
    3*ones(size(x,1),1,'single')],detectData,'uni',0);
trackInfo=uint32.empty([0,4]);%4th-column used only during PF tracking execution
trackNbMS=uint32.empty([0,4]);
distNeighCat=[tp.distNeighBBeads;tp.distNeighBTBeads;tp.distNeighTBeads];
veloRestPx=tp.veloRest/tp.mByPx/tp.acqFreq;
veloSaltPx=tp.veloSalt/tp.mByPx/tp.acqFreq;

%initialize decreasing exponential kernel
diamTransBeadPx=2*tp.radTransBeadPx;
expoKernel=zeros(diamTransBeadPx,'single');
for i=1:diamTransBeadPx
    for j=1:diamTransBeadPx
        expoKernel(i,j)=exp(-tp.dcDeltaCoef*sqrt((i-tp.radTransBeadPx-1)^2+...
            (j-tp.radTransBeadPx-1)^2));
    end
end

%set transition probabilities in separate variables for more readability
p0To0=tp.transitionProbabilities(1,1);
p0To1=tp.transitionProbabilities(1,2);
p0To2=tp.transitionProbabilities(1,3);
p1To0=tp.transitionProbabilities(2,1);
p1To1=tp.transitionProbabilities(2,2);
p1To2=tp.transitionProbabilities(2,3);
p2To0=tp.transitionProbabilities(3,1);
p2To1=tp.transitionProbabilities(3,2);
p2To2=tp.transitionProbabilities(3,3);
p3To0=tp.transitionProbabilities(4,1);
p3To1=tp.transitionProbabilities(4,2);
p3To2=tp.transitionProbabilities(4,3);

%initialize particles
pMS=3*ones(size(trackData{1},1),tp.pfNbParticles,1,'uint8');
pXY=zeros(size(trackData{1},1),tp.pfNbParticles,2,'single');
for b1=1:size(trackData{1},1)
    pXY(b1,:,:)=mvnrnd(repmat(trackData{1}(b1,1:2),tp.pfNbParticles,1),...
        tp.pfXYCovRoll*tp.newTrackCovCoef);
end

%loop on all pairs of successive images and compute tracking
t=now;
ParforProgress(t,tp.nbImages-1);
for im2=2:tp.nbImages
    im1=im2-1;
    
    %---------------------------------------------------------------------------
    %ASSOCIATION
    %---------------------------------------------------------------------------
    %compute all probable associations
    assoMat=ComputeAssociation(trackData{im1},detectData{im2},tp.radSearch);
    
    %link best associations to targets
    [trackData{im1},trackData{im2},trackInfo]=ComputeBestAssociation(assoMat,...
        trackData{im1},trackData{im2},trackInfo,im1);
    
    %update size of trackNbMS and count one at 'unknown' motion state for new
    %targets
    trackNbMS=[trackNbMS;[zeros(size(trackInfo,1)-size(trackNbMS,1),3),...
        ones(size(trackInfo,1)-size(trackNbMS,1),1)]];
    
    
    %---------------------------------------------------------------------------
    %PARTICLE FILTER
    %---------------------------------------------------------------------------
    nbBeadsIm2=size(trackData{im2},1);
    listBeadsUnasso=ones(nbBeadsIm2,1,'uint8');%to get list of unassociated beads at the end
    pMSnew=3*ones(nbBeadsIm2,tp.pfNbParticles,1,'uint8');
    pXYnew=zeros(nbBeadsIm2,tp.pfNbParticles,2,'single');
    pWnew=zeros(nbBeadsIm2,tp.pfNbParticles,'single');
    
    %generate image from detect conf values
    %imDetectConfAll=zeros(tp.imSize,'single');
    imDetectConfOnlyNotDetected=zeros(tp.imSize,'single');
    for bdc=1:size(detectConfData{im2},1)
        for i=1:diamTransBeadPx
            for j=1:diamTransBeadPx
                r=detectConfData{im2}(bdc,2)+i-tp.radTransBeadPx-1;
                c=detectConfData{im2}(bdc,1)+j-tp.radTransBeadPx-1;
                if r>=1 && r<=tp.imSize(1) && c>=1 && c<=tp.imSize(2)
                    %imDetectConfAll(r,c)=imDetectConfAll(r,c)+...
                    %    detectConfData{im2}(bdc,3)*expoKernel(i,j);
                    if isempty(find(all(bsxfun(@eq,...
                            detectConfData{im2}(bdc,1:2),...
                            detectData{im2}(detectData{im2}(:,3)==1,1:2)),2),1))
                        imDetectConfOnlyNotDetected(r,c)=...
                            imDetectConfOnlyNotDetected(r,c)+...
                            detectConfData{im2}(bdc,3)*expoKernel(i,j);
                    end
                end
            end
        end
    end
    
    
    %loop on all bead indexes of the first image
    for b1=1:size(trackData{im1},1)
        %ignore target if nan
        if isnan(trackData{im1}(b1,4)), continue; end

        %get current bead info
        b1XY=trackData{im1}(b1,1:2);
        b1Cat=trackData{im1}(b1,3);
        b1UV=trackData{im1}(b1,5:6);
        b1MS=trackData{im1}(b1,9);
        tr=trackData{im1}(b1,4);
        
        %get indexes of the associated beads in previous and next image
        b0=trackData{im1}(b1,7);
        b2=trackData{im1}(b1,8);
        
        %remove bead if it has no previous and no next bead
        if tr==0 || (b2==0 && (im2==2 || b0==0))
            trackData{im1}(b1,4)=NaN;
            continue;
        end
        
        %stop target if length of consecutive estimated locations is too high
        if     b1MS==0 && trackInfo(tr,4)>=tp.lengthEstimRest, continue;
        elseif b1MS==1 && trackInfo(tr,4)>=tp.lengthEstimRoll, continue;
        elseif b1MS==2 && trackInfo(tr,4)>=tp.lengthEstimSalt, continue;
        end
        
        %3 different cases for the target
        %-----------------------------------------------------------------------
        %1st: target continues
        %-----------------------------------------------------------------------
        if b2~=0
            %b2 has been associated so remove it from list
            listBeadsUnasso(b2)=0;
            
            %get location and velocity of the associated bead (observation z)
            zXY=trackData{im2}(b2,1:2);
            zUV=trackData{im2}(b2,5:6);
            
            %compute motion state of the associated bead with neighbors
            %information
            distNeigh=sqrt((zXY(1)-trackData{im2}([1:b2-1,b2+1:end],1)).^2+...
                (zXY(2)-trackData{im2}([1:b2-1,b2+1:end],2)).^2);
            catNeigh=trackData{im2}([1:b2-1,b2+1:end],3);
            nbNeigh=sum(distNeigh<=...
                (tp.factNeigh*distNeighCat(catNeigh+trackData{im2}(b2,3)+1)));
            zUVnorm=hypot(zUV(1),zUV(2));
            if     nbNeigh>=tp.nbNeighRest || zUVnorm<=veloRestPx, zMS=0;
            elseif nbNeigh<=tp.nbNeighSalt || zUVnorm>=veloSaltPx, zMS=2;
            else                                                   zMS=1;
            end
            
            %set coefficient multiplying noise variances of new tracks and gamma
            %according to the length of the target
            covCoef=1;
            if trackInfo(tr,2)<=tp.newTrackLength
                covCoef=tp.newTrackCovCoef;
            end
            
            %randomly generate particles based on their estimated motion state
            for p=1:tp.pfNbParticles
                veloSaltInit=0;
                
                %first: estimate the new motion state of the particle
                r=rand;
                switch pMS(b1,p)
                    case 0
                        if     r<=p0To0,       pMSnew(b2,p)=0;
                        elseif r<=p0To0+p0To1, pMSnew(b2,p)=1;
                        else                   pMSnew(b2,p)=2;
                        end                    
                    case 1
                        if     r<=p1To1,       pMSnew(b2,p)=1;
                        elseif r<=p1To1+p1To2, pMSnew(b2,p)=2;
                        else                   pMSnew(b2,p)=0;
                        end
                    case 2
                        if     r<=p2To2,       pMSnew(b2,p)=2;
                        elseif r<=p2To2+p2To1, pMSnew(b2,p)=1;
                        else                   pMSnew(b2,p)=0;
                        end
                    case 3
                        if     r<=p3To0,       pMSnew(b2,p)=0;
                        elseif r<=p3To0+p3To1, pMSnew(b2,p)=1;
                        else                   pMSnew(b2,p)=2;
                                               veloSaltInit=tp.veloSaltInit;
                        end
                end
                
                %second: generate the particle location and velocity
                switch pMSnew(b2,p)
                    case 0 %null x- and y-velocity
                        pXYnew(b2,p,:)=mvnrnd(squeeze(pXY(b1,p,:)),...
                            tp.pfXYCovRest*covCoef);
                    case 1 %constant x-velocity, null y-velocity
                        pXYnew(b2,p,:)=mvnrnd(squeeze(pXY(b1,p,:))+...
                            [b1UV(1);0],tp.pfXYCovRoll*covCoef);
                    case 2 %constant x- and y-velocity
                        if rand<0.5 %rebound management
                            pXYnew(b2,p,:)=mvnrnd(squeeze(pXY(b1,p,:))+...
                                [veloSaltInit;0]+b1UV',tp.pfXYCovSalt*covCoef);
                        else
                            pXYnew(b2,p,:)=mvnrnd(squeeze(pXY(b1,p,:))+...
                                [veloSaltInit;0]+[b1UV(1);-b1UV(2)],...
                                tp.pfXYCovSalt*covCoef);
                        end
                end
                
                %third: generate the particle weight
                zpXYnew=squeeze(pXYnew(b2,p,:))';
                pWnew(b2,p)=mvnpdf(zXY-zpXYnew,[0,0],tp.pfZXYCov)*...
                    ( ((pMSnew(b2,p)==zMS)*tp.pfGammaCoef)+...
                      ((pMSnew(b2,p)~=zMS)*(1-tp.pfGammaCoef)) );
                
            end
            
            %normalize to form a probability distribution (i.e. sum to 1).
            pWnew(b2,:)=pWnew(b2,:)./sum(pWnew(b2,:));
            
        else %target stops
            %-------------------------------------------------------------------
            %2nd: target stops correctly, i.e. bead would have been outside image
            %-------------------------------------------------------------------
            if (tp.flumeDirection==1  && b1XY(1)+b1UV(1)>tp.imSize(2)) || ...
               (tp.flumeDirection==-1 && b1XY(1)+b1UV(1)<1)
                continue;
            end
                
            %-------------------------------------------------------------------
            %3rd: target shouldn't stop (MISSING DETECTION = FALSE NEGATIVE)
            %-------------------------------------------------------------------
            %update nb beads in second image
            nbBeadsIm2=nbBeadsIm2+1;
            
            %update track info
            trackInfo(tr,2)=trackInfo(tr,2)+1;
            trackInfo(tr,4)=trackInfo(tr,4)+1;
            
            %set coefficient multiplying noise variances of new tracks
            covCoef=1;
            if trackInfo(tr,2)<=tp.newTrackLength
                covCoef=tp.newTrackCovCoef;
            end
            
            %randomly generate particles based on their estimated motion state
            pMSnew(end+1,:)=ones(1,tp.pfNbParticles,'uint8');
            pXYnew(end+1,:,:)=zeros(1,tp.pfNbParticles,2,'single');
            pWnew(end+1,:)=1/tp.pfNbParticles*ones(1,tp.pfNbParticles);
            for p=1:tp.pfNbParticles
                %first: estimate the new motion state of the particle
                r=rand;
                switch pMS(b1,p)
                    case 0
                        if     r<=p0To0,       pMSnew(end,p)=0;
                        elseif r<=p0To0+p0To1, pMSnew(end,p)=1;
                        else                   pMSnew(end,p)=2;
                        end                    
                    case 1
                        if     r<=p1To1,       pMSnew(end,p)=1;
                        elseif r<=p1To1+p1To2, pMSnew(end,p)=2;
                        else                   pMSnew(end,p)=0;
                        end
                    case 2
                        if     r<=p2To2,       pMSnew(end,p)=2;
                        elseif r<=p2To2+p2To1, pMSnew(end,p)=1;
                        else                   pMSnew(end,p)=0;
                        end
                end
                
                %second: generate the particle location
                switch pMSnew(end,p)
                    case 0 %null x- and y-velocity
                        pXYnew(end,p,:)=mvnrnd(squeeze(pXY(b1,p,:)),...
                            tp.pfXYCovRest*covCoef);
                    case 1 %constant x-velocity, null y-velocity
                        pXYnew(end,p,:)=mvnrnd(squeeze(pXY(b1,p,:))+...
                            [b1UV(1);0],tp.pfXYCovRoll*covCoef);
                    case 2 %constant x- and y-velocity
                        if rand<0.5 %rebound management
                            pXYnew(end,p,:)=mvnrnd(squeeze(pXY(b1,p,:))+...
                                b1UV',tp.pfXYCovSalt*covCoef);
                        else
                            pXYnew(end,p,:)=mvnrnd(squeeze(pXY(b1,p,:))+...
                                [b1UV(1);-b1UV(2)],tp.pfXYCovSalt*covCoef);
                        end
                end

                %third: generate the particle weight
                if b1Cat==1
                    zpXYnew=squeeze(pXYnew(end,p,:))';
                    zpXYnewInt=uint16([max(1,min(tp.imSize(2),zpXYnew(1))),...
                        max(1,min(tp.imSize(1),zpXYnew(2)))]);
                    pWnew(end,p)=imDetectConfOnlyNotDetected(...
                        zpXYnewInt(2),zpXYnewInt(1));
                end
            end

            %normalize to form a probability distribution (i.e. sum to 1).
            pWnew(end,:)=pWnew(end,:)./sum(pWnew(end,:));

            %add a new bead in the second image, add a line to the list of 
            %the associated beads and the chained link in the first image
            trackData{im2}(end+1,:)=[0,0,b1Cat,tr,0,0,b1,0,3];
            listBeadsUnasso(end+1)=0;
            trackData{im1}(b1,8)=nbBeadsIm2;
        end
        
    end
    
    %process the remaining unassociated (new) beads of the second image  
    for b2=find(listBeadsUnasso')
        %initialize particles
        pMSnew(b2,:)=3;
        pXYnew(b2,:,:)=mvnrnd(...
            repmat(trackData{im2}(b2,1:2),tp.pfNbParticles,1),...
            tp.pfXYCovRoll*tp.newTrackCovCoef);        
    end
    
    %resampling: from this new distribution, now we randomly sample from it
    %to generate our new estimated particles
    %and estimating: position, velocity and motion state of the beads
    for b2=1:nbBeadsIm2
        b2Cat=trackData{im2}(b2,3);
        tr=trackData{im2}(b2,4);
        b1=trackData{im2}(b2,7);
        
        %don't resample if track stopped or new
        if isnan(tr), continue; end             %track stopped because wrong
        if tr==0 || b1==0                       %new bead, no track yet
            pMS(b2,:)=pMSnew(b2,:);
            pXY(b2,:,:)=pXYnew(b2,:,:);
            continue;
        end
        
        %resample
        pWnewCS=cumsum(pWnew(b2,:));
        pWnewCS(end)=1; %to avoid rand>pWnewCS(end) -- YES IT HAPPENS !
        for p=1:tp.pfNbParticles
            iP=find(rand<=pWnewCS,1);
            pMS(b2,p)=pMSnew(b2,iP);
            pXY(b2,p,:)=squeeze(pXYnew(b2,iP,:));
        end

        %estimate position and motion state, and set velocity to the measured
        %velocity
        trackData{im2}(b2,1:2)=mean(squeeze(pXY(b2,:,:)));
        trackData{im2}(b2,5:6)=trackData{im2}(b2,1:2)-...
            trackData{im1}(b1,1:2);
        trackData{im2}(b2,9)=mode(pMS(b2,:));
        
        %test if the estimation is close enough to the measure
        if trackInfo(tr,4)==0 %a position has been measured
            distEstimToMeas=hypot(...
                trackData{im2}(b2,1)-single(detectData{im2}(b2,1)),...
                trackData{im2}(b2,2)-single(detectData{im2}(b2,2)));
            if (b2Cat==0 && distEstimToMeas>tp.radBlackBeadPx) ||...
               (b2Cat==1 && distEstimToMeas>tp.radTransBeadPx)
                    trackData{im2}(b2,:)=...
                        [single(detectData{im2}(b2,1:2)),b2Cat,0,0,0,0,0,3];
                    pMS(b2,:)=3;
                    pXY(b2,:,:)=mvnrnd(repmat(...
                        single(detectData{im2}(b2,1:2)),tp.pfNbParticles,1),...
                        tp.pfXYCovRoll*tp.newTrackCovCoef);
            end
        
        %test if the estimation without measure has a good detect conf
        elseif b2Cat==1 %no position measured
            b2XYInt=uint16([max(1,min(tp.imSize(2),trackData{im2}(b2,1))),...
                max(1,min(tp.imSize(1),trackData{im2}(b2,2)))]);
            if imDetectConfOnlyNotDetected(b2XYInt(2),b2XYInt(1))<...
                    tp.threshTransBeadDetectConf
                for im=trackInfo(tr,1):im2
                    trackData{im}(trackData{im}(:,4)==tr,4)=NaN;
                end
            end
        end
        
    end
    
    
    %neighbors information for motion state estimation
    for b2=1:nbBeadsIm2
        tr=trackData{im2}(b2,4);
        if isnan(tr) || tr==0, continue; end
        distNeigh=sqrt(...
            (trackData{im2}(b2,1)-trackData{im2}([1:b2-1,b2+1:end],1)).^2+...
            (trackData{im2}(b2,2)-trackData{im2}([1:b2-1,b2+1:end],2)).^2);
        catNeigh=trackData{im2}([1:b2-1,b2+1:end],3);
        nbNeigh=sum(distNeigh<=...
            (tp.factNeigh*distNeighCat(catNeigh+trackData{im2}(b2,3)+1)));
        veloNorm=hypot(trackData{im2}(b2,5),trackData{im2}(b2,6));
        if nbNeigh>=tp.nbNeighRest || veloNorm<=veloRestPx
            trackData{im2}(b2,9)=0;
        elseif nbNeigh<=tp.nbNeighSalt || veloNorm>=veloSaltPx
            trackData{im2}(b2,9)=2;
        else
            trackData{im2}(b2,9)=1;
        end
        trackNbMS(tr,trackData{im2}(b2,9)+1)=...
            trackNbMS(tr,trackData{im2}(b2,9)+1)+1;
    end
    
    ParforProgress(t,0,im2);
end
ParforProgress(t,0);

%remove 4th-column of trackInfo as it's used only during PF tracking execution
trackInfo(:,4)=[];

end