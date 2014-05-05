classdef  TiffSeriesReader < Reader
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
        paths
        filenames
    end
    
    methods
        %% Constructor
        function obj = TiffSeriesReader(channelPaths)
            obj.paths = channelPaths;
            nChan = numel(channelPaths);
            obj.sizeX = - ones(nChan, 1);
            obj.sizeY = - ones(nChan, 1);
            obj.sizeT = - ones(nChan, 1);
            obj.sizeC = numel(channelPaths);
            obj.sizeZ = 1;
            obj.bitDepth = - ones(nChan, 1);
            obj.filenames = cell(obj.sizeC, 1);
        end
        
        
        function checkPath(obj, iChan)
            % Check channel path existence
            assert(logical(exist(obj.paths{iChan}, 'dir')), ...
                'Channel path specified is not a valid directory! Please double check the channel path!');
        end
        
        function getXYDimensions(obj, iChan)
            fileNames = obj.getImageFileNames(iChan);
            imInfo = cellfun(@(x) imfinfo([obj.paths{iChan} filesep x]),...
                fileNames, 'UniformOutput', false);
            sizeX = unique(cellfun(@(x)(x.Width), imInfo));
            sizeY = unique(cellfun(@(x)(x.Height), imInfo));
            bitDepth = unique(cellfun(@(x)(x.BitDepth), imInfo));
            assert(isscalar(sizeX) && isscalar(sizeY),...
                ['Image sizes are inconsistent in: \n\n%s\n\n'...
                'Please make sure all the images have the same size.'],obj.paths{iChan});
            
            assert(isscalar(bitDepth),...
                ['Bit depth is inconsistent in: \n\n%s\n\n'...
                'Please make sure all the images have the same bit depth.'],obj.paths{iChan});

            obj.sizeX(iChan) = sizeX;
            obj.sizeY(iChan) = sizeY;
            obj.bitDepth(iChan) = bitDepth;
        end
        
        function sizeX = getSizeX(obj, iChan)
            if obj.sizeX(iChan) == -1,
                obj.getXYDimensions(iChan);
            end
            sizeX = obj.sizeX(iChan);
        end
        
        function sizeY = getSizeY(obj, iChan)
            if  obj.sizeY(iChan) == -1,
                obj.getXYDimensions(iChan);
            end
            sizeY = obj.sizeY(iChan);
        end
        
        function sizeZ = getSizeZ(obj, varargin)
            sizeZ = obj.sizeZ;
        end
        
        function sizeC = getSizeC(obj, varargin)
            sizeC = obj.sizeC;
        end
        
        function sizeT = getSizeT(obj, iChan)
            if obj.sizeT(iChan) == -1,
                fileNames = obj.getImageFileNames(iChan);
                obj.sizeT(iChan) = length(fileNames);
            end
            sizeT = obj.sizeT(iChan);
        end
        
        function bitDepth = getBitDepth(obj, iChan)
            if obj.bitDepth(iChan) == -1,
                obj.getXYDimensions(iChan);
            end
                
            bitDepth = obj.bitDepth(iChan);
        end
        
        function filenames = getImageFileNames(obj, iChan, iFrame)
            % Channel path is a directory of image files
            if isempty(obj.filenames{iChan})
                obj.checkPath(iChan);
                [files nofExt] = imDir(obj.paths{iChan}, true);
                assert(nofExt~=0,['No proper image files are detected in:'...
                    '\n\n%s\n\nValid image file extension: tif, TIF, STK, bmp, BMP, jpg, JPG.'],obj.paths{iChan});
                assert(nofExt==1,['More than one type of image files are found in:'...
                    '\n\n%s\n\nPlease make sure all images are of same type.'],obj.paths{iChan});
                
                obj.filenames{iChan} = arrayfun(@(x) x.name, files,...
                    'UniformOutput',false);
            end
            if nargin>2,
                filenames = obj.filenames{iChan}(iFrame);
            else
                filenames = obj.filenames{iChan};
            end
            
        end
        
        function chanNames = getChannelNames(obj, iChan)
            chanNames = obj.paths(iChan);
        end
        
        function I = loadImage(obj, iChan, iFrame)
            % Initialize array
            sizeX = obj.getSizeX(iChan);
            sizeY = obj.getSizeY(iChan);
            bitDepth = obj.getBitDepth(iChan);
            class = ['uint' num2str(bitDepth)];
            I = zeros([sizeY, sizeX, numel(iFrame)], class);
            
            % Read individual files
            fileNames = obj.getImageFileNames(iChan, iFrame);
            for i=1:numel(iFrame)
                I(:,:,i)  = imread([obj.paths{iChan} filesep fileNames{i}]);
            end
        end
    end
end