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
% Hugo Lafaye de Micheaux, 2019

[~,~,ext]=fileparts(imageFullFiles{1});
imageFullFilesReg=cellfun(@(x)str2double(regexp(x,'w*\d+$','match')),...
    regexprep(imageFullFiles,ext,''),'uni',0);
[~,sortIndexes]=sort(cell2mat(imageFullFilesReg));
imageFullFilesSorted=imageFullFiles(sortIndexes);

end