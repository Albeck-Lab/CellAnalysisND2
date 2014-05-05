classdef  MovieObject < hgsetget
    % Abstract interface defining the analyis tools for movie objects
    % (movies, movie lists...)
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
    
    % Sebastien Besson, Jan 2012
    
    properties (SetAccess = protected)
        createTime_             % Object creation time
        processes_ = {};        % Cell array of process objects
        packages_ = {};         % Cell array of process packaged
    end
    
    properties
        outputDirectory_  ='';      % Default output directory for all processes
        notes_                  % User's notes
        
        % For OMERO objects
        omeroId_
        omeroSave_ = false
    end
    
    properties (Transient =true)
        omeroSession_
    end
    
    methods
        %% Set/get methods
        function set.outputDirectory_(obj, path)
            % Set the ouput
            endingFilesepToken = [regexptranslate('escape',filesep) '$'];
            path = regexprep(path,endingFilesepToken,'');
            obj.checkPropertyValue('outputDirectory_',path);
            obj.outputDirectory_=path;
        end
        
        function checkPropertyValue(obj,property, value)
            % Check if a property/value pair can be set up
            
            % Test if the property is unchanged
            if isequal(obj.(property),value), return; end
            
            propName = regexprep(regexprep(property,'(_\>)',''),'([A-Z])',' ${lower($1)}');
            % Test if the property is writable
            assert(obj.checkProperty(property),'lccb:set:readonly',...
                ['The ' propName ' has been set previously and cannot be changed!']);
            
            % Test if the supplied value is valid
            assert(obj.checkValue(property,value),'lccb:set:invalid',...
                ['The supplied ' propName ' is invalid!']);
        end
        
        function status = checkProperty(obj,property)
            % Returns true/false if the non-empty property is writable
            status = isempty(obj.(property));
            if status, return; end
            
            % Allow user to rewrite on some properties (paths, outputDirectory, notes)
            switch property
                case {'notes_'};
                    status = true;
                case {'outputDirectory_',obj.getPathProperty,obj.getFilenameProperty};
                    stack = dbstack;
                    if any(cellfun(@(x)strcmp(x,[class(obj) '.sanityCheck']),{stack.name})),
                        status  = true;
                    end
            end
        end
        
        function set.notes_(obj, value)
            obj.checkPropertyValue('notes_',value);
            obj.notes_=value;
        end
        
        function value = getPath(obj)
            value = obj.(obj.getPathProperty);
        end
        
        function setPath(obj, value)
            obj.(obj.getPathProperty) = value;
        end
        
        function value = getFilename(obj)
            value = obj.(obj.getFilenameProperty);
        end
        
        function setFilename(obj, value)
            obj.(obj.getFilenameProperty) = value;
        end
        
        function fullPath = getFullPath(obj, askUser)
            % Return full path of the movie object
            
            if nargin < 2, askUser = true; end
            hasEmptyComponent = isempty(obj.getPath) || isempty(obj.getFilename);
            hasDisplay = feature('ShowFigureWindows');
            
            if any(hasEmptyComponent) && askUser && hasDisplay
                if ~isempty(obj.getPath),
                    defaultDir = obj.getPath;
                elseif ~isempty(obj.outputDirectory_)
                    defaultDir = obj.outputDirectory_;
                else
                    defaultDir = pwd;
                end
                
                % Open a dialog box asking where to save the movie object
                movieClass = class(obj);
                objName = regexprep(movieClass,'([A-Z])',' ${lower($1)}');
                defaultName = regexprep(movieClass,'(^[A-Z])','${lower($1)}');
                [filename,path] = uiputfile('*.mat',['Find a place to save your' objName],...
                    [defaultDir filesep defaultName '.mat']);
                
                if ~any([filename,path]),
                    fullPath=[];
                else
                    fullPath = [path, filename];
                    % Set new path and filename
                    obj.setPath(path);
                    obj.setFilename(filename);
                end
            else
                if all(hasEmptyComponent),
                    fullPath = '';
                else
                    fullPath = fullfile(obj.getPath(), obj.getFilename());
                end
            end
            
        end
        %% Functions to manipulate process object array
        function addProcess(obj, newprocess)
            % Add new process in process list
            assert(isa(newprocess,'Process'));
            obj.processes_ = horzcat(obj.processes_, {newprocess});
        end
        
        function proc = getProcess(obj, i)
            assert(isscalar(i) && ismember(i,1:numel(obj.processes_)));
            proc = obj.processes_{i};
        end
        
        
        function deleteProcess(obj, process)
            % Delete given process object in process list
            %
            % Input:
            %        process - Process object or index of process to be
            %                  deleted in movie data's process list
            
            % Check input
            if isa(process, 'Process')
                pid = obj.getProcessIndex(process,1,Inf,false);
                assert(~isempty(pid),'The given process is not in current movie processes list.')
                assert(length(pid)==1,'More than one process of this type exists in movie processes list.')
            elseif isscalar(process) && ismember(process,1:numel(obj.processes_))
                pid = process;
            else
                error('Please provide a Process object or a valid process index of movie data processes list.')
            end
            
            % Check process validity
            process = obj.processes_{pid};
            isValid = ~isempty(process) && process.isvalid;
            
            if isValid
                % Unassociate process from parent packages
                [packageID procID] = process.getPackage();
                for i=1:numel(packageID)
                    obj.packages_{packageID(i)}.setProcess(procID(i),[]);
                end
            end
            
            if isValid && isa(process.owner_, 'MovieData')
                % Remove process from list for owner and descendants
                for movie = [process.owner_ process.owner_.getDescendants()]
                    id = find(cellfun(@(x) isequal(x,process), movie.processes_),1);
                    if ~isempty(id), movie.processes_(id) = [ ]; end
                end
            else
                obj.processes_(pid) = [ ];
            end
            
            % Delete process object
            if isValid, delete(process); end
        end
        
        function replaceProcess(obj, pid, newprocess)
            % Replace process object by another in the analysis list
            
            % Input check
            ip=inputParser;
            ip.addRequired('pid',@(x) isscalar(x) && ismember(x,1:numel(obj.processes_)) || isa(x,'Process'));
            ip.addRequired('newprocess',@(x) isa(x,'Process'));
            ip.parse(pid, newprocess);
            
            % Retrieve process index if input is of process type
            if isa(pid, 'Process')
                pid = find(cellfun(@(x)(isequal(x,pid)),obj.processes_));
                assert(isscalar(pid))
            end
            
            [packageID procID] = obj.processes_{pid}.getPackage;
            
            % Check new process is compatible with parent packages
            if ~isempty(packageID)
                for i=1:numel(packageID)
                    isValid = isa(newprocess,...
                        obj.packages_{packageID(i)}.getProcessClassNames{procID(i)});
                    assert(isValid, 'Package class compatibility prevents process process replacement');
                end
            end
            
            % Delete old process and replace it by the new one
            oldprocess = obj.processes_{pid};
            if isa(oldprocess.owner_, 'MovieData')
                % Remove process from list for owner and descendants
                for movie = [oldprocess.owner_ oldprocess.owner_.getDescendants()]
                    id = find(cellfun(@(x) isequal(x, oldprocess), movie.processes_),1);
                    if ~isempty(id), movie.processes_{id} = newprocess; end
                end
            else
                obj.processes_{pid} = newprocess;
            end
            delete(oldprocess);
            
            % Associate new process in parent packages
            if ~isempty(packageID),
                for i=1:numel(packageID)
                    obj.packages_{packageID(i)}.setProcess(procID(i),newprocess);
                end
            end
        end
        
        function iProc = getProcessIndex(obj, type, varargin)
            if isa(type, 'Process'), type = class(type); end
            iProc = getIndex(obj.processes_, type, varargin{:});
        end
        
        %% Functions to manipulate package object array
        function addPackage(obj, newpackage)
            % Add package object to the package list
            assert(isa(newpackage,'Package'));
            obj.packages_ = horzcat(obj.packages_ , {newpackage});
        end
        
        function package = getPackage(obj, i)
            assert(isscalar(i) && ismember(i,1:numel(obj.packages_)));
            package = obj.packages_{i};
        end
        
        
        function deletePackage(obj, package)
            % Remove package object from the package list
            
            % Check input
            if isa(package, 'Package')
                pid = find(cellfun(@(x)isequal(x, package), obj.packages_));
                assert(~isempty(pid),'The given package is not in current movie packages list.')
                assert(length(pid)==1,'More than one package of this type exists in movie packages list.')
            elseif isscalar(package) && ismember(package,1:numel(obj.packages_))
                pid = package;
            else
                error('Please provide a Package object or a valid package index of movie data processes list.')
            end
            
            % Check package validity
            package = obj.packages_{pid};
            isValid = ~isempty(package) && package.isvalid;
            
            if isValid && isa(package.owner_, 'MovieData')
                % Remove package from list for owner and descendants
                for movie = [package.owner_ package.owner_.getDescendants()]
                    id = find(cellfun(@(x) isequal(x,package), movie.packages_),1);
                    if ~isempty(id), movie.packages_(id) = [ ]; end
                end
            else
                obj.packages_(pid) = [ ];
            end
            
            % Delete package object
            if isValid, delete(package); end
        end
        
        function iPackage = getPackageIndex(obj, type, varargin)
            if isa(type, 'Package'), type = class(type); end
            iPackage = getIndex(obj.packages_, type, varargin{:});
        end
        %% Miscellaneous functions
        function askUser = sanityCheck(obj, path, filename,askUser)
            % Check sanity of movie object
            %
            % Check if the path and filename stored in the movie object are
            % the same as the input if any. If they differ, call the
            % movie object relocation routine. Use a dialog interface to ask
            % for relocation if askUser is set as true and return askUser.
            
            if nargin < 4, askUser = true; end
            if nargin > 1 && ~isempty(path)
                % Remove ending file separators from paths
                endingFilesepToken = [regexptranslate('escape',filesep) '$'];
                oldPath = regexprep(obj.getPath(),endingFilesepToken,'');
                newPath = regexprep(path,endingFilesepToken,'');
                
                % If different path
                if ~strcmp(oldPath, newPath)
                    confirmRelocate = 'Yes to all';
                    if askUser
                        if isa(obj,'MovieData')
                            type='movie';
                            components='channels';
                        elseif isa(obj,'MovieList')
                            type='movie list';
                            components='movies';
                        else
                            error('Non supported movie object');
                        end
                        relocateMsg=sprintf(['The %s and its analysis will be relocated from \n%s to \n%s.\n'...
                            'Should I relocate its %s as well?'],type,oldPath,newPath,components);
                        confirmRelocate = questdlg(relocateMsg,['Relocation - ' type],'Yes to all','Yes','No','Yes');
                    end
                    
                    full = ~strcmp(confirmRelocate,'No');
                    askUser = ~strcmp(confirmRelocate,'Yes to all');
                    % Get old and new relocation directories
                    [oldRootDir newRootDir]=getRelocationDirs(oldPath,newPath);
                    oldRootDir = regexprep(oldRootDir,endingFilesepToken,'');
                    newRootDir = regexprep(newRootDir,endingFilesepToken,'');
                    
                    % Relocate the object
                    fprintf(1,'Relocating analysis from %s to %s\n',oldRootDir,newRootDir);
                    obj.relocate(oldRootDir,newRootDir,full);
                end
            end
            if nargin > 2 && ~isempty(filename), obj.setFilename(filename); end
            
            if isempty(obj.outputDirectory_), warning('lccb:MovieObject:sanityCheck',...
                    'Empty output directory!'); end
        end
        
        function relocate(obj,oldRootDir,newRootDir)
            % Relocate all analysis paths of the movie object
            %
            % The relocate method automatically relocates the output directory,
            % as well as the paths in each process and package of the movie
            % assuming the internal architecture of the  project is conserved.
            
            % Relocate output directory and set the ne movie path
            obj.outputDirectory_=relocatePath(obj.outputDirectory_,oldRootDir,newRootDir);
            obj.setPath(relocatePath(obj.getPath,oldRootDir,newRootDir));
            
            % Relocate the processes
            for i=1:numel(obj.processes_), obj.processes_{i}.relocate(oldRootDir,newRootDir); end
            
            % Relocate the packages
            for i=1:numel(obj.packages_), obj.packages_{i}.relocate(oldRootDir,newRootDir); end
        end
        
        function reset(obj)
            % Reset the analysis of the movie object
            obj.processes_={};
            obj.packages_={};
        end
        
        %% OMERO functions
        function status = isOmero(obj)
            status = ~isempty(obj.omeroId_);
        end
        
        function setOmeroSession(obj,session)
            obj.omeroSession_ = session;
        end
        
        function session = getOmeroSession(obj)
            session = obj.omeroSession_;
        end
        
        function setOmeroSave(obj, status)
            obj.omeroSave_ = status;
        end
        
        function id = getOmeroId(obj)
            id = obj.omeroId_;
        end
        
        function setOmeroId(obj, id)
            obj.checkPropertyValue('omeroId_', id);
            obj.omeroId_ = id;
        end
        
        function status = canUpload(obj)
            status = obj.omeroSave_ && ~isempty(obj.getOmeroSession());
        end
        
    end
    
    methods(Static)
        function obj = load(moviepath,varargin)
            % Load a movie object from a path
            
            if MovieObject.isOmeroSession(moviepath),
                obj = getOmeroMovies(moviepath, varargin{:});
                return;
            end
            
            % Check the path is a valid file
            assert(~isempty(ls(moviepath)),'lccb:movieObject:load', 'File does not exist.');
            
            % Retrieve the absolute path
            [~,f]= fileattrib(moviepath);
            moviepath=f.Name;
            
            if strcmpi(moviepath(end-3:end),'.mat')
                % Import movie object from MAT file
                try
                    % List variables in the path
                    vars = whos('-file',moviepath);
                catch whosException
                    ME = MException('lccb:movieObject:load', 'Fail to open file. Make sure it is a MAT file.');
                    ME = ME.addCause(whosException);
                    throw(ME);
                end
                
                % Check if a single movie object is in the variables
                isMovie = cellfun(@(x) any(strcmp(superclasses(x),'MovieObject')),{vars.class});
                assert(any(isMovie),'lccb:movieObject:load', ...
                    'No movie object is found in selected MAT file.');
                assert(sum(isMovie)==1,'lccb:movieObject:load', ...
                    'Multiple movie objects are found in selected MAT file.');
                
                % Load movie object
                data = load(moviepath,'-mat',vars(isMovie).name);
                obj= data.(vars(isMovie).name);
                
                % Perform sanityCheck using the input path
                [moviePath,movieName,movieExt]=fileparts(moviepath);
                if nargin>1 &&  MovieObject.isOmeroSession(varargin{1}),
                    obj.setOmeroSession(varargin{1});
                    obj.sanityCheck(moviePath,[movieName movieExt], varargin{2:end});
                else
                    obj.sanityCheck(moviePath,[movieName movieExt], varargin{:});
                end
            else
                % Assume proprietary file - use Bioformats library
                obj=bfImport(moviepath,varargin{:});
            end
        end
        
        function validator = getPropertyValidator(property)
            validator=[];
            if ismember(property,{'outputDirectory_','notes_'})
                validator=@ischar;
            elseif strcmp(property, 'omeroId_')
                validator = @isposint;
            end
        end
        
        function status = isOmeroSession(session)
            status = isa(session, 'omero.api.ServiceFactoryPrxHelper');
        end
        
    end
    methods (Static,Abstract)
        getPathProperty()
        getFilenameProperty()
    end
end

function iProc = getIndex(list, type, varargin)
% Find the index of a object of given class

% Input check
ip = inputParser;
ip.addRequired('list',@iscell);
ip.addRequired('type',@ischar);
ip.addOptional('nDesired',1,@isscalar);
ip.addOptional('askUser',true,@isscalar);
ip.parse(list, type, varargin{:});
nDesired = ip.Results.nDesired;
askUser = ip.Results.askUser;


iProc = find(cellfun(@(x) isa(x,type), list));
nProc = numel(iProc);

%If there are only nDesired or less processes found, return
if nProc <= nDesired, return; end

% If more than nDesired processes
if askUser
    isMultiple = nDesired > 1;
    names = cellfun(@(x) (x.getName()), list(iProc), 'UniformOutput', false);
    iSelected = listdlg('ListString', names,...
        'SelectionMode', isMultiple, 'ListSize', [400,400],...
        'PromptString', ['Select the desired ' type ':']);
    iProc = iProc(iSelected);
    assert(~isempty(iProc), 'You must select a process to continue!');
else
    warning('lccb:process', ['More than ' num2str(nDesired) ' objects '...
        'of class ' type ' were found! Returning most recent!'])
    iProc = iProc(end:-1:(end-nDesired+1));
end
end