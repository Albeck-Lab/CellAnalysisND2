
%% movie information
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
movieParam.imageDir = 'C:\kjData\Galbraiths\data\alphaVY773AandCellEdge\121128_Cs1C3_Y773A\imagesAlphaVY773A\'; %directory where images are
movieParam.filenameBase = '121128_Cs1C3_CHO_mEos2AvBeta3Y773A_'; %image file name base
movieParam.firstImageNum = 2; %number of first image in movie
movieParam.lastImageNum = 9600; %number of last image in movie
movieParam.digits4Enum = 5; %number of digits used for frame enumeration (1-4).

%% detection parameters
detectionParam.psfSigma = 1.2; %point spread function sigma (in pixels)
detectionParam.testAlpha = struct('alphaR',0.05,'alphaA',0.05,'alphaD',0.05,'alphaF',0); %alpha-values for detection statistical tests
detectionParam.visual = 0; %1 to see image with detected features, 0 otherwise
detectionParam.doMMF = 1; %1 if mixture-model fitting, 0 otherwise
detectionParam.bitDepth = 16; %Camera bit depth
detectionParam.alphaLocMax = 0.1; %alpha-value for initial detection of local maxima
detectionParam.numSigmaIter = 0; %maximum number of iterations for PSF sigma estimation
detectionParam.integWindow = 0; %number of frames before and after a frame for time integration

detectionParam.calcMethod = 'g';

%absolute background info and parameters...
background.imageDir = 'C:\kjData\Galbraiths\data\alphaVY773AandCellEdge\121128_Cs1C3_Y773A\bgAlphaVY773A\';
background.filenameBase = 'crop_121128_Cs1C3_CHO_mEos2AvBeta3Y773A_';
background.alphaLocMaxAbs = 0.01;
detectionParam.background = background;

%% additional input

%saveResults
saveResults.dir = 'C:\kjData\Galbraiths\data\alphaVY773AandCellEdge\121128_Cs1C3_Y773A\analysisAlphaVY773A\tracks\'; %directory where to save input and output
saveResults.filename = 'detectionAll1.mat'; %name of file where input and output are saved
% saveResults = 0;

%verbose state
verbose = 1;

%% run the detection function
[movieInfo,exceptions,localMaxima,background,psfSigma] = ...
    detectSubResFeatures2D_StandAlone(movieParam,detectionParam,saveResults,verbose);
