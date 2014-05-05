% [r, udata, sdata] = getMultiplicity(data) returns the occurrences/Multiplicity of the elements of 'data'
%
% Inputs:
%         data : n-dimensional input array
%
% Outputs: 
%          rep : # of occurrences for each element of 'data'
%        udata : sorted 1-D array of unique values in 'data'
%        sdata : sorted 1-D array of values in 'data'
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

% Francois Aguet, 03/02/2012 (modified on 10/29/2012)

function [rep, udata, sdata] = getMultiplicity(data)
sdata = sort(data(:))';
rep = diff([0 find([diff(sdata)~=0 1])]);
udata = unique(sdata);