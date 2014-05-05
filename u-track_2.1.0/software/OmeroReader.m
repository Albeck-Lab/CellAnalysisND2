classdef  OmeroReader < Reader
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
        imageID
    end
    
    properties (Transient = true)
        session
        image
        pixels
    end
    
    methods
        %% Constructor
        function obj = OmeroReader(imageID, session)
            obj.imageID = imageID;
            obj.setSession(session);
        end
        
        
        %% Dimensions functions
        function sizeX = getSizeX(obj, varargin)
            sizeX = obj.getPixels().getSizeX.getValue;
        end
        
        function sizeY = getSizeY(obj, varargin)
            sizeY = obj.getPixels().getSizeY.getValue;
        end
        
        function sizeC = getSizeC(obj, varargin)
            sizeC = obj.getPixels().getSizeC.getValue;
        end
        
        function sizeZ = getSizeZ(obj, varargin)
            sizeZ = obj.getPixels().getSizeZ.getValue;
        end
        
        function sizeT = getSizeT(obj, varargin)
            sizeT = obj.getPixels().getSizeT.getValue;
        end
        
        function session = getSession(obj)
            % Check session is not empty
            assert(~isempty(obj.session), 'No session created');
            session =  obj.session;
        end
        
        function setSession(obj, session)
            % Check input
            ip = inputParser;
            ip.addRequired('session', @MovieObject.isOmeroSession);
            ip.parse(session);
            
            obj.session = session;
        end
        
        function bitDepth = getBitDepth(obj, varargin)
            pixelType = obj.getPixels().getPixelsType();
            pixelsService=obj.getSession().getPixelsService();
            bitDepth = pixelsService.getBitDepth(pixelType);
        end
        
        %% Image/Channel name functions
        function fileNames = getImageFileNames(obj, iChan, varargin)
            % Generate image file names
            basename = sprintf('Image%g_c%d_t', obj.imageID, iChan);
            fileNames = arrayfun(@(t) [basename num2str(t, ['%0' num2str(floor(log10(obj.getSizeT))+1) '.f']) '.tif'],...
                1:obj.getSizeT,'Unif',false);
            
        end
        
        function chanNames = getChannelNames(obj, iChan)
            chanNames = arrayfun(@(x) ['Image ' num2str(obj.imageID) ...
                ': Channel ' num2str(x)], iChan, 'UniformOutput', false);
        end
        
        
        %% Image loading function
        function I = loadImage(obj, iChan, iFrame)

            % Initialize array
            class = ['uint' num2str(obj.getBitDepth())];
            I = zeros([obj.getSizeY(), obj.getSizeX(), numel(iFrame)], class);

            % Test session integrity
            store = obj.getSession().createRawPixelsStore();
            store.setPixelsId(obj.getPixels().getId().getValue(), false);
            
            for i=1:numel(iFrame),
                plane = store.getPlane(0, iChan-1, iFrame(i)-1);
                I(:,:,i)=toMatrix(plane, obj.getPixels())';
            end
        end
        
        %% Helper functions
        function image = getImage(obj)
            if isempty(obj.image),
                obj.image = getImages(obj.getSession(), obj.imageID);
            end
            image = obj.image;
        end
        
        function pixels = getPixels(obj)
            pixels = obj.getImage().getPrimaryPixels();
        end       
    end
end