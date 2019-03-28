function Submit(hObj,~,f)
%----------------------------------------------------------------------
%----------------------------------------------------------------------
%---             --- Thomas Gautrais                                ---
%---    Author   --- thomas.gautrais@univ-st-etienne.fr             ---
%---             --- Laboratoire Hubert Curien (UMR 5516)           ---
%----------------------------------------------------------------------
%---             --- Callback of the 'RUN' and 'CANCEL' push        ---
%--- Description --- buttons and close figure button in the figures ---
%---             --- generated by the DetectionGui.m and            ---
%---             --- TrackingGui.m                                  ---
%----------------------------------------------------------------------
%---   Version   ---  2019-03-01:                                   ---
%---   History   ---       First version                            ---
%----------------------------------------------------------------------
%----------------------------------------------------------------------

s=guidata(f);

if     hObj==s.submit.run,               run=true;
elseif hObj==s.submit.cancel || hObj==f, run=false;
end

if run
    for m=1:s.real.count
        rawVal=get(s.real.hEdit(m),'String');
        if isnan(str2double(rawVal))
            set(s.submit.info,'String',['Value of the field "',...
                s.real.mapKeys{m},'" must be a number.']);
            return;
        end
    end
    set(s.submit.info,'String','');
end

for m=1:s.path.count
    if     max(It2DefStructFieldIdx(s.path,m)==s.path.editIdx)
        outStruct.(s.path.mapKeys{m})=get(s.path.hEdit(m),'String');
    elseif max(It2DefStructFieldIdx(s.path,m)==s.path.browseIdx)
        outStruct.(s.path.mapKeys{m})=get(s.path.hText(m),'String');
    end
end

for m=1:s.bool.count
    outStruct.(s.bool.mapKeys{m})=logical(get(s.bool.hCheck(m),'Value'));
end

for m=1:s.real.count
    outStruct.(s.real.mapKeys{m})=str2double(get(s.real.hEdit(m),'String'));
end

assignin('caller','outStruct',outStruct);
assignin('caller','run',run);
set(0,'CurrentFigure',f);
closereq;
pause(0.01);

end