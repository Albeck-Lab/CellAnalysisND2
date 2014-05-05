classdef  MovieData < MovieObject
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
    
    properties (SetAccess = protected)
        channels_               % Channel object array
        nFrames_                % Number of frames
        imSize_                 % Image size 1x2 array[height width]
        rois_ =  MovieData.empty(1,0);
        parent_ =  MovieData.empty(1,0);
    end
    
    properties
        roiMaskPath_            % The path where the roi mask is stored
        movieDataPath_          % The path where the movie data is saved
        movieDataFileName_      % The name under which the movie data is saved
        pixelSize_              % Pixel size in the object domain (nm)
        timeInterval_           % Time interval (s)
        numAperture_            % Lens numerical aperture
        camBitdepth_            % Camera Bit-depth
                
        % ---- Un-used params ----
        eventTimes_             % Time of movie events
        magnification_
        binning_
        
        % For Bio-Formats objects
        bfSeries_
    end
    
    properties (Transient =true)
        reader
    end

    methods
        %% Constructor
        function obj = MovieData(channels,outputDirectory,varargin)
            % Constructor of the MovieData object
            %
            % INPUT
            %    channels - a Channel object or an array of Channels
            %    outputDirectory - a string containing the output directory
            %    OPTIONAL - a set of options under the property/key format
            
            if nargin>0
                % Required input fields
                obj.channels_ = channels;
                obj.outputDirectory_ = outputDirectory;
                
                % Construct the Channel object
                nVarargin = numel(varargin);
                if mod(nVarargin,2)==0
                    for i=1 : 2 : nVarargin-1
                        obj.(varargin{i}) = varargin{i+1};
                    end
                end
                obj.createTime_ = clock;
            end
        end
        

        %% MovieData specific set/get methods
        function set.movieDataPath_(obj, path)
            % Format the path
            endingFilesepToken = [regexptranslate('escape',filesep) '$'];
            path = regexprep(path,endingFilesepToken,'');
            obj.checkPropertyValue('movieDataPath_',path);
            obj.movieDataPath_=path;
        end
        
        function set.movieDataFileName_(obj, filename)
            obj.checkPropertyValue('movieDataFileName_',filename);
            obj.movieDataFileName_=filename;
        end
        
        function set.channels_(obj, value)
            obj.checkPropertyValue('channels_',value);
            obj.channels_=value;
        end
        
        function set.pixelSize_ (obj, value)
            obj.checkPropertyValue('pixelSize_',value);
            obj.pixelSize_=value;
        end
        
        function set.timeInterval_ (obj, value)
            obj.checkPropertyValue('timeInterval_',value);
            obj.timeInterval_=value;
        end
        
        function set.numAperture_ (obj, value)
            obj.checkPropertyValue('numAperture_',value);
            obj.numAperture_=value;
        end
        
        function set.camBitdepth_ (obj, value)
            obj.checkPropertyValue('camBitdepth_',value);
            obj.camBitdepth_=value;
        end
        
        function set.magnification_ (obj, value)
            obj.checkPropertyValue('magnification_',value);
            obj.magnification_=value;
        end
        function set.binning_ (obj, value)
            obj.checkPropertyValue('binning_',value);
            obj.binning_=value;
        end

        function fileNames = getImageFileNames(obj,iChan)
            % Retrieve the names of the images in a specific channel
            
            if nargin < 2 || isempty(iChan), iChan = 1:numel(obj.channels_); end
            assert(all(ismember(iChan,1:numel(obj.channels_))),...
                'Invalid channel numbers! Must be positive integers less than the number of image channels!');
            
            % Delegates the method to the classes
            fileNames = arrayfun(@getImageFileNames,obj.channels_(iChan),...
                'UniformOutput',false);
            if ~all(cellfun(@numel,fileNames) == obj.nFrames_)
                error('Incorrect number of images found in one or more channels!')
            end
        end
        
        function channel = getChannel(obj, i)
            assert(isscalar(i) && ismember(i, 1:numel(obj.channels_)));
            channel = obj.channels_(i);
        end
        
        function chanPaths = getChannelPaths(obj,iChan)
            %Returns the directories for the selected channels
            if nargin < 2 || isempty(iChan), iChan = 1:numel(obj.channels_); end
            assert(all(ismember(iChan,1:numel(obj.channels_))),...
                'Invalid channel index specified! Cannot return path!');
            
            chanPaths = obj.getReader().getChannelNames(iChan);
        end  
        
        %% ROI methods
        function roiMovie = addROI(obj,roiMaskPath,outputDirectory,varargin)
            % Create a new object using the movie's channels
            roiMovie = MovieData(obj.channels_,outputDirectory,varargin{:});
            copyfields = {'pixelSize_','timeInterval_','numAperture_',...
                'camBitdepth_','processes_','packages_','nFrames_','imSize_'};
            set(roiMovie,copyfields,get(obj,copyfields));
            
            % Set toi properties
            roiMovie.roiMaskPath_=roiMaskPath;
            roiMovie.parent_=obj;
            obj.rois_(end+1)=roiMovie;
        end
        
        function roi = getROI(obj, i)
            assert(isscalar(i) && ismember(i, 1:numel(obj.rois_)));
            roi = obj.rois_(i);
        end
        
        function deleteROI(obj, index, askUser)
            assert(all(ismember(index,1:numel(obj.rois_))));
            if nargin < 3, askUser = true; end
            paths = arrayfun(@(x) getFullPath(x, askUser), obj.rois_(index),'Unif',false);
            
            delete(obj.rois_(index)); % Delete objects
            % Save deleted object (to prevent future loading)
            for i=find(~cellfun(@isempty,paths))
               MD=obj.rois_(i); %#ok<NASGU>
               save(paths{i},'MD');
            end
            obj.rois_(index)=[]; % Remove from the list
        end
        
        function roiMask=getROIMask(obj)
            % If no roiMaskPath_, the whole mask is the region of interest
            if isempty(obj.roiMaskPath_)
                roiMask = true([obj.imSize_ obj.nFrames_]);
                return; 
            end
           
            % Support single tif files for now - should be extended to
            % polygons, series of masks and other ROI objects
            assert(exist(obj.roiMaskPath_,'file')==2)
            if strcmpi(obj.roiMaskPath_(end-2:end),'tif'),
                roiMask = logical(imread(obj.roiMaskPath_));
                assert(isequal(size(roiMask(:,:,1)), obj.imSize_));
                if size(roiMask,3)==1, roiMask=repmat(roiMask,[1 1 obj.nFrames_]); end
                assert(size(roiMask,3) == obj.nFrames_);
            end
        end
        
        function parent=getAncestor(obj)
            % Get oldest common ancestor of the movie
            if isempty(obj.parent_), parent=obj; else parent=obj.parent_.getAncestor(); end
        end
        
        function descendants=getDescendants(obj)
            % List all descendants of the movie
            nRois = numel(obj.rois_);
            roiDescendants=cell(nRois,1);
%             for i=1:nRois, roiDescendants{i} = obj.rois_(i).getDescendants; end
            descendants = horzcat(obj.rois_,roiDescendants{:});
        end
             
        %% Sanitycheck/relocation
        function sanityCheck(obj,varargin)
            % Check the sanity of the MovieData objects
            %
            % First call the superclass sanityCheck. Then call the Channel
            % objects sanityCheck, check image properties and set the 
            % nFrames_ and imSize_ properties. 
            % Save the movie to disk if run successfully
            
            % Call the superclass sanityCheck
            if nargin>1, sanityCheck@MovieObject(obj,varargin{:}); end
            
            % Initialize channels dimensions
            width = zeros(1, length(obj.channels_));
            height = zeros(1, length(obj.channels_));
            nFrames = zeros(1, length(obj.channels_));
            
            % Call subcomponents sanityCheck
            disp('Checking channels');
            for i = 1: length(obj.channels_)
                [width(i) height(i) nFrames(i)] = obj.channels_(i).sanityCheck(obj);
            end
            
            assert(max(nFrames) == min(nFrames), 'MovieData:sanityCheck:nFrames',...
                'Different number of frames are detected in different channels. Please make sure all channels have same number of frames.')
            assert(max(width)==min(width) && max(height)==min(height), ...
                'MovieData:sanityCheck:imSize',...
                'Image sizes are inconsistent in different channels.\n\n')
            
            % Define imSize_ and nFrames_;
            if ~isempty(obj.nFrames_)
                assert(obj.nFrames_ == nFrames(1), 'MovieData:sanityCheck:nFrames',...
                    'Record shows the number of frames has changed in this movie.')
            else
                obj.nFrames_ = nFrames(1);
            end
            if ~isempty(obj.imSize_)
                assert(obj.imSize_(2) == width(1) && obj.imSize_(1) ==height(1),...
                    'MovieData:sanityCheck:imSize',...
                    'Record shows image size has changed in this movie.')
            else
                obj.imSize_ = [height(1) width(1)];
            end

            % Fix roi/parent initialization
            if isempty(obj.rois_), obj.rois_=MovieData.empty(1,0); end
            if isempty(obj.parent_), obj.parent_=MovieData.empty(1,0); end
            
            disp('Saving movie');            
            obj.save();
        end
        
        function relocate(obj,oldRootDir,newRootDir,full)
            
            % Relocate movie and rois analysis
            for movie = [obj.getAncestor() obj.getAncestor().getDescendants()]
                relocate@MovieObject(movie, oldRootDir, newRootDir);
                if ~isempty(movie.roiMaskPath_)
                    movie.roiMaskPath_ = relocatePath(movie.roiMaskPath_,...
                        oldRootDir,newRootDir);
                end
            end
            
            if nargin<3 || ~full || obj.isOmero(),
                return 
            end
            
            % Check that channels paths start with oldRootDir           
            channelPaths = arrayfun(@(x) x.channelPath_, obj.channels_,...
                'Unif', false);
            status = cellfun(@(x) ~isempty(regexp(x,['^' regexptranslate('escape',oldRootDir) '*'],...
                'once')),channelPaths);
            if ~all(status)
                relocateMsg=sprintf(['The movie channels can not be automatically relocated.\n'...
                    'Do you want to manually relocate channel %g:\n %s?'],1,channelPaths{1});
                confirmRelocate = questdlg(relocateMsg,'Relocation - channels','Yes','No','Yes');
                if ~strcmp(confirmRelocate,'Yes'), return; end
                newChannelPath = uigetdir(newRootDir);
                if isequal(newChannelPath,0), return; end
                [oldRootDir newRootDir]=getRelocationDirs(channelPaths{1},newChannelPath);
            end
            
            % Relocate the movie channels
            fprintf(1,'Relocating channels from %s to %s\n',oldRootDir,newRootDir);
            for i=1:numel(obj.channels_),
                obj.channels_(i).relocate(oldRootDir,newRootDir);
            end
        end
        
        function setFig = edit(obj)
            setFig = movieDataGUI(obj);
        end
        
        function save(obj,varargin)
            
            % Create list of movies to save simultaneously
            ancestor = obj.getAncestor();
            allMovies = [ancestor ancestor.getDescendants()];
            
            % Check path validity for all movies in the tree
            checkPath = @(x) assert(~isempty(x.getFullPath()), 'Invalid path');
            arrayfun(checkPath, allMovies);
            
            % Backup existing file and save each movie in the list
            for MD = allMovies
                fullPath = MD.getFullPath();
                if exist(fullPath,'file')
                    movefile(fullPath,[fullPath(1:end-3) 'old'],'f');
                end
                save(fullPath, 'MD');
            end
            
            % Save to OMERO if OMERO object
            if ancestor.isOmero() && ancestor.canUpload(),
                omeroSave(ancestor);
            end
        end
        
        function input = getSampledOutput(obj,index)
            % Read process names from parameters
            samplingProcesses = {'ProtrusionSamplingProcess','WindowSamplingProcess'};
            validProc =cellfun(@(x) ~isempty(obj.getProcessIndex(x,1)),samplingProcesses);
            procNames=samplingProcesses(validProc);
            nProc = numel(procNames);
            
            % Initialize process status
            procIndex = zeros(nProc,1);
            outputList = cell(nProc,1);
            isMovieProc = false(nProc,1);
            procOutput = cell(nProc,1);
            
                
            % For each input process check the output validity
            for i=1:nProc
                procIndex(i) =obj.getProcessIndex(procNames{i},1);
                proc =obj.processes_{procIndex(i)};
                outputList{i} = proc.getDrawableOutput;
                isMovieProc(i) = strcmp('movieGraph',outputList{i}(1).type);
                procOutput{i} = proc.checkChannelOutput;
                assert(any(procOutput{i}(:)),[proc.getName ' has no valid output !' ...
                    'Please apply ' proc.getName ' before running correlation!']);             
            end
            
            % Push all input into a structre
            nInput = sum(cellfun(@(x)sum(x(:)),procOutput));
            if nInput==0, input=[]; return; end
            input(nInput,1)=struct(); % Initialize time-series input structure
            iInput=0;
            for iProc=1:nProc
                for iOutput = 1:size(procOutput{iProc},1)
                    if isMovieProc(iProc)
                        % Add processIndex and output variable/name
                        iInput=iInput+1;
                        input(iInput).processIndex = procIndex(iProc);
                        input(iInput).var = outputList{iProc}(iOutput).var;
                        input(iInput).channelIndex = [];
                        input(iInput).name = regexprep(outputList{iProc}(iOutput).name,' map','');
                    else
                        % Loop over channels with valid output
                        for iChan=find(procOutput{iProc}(iOutput,:))
                            iInput=iInput+1;
                            input(iInput).processIndex = procIndex(iProc);
                            input(iInput).var = outputList{iProc}(iOutput).var;
                            input(iInput).outputIndex = iOutput;
                            input(iInput).channelIndex = iChan;
                            input(iInput).name = [regexprep(outputList{iProc}(iOutput).name,' map','') ' channel '...
                                num2str(iChan)];
                        end
                    end
                end
            end
            if nargin>1
                assert(all(ismember(index,1:numel(input))));
                input=input(index);
            end
        end  
        
        %% Bio-Formats functions
        
        function setSeries(obj, iSeries)
            assert(obj.isBF(), 'Object must be using the Bio-Formats library');
            assert(isempty(obj.bfSeries_), 'The series number has already been set');
            obj.bfSeries_ = iSeries;
        end
        
        function iSeries = getSeries(obj)
            if isempty(obj.bfSeries_),
                iSeries = 0;
            else
                iSeries = obj.bfSeries_;
            end
        end
        
        function r = getReader(obj)
            if ~isempty(obj.reader),
                r = obj.reader;
                return
            end
            
            if obj.isBF()
                r = BioFormatsReader(obj.channels_(1).channelPath_, obj.bfSeries_);
            elseif obj.isOmero()
                r = OmeroReader(obj.getOmeroId(), obj.getOmeroSession());
            else
                r = TiffSeriesReader({obj.channels_.channelPath_});
            end
            obj.reader = r;
        end
        
        function status = isBF(obj)
            channelPaths = arrayfun(@(x) x.channelPath_, obj.channels_, 'Unif', false);
            channelPaths = unique(channelPaths);
            status = numel(channelPaths) == 1 && ...
                exist(channelPaths{1}, 'file') ==2;
        end
        
        function delete(obj)
            if ~isempty(obj.reader),
                obj.reader.delete()
            end
        end

    end
    methods(Static)        
        function status=checkValue(property,value)
           % Return true/false if the value for a given property is valid
            
           % Parse input
           ip = inputParser;
           ip.addRequired('property',@(x) ischar(x) || iscell(x));
           ip.parse(property);
           if iscell(property)
               ip.addRequired('value',@(x) iscell(x)&&isequal(size(x),size(property)));
               ip.parse(property,value);
               status=cellfun(@(x,y) MovieData.checkValue(x,y),property,value);
               return
           end
           
           % Get validator for single property
           validator=MovieData.getPropertyValidator(property);
           propName = regexprep(regexprep(property,'(_\>)',''),'([A-Z])',' ${lower($1)}');
           assert(~isempty(validator),['No validator defined for property ' propName]);
           
           % Return result of validation
           status = isempty(value) || validator(value);
        end
        
        function validator = getPropertyValidator(property) 
            validator = getPropertyValidator@MovieObject(property);
            if ~isempty(validator), return; end
            switch property
                case {'channels_'}
                    validator=@(x) isa(x,'Channel');
                case {'movieDataPath_','movieDataFileName_'}
                    validator=@ischar;
                case {'pixelSize_', 'timeInterval_','numAperture_','magnification_','binning_'}
                    validator=@(x) all(isnumeric(x)) && all(x>0);
                case {'camBitdepth_'}
                    validator=@(x) isscalar(x) && x>0 && ~mod(x, 2);
                otherwise
                    validator=[];
            end
        end
        
        function propName = getPathProperty()
            propName = 'movieDataPath_';
        end
        function propName = getFilenameProperty()
            propName = 'movieDataFileName_';
        end
    end
end