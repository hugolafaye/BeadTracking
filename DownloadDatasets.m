% This script downloads and extracts some datasets to the path specified below.
%
% Copyright (c) 2019, Hugo Lafaye de Micheaux, Thomas Gautrais, Université
% Jean Monnet, CNRS, Irstea
% All rights reserved.
%
% This source code is part of the BeadTracking package
% <https://github.com/hugolafaye/BeadTracking> and it is licensed under the
% BSD-style license found in the LICENSE file in the root directory of this
% source tree.

%default parameters
boolComputeParallel=1;

%local path where the datatsets will be located, change it as you wish
pathData='.\Data1\';

%url where datasets are located
url='https://dossier.univ-st-etienne.fr/ltsi/public/Dataset/BeadTrackingData/';

%list of datatsets to download
datasets={'BaumerBimAmont500a','BaumerBimAmont500b','BaumerBimAmont1000',...
    'NumericalSimulation5000a','NumericalSimulation5000b',...
    'NumericalSimulation10000'};

%create the data folder if it doesn't exist already
if ~exist(pathData,'dir'), mkdir(pathData); end

%download all datasets in parallel or not according what is asked and possible
fprintf('Downloading and extracting datasets...\n');
v=ver;
if boolComputeParallel && find(ismember({v.Name},'Parallel Computing Toolbox'))
    if isempty(gcp('nocreate')), parpool; end
    t=now;
    ParforProgress(t,length(datasets));
    parfor d=1:length(datasets)
        unzip([url,datasets{d},'.zip'],[pathData,datasets{d}]);
        ParforProgress(t,0,d);
    end
    ParforProgress(t,0);
    delete(gcp('nocreate'));
else
    t=now;
    ParforProgress(t,length(datasets));
    for d=1:length(datasets)
        unzip([url,datasets{d},'.zip'],[pathData,datasets{d}]);
        ParforProgress(t,0,d);
    end
    ParforProgress(t,0);
end