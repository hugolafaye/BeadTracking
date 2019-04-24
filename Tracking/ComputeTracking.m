function [trackData,trackInfo] = ComputeTracking(detectData,tp)
% Compute the tracking of black and transparent beads in a sequence of images.
% From beads in an image, look for the most likely beads in the next image
% (using a circle of search). Take into account the previous velocity. Choose
% the best associations according to distance and speed (slow beads preferred).
%
% INPUT ARGUMENTS:
%  detectData: cell array of detection matrices. One detection matrix for each
%              image of the sequence. A detection matrix has 3 infos (col) for
%              each detection (row) of the image:
%                1. x-coordinate of the detection
%                2. y-coordinate of the detection
%                3. category of the detection ('0' for black bead, '1' for
%                   transparent bead)
%  tp        : structure containing the tracking parameters.
%
% OUTPUT ARGUMENTS:
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
%  trackInfo: matrix of target information, a target (row) has 2 infos (col):
%               1. image number where the target starts
%               2. length of the target
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
trackData=cellfun(@(x)[single(x),zeros(size(x,1),5,'single')],detectData,...
    'uni',0);
trackInfo=uint32.empty([0,2]);

%loop on all pairs of successive images and compute tracking
t=now;
ParforProgress(t,tp.nbImages-1);
for im2=2:tp.nbImages
    im1=im2-1;
    
    %compute all probable associations
    assoMat=ComputeAssociation(trackData{im1},detectData{im2},tp.radSearch);
    
    %link best associations to targets
    [trackData{im1},trackData{im2},trackInfo]=ComputeBestAssociation(...
        assoMat,trackData{im1},trackData{im2},trackInfo,im1);
    
    ParforProgress(t,0,im2);
end
ParforProgress(t,0);

end