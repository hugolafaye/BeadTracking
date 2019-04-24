function imageFullFilesSorted = SortImageFullFiles(imageFullFiles)
% Sort image full files of a sequence in case the file names are not well sorted 
% because of missing zeros in front of numbers, and remove files without 
% numbers. Ex: 'image10.tif' appears before 'image2.tif' when names are loaded.
%
% INPUT ARGUMENTS:
%  imageFullFiles: cell array of unsorted image full files.
%
% OUTPUT ARGUMENTS:
%  imageFullFilesSorted: cell array of sorted image full files.
%
% Copyright (c) 2019, Hugo Lafaye de Micheaux, Thomas Gautrais, Université
% Jean Monnet, CNRS, Irstea
% All rights reserved.
%
% This source code is part of the BeadTracking package
% <https://github.com/hugolafaye/BeadTracking> and it is licensed under the
% BSD-style license found in the LICENSE file in the root directory of this
% source tree.

[~,~,ext]=fileparts(imageFullFiles{1});
imageFullFilesReg=cellfun(@(x)str2double(regexp(x,'w*\d+$','match')),...
    regexprep(imageFullFiles,ext,''),'uni',0);
[~,sortIndexes]=sort(cell2mat(imageFullFilesReg));
imageFullFilesSorted=imageFullFiles(sortIndexes);

end