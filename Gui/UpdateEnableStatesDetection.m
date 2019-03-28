function UpdateEnableStatesDetection(hObj, ~, f)
%----------------------------------------------------------------------
%----------------------------------------------------------------------
%---             --- Thomas Gautrais                                ---
%---    Author   --- thomas.gautrais@univ-st-etienne.fr             ---
%---             --- Laboratoire Hubert Curien (UMR 5516)           ---
%----------------------------------------------------------------------
%--- Description --- Callback of the checkbox buttons in the        ---
%---             --- the figure generated by the DetectionGui.m.    ---
%----------------------------------------------------------------------
%---   Version   ---  2019-03-01:                                   ---
%---   History   ---       First version                            ---
%----------------------------------------------------------------------
%----------------------------------------------------------------------

s=guidata(f);

idx=find(s.bool.hCheck==hObj);
seqDirIdx=It2DefStructFieldIdx(s.bool,idx);

isChecked=get(hObj,'Value');

% Remove base
if seqDirIdx==Field2Idx(s.bool.fieldNames.BOOL_REMOVE_BASE,...
        s.bool.defaultStructFields(:,1))
    pathIdx=strcmp(s.path.mapKeys,s.path.fieldNames.PATH_MASK_FILE);
    obj=[s.path.hText(pathIdx),s.path.hPush(pathIdx)];
    if isChecked, set(obj,'Enable','on');
    else          set(obj,'Enable','off');
    end
    
% Detect black beads
elseif seqDirIdx==Field2Idx(s.bool.fieldNames.BOOL_BLACK,...
        s.bool.defaultStructFields(:,1))
    realIdx=strcmp(s.real.mapKeys,s.real.fieldNames.REAL_BLACK_TH);
    obj=[s.real.hText(realIdx),s.real.hEdit(realIdx)];
    if isChecked, set(obj,'Enable','on');
    else          set(obj,'Enable','off');
    end
    
% Detect transparent beads
elseif seqDirIdx==Field2Idx(s.bool.fieldNames.BOOL_TRANS,...
        s.bool.defaultStructFields(:,1))
    pathIdx=strcmp(s.path.mapKeys,s.path.fieldNames.PATH_TRANS_FILE);
    realIdx=strcmp(s.real.mapKeys,s.real.fieldNames.REAL_TRANS_TH) | ...
            strcmp(s.real.mapKeys,s.real.fieldNames.REAL_TRANS_HMAX) | ...
            strcmp(s.real.mapKeys,s.real.fieldNames.REAL_TRANS_RAD_FILT) | ...
            strcmp(s.real.mapKeys,s.real.fieldNames.REAL_TRANS_NB_FILT);
    obj=[s.path.hText(pathIdx),s.path.hPush(pathIdx),...
         s.real.hText(realIdx),s.real.hEdit(realIdx)];
    if isChecked, set(obj,'Enable','on');
    else          set(obj,'Enable','off');
    end
    
% Detect water lines
elseif seqDirIdx==Field2Idx(s.bool.fieldNames.BOOL_WATER_LINE,...
        s.bool.defaultStructFields(:,1))
    realIdx=strcmp(s.real.mapKeys,s.real.fieldNames.REAL_WATER_LINE_TH); 
    obj=[s.real.hText(realIdx),s.real.hEdit(realIdx)];
    if isChecked, set(obj,'Enable','on');
    else          set(obj,'Enable','off');
    end
end

end