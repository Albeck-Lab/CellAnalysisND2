function MD = bfImport(dataPath,varargin)
% BFIMPORT imports movie files into MovieData objects using Bioformats
%
% MD = bfimport(dataPath)
% MD = bfimport(dataPath, false)
% MD = bfimport(dataPath, 'outputDirectory', outputDir)
%
% Load proprietary files using the Bioformats library. Read the metadata
% that is associated with the movie and the channels and set them into the
% created movie objects.
%
% Input:
%
%   dataPath - A string containing the full path to the movie file.
%
%   importMetadata - A flag specifying whether the movie metadata read by
%   Bio-Formats should be copied into the MovieData. Default: true.
%
%   Optional Parameters :
%       ('FieldName' -> possible values)
%
%       outputDirectory - A string giving the directory where to save the
%       created MovieData as well as the analysis output. In the case of
%       multi-series images, this string gives the basename of the output
%       folder and will be exanded as basename_sxxx for each movie
%
% Output:
%
%   MD - A single MovieData object or an array of MovieData objects
%   depending on the number of series in the original images.
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

% Sebastien Besson, Dec 2011

status = bfCheckJavaPath();
assert(status, 'Bioformats library missing');

% Input check
ip=inputParser;
ip.addRequired('dataPath',@ischar);
ip.addOptional('importMetadata',true,@islogical);
ip.addParamValue('outputDirectory',[],@ischar);
ip.parse(dataPath,varargin{:});

assert(exist(dataPath,'file')==2,'File does not exist'); % Check path

try
    % Retrieve movie reader and metadata
    r=bfGetReader(dataPath);
    r.setSeries(0);
catch bfException
    ME = MException('lccb:import:error','Import error');
    ME = ME.addCause(bfException);
    throw(ME);
end

% Read number of series and initialize movies
nSeries = r.getSeriesCount();
MD(1, nSeries) = MovieData();

% Set output directory (based on image extraction flag)
[mainPath,movieName,movieExt]=fileparts(dataPath);
token = regexp([movieName,movieExt],'(.+)\.ome\.tiff','tokens');
if ~isempty(token), movieName = token{1}{1}; end

if ~isempty(ip.Results.outputDirectory)
    mainOutputDir = ip.Results.outputDirectory;
else
    mainOutputDir = fullfile(mainPath, movieName);
end

% Create movie channels
nChan = r.getSizeC();
movieChannels(nSeries, nChan) = Channel();

for i = 1:nSeries
    fprintf(1,'Creating movie %g/%g\n',i,nSeries);
    iSeries = i-1;
    
    % Read movie metadata using Bio-Formats
    if ip.Results.importMetadata
        movieArgs = getMovieMetadata(r, iSeries);
    else
        movieArgs = {};
    end
    
    % Read number of channels, frames and stacks
    nChan =  r.getMetadataStore().getPixelsSizeC(iSeries).getValue;
    
    % Generate movie filename out of the input name
    if nSeries>1
        sString = num2str(i, ['_s%0' num2str(floor(log10(nSeries))+1) '.f']);
        outputDir = [mainOutputDir sString];
        movieFileName = [movieName sString '.mat'];
    else
        outputDir = mainOutputDir;
        movieFileName = [movieName '.mat'];
    end
    
    % Create output directory
    if ~isdir(outputDir), mkdir(outputDir); end
    
    for iChan = 1:nChan
        
        if ip.Results.importMetadata
            channelArgs = getChannelMetadata(r, iSeries, iChan-1);
        else
            channelArgs = {};
        end
        
        % Create new channel
        movieChannels(i, iChan) = Channel(dataPath, channelArgs{:});
    end
    
    % Create movie object
    MD(i) = MovieData(movieChannels(i, :), outputDir, movieArgs{:});
    MD(i).setPath(outputDir);
    MD(i).setFilename(movieFileName);
    MD(i).setSeries(iSeries);
    
    % Close reader and check movie sanity
    MD(i).sanityCheck;
    
end
% Close reader
r.close;

function movieArgs = getMovieMetadata(r, iSeries)

% Create movie metadata cell array using read metadata
movieArgs={};

pixelSizeX = r.getMetadataStore().getPixelsPhysicalSizeX(iSeries);
% Pixel size might be automatically set to 1.0 by @#$% Metamorph
hasValidPixelSize = ~isempty(pixelSizeX) && pixelSizeX.getValue ~= 1;
if hasValidPixelSize
    % Convert from microns to nm and check x and y values are equal
    pixelSizeX= pixelSizeX.getValue*10^3;
    pixelSizeY= r.getMetadataStore().getPixelsPhysicalSizeY(iSeries).getValue*10^3;
    assert(isequal(pixelSizeX,pixelSizeY),'Pixel size different in x and y');
    movieArgs=horzcat(movieArgs,'pixelSize_',pixelSizeX);
end

% Camera bit depth
camBitdepth = r.getBitsPerPixel();
hasValidCamBitDepth = ~isempty(camBitdepth) && mod(camBitdepth, 2) == 0;
if hasValidCamBitDepth
    movieArgs=horzcat(movieArgs,'camBitdepth_',camBitdepth);
end

% Time interval
timeInterval = r.getMetadataStore().getPixelsTimeIncrement(iSeries);
if ~isempty(timeInterval)
    movieArgs=horzcat(movieArgs,'timeInterval_',double(timeInterval));
end

% Lens numerical aperture
try % Use a try-catch statement because property is not always defined
    lensNA=r.getMetadataStore().getObjectiveLensNA(0,0);
    if ~isempty(lensNA)
        movieArgs=horzcat(movieArgs,'numAperture_',double(lensNA));
    elseif ~isempty(r.getMetadataStore().getObjectiveID(0,0))
        % Hard-coded for deltavision files. Try to get the objective id and
        % read the objective na from a lookup table
        tokens=regexp(char(r.getMetadataStore().getObjectiveID(0,0).toString),...
            '^Objective\:= (\d+)$','once','tokens');
        if ~isempty(tokens)
            [na,mag]=getLensProperties(str2double(tokens),{'na','magn'});
            movieArgs=horzcat(movieArgs,'numAperture_',na,'magnification_',mag);
        end
    end
end

function channelArgs = getChannelMetadata(r, iSeries, iChan)

channelArgs={};

% Read excitation wavelength
exwlgth=r.getMetadataStore().getChannelExcitationWavelength(iSeries, iChan);
if ~isempty(exwlgth)
    channelArgs=horzcat(channelArgs, 'excitationWavelength_', exwlgth.getValue);
end

% Fill emission wavelength
emwlgth=r.getMetadataStore().getChannelEmissionWavelength(iSeries, iChan);
if isempty(emwlgth)
    try
        emwlgth= r.getMetadataStore().getChannelLightSourceSettingsWavelength(iSeries, iChan);
    end
end
if ~isempty(emwlgth)
    channelArgs = horzcat(channelArgs, 'emissionWavelength_', emwlgth.getValue);
end

% Read imaging mode
acquisitionMode = r.getMetadataStore().getChannelAcquisitionMode(iSeries, iChan);
if ~isempty(acquisitionMode),
    acquisitionMode = char(acquisitionMode.toString);
    switch acquisitionMode
        case {'TotalInternalReflection','TIRF'}
            channelArgs = horzcat(channelArgs, 'imageType_', 'TIRF');
        case 'WideField'
            channelArgs = horzcat(channelArgs, 'imageType_', 'Widefield');
        case {'SpinningDiskConfocal','SlitScanConfocal','LaserScanningConfocalMicroscopy'}
            channelArgs = horzcat(channelArgs, 'imageType_', 'Confocal');
        otherwise
            disp('Acqusition mode not supported by the Channel object');
    end
end

% Read fluorophore
fluorophore = r.getMetadataStore().getChannelFluor(iSeries, iChan);
if ~isempty(fluorophore),
    fluorophores = Channel.getFluorophores();
    isFluorophore = strcmpi(fluorophore, fluorophores);
    if ~any(isFluorophore),
        disp('Fluorophore not supported by the Channel object');
    else
        channelArgs = horzcat(channelArgs, 'fluorophore_',...
            fluorophores(find(isFluorophore, 1)));
    end
end
