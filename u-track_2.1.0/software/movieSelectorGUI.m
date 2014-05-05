function varargout = movieSelectorGUI(varargin)
% MOVIESELECTORGUI M-file for movieSelectorGUI.fig
%      MOVIESELECTORGUI, by itself, creates a new MOVIESELECTORGUI or raises the existing
%      singleton*.
%
%      H = MOVIESELECTORGUI returns the handle to a new MOVIESELECTORGUI or the handle to
%      the existing singleton*.
%
%      MOVIESELECTORGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MOVIESELECTORGUI.M with the given input arguments.
%
%      MOVIESELECTORGUI('Property','Value',...) creates a new MOVIESELECTORGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before movieSelectorGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to movieSelectorGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES
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

% Edit the above text to modify the response to help movieSelectorGUI

% Last Modified by GUIDE v2.5 07-Nov-2012 18:14:25

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @movieSelectorGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @movieSelectorGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before movieSelectorGUI is made visible.
function movieSelectorGUI_OpeningFcn(hObject, eventdata, handles, varargin)
%
% Useful tools:
% 
% User Data:
%
%   userData.MD - new or loaded MovieData object
%   userData.ML - newly saved or loaded MovieList object
%
%   userData.userDir - default open directory
%   userData.colormap - color map (used for )
%   userData.questIconData - image data of question icon
%
%   userData.packageGUI - the name of package GUI
%
%   userData.newFig - handle of new movie set-up GUI
%   userData.iconHelpFig - handle of help dialog
%   userData.msgboxGUI - handle of message box GUI

ip = inputParser;
ip.addRequired('hObject',@ishandle);
ip.addRequired('eventdata',@(x) isstruct(x) || isempty(x));
ip.addRequired('handles',@isstruct);
ip.addParamValue('packageName','',@ischar);
ip.addParamValue('MD', MovieData.empty(1,0) ,@(x) isempty(x) || isa(x,'MovieData'));
ip.addParamValue('ML', MovieList.empty(1,0), @(x) isempty(x) || isa(x,'MovieList'));
ip.parse(hObject,eventdata,handles,varargin{:});

set(handles.text_copyright, 'String', getLCCBCopyright())

userData = get(handles.figure1, 'UserData');

% Choose default command line output for setupMovieDataGUI
handles.output = hObject;

% other user data set-up
userData.MD = MovieData.empty(1,0);
userData.ML = MovieList.empty(1,0);
userData.userDir = pwd;
userData.newFig=-1;
userData.msgboxGUI=-1;
userData.iconHelpFig =-1;

% Load help icon from dialogicons.mat
userData = loadLCCBIcons(userData);

% Get concrete packages
packageList = getPackageList();
if isempty(packageList), 
    warndlg('No package found! Please make sure you properly added the installation directory to the path (see user''s manual).',...
        'Movie Selector','modal'); 
end
packageNames = cellfun(@(x) eval([x '.getName']),packageList,'Unif',0);
[packageNames,index]=sort(packageNames);
packageList=packageList(index);

% Create radio controls for packages
nPackages=numel(packageList);
pos = get(handles.uipanel_packages,'Position');
for i=1:nPackages
    uicontrol(handles.uipanel_packages,'Style','radio',...
    'Position',[30 pos(4)-20-30*i pos(3)-35 20],'Tag',['radiobutton_package' num2str(i)],...
    'String',[' ' packageNames{i}],'UserData',packageList{i},...
    'Value',strcmp(packageList{i},ip.Results.packageName))

    axes('Units','pixels',...
        'Position',[10 pos(4)-20-30*i 20 20],'Tag',['axes_help_package' num2str(i)],...
        'Parent',handles.uipanel_packages)
    Img = image(userData.questIconData, 'UserData', struct('class', packageList{i}));
    set(gca, 'XLim',get(Img,'XData'),'YLim',get(Img,'YData'), 'Visible','off');
    set(Img,'ButtonDownFcn',@icon_ButtonDownFcn);
    
end
set(handles.uipanel_packages,'SelectionChangeFcn','');

% Populate movie list to analyze
if ~isempty(ip.Results.ML)
    userData.ML=ip.Results.ML;
    % Populate movies with the movie list components if no MD is passed
    if isempty(ip.Results.MD)
        MD = arrayfun(@(x) horzcat(x.getMovies{:}),userData.ML,'Unif',0);
        userData.MD = horzcat(MD{:});
    else
        userData.MD = MovieData.empty(1,0);
    end
end

% Populate movies to analyze
if ~isempty(ip.Results.MD)
    userData.MD = horzcat(userData.MD,ip.Results.MD);
end

% Filter movies to get a unique list
[~,index] = unique(arrayfun(@getFullPath,userData.MD,'Unif',0));
userData.MD = userData.MD(sort(index));

% Filter movie lists to get a unique list
[~,index] = unique(arrayfun(@getFullPath,userData.ML,'Unif',0));
userData.ML = userData.ML(sort(index));

supermap(1,:) = get(hObject,'color');

userData.colormap = supermap;

set(handles.figure1,'CurrentAxes',handles.axes_help);
Img = image(userData.questIconData);
set(hObject,'colormap',supermap);
set(gca, 'XLim',get(Img,'XData'),'YLim',get(Img,'YData'),...
    'visible','off');
set(Img,'ButtonDownFcn',@icon_ButtonDownFcn,'UserData', struct('class',mfilename)); 

set(handles.figure1,'UserData',userData);
refreshDisplay(hObject,eventdata,handles);
% Save userdata
guidata(hObject, handles);

function packageList = getPackageList()

packageList = {'BiosensorsPackage';...
    'FocalAdhesionPackage'
    'FocalAdhesionSegmentationPackage'
    'IntegratorPackage'
    'QFSMPackage'
    'SegmentationPackage'
    'TFMPackage'
    'TrackingPackage'
    'WindowingPackage'};
validPackage = cellfun(@(x) exist(x,'class')==8,packageList);
packageList = packageList(validPackage);

% --- Outputs from this function are returned to the command line.
function varargout = movieSelectorGUI_OutputFcn(hObject, eventdata, handles) 
% %varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in pushbutton_cancel.
function pushbutton_cancel_Callback(hObject, eventdata, handles)
delete(handles.figure1)

% --- Executes on button press in pushbutton_done.
function pushbutton_done_Callback(hObject, eventdata, handles)

% Check a package is selected
if isempty(get(handles.uipanel_packages, 'SelectedObject'))
   warndlg('Please select a package to continue.', 'Movie Selector', 'modal')
   return
end

% Retrieve the ID of the selected button and call the appropriate
userData = get(handles.figure1, 'UserData');
selectedPackage=get(get(handles.uipanel_packages, 'SelectedObject'),'UserData');

% Select movie or list depending on the package nature
class = eval([selectedPackage '.getMovieClass()']);
if strcmp(class, 'MovieList')
    type = 'movie list';
    field = 'ML';
else
    type = 'movie';
    field = 'MD'; 
end
  
if isempty(userData.(field))
    warndlg(['Please load at least one ' type ' to continue.'], 'Movie Selector', 'modal')
    return
end

close(handles.figure1);
packageGUI(selectedPackage,userData.(field),...
    'MD', userData.MD, 'ML', userData.ML);

% --- Executes on selection change in listbox_movie.
function listbox_movie_Callback(hObject, eventdata, handles)

refreshDisplay(hObject, eventdata, handles)

% --- Executes on button press in pushbutton_new.
function pushbutton_new_Callback(hObject, eventdata, handles)

userData = get(handles.figure1, 'UserData');
% if movieDataGUI exist, delete it
if ishandle(userData.newFig), delete(userData.newFig); end
userData.newFig = movieDataGUI('mainFig',handles.figure1);
set(handles.figure1,'UserData',userData);

% --- Executes on button press in pushbutton_prepare.
function pushbutton_prepare_Callback(hObject, eventdata, handles)

userData = get(handles.figure1, 'UserData');
% if preparation GUI exist, delete it
if ishandle(userData.newFig), delete(userData.newFig); end
userData.newFig = dataPreparationGUI('mainFig',handles.figure1);
set(handles.figure1,'UserData',userData);

% --- Executes on button press in pushbutton_delete.
function pushbutton_delete_Callback(hObject, eventdata, handles)

userData = get(handles.figure1, 'Userdata');
if isempty(userData.MD), return;end

% Delete channel object
num = get(handles.listbox_movie,'Value');
removedMovie=userData.MD(num);
userData.MD(num) = [];

% Test if movie does not share common ancestor
checkCommonAncestor= arrayfun(@(x) any(isequal(removedMovie.getAncestor,x.getAncestor)),userData.MD);
if ~any(checkCommonAncestor), delete(removedMovie); end

% Refresh listbox_channel
set(handles.figure1, 'Userdata', userData)
refreshDisplay(hObject,eventdata,handles);
guidata(hObject, handles);

% --- Executes on button press in pushbutton_detail.
function pushbutton_detail_Callback(hObject, eventdata, handles)

% Return if no movie 
props=get(handles.listbox_movie, {'String','Value'});
if isempty(props{1}), return; end

userData = get(handles.figure1, 'UserData');
% if movieDataGUI exist, delete it
userData.newFig = movieDataGUI(userData.MD(props{2}));
set(handles.figure1,'UserData',userData);

% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)

userData = get(handles.figure1, 'UserData');

if ishandle(userData.newFig), delete(userData.newFig); end
if ishandle(userData.iconHelpFig), delete(userData.iconHelpFig); end
if ishandle(userData.msgboxGUI), delete(userData.msgboxGUI); end

% --- Executes on button press in pushbutton_open.
function pushbutton_open_Callback(hObject, eventdata, handles)

userData = get(handles.figure1, 'UserData');
filespec = {'*.mat','MATLAB Files'};
[filename, pathname] = uigetfile(filespec,'Select a movie or a list of movies', ...
    userData.userDir);
if ~any([filename pathname]), return; end
userData.userDir = pathname;

% Check if reselect the movie data that is already in the listbox
moviePaths = get(handles.listbox_movie, 'String');
movieListPaths = get(handles.listbox_movieList, 'String');

if any(strcmp([pathname filename],vertcat(moviePaths,movieListPaths)))
    errordlg('This movie has already been selected.','Error','modal');
    return
end

try
    M = MovieObject.load([pathname filename]);
catch ME
    msg = sprintf('Movie: %s\n\nError: %s\n\nMovie is not successfully loaded. Please refer to movie detail and adjust your data.', [pathname filename],ME.message);
    errordlg(msg, 'Movie error','modal');
    return
end

switch class(M)
    case 'MovieData'
        userData.MD = horzcat(userData.MD, M);
    case 'MovieList'        
        % Find duplicate movie data in list box
        movieDataFile = M.movieDataFile_;
        index = 1: length(movieDataFile);
        movieList=get(handles.listbox_movie,'String');
        index = index(~ismember(movieDataFile,movieList));
        
        if isempty(index)
            msg = sprintf('All movie data in movie list file %s has already been added to the movie list box.', M.movieListFileName_);
            warndlg(msg,'Warning','modal');
        end
                  
        % Healthy Movie Data        
        userData.ML = horzcat(userData.ML, M);
        userData.MD = horzcat(userData.MD,M.getMovies{index});
    otherwise
        error('User-defined: varable ''type'' does not have an approprate value.')
end

% Refresh movie list box in movie selector panel
set(handles.figure1, 'UserData', userData);
refreshDisplay(hObject,eventdata,handles);

function menu_about_Callback(hObject, eventdata, handles)

status = web(get(hObject,'UserData'), '-browser');
if status
    switch status
        case 1
            msg = 'System default web browser is not found.';
        case 2
            msg = 'System default web browser is found but could not be launched.';
        otherwise
            msg = 'Fail to open browser for unknown reason.';
    end
    warndlg(msg,'Fail to open browser','modal');
end

% --------------------------------------------------------------------
function menu_file_quit_Callback(hObject, eventdata, handles)
delete(handles.figure1)

% --- Executes on button press in pushbutton_deleteall.
function pushbutton_deleteall_Callback(hObject, eventdata, handles)
userData = get(handles.figure1, 'Userdata');

contentlist = get(handles.listbox_movie,'String');
% Return if list is empty
if isempty(contentlist), return; end
 
% Confirm deletion
user_response = questdlg(['Are you sure to delete all the '...
    'movies and movie lists?'], ...
    'Movie Listbox', 'Yes','No','Yes');
if strcmpi('no', user_response), return; end

% Delete movies and movie lists
userData.MD = MovieData.empty(1,0);
userData.ML = MovieList.empty(1,0);
set(handles.figure1, 'Userdata', userData)
refreshDisplay(hObject, eventdata, handles)
guidata(hObject, handles);

% --- Executes on button press in pushbutton_save.
function pushbutton_save_Callback(hObject, eventdata, handles)

userData = get(handles.figure1, 'UserData');

if isempty(userData.MD)
    warndlg('No movie selected. Please create new movie data or open existing movie data or movie list.', 'No Movie Selected', 'modal')
    return
end

if isempty(userData.ML)
    movieListPath = [userData.userDir filesep];
    movieListFileName = 'movieList.mat';
else
    movieListPath = userData.ML(end).movieListPath_;
    movieListFileName = userData.ML(end).movieListFileName_;
end

% Ask user where to save the movie data file
[filename,path] = uiputfile('*.mat','Find a place to save your movie list',...
             [movieListPath filesep movieListFileName]);         
if ~any([filename,path]), return; end

listPaths = arrayfun(@getFullPath,userData.ML,'Unif',false);
if any(strcmp([path filename], listPaths))
    user_response = questdlg(['Are you sure to want to overwrite the list '...
        'with the current selection of movies? All analysis performed at the '...
        'list level will be lost.'], ...
        'Movie Listbox', 'Yes','No','Yes');
    if strcmpi('no', user_response), return; end
    iList = strcmp([path filename], listPaths);
    outputDir = userData.ML(iList).outputDirectory_;
    delete(userData.ML(iList));
    userData.ML(iList) = [];
else
    % Ask user where to select the output directory of the
    outputDir = uigetdir(path,'Select a directory to store the list analysis output');
    if isequal(outputDir,0), return; end
end

try
    ML = MovieList(userData.MD, outputDir);
    ML.setPath(path);
    ML.setFilename(filename);
    ML.sanityCheck;
catch ME
    msg = sprintf('%s\n\nMovie list is not saved.', ME.message);
    errordlg(msg, 'Movie List Error', 'modal')
    return
end
userData.ML = horzcat(userData.ML, ML);
set(handles.figure1,'UserData',userData);
refreshDisplay(hObject, eventdata, handles)

% --------------------------------------------------------------------
function menu_tools_crop_Callback(hObject, eventdata, handles)

% Return if no movie 
props=get(handles.listbox_movie, {'String','Value'});
if isempty(props{1}), return; end

userData = get(handles.figure1, 'UserData');
if ishandle(userData.newFig), delete(userData.newFig); end
userData.newFig = cropMovieGUI(userData.MD(props{2}),'mainFig',handles.figure1);
set(handles.figure1,'UserData',userData);


% --------------------------------------------------------------------
function menu_tools_addROI_Callback(hObject, eventdata, handles)

% Return if no movie 
props=get(handles.listbox_movie, {'String','Value'});
if isempty(props{1}), return; end

userData = get(handles.figure1, 'UserData');
if ishandle(userData.newFig), delete(userData.newFig); end
userData.newFig = addMovieROIGUI(userData.MD(props{2}),'mainFig',handles.figure1);
set(handles.figure1,'UserData',userData);

% --- Executes on selection change in listbox_movie.
function refreshDisplay(hObject, eventdata, handles)

userData = get(handles.figure1,'UserData');

% Display Movie information
moviePaths = arrayfun(@getFullPath,userData.MD,'Unif',false);
nMovies= numel(userData.MD);
iMovie = get(handles.listbox_movie, 'Value');
if isempty(userData.MD), 
    iMovie=0; 
else
    iMovie=max(1,min(iMovie,nMovies));
end
set(handles.listbox_movie,'String',moviePaths,'Value',iMovie);
set(handles.text_movies, 'String', sprintf('%g/%g movie(s)',iMovie,nMovies))

% Display list information
listPaths = arrayfun(@getFullPath,userData.ML,'Unif',false);
nLists= numel(userData.ML);
iList = get(handles.listbox_movieList, 'Value');
if isempty(userData.ML), 
    iList=0; 
else
    iList=max(1,min(iList,nLists));
end
set(handles.listbox_movieList,'String',listPaths);
set(handles.text_movieList, 'String', sprintf('%g/%g movie list(s)',iList,nLists))


% --- Executes on button press in pushbutton_deletelist.
function pushbutton_deletelist_Callback(hObject, eventdata, handles)

userData = get(handles.figure1, 'Userdata');
if isempty(userData.MD), return;end

% Delete channel object
iList = get(handles.listbox_movie,'Value');
delete(userData.ML(iList));
userData.ML(iList) = [];

% Refresh listbox_channel
set(handles.figure1, 'Userdata', userData)
refreshDisplay(hObject,eventdata,handles);
guidata(hObject, handles);
