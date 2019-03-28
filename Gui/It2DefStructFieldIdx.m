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

if numel(it)==1
    ret=Field2Idx(st.mapKeys{it},st.defaultStructFields(:,1));
else
    ret=nan(size(it));
    for k=1:numel(it)
        ret(k)=Field2Idx(st.mapKeys{it(k)},st.defaultStructFields(:,1));
    end
end

end