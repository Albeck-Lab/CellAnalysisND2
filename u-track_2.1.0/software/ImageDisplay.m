classdef ImageDisplay < MovieDataDisplay
    %Abstract class for displaying image processing output
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
        Colormap ='gray';
        Colorbar ='off';
        ColorbarLocation ='EastOutside';
        CLim = [];
        Units='';
        sfont = {'FontName', 'Helvetica', 'FontSize', 18};
        lfont = {'FontName', 'Helvetica', 'FontSize', 22};
        ScaleFactor = 1;
        NaNColor = [0 0 0];
    end
    methods
        function obj=ImageDisplay(varargin)
            obj@MovieDataDisplay(varargin{:});
        end
            
        function h=initDraw(obj,data,tag,varargin)
            % Plot the image and associate the tag
            h=imshow(data/obj.ScaleFactor,varargin{:});
            set(h,'Tag',tag,'CDataMapping','scaled');
            hAxes = get(h,'Parent');
            set(hAxes,'XLim',[0 size(data,2)],'YLim',[0 size(data,1)]);
            usrData = get(h,'UserData');
            usrData.DisplayClass = 'ImageDisplay';%Tag all objects displayed by this class, so they can be easily identified and cleared.
            set(h,'UserData',usrData)            
            obj.applyImageOptions(h)
        end
        function updateDraw(obj,h,data)
            set(h,'CData',data/obj.ScaleFactor)
            obj.applyImageOptions(h)
        end
        
        function applyImageOptions(obj,h)
            % Clean existing image and set image at the bottom of the stack
            hAxes = get(h,'Parent');
            child=get(hAxes,'Children');
            imChild = child(cellfun(@(x)(isfield(x,'DisplayClass') && strcmp(x.DisplayClass,'ImageDisplay')),arrayfun(@(x)(get(x,'UserData')),child,'Unif',false)));%Clear all objects which were displayed by this class. Use arrayfun for get so it always returns cell.
            delete(imChild(imChild~=h));
            uistack(h,'bottom');
            
            % Set the colormap
            if any(isnan(get(h, 'CData')))
                c = colormap(obj.Colormap);
                c=[obj.NaNColor; c];
                colormap(hAxes, c);
            else
                colormap(hAxes,obj.Colormap);
            end
            
            % Set the colorbar
            hCbar = findobj(get(hAxes,'Parent'),'Tag','Colorbar');
            axesPosition = [0 0 1 1];
            if strcmp(obj.Colorbar,'on')
                if length(obj.ColorbarLocation) >6 && strcmp(obj.ColorbarLocation(end-6:end),'Outside'),
                    axesPosition = [0.05 0.05 .9 .9];
                end
                if isempty(hCbar)
                    set(hAxes,'Position',axesPosition);   
                    hCbar = colorbar('peer',hAxes,obj.sfont{:});
                end
                set(hCbar,'Location',obj.ColorbarLocation);
                ylabel(hCbar,obj.Units,obj.lfont{:});
            else
                if ~isempty(hCbar),colorbar(hCbar,'delete'); end
                set(hAxes,'Position',axesPosition);
            end
            
            % Set the color limits
            if ~isempty(obj.CLim),set(hAxes,'CLim',obj.CLim/obj.ScaleFactor); end
        end
    end 
 
    methods (Static)
         function params=getParamValidators()
            params(1).name='Colormap';
            params(1).validator=@ischar;
            params(2).name='Colorbar';
            params(2).validator=@(x) any(strcmp(x,{'on','off'}));
            params(3).name='CLim';
            params(3).validator=@isvector;
            params(4).name='Units';
            params(4).validator=@ischar;
            params(5).name='sfont';
            params(5).validator=@iscell;
            params(6).name='lfont';
            params(6).validator=@iscell;
            params(7).name='ColorbarLocation';
            findclass(findpackage('scribe'),'colorbar');
            locations = findtype('ColorbarLocationPreset');
            locations = locations.Strings;
            params(7).validator=@(x) any(strcmp(x,locations));
            params(8).name='ScaleFactor';
            params(8).validator=@isscalar;
            params(9).name='NaNColor';
            params(9).validator=@isvector;
        end
        function f=getDataValidator()
            f=@isnumeric;
        end
    end    
end