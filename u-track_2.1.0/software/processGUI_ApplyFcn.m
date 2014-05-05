function processGUI_ApplyFcn(hObject, eventdata, handles,funParams,varargin)
%processGUI_ApplyFcn is a callback called when setting concrete process GUIs
%
%
% Sebastien Besson May 2011 (last modified Oct 2011)
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
ip.addRequired('hObject',@ishandle);
ip.addRequired('eventdata',@(x) isstruct(x) || isempty(x));
ip.addRequired('handles',@isstruct);
ip.addRequired('funParams',@(x) isstruct(x) || isempty(x))
ip.addOptional('settingFcn',{},@iscell);
ip.parse(hObject,eventdata,handles,funParams,varargin{:});
settingFcn=ip.Results.settingFcn;

if get(handles.checkbox_applytoall, 'Value')
    confirmApplytoAll = questdlg(...
        ['You are about to copy the current process settings to all movies.'...
        ' Previous settings will be lost. Do you want to continue?'],...
        'Apply settings to all movies','Yes','No','Yes'); 
    if ~strcmp(confirmApplytoAll,'Yes'),
        set(handles.checkbox_applytoall,'Value',0);
        return
    end
end

% Get the main figure userData
userData = get(handles.figure1, 'UserData');
if isfield(userData,'MD'), field='MD'; else field = 'ML'; end

% Check if the current process is equal to the package process (to cover
% empty processes as well as new subclass processes)
if ~isequal(userData.crtPackage.processes_{userData.procID},userData.crtProc)
    
    if isempty(userData.crtPackage.processes_{userData.procID})
        % Create a new process and set it in the package
        userData.(field).addProcess(userData.crtProc);
        userData.crtPackage.setProcess(userData.procID,userData.crtProc);
    else
        userData.(field).replaceProcess(userData.crtPackage.processes_{userData.procID},userData.crtProc);
    end
       
end

 % Override the parameters with the GUI set-up ones
parseProcessParams(userData.crtProc,funParams);
 
% Refresh main screen
packageGUI_RefreshFcn(userData.handles_main,'refresh')

userData_main = get(userData.mainFig, 'UserData');

if get(handles.checkbox_applytoall, 'Value'),
    moviesId = setdiff(1:numel(userData_main.(field)),userData_main.id);
else
    moviesId=[];
end

% Apply setting to all movies
for i = moviesId
    
    % if process classes differ, create a new process with default parameters
    if ~strcmp(class(userData_main.package(i).processes_{userData.procID}),...
            class(userData.crtProc))
        newProcess = userData.procConstr(userData_main.(field)(i), ...
            userData_main.package(i).outputDirectory_);
        
        % if package process is empty, add new process and associate it
        if isempty(userData_main.package(i).processes_{userData.procID})
            userData_main.(field)(i).addProcess(newProcess);
            userData_main.package(i).setProcess(userData.procID, newProcess);
        else
            userData_main.(field)(i).replaceProcess(userData_main.package(i).processes_{userData.procID},newProcess);
        end
    end
    
    % Override the parameters with the GUI defeined
    parseProcessParams(userData_main.package(i).processes_{userData.procID},...
        funParams);
    
    for j=1:numel(settingFcn)
        settingFcn{j}(userData_main.package(i).processes_{userData.procID});
    end
end

% Store the applytoall choice for this particular process
userData_main.applytoall(userData.procID)=get(handles.checkbox_applytoall,'Value');
% Save user data
set(userData.mainFig, 'UserData', userData_main)
set(handles.figure1, 'UserData', userData);
guidata(hObject,handles);
delete(handles.figure1);
end