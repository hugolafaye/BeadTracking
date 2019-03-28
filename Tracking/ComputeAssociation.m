function assoMat = ComputeAssociation(trackMat1,detectMat2,radSearch)
% Compute all probable bead-to-bead associations of two consecutive images using
% detection matrices, target velocities and an area of search.
%
% INPUT ARGUMENTS:
%  trackMat1 : tracking matrix of 1st image.
%  detectMat2: detection matrix of 2nd image.
%  radSearch : radius of the circle where to search the associated beads.
%
% OUTPUT ARGUMENTS:
%  assoMat: association matrix, an association (row) has 3 infos (col):
%             1. index of bead1 in the detection matrix of the first image
%             2. index of bead2 in the detection matrix of the second image
%             3. likelihood criterion of the association
%
% Hugo Lafaye de Micheaux, 2019

%criterium proportion setting
propCrit1=0.75;
propCrit2=0.25;

%pre-allocate a big matrix of association (for memory matters), unused rows are
%removed after the computation of associations
nbBeads1=size(trackMat1,1);
nbBeads2=size(detectMat2,1);
assoMat=nan(nbBeads1*nbBeads2,3,'single');
maxVelocity=max(arrayfun(@(x,y)hypot(x,y),trackMat1(:,5),trackMat1(:,6)));

%compute associations between previous tracking matrix and new detection matrix
nbAsso=0;
for b1=1:nbBeads1
    for b2=find(detectMat2(:,3)==trackMat1(b1,3))'
        diffX=single(detectMat2(b2,1))-trackMat1(b1,1)-trackMat1(b1,5);
        diffY=single(detectMat2(b2,2))-trackMat1(b1,2)-trackMat1(b1,6);
        diff=hypot(diffX,diffY);
        if diff<=radSearch
            nbAsso=nbAsso+1;
            crit1=diff/radSearch;
            if maxVelocity==0,             crit2=0;
            elseif isnan(trackMat1(b1,4)), crit2=1;
            else crit2=hypot(trackMat1(b1,5),trackMat1(b1,6))/maxVelocity;
            end
            assoMat(nbAsso,:)=[b1,b2,propCrit1*crit1+propCrit2*crit2];
        end
    end
end

%remove unused rows
assoMat=RemoveNaNs(assoMat);

end



function mat = RemoveNaNs(mat)
% Remove NaN values at the last rows of a matrix, i.e. reshape matrix without
% the NaN values present at the bottom of the matrix.
%
% INPUT ARGUMENTS:
%  mat: matrix with NaN rows at the bottom of the matrix.
%
% OUTPUT ARGUMENTS:
%  mat: matrix reshaped without NaNs at the bottom of the matrix.

if size(mat)==0, return; end
rowNaN=isnan(mat(:,1));
mat(rowNaN,:)=[];
mat=reshape(mat,sum(~rowNaN),size(mat,2));

end