classdef  BioFormatsReader < Reader
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
    
    properties (Transient =true)
        formatReader
    end
    
    methods
        %% Constructor
        function obj = BioFormatsReader(path, iSeries)
            bfCheckJavaPath(); % Check loci-tools.jar is in the Java path
            loci.common.DebugTools.enableLogging('OFF');
            obj.formatReader = bfGetReader(path, false);
            if nargin>1,
                obj.formatReader.setSeries(iSeries);
            end
        end
        
        function metadataStore = getMetadataStore(obj)
            r = obj.formatReader;
            metadataStore = r.getMetadataStore();
        end
        
        function series = getSeries(obj)
            series = obj.formatReader.getSeries();
        end
        
        function sizeX = getSizeX(obj, varargin)
            sizeX = obj.getMetadataStore().getPixelsSizeX(obj.getSeries()).getValue();
        end
        
        function sizeY = getSizeY(obj, varargin)
            sizeY = obj.getMetadataStore().getPixelsSizeY(obj.getSeries()).getValue();
        end
        
        function sizeZ = getSizeZ(obj, varargin)
            sizeZ = obj.getMetadataStore().getPixelsSizeZ(obj.getSeries()).getValue();
        end
        
        function sizeT = getSizeT(obj, varargin)
            sizeT = obj.getMetadataStore().getPixelsSizeT(obj.getSeries()).getValue();
        end
        
        function sizeC = getSizeC(obj, varargin)
            sizeC = obj.getMetadataStore().getPixelsSizeC(obj.getSeries()).getValue();
        end
        
        function bitDepth = getBitDepth(obj, varargin)
            pixelType = obj.formatReader.getPixelType();
            bpp = loci.formats.FormatTools.getBytesPerPixel(pixelType);
            bitDepth = 8 * bpp;
        end
        
        function fileNames = getImageFileNames(obj, iChan, varargin)
            % Generate image file names
            [~, fileName] = fileparts(char(obj.formatReader.getCurrentFile));
            basename = sprintf('%s_s%g_c%d_t',fileName, obj.getSeries()+1, iChan);
            fileNames = arrayfun(@(t) [basename num2str(t, ['%0' num2str(floor(log10(obj.getSizeT))+1) '.f']) '.tif'],...
                1:obj.getSizeT,'Unif',false);
        end
        
        function channelNames = getChannelNames(obj, iChan)
            [~, fileName, fileExt] = fileparts(char(obj.formatReader.getCurrentFile));
            
            if obj.formatReader.getSeriesCount() > 1
                base = [fileName fileExt ' Series ' num2str(obj.getSeries()+1) ' Channel '];
            else
                base = [fileName fileExt ' Channel '];
            end
            
            channelNames = arrayfun(@(x) [base num2str(x)], iChan, 'Unif',false);
        end
        
        function I = loadImage(obj, c, t)
            % Using bioformat tools, get the reader and retrieve dimension order
            r = obj.formatReader;
            class = char(loci.formats.FormatTools.getPixelTypeString(r.getPixelType));
            if strcmp(class, 'float'), class = 'single'; end
            I = zeros([obj.getSizeY(), obj.getSizeX(), numel(t)], class);
            
            z = 1;
            for i = 1 : numel(t),
                iPlane = loci.formats.FormatTools.getIndex(r, z-1, c-1, t(i)-1);
                I(:,:,i) = bfGetPlane(r, iPlane + 1);
            end
        end
        
        function delete(obj)
            obj.formatReader.close()
        end
    end
end