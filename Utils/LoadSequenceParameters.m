function [sp,flagError] = LoadSequenceParameters(spFullFile)
% Load the sequence parameters from a file.
%
% INPUT ARGUMENTS:
%  spFullFile: full file containing the sequence parameters.
%
% OUTPUT ARGUMENTS:
%  seqParam : structure containing the sequence parameters.
%  flagError: boolean saying if an error occured.
%
% Hugo Lafaye de Micheaux, 2019

sp=[];
flagError=false;
try
    fid=fopen(spFullFile);
    C=textscan(fid,'%s\t%f\t%s');
    fclose(fid);
    for p=1:length(C{1})
        sp.(C{1}{p})=C{2}(p);
    end
catch
    warning(['Execution stopped: Inexistent or uncorrect file of sequence ',...
        'parameters. Each parameter (i.e. each line of the file) ',...
        'must be nameParam \t value \t unit.']);
    flagError=true;
end

end