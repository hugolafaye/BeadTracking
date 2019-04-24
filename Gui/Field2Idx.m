function ret = Field2Idx(cellStr,refCellStr)
%----------------------------------------------------------------------
%----------------------------------------------------------------------
%---             --- Thomas Gautrais                                ---
%---    Author   --- thomas.gautrais@univ-st-etienne.fr             ---
%---             --- Laboratoire Hubert Curien (UMR 5516)           ---
%----------------------------------------------------------------------
%---             --- Fonction to convert a char array or a cell     ---
%--- Description --- array of char arrays to the position index at  ---
%---             --- which the matching user interface objects are  ---
%---             --- displayed.                                     ---
%----------------------------------------------------------------------
%---   Version   ---  2019-03-01:                                   ---
%---   History   ---       First version                            ---
%----------------------------------------------------------------------
%----------------------------------------------------------------------
%
% Copyright (c) 2019, Hugo Lafaye de Micheaux, Thomas Gautrais, Université
% Jean Monnet, CNRS, Irstea
% All rights reserved.
%
% This source code is part of the BeadTracking package
% <https://github.com/hugolafaye/BeadTracking> and it is licensed under the
% BSD-style license found in the LICENSE file in the root directory of this
% source tree.

if ischar(cellStr)
    ret=find(strcmp(cellStr,refCellStr));
elseif iscell(cellStr)
    ret=zeros(size(cellStr));
    for m=1:size(cellStr,1)
        for n=1:size(cellStr,2)
            ret(m,n)=find(strcmp(cellStr{m,n},refCellStr));
        end
    end
end

end