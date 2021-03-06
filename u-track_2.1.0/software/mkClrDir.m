function mkClrDir(dirPath)
%MKCLRDIR makes sure that the specified directory exists AND is empty 
% 
% This is just a little function for creating / settin up output
% directories. It checks if a directory exists and if not, makes it. If the
% directories does exist and contains files, these are deleted.
% 
% Input:
% 
%   dirPath - the path to the directory to make/clear.
% 
% Hunter Elliott
% 6/2010
%
% Copyright (C) 2013 LCCB 
%
% This file is part of U-Track.
% 
% U-Track is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% U-Track is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with U-Track.  If not, see <http://www.gnu.org/licenses/>.
% 
% 

if nargin < 1 || isempty(dirPath)
    error('You must specify the directory to set up!')
end

if ~exist(dirPath,'dir')
    mkdir(dirPath)
else
    %Check for files in the directory
    inDir = dir([dirPath filesep '*']);
    if ~isempty(inDir)
        %Remove the . and .. from dir (on linux)
        inDir = inDir(arrayfun(@(x)(~strcmp('.',x.name) ...
            && ~strcmp('..',x.name)),inDir));
        arrayfun(@(x)(delete([dirPath filesep x.name])),inDir);
    end
end