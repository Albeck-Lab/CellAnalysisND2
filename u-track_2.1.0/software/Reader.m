classdef  Reader < handle
    % Concrete implementation of MovieObject for a single movie
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
    
    properties
        sizeX
        sizeY
        sizeZ
        sizeC
        sizeT
        bitDepth
    end
    
    methods(Abstract)
        getSizeX(obj)
        getSizeY(obj)
        getSizeZ(obj)
        getSizeC(obj)
        getSizeT(obj)
        getBitDepth(obj)
        getImageFileNames(obj)
        getChannelNames(obj)
        loadImage(obj)
    end
    
end