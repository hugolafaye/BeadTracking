function ret = It2DefStructFieldIdx(st,it)
%----------------------------------------------------------------------
%----------------------------------------------------------------------
%---             --- Thomas Gautrais                                ---
%---    Author   --- thomas.gautrais@univ-st-etienne.fr             ---
%---             --- Laboratoire Hubert Curien (UMR 5516)           ---
%----------------------------------------------------------------------
%---             --- Fonction to convert the position index at      ---
%--- Description --- which an user interface object is displayed    --- 
%---             --- to the matching index in the                   ---
%---             --- defaultStructFields field in the st structure  ---
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

if numel(it)==1
    ret=Field2Idx(st.mapKeys{it},st.defaultStructFields(:,1));
else
    ret=nan(size(it));
    for k=1:numel(it)
        ret(k)=Field2Idx(st.mapKeys{it(k)},st.defaultStructFields(:,1));
    end
end

end