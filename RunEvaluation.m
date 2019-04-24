function RunEvaluation(trackTruthFullFile,trackDataFullFiles,trackDataNames)
% Function to evaluate the results of tracking algorithms against a ground
% truth.

% INPUT ARGUMENTS:
%  trackTruthFullFile: file of the ground truth tracking data.
%  trackDataFullFiles: files of the tracking data to evaluate.
%  trackDataNames    : names of the tracking data in the plots.
%
% Copyright (c) 2019, Hugo Lafaye de Micheaux, Thomas Gautrais, Université
% Jean Monnet, CNRS, Irstea
% All rights reserved.
%
% This source code is part of the BeadTracking package
% <https://github.com/hugolafaye/BeadTracking> and it is licensed under the
% BSD-style license found in the LICENSE file in the root directory of this
% source tree.



fprintf('---------------------------------------------------------------\n');
fprintf(' EVALUATION OF BLACK AND TRANSPARENT BEADS TRACKING ALGORITHMS \n');
fprintf('---------------------------------------------------------------\n');



%-------------------------------------------------------------------------------
% SET PARAMETERS
%-------------------------------------------------------------------------------

%default parameters
seqParamFile='sequence_param.txt';
factRadDistOk=1;%valid distance between tracking data and truth as a factor of radius
boolComputeParallel=1;

%set file of ground truth tracking data
if nargin<1 || exist(trackTruthFullFile,'file')~=2
    if nargin>=1
        warning(['Execution continue: Inexistent or uncorrect file of ',...
            'ground truth tracking data, please select a valid one.']);
    end
    [trackTruthFile,trackTruthPath]=uigetfile('*.mat',['Select the file of ',...
        'ground truth tracking data']);
    trackTruthFullFile=fullfile(trackTruthPath,trackTruthFile);
end

%set files of tracking data
if nargin<2
    trackDataFullFiles=uipickfiles('FilterSpec','*.mat');
end
nbData=length(trackDataFullFiles);

%set names of tracking data
if nargin<3
    trackDataNames=inputdlg('Enter space-separated tracking data names',...
        'Tracking data names',1,{'DET MMPF'});
    trackDataNames=strsplit(trackDataNames{1});
end
if nbData~=length(trackDataNames)
    warning(['Execution stopped: Nb of tracking data and names must be ',...
        'the same.']);
    return;
end

%set file of sequence parameters
pathImages=fileparts(fileparts(trackDataFullFiles{1}));
if exist(fullfile(pathImages,seqParamFile),'file')~=2
    warning(['Execution continue: Inexistent or uncorrect file of ',...
        'sequence parameters, please select a valid one.']);
    [seqParamFile,pathImages]=uigetfile('*.txt',['Select the file of ',...
        'sequence parameters']);
end

%set output file of evaluation
if nargin<4
    outputFile=inputdlg('Enter output file name without extension:',...
        'Output file name',1,{['res_eval',sprintf('_%s',trackDataNames{:})]});
    outputFile=outputFile{1};
end

%set valid distance between tracking data and truth
sp=LoadSequenceParameters(fullfile(pathImages,seqParamFile));
radBeadPxCat=round(round([sp.diamBlackBead,sp.diamTransBead]/sp.mByPx)/2);
distOkCat=factRadDistOk*radBeadPxCat;

%load data
fprintf('Loading data...\n');
trackTruthTemp=load(trackTruthFullFile,'trackData','trackInfo');
trackTruth=trackTruthTemp(1).trackData;
trackInfoTruth=trackTruthTemp(1).trackInfo;
clear trackTruthTemp;
trackData(1,1:nbData)=cellfun(@(x)load(x,'trackData'),...
    trackDataFullFiles(1:nbData),'uni',0);
trackData(1,1:nbData)=cellfun(@(x)x(1).trackData,trackData(1:nbData),'uni',0);



%-------------------------------------------------------------------------------
% FN and FP analysis
%-------------------------------------------------------------------------------

fprintf('Analysing FP and FN...\n');

%initializing variables
nbImages=length(trackTruth);
fpTemp=cell(nbImages,1);fpTemp(:)={zeros(nbData,2)};
fnTemp=cell(nbImages,1);fnTemp(:)={zeros(nbData,2,4)};

%compute nb beads in each image
nbB=zeros(3,5,nbImages); %cat(0,1,all), ms(0,1,2,3,all), im(1,...,nbIm)
for cat=0:1
    for ms=0:3
        nbB(cat+1,ms+1,:)=cell2mat(cellfun(@(x)sum(x(:,3)==cat & x(:,9)==ms),...
            trackTruth,'uni',0));
    end
    nbB(cat+1,5,:)=sum(squeeze(nbB(cat+1,:,:)),1);
end
for ms=0:3
    nbB(3,ms+1,:)=cell2mat(cellfun(@(x)sum(x(:,9)==ms),trackTruth,'uni',0));
end
nbB(3,5,:)=sum(squeeze(nbB(3,:,:)),1);

%compute fp/fn image by image in parallel if possible
nbW=0;
v=ver;
if boolComputeParallel && find(ismember({v.Name},'Parallel Computing Toolbox'))
    p=parcluster(parallel.defaultClusterProfile);
    nbW=p.NumWorkers;
    if isempty(gcp('nocreate')) && nbW~=0, parpool(nbW); end
end
t=now;
ParforProgress(t,nbImages);
parfor(im=1:nbImages,nbW)
    %compute fp/fn in the image for each tracking data
    for data=1:nbData
        %false positives
        for bs=1:size(trackData{data}{im},1)
            cat=trackData{data}{im}(bs,3);
            if isnan(trackData{data}{im}(bs,4)), continue; end
            d=min((trackTruth{im}(trackTruth{im}(:,3)==cat,1)-...
                trackData{data}{im}(bs,1)).^2+...
                (trackTruth{im}(trackTruth{im}(:,3)==cat,2)-...
                trackData{data}{im}(bs,2)).^2);
            if sqrt(d)>distOkCat(cat+1)
                fpTemp{im}(data,cat+1)=fpTemp{im}(data,cat+1)+1;
            end
        end
        
        %false negatives
        for bt=1:nbB(3,5,im)
            cat=trackTruth{im}(bt,3);
            ms=trackTruth{im}(bt,9);
            d=min((trackData{data}{im}(trackData{data}{im}(:,3)==cat,1)-...
                trackTruth{im}(bt,1)).^2+...
                (trackData{data}{im}(trackData{data}{im}(:,3)==cat,2)-...
                trackTruth{im}(bt,2)).^2);
            if sqrt(d)>distOkCat(cat+1)
                fnTemp{im}(data,cat+1,ms+1)=fnTemp{im}(data,cat+1,ms+1)+1;
            end
        end
    end
    ParforProgress(t,0,im);
end
ParforProgress(t,0);

%transform fn and fp variables to simplify their future use
fp=cell(1,nbData);fp(:)={zeros(2,nbImages)}; %cat(0,1), ms(0,1,2,3)
fn=cell(1,nbData);fn(:)={zeros(2,4,nbImages)}; %cat(0,1), ms(0,1,2,3)
for data=1:nbData
    for im=1:nbImages
        for cat=1:2
            fp{data}(cat,im)=fpTemp{im}(data,cat);
            for ms=1:4
                fn{data}(cat,ms,im)=fnTemp{im}(data,cat,ms);
            end
        end
    end
end

%compute fp rates according to tracking data and bead category
fprG=zeros(nbData,3);
for data=1:nbData
    for cat=0:1
        fprG(data,cat+1)=sum(fp{data}(cat+1,:))/sum(nbB(cat+1,5,:));
    end
    fprG(data,3)=sum(fp{data}(:))/sum(nbB(3,5,:));
end

%compute fn rates according to tracking data, bead category and motion state
fnrG=zeros(nbData,3,5);
for data=1:nbData
    for cat=0:1
        fpCat=sum(fp{data}(cat+1,:));
        for ms=0:3
            fnrG(data,cat+1,ms+1)=sum(fn{data}(cat+1,ms+1,:))/...
                (sum(nbB(cat+1,ms+1,:))+fpCat+sum(fn{data}(cat+1,ms+1,:)));
        end
        fnrG(data,cat+1,5)=sum(sum(fn{data}(cat+1,:,:)))/...
            (sum(nbB(cat+1,5,:))+fpCat+sum(sum(fn{data}(cat+1,:,:))));
    end
    for ms=0:3
        fnrG(data,3,ms+1)=sum(sum(fn{data}(:,ms+1,:)))/...
            (sum(nbB(3,ms+1,:))+sum(fp{data}(:))+sum(sum(fn{data}(:,ms+1,:))));
    end
    fnrG(data,3,5)=sum(fn{data}(:))/...
        (sum(nbB(3,5,:))+sum(fp{data}(:))+sum(fn{data}(:)));
end

%plot results of fp/fn analysis
figure;
subplot(2,3,1)
bar(squeeze(fnrG(:,:,1))'*100,'grouped');
title('Global FNR on RESTING');
set(gca,'xticklabel',{'Black','Transparent','Both'});
ylabel('Global FNR (%)');
legend(trackDataNames,'location','northwest');

subplot(2,3,2)
bar(squeeze(fnrG(:,:,2))'*100,'grouped');
title('Global FNR on ROLLING');
set(gca,'xticklabel',{'Black','Transparent','Both'});
ylabel('Global FNR (%)');
legend(trackDataNames,'location','northwest');

subplot(2,3,3)
bar(squeeze(fnrG(:,:,3))'*100,'grouped');
title('Global FNR on SALTATING');
set(gca,'xticklabel',{'Black','Transparent','Both'});
ylabel('Global FNR (%)');
legend(trackDataNames,'location','northwest');

subplot(2,3,4)
bar(squeeze(fnrG(:,:,4))'*100,'grouped');
title('Global FNR on UNKNOWN');
set(gca,'xticklabel',{'Black','Transparent','Both'});
ylabel('Global FNR (%)');
legend(trackDataNames,'location','northwest');

subplot(2,3,5)
bar(squeeze(fnrG(:,:,5))'*100,'grouped');
title('Global FNR on ALL motion states');
set(gca,'xticklabel',{'Black','Transparent','Both'});
ylabel('Global FNR (%)');
legend(trackDataNames,'location','northwest');

subplot(2,3,6)
bar(fprG'*100,'grouped');
title('Global FPR');
set(gca,'xticklabel',{'Black','Transparent','Both'});
ylabel('Global FPR (%)');
legend(trackDataNames,'location','northwest');



%-------------------------------------------------------------------------------
% Distance errors analysis
%-------------------------------------------------------------------------------

fprintf('Analysing distance errors...\n');

%initialize variables
%distTr: [dist truth bead - closest detection, associated tr, truth motion state]
%evalTr: [percent ok, mean on ok, std on ok]
nbTrTruth=size(trackInfoTruth,1);
distTr=cell(nbTrTruth,nbData);
evalTrTemp=cell(nbTrTruth,1);evalTrTemp(:)={zeros(nbData,3)};
idSwTr=zeros(nbTrTruth,nbData);
catTr=uint8(arrayfun(@(tr)...
    trackTruth{trackInfoTruth(tr,1)}(trackTruth{trackInfoTruth(tr,1)}(:,4)==tr,3),...
    1:nbTrTruth))';

%compute distance errors
if isempty(gcp('nocreate')) && nbW~=0, parpool(nbW); end
t=now;
ParforProgress(t,nbData*nbTrTruth);
parfor(trt=1:nbTrTruth,nbW)
    for data=1:nbData
        numim=trackInfoTruth(trt,1);
        len=trackInfoTruth(trt,2);
        b=find(trackTruth{numim}(:,4)==trt);
        cat=trackTruth{numim}(b,3);
        distTr(trt,data)={nan(len,3,'single')};
        fnTr=0;
        
        for im=numim:(numim+len-1)
            if im>numim, b=trackTruth{im-1}(b,8); end
            dist=(trackData{data}{im}(:,1)-trackTruth{im}(b,1)).^2+...
                 (trackData{data}{im}(:,2)-trackTruth{im}(b,2)).^2;
            dist(trackData{data}{im}(:,3)~=cat)=NaN;
            [d,p]=min(dist);
            d=sqrt(d);
            if d<=distOkCat(cat+1)
                distTr{trt,data}(im-numim+1,:)=...
                    [d,trackData{data}{im}(p,4),trackTruth{im}(b,9)];
            else
                fnTr=fnTr+1;
            end
        end
        
        idSwTr(trt,data)=length(unique(...
            distTr{trt,data}(~isnan(distTr{trt,data}(:,2)),2)))-1;
        
        modeTr=mode(distTr{trt,data}(:,2));
        
        evalTrTemp{trt}(data,1)=(len-idSwTr(trt,data)-fnTr)/len;
        evalTrTemp{trt}(data,2)=mean(...
            distTr{trt,data}(distTr{trt,data}(:,2)==modeTr,1));
        evalTrTemp{trt}(data,3)=std(...
            distTr{trt,data}(distTr{trt,data}(:,2)==modeTr,1));
        
        ParforProgress(t,0,(trt-1)*nbData+data);
    end
end
ParforProgress(t,0);
delete(gcp('nocreate'));

%transform evalTr variable to simplify its futur use
evalTr=cell(1,nbData);evalTr(:)={zeros(nbTrTruth,3)};
for data=1:nbData
    for trt=1:nbTrTruth
        for i=1:3
            evalTr{data}(trt,i)=evalTrTemp{trt}(data,i);
        end
    end
end


%compute mean and std distance errors for each bead category and each ground
%truth motion state
meanDist=zeros(nbData,3,4);%data(1,2,...), cat(0,1,all), ms(0,1,2,all)
stdDist=zeros(nbData,3,4); %data(1,2,...), cat(0,1,all), ms(0,1,2,all)
for data=1:nbData
    for cat=0:1
        for ms=0:2
            dist=cellfun(@(x)x(x(:,3)==ms,1)',distTr(catTr==cat,data),'uni',0);
            dist=[dist{:}];
            meanDist(data,cat+1,ms+1)=mean(dist(~isnan(dist)));
            stdDist(data,cat+1,ms+1)=std(dist(~isnan(dist)));
        end
        dist=cellfun(@(x)x(:,1)',distTr(catTr==cat,data),'uni',0);
        dist=[dist{:}];
        meanDist(data,cat+1,4)=mean(dist(~isnan(dist)));
        stdDist(data,cat+1,4)=std(dist(~isnan(dist)));
    end
    
    for ms=0:2
        dist=cellfun(@(x)x(x(:,3)==ms,1)',distTr(:,data),'uni',0);
        dist=[dist{:}];
        meanDist(data,3,ms+1)=mean(dist(~isnan(dist)));
        stdDist(data,3,ms+1)=std(dist(~isnan(dist)));
    end
    dist=cellfun(@(x)x(:,1)',distTr(:,data),'uni',0);
    dist=[dist{:}];
    meanDist(data,3,4)=mean(dist(~isnan(dist)));
    stdDist(data,3,4)=std(dist(~isnan(dist)));
end

%plot results of distance errors analysis

%result: percent of correct tracks
figure;
subplot(1,2,1);
hist(cell2mat(cellfun(@(x)x(:,1),evalTr,'uni',0)),0:0.05:1);
title('Histogram of correct tracks');
xlabel('Percent of correct tracks');
ylabel('Number of tracks in bins');
legend(trackDataNames,'location','northwest');
xlim([-0.02,1.02]);

subplot(1,2,2);
[tr0Ok,~]=hist(cell2mat(cellfun(@(x)x(catTr==0,1),evalTr,'uni',0)),0:0.05:1);
[tr1Ok,~]=hist(cell2mat(cellfun(@(x)x(catTr==1,1),evalTr,'uni',0)),0:0.05:1);
[trAllOk,~]=hist(cell2mat(cellfun(@(x)x(:,1),evalTr,'uni',0)),0:0.05:1);
trOk=[tr0Ok(21,:)'/sum(catTr==0),tr1Ok(21,:)'/sum(catTr==1),...
    trAllOk(21,:)'/nbTrTruth];
bar(trOk'*100,'grouped');
title('Percent of correct tracks (more than 95% ok)');
set(gca,'xticklabel',{'Black','Transparent','Both'});
ylabel('Percent of correct tracks (%)');
legend(trackDataNames,'location','north');
ylim([min(trOk(:))*100-1,100]);

%result: std of distance errors by target
figure;
h=plot(cell2mat(cellfun(@(x)x(:,3),evalTr,'uni',0)),'.');
markers='o+*xsd';
for data=1:nbData, set(h(data),'marker',markers(data)); end
title('Std of distance error of target positions');
xlabel('Track id');
ylabel('Std errors');
legend(trackDataNames,'location','northwest');

%result: mean and std distance errors by bead category and GT motion state
figure;
subplot(2,3,1);
bar(squeeze(meanDist(:,1,:))','grouped');
title('Mean distance errors for BLACK beads for each GT motion state');
set(gca,'xticklabel',{'Resting','Rolling','Saltating','All'});
ylabel('Mean distance errors');
legend(trackDataNames,'location','northwest');
ylim([0,2.5]);

subplot(2,3,2);
bar(squeeze(meanDist(:,2,:))','grouped');
title('Mean distance errors for TRANSPARENT beads for each GT motion state');
set(gca,'xticklabel',{'Resting','Rolling','Saltating','All'});
ylabel('Mean distance errors');
legend(trackDataNames,'location','northwest');
ylim([0,2.5]);

subplot(2,3,3);
bar(squeeze(meanDist(:,3,:))','grouped');
title('Mean distance errors for ALL beads for each GT motion state');
set(gca,'xticklabel',{'Resting','Rolling','Saltating','All'});
ylabel('Mean distance errors');
legend(trackDataNames,'location','northwest');
ylim([0,2.5]);

subplot(2,3,4);
bar(squeeze(stdDist(:,1,:))','grouped');
title('Std distance errors for BLACK beads for each GT motion state');
set(gca,'xticklabel',{'Resting','Rolling','Saltating','All'});
ylabel('Std distance errors');
legend(trackDataNames,'location','northwest');

subplot(2,3,5);
bar(squeeze(stdDist(:,2,:))','grouped');
title('Std distance errors for TRANSPARENT beads for each GT motion state');
set(gca,'xticklabel',{'Resting','Rolling','Saltating','All'});
ylabel('Std distance errors');
legend(trackDataNames,'location','northwest');

subplot(2,3,6);
bar(squeeze(stdDist(:,3,:))','grouped');
title('Std distance errors for ALL beads for each GT motion state');
set(gca,'xticklabel',{'Resting','Rolling','Saltating','All'});
ylabel('Std distance errors');
legend(trackDataNames,'location','northwest');



%-------------------------------------------------------------------------------
% MOTP and MOTA analysis
%-------------------------------------------------------------------------------

fprintf('Analysing MOTP and MOTA...\n');

idSw0=cell2mat(cellfun(@(x)length(unique(x(~isnan(x(:,2)),2)))-1,...
    distTr(catTr==0,:),'uni',0));
idSw0=num2cell(sum(idSw0,1));
idSw1=cell2mat(cellfun(@(x)length(unique(x(~isnan(x(:,2)),2)))-1,...
    distTr(catTr==1,:),'uni',0));
idSw1=num2cell(sum(idSw1,1));
idSw=num2cell(cell2mat(idSw0)+cell2mat(idSw1));

motp=zeros(nbData,3,4);%data(1,2,...), cat(0,1,all), ms(0,1,2,all)
for data=1:nbData
    motp(data,1,:)=IouFromDistCenterDisks(...
        radBeadPxCat(1),meanDist(data,1,:))/(pi*radBeadPxCat(1)^2);
    motp(data,2,:)=IouFromDistCenterDisks(...
        radBeadPxCat(2),meanDist(data,2,:))/(pi*radBeadPxCat(2)^2);
    motp(data,3,:)=(...
        squeeze(motp(data,1,:)).*sum(squeeze(nbB(1,[1,2,3,5],:)),2)+...
        squeeze(motp(data,2,:)).*sum(squeeze(nbB(2,[1,2,3,5],:)),2))./...
        sum(squeeze(nbB(3,[1,2,3,5],:)),2);
end

mota=[cell2mat(cellfun(@(x,y,z)...%data(1,2,...), cat(0,1,all)
    1-(sum(sum(x(1,:,:)))+sum(y(1,:))+z)/sum(nbB(1,5,:)),fn,fp,idSw0,'uni',0))',...
    cell2mat(cellfun(@(x,y,z)...
    1-(sum(sum(x(2,:,:)))+sum(y(2,:))+z)/sum(nbB(2,5,:)),fn,fp,idSw1,'uni',0))',...
    cell2mat(cellfun(@(x,y,z)...
    1-(sum(x(:))+sum(y(:))+z)/sum(nbB(3,5,:)),fn,fp,idSw,'uni',0))'];

%plot results of MOTP/MOTA analysis
figure;
subplot(2,3,1);
bar(squeeze(motp(:,1,:))'*100,'grouped');
title('MOTP for BLACK beads');
set(gca,'xticklabel',{'Resting','Rolling','Saltating','All'});
%xlabel('Ground Truth motion states');
ylabel('Mean distance errors (%)');
legend(trackDataNames,'location','southwest');
ylim([min(motp(:))*100-1,100]);

subplot(2,3,2);
bar(squeeze(motp(:,2,:))'*100,'grouped');
title('MOTP for TRANSPARENT beads');
set(gca,'xticklabel',{'Resting','Rolling','Saltating','All'});
ylabel('Mean distance errors (%)');
legend(trackDataNames,'location','southwest');
ylim([min(motp(:))*100-1,100]);

subplot(2,3,3);
bar(squeeze(motp(:,3,:))'*100,'grouped');
title('MOTP for ALL beads');
set(gca,'xticklabel',{'Resting','Rolling','Saltating','All'});
ylabel('Mean distance errors (%)');
legend(trackDataNames,'location','southwest');
ylim([min(motp(:))*100-1,100]);

subplot(2,3,5);
bar(mota'*100,'grouped');
title('MOTA');
set(gca,'xticklabel',{'Black','Transparent','Both'});
ylabel('MOTA (%)');
legend(trackDataNames,'location','north');
ylim([min(mota(:))*100-1,100]);



%-------------------------------------------------------------------------------
% Saving
%-------------------------------------------------------------------------------

trackTruthPath=fileparts(trackTruthFullFile);
save(fullfile(trackTruthPath,[outputFile,'.mat']),'trOk','fnrG','fprG',...
    'idSw','idSwTr','motp','mota','meanDist','stdDist','factRadDistOk');



%-------------------------------------------------------------------------------
% Main evaluation results
%-------------------------------------------------------------------------------

fprintf('Main evaluation results\n');
table(trackDataNames',...
    round(trOk(:,3)*10000)/10000,...
    round(squeeze(motp(:,3,4))*10000)/10000,...
    round(fnrG(:,3,5)*10000)/10000,...
    round(fprG(:,3)*10000)/10000,...
    cell2mat(idSw)',...
    round(mota(:,3)*10000)/10000,...
    'VariableNames',{'TrackData','TrackOk','MOTP','FN','FP','IdSw','MOTA'})

end



function iou = IouFromDistCenterDisks(r,d)
% Compute the IoU (intersection over union) between two disks of the same
% radius knowing the distance between their center.
%
% INPUT ARGUMENTS:
%  r: radius of the disks (in px).
%  d: distance between the center of the disks (in px).
%
% OUTPUT ARGUMENTS:
%  iou: intersection over union (in %).

iou=2*r^2*acos(d/(2*r))-d.*sqrt(r^2-(d/2).^2);

end