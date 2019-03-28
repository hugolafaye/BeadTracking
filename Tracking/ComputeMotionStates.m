function [trackData2,trNbStates] = ComputeMotionStates(trackData,tp,nbTraj)
% Compute the motion state for each target at each time step.
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
%  nbTraj   : total number of tajectories.
%
% OUTPUT ARGUMENTS:
%  trackData2: cell array of tracking matrices. One tracking matrix for each
%              image of the sequence. A tracking matrix has 9 infos (col) for
%              each target (row) of the image:
%                1. x-coordinate of the target
%                2. y-coordinate of the target
%                3. category of the target ('0' for black bead, '1' for
%                   transparent bead)
%                4. target identity
%                5. x-velocity of the target
%                6. y-velocity of the target
%                7. row of the target in previous tracking matrix
%                8. row of the target in next tracking matrix
%                9. motion state of the target ('0' for resting, '1' for 
%                   rolling, '2' for saltating, '3' for unknown)
%  trNbStates: total number of each motion state for each trajectory.
%
% Hugo Lafaye de Micheaux, 2019

%useful variables
points=2;
per=2*points+1;
uRestPx=tp.msVeloRest/tp.mByPx/tp.acqFreq;
uSaltPx=tp.msVeloSalt/tp.mByPx/tp.acqFreq;


%initialize variables
trackData2=cellfun(@(x)[x,2*ones(size(x,1),1,'single')],trackData,'uni',0);


%------------------------------------------------------------------------------%
%set motion state
%------------------------------------------------------------------------------%
fprintf('Step #1: local state computation\n');
t=now;
ParforProgress(t,tp.nbImages);
parfor im=1:tp.nbImages
    nbBeads=size(trackData{im},1);
    for b=1:nbBeads
        %----------------------------------------------------------------------%
        %set motion state to rest using absolute speed calculted on window
        %----------------------------------------------------------------------%
        %get 1st bead of the moving window rounding bead b
        im1=im;
        b1=b;
        vSumPx=hypot(trackData{im1}(b,5),trackData{im1}(b,6));
        while trackData{im1}(b1,7)~=0 && im-im1<points
            b1=trackData{im1}(b1,7);
            im1=im1-1;
            vSumPx=vSumPx+hypot(trackData{im1}(b1,5),trackData{im1}(b1,6));
        end
        
        %get last bead of the moving window rounding bead b
        im2=im;
        b2=b;
        while trackData{im2}(b2,8)~=0 && im2-im<points && im2<tp.nbImages
            b2=trackData{im2}(b2,8);
            im2=im2+1;
            vSumPx=vSumPx+hypot(trackData{im2}(b2,5),trackData{im2}(b2,6));
        end
        
        %compute absolute speed and set resting if needed
        %speed=hypot(b2Pos(1)-b1Pos(1),b2Pos(2)-b1Pos(2))/(im2-im1+1);
        if vSumPx/(im2-im1+1)<=uRestPx, trackData2{im}(b,9)=0; end
        
        
        %----------------------------------------------------------------------%
        %set motion state of beads to rolling/saltating using probability
        %----------------------------------------------------------------------%
        if trackData2{im}(b,9)~=0
            %set high speed to saltation
            if hypot(trackData{im}(b,5),trackData{im}(b,6))>=uSaltPx
                trackData2{im}(b,9)=2;
            else
                %set neighbor normalisation depending on bead category
                dNeigh=zeros(nbBeads,1);
                if trackData{im}(b,3)==0
                    dNeigh(trackData{im}(:,3)==0)=tp.msDistNeighBBeads;
                elseif trackData{im}(b,3)==1
                    dNeigh(trackData{im}(:,3)==1)=tp.msDistNeighTBeads;
                end
                dNeigh(trackData{im}(:,3)~=trackData{im}(b,3))=tp.msDistNeighBTBeads;
                dNeigh(b)=NaN;

                %keep the value of the closest bead
                trackData2{im}(b,9)=min(hypot(...
                    trackData{im}(b,1)-trackData{im}(:,1),...
                    trackData{im}(b,2)-trackData{im}(:,2))./dNeigh);
            end
        end     
    end
    
    ParforProgress(t,0,im);
end
ParforProgress(t,0);


%------------------------------------------------------------------------------%
%post-processing to correct states according to average window
%------------------------------------------------------------------------------%
%first correct states with a parallel loop
fprintf('Step #2: window state correction\n');
trStates=cell(1,nbTraj);
t=now;
ParforProgress(t,nbTraj);
parfor tr=1:nbTraj
    trImages=cell2mat(cellfun(@(x)sum(x(:,4)==tr),trackData2,'uni',0));
    trLength=sum(trImages);
    if trLength>=points
        %re-set states using moving average
        trStates{tr}=cell2mat(cellfun(@(x)x(x(:,4)==tr,9),...
            trackData2(trImages==1),'uni',0));
        movAvgState=smooth(trStates{tr},per,'moving');
        trStates{tr}(:)=1;
        trStates{tr}(movAvgState<0.5)=0;
        trStates{tr}(movAvgState>tp.msFactNeigh)=2;
        trStates{tr}(1)=3;
        
        %triplet correction
        trStates{tr}(strfind(trStates{tr},[0,1,0])+1)=0;        
        trStates{tr}(strfind(trStates{tr},[0,2,0])+1)=0;
        trStates{tr}(strfind(trStates{tr},[0,2,1])+1)=1;
        trStates{tr}(strfind(trStates{tr},[1,0,1])+1)=1;
        trStates{tr}(strfind(trStates{tr},[1,0,2])+1)=1;
        trStates{tr}(strfind(trStates{tr},[1,2,1])+1)=1;
        trStates{tr}(strfind(trStates{tr},[2,0,1])+1)=1;
        trStates{tr}(strfind(trStates{tr},[2,0,2])+1)=2;
        trStates{tr}(strfind(trStates{tr},[2,1,2])+1)=2;
    else
        trStates{tr}(1:trLength)=3;
    end
    
    ParforProgress(t,0,tr);
end
ParforProgress(t,0);

%then store new states in track structure with a normal loop and compute the
%number of each state for every trajectory
fprintf('Step #3: storage\n');
trNbStates=zeros(nbTraj,4);
t=now;
ParforProgress(t,nbTraj);
for tr=1:nbTraj
    trImages=cell2mat(cellfun(@(x)sum(x(:,4)==tr),trackData2,'uni',0));
    im1=find(trImages,1);
    for im=im1:im1+sum(trImages)-1
        trackData2{im}(trackData2{im}(:,4)==tr,9)=trStates{tr}(im-im1+1);
    end
    
    %compute number of states
    trNbStates(tr,:)=uint32([sum(trStates{tr}==0),sum(trStates{tr}==1),...
        sum(trStates{tr}==2),sum(trStates{tr}==3)]);
    
    ParforProgress(t,0,tr);
end
ParforProgress(t,0);


end