function [trackMat1,trackMat2,trackInfo] = ComputeBestAssociation(assoMat,...
    trackMat1,trackMat2,trackInfo,imNum)
% Link best associations to targets.
%
% INPUT ARGUMENTS:
%  assoMat  : association matrix, an association (row) has 3 infos (col):
%               1. index of bead1 in the detection matrix of the first image
%               2. index of bead2 in the detection matrix of the second image
%               3. likelihood criterion of the association.
%  trackMat1: tracking matrix of 1st image.
%  trackMat2: tracking matrix of 2nd image.
%  trackInfo: matrix of target information, a target (row) has 3 infos (col):
%               1. image number where the target starts
%               2. length of the target
%  imNum    : current image number.
%
% OUTPUT ARGUMENTS:
%  trackMat1: tracking matrix of 1st image - updated.
%  trackMat2: tracking matrix of 2nd image - updated.
%  trackInfo: matrix of target information - updated.
%
% Hugo Lafaye de Micheaux, 2019

%loop on the beads of the image containing the smallest number of beads
for b=1:min(size(trackMat1,1),size(trackMat2,1))
    
    %find best untreated association
    [crit,asso]=min(assoMat(:,3));
    
    %treat the association
    if ~isnan(crit)
        b1=assoMat(asso,1); %row of the 1st asso bead in the 1st matrix
        b2=assoMat(asso,2); %row of the 2nd asso bead in the 2nd matrix
        tr=trackMat1(b1,4);
        if tr==0
            %no trajectory exists for this association, create a new trajectory
            tr=size(trackInfo,1)+1;
            trackMat1(b1,4)=tr;
            trackMat2(b2,4)=tr;
            trackInfo(tr,1)=imNum;
            trackInfo(tr,2)=2;
        else
            %a trajectory already exists for this association, extend trajectory
            trackMat2(b2,4)=tr;
            trackInfo(tr,2)=trackInfo(tr,2)+1;
        end
        
        %set link between between bead and trajectory
        trackMat1(b1,8)=b2;
        trackMat2(b2,7)=b1;
        
        %calculate x- and y-velocity
        trackMat2(b2,5)=trackMat2(b2,1)-trackMat1(b1,1);
        trackMat2(b2,6)=trackMat2(b2,2)-trackMat1(b1,2);
        
        %set both beads of the association as treated
        assoMat((assoMat(:,1)==b1)|(assoMat(:,2)==b2),3)=NaN;
    end
    
end

end