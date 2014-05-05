function mainFig = movieViewer(MO,varargin)
%MOVIEVIEWER creates a graphical interface to display the analysis output of a MovieObject
% 
% h = movieViewer(MD)
% movieViewer(MD, [1 2]);
% h = movieViewer(ML, 'movieIndex', 3);
%
% This function reads the components of a MovieObject including all
% drawable anlaysis results (determined by the getDrawableOutput method).
% It then generates a graphical interface allowing to switch between image
% results and toggle on/off overlay components. Additionally, two
% interfaces can be created: one to control movie display options (for the
% image and the various overlays) and one interface showing the different
% graph results (i.e. results displayed on separate figures).
% 
% Input 
%
%   MO - the MovieObject to be displayed. If a MovieList is input, the main
%   interface will have a popupmenu allowing to switch between the list and
%   all the movie components.
% 
%   procId - Optional. An array containing the indices of the processes 
%   which output should be displayed by default. Default: empty.
%
%   Optional parameters in param/value pairs
%
%   movieIndex - Integer. For movie list input. If 0 display the movie list
%   and its analysis. If non-zero, set the index of the movie to be
%   displayed. Default: 0.
%
% Output:
%   
%   mainFig - the handle of the main control interface
%
% See also: graphViewer, movieViewerOptions
%
% Sebastien Besson, July 2012 (last modified Nov 2012)
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

% Check input
ip = inputParser;
ip.addRequired('MO',@(x) isa(x,'MovieObject'));
ip.addOptional('procId',[],@isnumeric);
ip.addParamValue('movieIndex',0,@isscalar);
ip.parse(MO,varargin{:});

% Check existence of viewer interface
h=findobj(0,'Name','Viewer');
if ~isempty(h), delete(h); end

% Generate the main figure
mainFig=figure('Name','Viewer','Position',[0 0 200 200],...
    'NumberTitle','off','Tag','figure1','Toolbar','none','MenuBar','none',...
    'Color',get(0,'defaultUicontrolBackgroundColor'),'Resize','off',...
    'DeleteFcn', @(h,event) deleteViewer());
userData=get(mainFig,'UserData');

% Read the MovieObject and process index input 
if isa(ip.Results.MO,'MovieList')
    userData.ML=ip.Results.MO;
    userData.movieIndex=ip.Results.movieIndex;
    if userData.movieIndex~=0
        userData.MO=ip.Results.MO.getMovies{userData.movieIndex};
    else
        userData.MO=ip.Results.MO;
    end
        
    userData.procId = ip.Results.procId;
    if ~isempty(ip.Results.procId)
        procId = userData.MO.getProcessIndex(class(userData.ML.processes_{ip.Results.procId}));
    else
        procId = ip.Results.procId;
    end
else
    userData.MO=ip.Results.MO;
    procId=ip.Results.procId;
end

% Read all drawable output
validProcId= find(cellfun(@(x) ismember('getDrawableOutput',methods(x)) &...
    x.success_,userData.MO.processes_));
validProc=userData.MO.processes_(validProcId);

% Classify movieData processes by type (image, overlay or graph)
getOutputType = @(type) cellfun(@(x) any(~cellfun(@isempty,...
    regexp({x.getDrawableOutput.type},type,'once','start'))), validProc);
isImageProc = getOutputType('image');
imageProc=validProc(isImageProc);
imageProcId = validProcId(isImageProc);
isOverlayProc = getOutputType('[oO]verlay');
overlayProc = validProc(isOverlayProc);
overlayProcId = validProcId(isOverlayProc);
isGraphProc =getOutputType('[gG]raph');
graphProc=validProc(isGraphProc);
graphProcId = validProcId(isGraphProc);

% Create series of anonymous function to generate process controls
createProcText= @(panel,i,j,pos,name) uicontrol(panel,'Style','text',...
    'Position',[10 pos 250 20],'Tag',['text_process' num2str(i)],...
    'String',name,'HorizontalAlignment','left','FontWeight','bold');
createOutputText= @(panel,i,j,pos,text) uicontrol(panel,'Style','text',...
    'Position',[40 pos 200 20],'Tag',['text_process' num2str(i) '_output'...
    num2str(j)],'String',text,'HorizontalAlignment','left');
createProcButton= @(panel,i,j,k,pos) uicontrol(panel,'Style','radio',...
    'Position',[200+30*k pos 20 20],'Tag',['radiobutton_process' num2str(i) '_output'...
    num2str(j) '_channel' num2str(k)]);
createChannelBox= @(panel,i,j,k,pos,varargin) uicontrol(panel,'Style','checkbox',...
    'Position',[200+30*k pos 20 20],'Tag',['checkbox_process' num2str(i) '_output'...
    num2str(j) '_channel' num2str(k)],varargin{:});
createMovieBox= @(panel,i,j,pos,name,varargin) uicontrol(panel,'Style','checkbox',...
    'Position',[40 pos 200 25],'Tag',['checkbox_process' num2str(i) '_output'...
    num2str(j)],'String',[' ' name],varargin{:});

%% Image panel creation
if isa(userData.MO,'MovieData')
    imagePanel = uibuttongroup(mainFig,'Position',[0 0 1/2 1],...
        'Title','Image','BackgroundColor',get(0,'defaultUicontrolBackgroundColor'),...
        'Units','pixels','Tag','uipanel_image');
        
    % Create controls for switching between process image output
    hPosition=10;
    nProc = numel(imageProc);
    for iProc=nProc:-1:1;
        output=imageProc{iProc}.getDrawableOutput;
        validChan = imageProc{iProc}.checkChannelOutput;
        validOutput = find(strcmp({output.type},'image'));
        for iOutput=validOutput(end:-1:1)
            createOutputText(imagePanel,imageProcId(iProc),iOutput,hPosition,output(iOutput).name);
            arrayfun(@(x) createProcButton(imagePanel,imageProcId(iProc),iOutput,x,hPosition),...
                find(validChan));
            hPosition=hPosition+20;
        end
        createProcText(imagePanel,imageProcId(iProc),iOutput,hPosition,imageProc{iProc}.getName);
        hPosition=hPosition+20;
    end
    
    % Create controls for selecting channels (raw image)
    hPosition=hPosition+10;
    uicontrol(imagePanel,'Style','radio','Position',[10 hPosition 200 20],...
        'Tag','radiobutton_channels','String',' Raw image','Value',1,...
        'HorizontalAlignment','left','FontWeight','bold');
    arrayfun(@(i) uicontrol(imagePanel,'Style','checkbox',...
        'Position',[200+30*i hPosition 20 20],...
        'Tag',['checkbox_channel' num2str(i)],'Value',i<4,...
        'Callback',@(h,event) redrawChannel(h,guidata(h))),...
        1:numel(userData.MO.channels_));
    
    hPosition=hPosition+20;
    uicontrol(imagePanel,'Style','text','Position',[120 hPosition 100 20],...
        'Tag','text_channels','String','Channels');
    arrayfun(@(i) uicontrol(imagePanel,'Style','text',...
        'Position',[200+30*i hPosition 20 20],...
        'Tag',['text_channel' num2str(i)],'String',i),...
        1:numel(userData.MO.channels_));    
else
    imagePanel=-1;
end

%% Overlay panel creation
if ~isempty(overlayProc)
    overlayPanel = uipanel(mainFig,'Position',[1/2 0 1/2 1],...
        'Title','Overlay','BackgroundColor',get(0,'defaultUicontrolBackgroundColor'),...
        'Units','pixels','Tag','uipanel_overlay');
    
    % Create overlay options
    hPosition=10;
    nProc = numel(overlayProc);
    for iProc=nProc:-1:1;
        output=overlayProc{iProc}.getDrawableOutput;
        
        % Create checkboxes for movie overlays
        validOutput = find(strcmp({output.type},'movieOverlay'));
        for iOutput=validOutput(end:-1:1)
            createMovieBox(overlayPanel,overlayProcId(iProc),iOutput,hPosition,output(iOutput).name,...
                'Callback',@(h,event) redrawOverlay(h,guidata(h)));
            hPosition=hPosition+20;
        end
        
        % Create checkboxes for channel-specific overlays
        validOutput = find(strcmp({output.type},'overlay'));
        for iOutput=validOutput(end:-1:1)
            validChan = overlayProc{iProc}.checkChannelOutput;
            createOutputText(overlayPanel,overlayProcId(iProc),iOutput,hPosition,output(iOutput).name);
            arrayfun(@(x) createChannelBox(overlayPanel,overlayProcId(iProc),iOutput,x,hPosition,...
                'Callback',@(h,event) redrawOverlay(h,guidata(h))),find(validChan));
            hPosition=hPosition+20;
        end
        createProcText(overlayPanel,overlayProcId(iProc),iOutput,hPosition,overlayProc{iProc}.getName);
        hPosition=hPosition+20;
    end
    
    if ~isempty(overlayProc)
        uicontrol(overlayPanel,'Style','text','Position',[120 hPosition 100 20],...
            'Tag','text_channels','String','Channels');
        arrayfun(@(i) uicontrol(overlayPanel,'Style','text',...
            'Position',[200+30*i hPosition 20 20],...
            'Tag',['text_channel' num2str(i)],'String',i),...
            1:numel(userData.MO.channels_));
    end
else
    overlayPanel=-1;
end

%% Get image/overlay panel size and resize them
imagePanelSize = getPanelSize(imagePanel);
overlayPanelSize = getPanelSize(overlayPanel);
panelsLength = max(500,imagePanelSize(1)+overlayPanelSize(1));
panelsHeight = max([imagePanelSize(2),overlayPanelSize(2)]);

% Resize panel
if ishandle(imagePanel)
    set(imagePanel,'Position',[10 panelsHeight-imagePanelSize(2)+10 ...
        imagePanelSize(1) imagePanelSize(2)],...
        'SelectionChangeFcn',@(h,event) redrawImage(guidata(h)))
end
if ishandle(overlayPanel)
    set(overlayPanel,'Position',[imagePanelSize(1)+10 panelsHeight-overlayPanelSize(2)+10 ...
        overlayPanelSize(1) overlayPanelSize(2)]);
end


%% Create movie panel
moviePanel = uipanel(mainFig,...
    'Title','','BackgroundColor',get(0,'defaultUicontrolBackgroundColor'),...
    'Units','pixels','Tag','uipanel_movie','BorderType','none');

hPosition=10;

if isa(userData.MO,'MovieData')
    % Create control button for exporting figures and movie (cf Francois' GUI)
    uicontrol(moviePanel, 'Style', 'togglebutton','String', 'Run movie',...
        'Position', [10 hPosition 100 20],'Callback',@(h,event) runMovie(h,guidata(h)));
    uicontrol(moviePanel, 'Style', 'checkbox','Tag','checkbox_saveFrames',...
        'Value',0,'String', 'Save frames','Position', [150 hPosition 100 20]);
    uicontrol(moviePanel, 'Style', 'checkbox','Tag','checkbox_saveMovie',...
        'Value',0,'String', 'Save movie','Position', [250 hPosition 100 20]);
    uicontrol(moviePanel, 'Style', 'popupmenu','Tag','popupmenu_movieFormat',...
        'Value',1,'String', {'MOV';'AVI'},'Position', [350 hPosition 100 20]);
    

    
    % Create controls for scrollling through the movie
    hPosition = hPosition+30;
    uicontrol(moviePanel,'Style','text','Position',[10 hPosition 50 15],...
        'String','Frame','Tag','text_frame','HorizontalAlignment','left');
    uicontrol(moviePanel,'Style','edit','Position',[70 hPosition 30 20],...
        'String','1','Tag','edit_frame','BackgroundColor','white',...
        'HorizontalAlignment','left',...
        'Callback',@(h,event) redrawScene(h,guidata(h)));
    uicontrol(moviePanel,'Style','text','Position',[100 hPosition 40 15],...
        'HorizontalAlignment','left',...
        'String',['/' num2str(userData.MO.nFrames_)],'Tag','text_frameMax');
    
    uicontrol(moviePanel,'Style','slider',...
        'Position',[150 hPosition panelsLength-160 20],...
        'Value',1,'Min',1,'Max',userData.MO.nFrames_,...
        'SliderStep',[1/double(userData.MO.nFrames_)  5/double(userData.MO.nFrames_)],...
        'Tag','slider_frame','BackgroundColor','white',...
        'Callback',@(h,event) redrawScene(h,guidata(h)));
end
% Create movie location edit box
hPosition = hPosition+30;
uicontrol(moviePanel,'Style','text','Position',[10 hPosition 40 20],...
    'String','Movie','Tag','text_movie');

% Create popupmenu if input is a MovieList, else  list the movie path
if isa(ip.Results.MO,'MovieList')
    moviePaths = cellfun(@getDisplayPath,userData.ML.getMovies,'UniformOutput',false);
    movieIndex=0:numel(moviePaths);
    
    uicontrol(moviePanel,'Style','popupmenu','Position',[60 hPosition panelsLength-110 20],...
        'String',vertcat(getDisplayPath(ip.Results.MO),moviePaths'),'UserData',movieIndex,...
        'Value',find(userData.movieIndex==movieIndex),...
        'HorizontalAlignment','left','BackgroundColor','white','Tag','popup_movie',...
        'Callback',@(h,event) switchMovie(h,guidata(h)));
    if userData.movieIndex==0, set(findobj(moviePanel,'Tag','text_movie'),'String','List'); end
    
else
    uicontrol(moviePanel,'Style','edit','Position',[60 hPosition panelsLength-110 20],...
        'String',getDisplayPath(ip.Results.MO),...
        'HorizontalAlignment','left','BackgroundColor','white','Tag','edit_movie');
end

% Add help button
set(0,'CurrentFigure',mainFig)
hAxes = axes('Units','pixels','Position',[panelsLength-50 hPosition  48 48],...
    'Tag','axes_help', 'Parent', moviePanel);
icons = loadLCCBIcons();
Img = image(icons.questIconData);
set(hAxes, 'XLim',get(Img,'XData'),'YLim',get(Img,'YData'), 'visible','off','YDir','reverse');
set(Img,'ButtonDownFcn',@icon_ButtonDownFcn, 'UserData', struct('class','movieViewer'));

% Add copyrigth
hPosition = hPosition+30;
uicontrol(moviePanel,'Style','text','Position',[10 hPosition panelsLength-100 20],...
    'String',getLCCBCopyright(),'Tag','text_copyright',...
    'HorizontalAlignment','left');

% Get overlay panel size
moviePanelSize = getPanelSize(moviePanel);
moviePanelHeight =moviePanelSize(2);

%% Resize panels and figure
sz=get(0,'ScreenSize');
maxWidth = panelsLength+20;
maxHeight = panelsHeight+moviePanelHeight;
set(mainFig,'Position',[sz(3)/50 sz(4)/2 maxWidth maxHeight]);
set(moviePanel,'Position',[10 panelsHeight+10 panelsLength moviePanelHeight]);

% Update handles structure and attach it to the main figure
handles = guihandles(mainFig);
guidata(handles.figure1, handles);


% Create redraw callbacks
userData.redrawImageFcn = @(varargin) redrawImage(handles, varargin{:});
userData.redrawOverlaysFcn = @(varargin) redrawOverlays(handles, varargin{:});
userData.getFigure = @(figName) getFigure(handles, figName);
set(handles.figure1,'UserData',userData);

% Create options figure
if isa(userData.MO, 'MovieData')
    optionsFig = movieViewerOptions(mainFig);
    set(optionsFig, 'Tag', 'optionsFig');
end
%% Add additional panel for independent graphs
if ~isempty(graphProc) 
    graphFig = graphViewer(mainFig, graphProc, graphProcId, intersect(graphProcId,procId));
    set(graphFig, 'Tag', 'graphFig');
end
%% Set up default parameters
% Auto check input process
for i=intersect(procId,validProcId)
    h=findobj(mainFig,'-regexp','Tag',['(\w)_process' num2str(i)  '_output1.*'],...
        '-not','Style','text');
    set(h,'Value',1);
end

% Update the image and overlays
if isa(userData.MO,'MovieData'), redrawScene(handles.figure1, handles); end

function displayPath= getDisplayPath(movie)
[~,endPath] = fileparts(movie.getPath);
displayPath = fullfile(endPath,movie.getFilename);

function switchMovie(hObject,handles)
userData=get(handles.figure1,'UserData');
props=get(hObject,{'UserData','Value'});
if isequal(props{1}(props{2}), userData.movieIndex),return;end
movieViewer(userData.ML,userData.procId,'movieIndex',props{1}(props{2}));

function size = getPanelSize(hPanel)
if ~ishandle(hPanel), size=[0 0]; return; end
a=get(get(hPanel,'Children'),'Position');
P=vertcat(a{:});
size = [max(P(:,1)+P(:,3))+10 max(P(:,2)+P(:,4))+20];

function runMovie(hObject,handles)

userData = get(handles.figure1, 'UserData');
nFrames = userData.MO.nFrames_;
startFrame = get(handles.slider_frame,'Value');
if startFrame == nFrames, startFrame =1; end;
if get(hObject,'Value'), action = 'Stop'; else action = 'Run'; end
set(hObject,'String',[action ' movie']);

% Get frame/movies export status
saveMovie = get(handles.checkbox_saveMovie,'Value');
saveFrames = get(handles.checkbox_saveFrames,'Value');
props = get(handles.popupmenu_movieFormat,{'String','Value'});
movieFormat = props{1}{props{2}};

if saveMovie,
    moviePath = fullfile(userData.MO.outputDirectory_,['Movie.' lower(movieFormat)]);
end

% Initialize movie output
if saveMovie && strcmpi(movieFormat,'mov')
    MakeQTMovie('start',moviePath);
    MakeQTMovie('quality',.9)
end

if saveMovie && strcmpi(movieFormat,'avi')
    movieFrames(1:nFrames) = struct('cdata', [],'colormap', []);
end

% Initialize frame output
if saveFrames;
    fmt = ['%0' num2str(ceil(log10(nFrames))) 'd'];
    frameName = @(frame) ['frame' num2str(frame, fmt) '.tif'];
    fpath = [userData.MO.outputDirectory_ filesep 'Frames'];
    mkClrDir(fpath);
    fprintf('Generating movie frames:     ');
end

for iFrame = startFrame : nFrames
    if ~get(hObject,'Value'), return; end % Handle pushbutton press
    set(handles.slider_frame, 'Value',iFrame);
    redrawScene(hObject, handles);    
    drawnow;
    
    % Get current frame for frame/movie export
    hFig = getFigure(handles,'Movie');
    if saveMovie && strcmpi(movieFormat,'mov'), MakeQTMovie('addfigure'); end
    if saveMovie && strcmpi(movieFormat,'avi'), movieFrames(iFrame) = getframe(hFig); end
    if saveFrames
        print(hFig, '-dtiff', fullfile(fpath,frameName(iFrame)));
        fprintf('\b\b\b\b%3d%%', round(100*iFrame/(nFrames)));
    end
end

% Finish frame/movie creation
if saveFrames; fprintf('\n'); end
if saveMovie && strcmpi(movieFormat,'mov'), MakeQTMovie('finish'); end
if saveMovie && strcmpi(movieFormat,'avi'), movie2avi(movieFrames,moviePath); end

% Reset button
set(hObject,'String', 'Run movie', 'Value', 0);

function redrawScene(hObject, handles)

userData = get(handles.figure1, 'UserData');
% Retrieve the value of the selected image
if strcmp(get(hObject,'Tag'),'edit_frame')
    frameNumber = str2double(get(handles.edit_frame, 'String'));
else
    frameNumber = get(handles.slider_frame, 'Value');
end
frameNumber=round(frameNumber);
frameNumber = min(max(frameNumber,1),userData.MO.nFrames_);

% Set the slider and editboxes values
set(handles.edit_frame,'String',frameNumber);
set(handles.slider_frame,'Value',frameNumber);

% Update the image and overlays
redrawImage(handles);
redrawOverlays(handles);

function h= getFigure(handles,figName)

h = findobj(0,'-regexp','Name',['^' figName '$']);
if ~isempty(h), figure(h); return; end

%Create a figure
if strcmp(figName,'Movie')
    userData = get(handles.figure1,'UserData');
    sz=get(0,'ScreenSize');
    nx=userData.MO.imSize_(2);
    ny=userData.MO.imSize_(1);
    sc = max(1, max(nx/(.9*sz(3)), ny/(.9*sz(4))));
    h = figure('Position',[sz(3)*.2 sz(4)*.2 nx/sc ny/sc],...
        'Name',figName,'NumberTitle','off','Tag','viewerFig',...
        'UserData',handles.figure1);
    
    % figure options for movie export
    iptsetpref('ImShowBorder','tight');
    set(h, 'InvertHardcopy', 'off');
    set(h, 'PaperUnits', 'Points');
    set(h, 'PaperSize', [nx ny]);
    set(h, 'PaperPosition', [0 0 nx ny]); % very important
    set(h, 'PaperPositionMode', 'auto');
    % set(h,'DefaultLineLineSmoothing','on');
    % set(h,'DefaultPatchLineSmoothing','on');
    
    axes('Parent',h,'XLim',[0 userData.MO.imSize_(2)],...
        'YLim',[0 userData.MO.imSize_(1)],'Position',[0.05 0.05 .9 .9]);
    set(handles.figure1,'UserData',userData);
    
    % Set the zoom properties
    hZoom=zoom(h);
    hPan=pan(h);
    set(hZoom,'ActionPostCallback',@(h,event)panZoomCallback(h));
    set(hPan,'ActionPostCallback',@(h,event)panZoomCallback(h));
else
    h = figure('Name',figName,'NumberTitle','off','Tag','viewerFig');
end


function redrawChannel(hObject,handles)

% Callback for channels checkboxes to avoid 0 or more than 4 channels
channelBoxes = findobj(handles.figure1,'-regexp','Tag','checkbox_channel*');
nChan=numel(find(arrayfun(@(x)get(x,'Value'),channelBoxes)));
if nChan==0, set(hObject,'Value',1); elseif nChan>3, set(hObject,'Value',0); end

redrawImage(handles)

function redrawImage(handles,varargin)
frameNr=get(handles.slider_frame,'Value');
imageTag = get(get(handles.uipanel_image,'SelectedObject'),'Tag');

% Get the figure handle
drawFig = getFigure(handles,'Movie');
userData=get(handles.figure1,'UserData');

% Use corresponding method depending if input is channel or process output
channelBoxes = findobj(handles.figure1,'-regexp','Tag','checkbox_channel*');
[~,index]=sort(arrayfun(@(x) get(x,'Tag'),channelBoxes,'UniformOutput',false));
channelBoxes =channelBoxes(index);
if strcmp(imageTag,'radiobutton_channels')
    set(channelBoxes,'Enable','on');
    chanList=find(arrayfun(@(x)get(x,'Value'),channelBoxes));
    userData.MO.channels_(chanList).draw(frameNr,varargin{:});
    displayMethod = userData.MO.channels_(chanList(1)).displayMethod_;
else
    set(channelBoxes,'Enable','off');
    % Retrieve the id, process nr and channel nr of the selected imageProc
    tokens = regexp(imageTag,'radiobutton_process(\d+)_output(\d+)_channel(\d+)','tokens');
    procId=str2double(tokens{1}{1});
    outputList = userData.MO.processes_{procId}.getDrawableOutput;
    iOutput = str2double(tokens{1}{2});
    output = outputList(iOutput).var;
    iChan = str2double(tokens{1}{3});
    userData.MO.processes_{procId}.draw(iChan,frameNr,'output',output,varargin{:});
    displayMethod = userData.MO.processes_{procId}.displayMethod_{iOutput,iChan};
end

optFig = findobj(0,'-regexp','Name','Movie options');
if ~isempty(optFig), 
    userData = get(optFig,'userData');
    userData.setImageOptions(drawFig, displayMethod)
end

function panZoomCallback(varargin)

% Find if options figure exist
optionsFig = findobj(0,'-regexp','Tag', 'optionsFig');
if ~isempty(optionsFig)
    % Reset the scaleBar
    handles = guidata(optionsFig);
    scalebarCallback = get(handles.edit_imageScaleBar,'Callback');
    timeStampCallback = get(handles.checkbox_timeStamp,'Callback');
    scalebarCallback(optionsFig);
    timeStampCallback(optionsFig);
end

function redrawOverlays(handles)
if ~isfield(handles,'uipanel_overlay'), return; end

overlayBoxes = findobj(handles.uipanel_overlay,'-regexp','Tag','checkbox_process*');
checkedBoxes = logical(arrayfun(@(x) get(x,'Value'),overlayBoxes));
overlayTags=arrayfun(@(x) get(x,'Tag'),overlayBoxes(checkedBoxes),...
    'UniformOutput',false);
for i=1:numel(overlayTags),
    redrawOverlay(handles.(overlayTags{i}),handles)
end

function redrawOverlay(hObject,handles)
userData=get(handles.figure1,'UserData');
frameNr=get(handles.slider_frame,'Value');
overlayTag = get(hObject,'Tag');

% Get figure handle or recreate figure
movieFig = findobj(0,'Name','Movie');
if isempty(movieFig),  redrawScene(hObject, handles); return; end
figure(movieFig);
% Retrieve the id, process nr and channel nr of the selected imageProc
tokens = regexp(overlayTag,'^checkbox_process(\d+)_output(\d+)','tokens');
procId=str2double(tokens{1}{1});
outputList = userData.MO.processes_{procId}.getDrawableOutput;
iOutput = str2double(tokens{1}{2});
output = outputList(iOutput).var;

% Discriminate between channel-specific processes annd movie processes
tokens = regexp(overlayTag,'_channel(\d+)$','tokens');
if ~isempty(tokens)
    iChan = str2double(tokens{1}{1});
    inputArgs={iChan,frameNr};
    graphicTag =['process' num2str(procId) '_channel'...
        num2str(iChan) '_output' num2str(iOutput)];
else
    iChan = [];
    inputArgs={frameNr};
    graphicTag = ['process' num2str(procId) '_output' num2str(iOutput)];
end
% Get options figure handle
optFig = findobj(0,'-regexp','Name','Movie options');
if ~isempty(optFig), userData = get(optFig, 'userData'); end

% Draw or delete the overlay depending on the checkbox value
if get(hObject,'Value')
    if ~isempty(optFig),
        options = userData.getOverlayOptions();
    else
        options = {};
    end    
    
    userData.MO.processes_{procId}.draw(inputArgs{:},'output',output,...
        options{:});
else
    h=findobj('Tag',graphicTag);
    if ~isempty(h), delete(h); end
end

% Get display method and update option status
if isempty(iChan),
    displayMethod = userData.MO.processes_{procId}.displayMethod_{iOutput};
else
    displayMethod = userData.MO.processes_{procId}.displayMethod_{iOutput,iChan};
end
if ~isempty(optFig),
    userData.setOverlayOptions(displayMethod)
end

function deleteViewer()

tags = {'viewerFig','optionsFig','graphFig'};
for i = 1:numel(tags)
    h = findobj(0,'-regexp','Tag', tags{i});
    if ~isempty(h), delete(h); end
end
