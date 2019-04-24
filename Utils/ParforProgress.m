function percent = ParforProgress(t,N,i)
% ParforProgress Progress monitor (progress bar) that works with parfor.
%   ParforProgress works by creating a file called parfor_progress_timestamp.txt
%   in your working directory, and then keeping track of the parfor loop's
%   progress within that file. This workaround is necessary because parfor
%   workers cannot communicate with one another so there is no simple way
%   to know which iterations have finished and which haven't.
%
%   ParforProgress(t,N) initializes the progress monitor and time for a 
%   set of N upcoming calculations.
%
%   ParforProgress(t,0,i) updates the progress inside your parfor loop and
%   displays an updated progress bar and remaining time.
%
%   ParforProgress(t,0) deletes parfor_progress_timestamp.txt, finalizes
%   progress bar and change remaining time by elasped time.
%
%   To suppress output from any of these functions, just ask for a return
%   variable from the function calls, like PERCENT = ParforProgress which
%   returns the percentage of completion.
%
%   Example:
%
%      N=100;
%      t=now;
%      ParforProgress(t,N);
%      parfor i=1:N
%         pause(rand); %replace with real code
%         ParforProgress(t,0,i);
%      end
%      ParforProgress(t,0);
%
%   See also PARFOR.
%
% On the initial idea and work of Jeremy Scheff.
% jdscheff@gmail.com - http://www.jeremyscheff.com/
%
% Copyright (c) 2011, Jeremy Scheff
% All rights reserved.
% 
% Modified by Hugo Lafaye de Micheaux to include timestamp in file name.
%
% Copyright (c) 2019, Hugo Lafaye de Micheaux, Thomas Gautrais, Université
% Jean Monnet, CNRS, Irstea
% All rights reserved.
%
% This source code is part of the BeadTracking package
% <https://github.com/hugolafaye/BeadTracking> and it is licensed under the
% BSD-style license found in the LICENSE file in the root directory of this
% source tree.

narginchk(2,3);

percent=0;
w=50; %width of progress bar

%initialization
if nargin==2
    if N>0
        f=fopen(['parfor_progress_',datestr(t,'HHMMSSFFF'),'.txt'],'w');
        timer=tic;
        if f<0
            error('Do you have write permissions for %s?',pwd);
        end
        fprintf(f,'%d\n',N); %save N at the top of file
        fprintf(f,'%d\n',timer);
        fclose(f);

        if nargout==0
            disp(['  0%[>',repmat(' ',1,w),']','999:59:59']);
        end

    %finalization
    else
        f=fopen(['parfor_progress_',datestr(t,'HHMMSSFFF'),'.txt'],'r');
        progress=fscanf(f,'%ld');
        fclose(f);
        [hour,min,sec]=SecondToHMS(toc(uint64(progress(2))));
        delete(['parfor_progress_',datestr(t,'HHMMSSFFF'),'.txt']);
        percent=100;

        if nargout==0
            time=sprintf('%03d:%02d:%02d',hour,min,sec);
            disp([repmat(char(8),1,(w+9)+8),'100%[',repmat('=',1,w+1),']',...
                time]);
        end
    end
    
%iteration
else
    if ~exist(['parfor_progress_',datestr(t,'HHMMSSFFF'),'.txt'],'file')
        error(['parfor_progress_timestamp.txt not found. Run ',...
            'ParforProgress(t,N) before ParforProgress(t,0,i) to ',...
            'initialize parfor_progress_timestamp.txt.']);
    end
    
    f=fopen(['parfor_progress_',datestr(t,'HHMMSSFFF'),'.txt'],'a');
    fprintf(f,'%d\n',i);
    fclose(f);
    f=fopen(['parfor_progress_',datestr(t,'HHMMSSFFF'),'.txt'],'r');
    progress=fscanf(f,'%ld');
    fclose(f);
    [hour,min,sec]=SecondToHMS(toc(uint64(progress(2)))*...
        (progress(1)-(length(progress)-2))/double(length(progress)-2));
    percent=(length(progress)-2)/double(progress(1))*100;
    
    if nargout==0
        time=sprintf('%03d:%02d:%02d',hour,min,sec);
        perc=sprintf('%3.0f%%',percent);
        disp([repmat(char(8),1,(w+9)+8),perc,'[',...
            repmat('=',1,round(percent*w/100)),'>',...
            repmat(' ',1,w-round(percent*w/100)),']',time]);
    end
end

end



function [hour,min,sec] = SecondToHMS(seconds)
% Convert a time in seconds to hours, minutes and seconds.
%
% INPUT ARGUMENTS:
%  seconds: time in seconds.
%
% OUTPUT ARGUMENTS:
%  hour: hours.
%  min : minutes.
%  sec : seconds.

seconds=double(seconds);
hour=floor(seconds/3600);
min=floor(mod(seconds,3600)/60);
sec=round(mod(mod(seconds,3600),60));

end