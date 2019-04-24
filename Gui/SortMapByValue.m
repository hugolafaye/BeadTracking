function outMapKeys = SortMapByValue(inMap)
%----------------------------------------------------------------------
%----------------------------------------------------------------------
%---             --- Thomas Gautrais                                ---
%---    Author   --- thomas.gautrais@univ-st-etienne.fr             ---
%---             --- Laboratoire Hubert Curien (UMR 5516)           ---
%----------------------------------------------------------------------
%---             --- This function return as a cell array, the keys ---
%--- Description --- of the input map of type containers.map,       ---
%---             --- sorted by ASCII dictionary order               ---
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

inMapValues=cell2mat(inMap.values);
inMapKeys=inMap.keys;
[sortedInMapValues,sortIdx]=sort(inMapValues);
assert(min(sortedInMapValues==1:inMap.Count),...
    'map Values must be the vector 1:inMap.Count');
outMapKeys={inMapKeys{sortIdx}};

end