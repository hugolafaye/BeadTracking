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

inMapValues=cell2mat(inMap.values);
inMapKeys=inMap.keys;
[sortedInMapValues,sortIdx]=sort(inMapValues);
assert(min(sortedInMapValues==1:inMap.Count),...
    'map Values must be the vector 1:inMap.Count');
outMapKeys={inMapKeys{sortIdx}};

end