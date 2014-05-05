function omeroSave(movieObject)
% OMEROSAVE uploads the output directory into OMERO as a file annotation
%
% omeroSave first create a zipped archive of all the content of the movie
% output directory. It then looks for a file annotation with the correct
% namespace attached to the Image. If existing, it uses the corresponding
% file else it create a new OriginalFile, saves the content of the zip file
% into this OriginalFile, uploads it to the server. Finally if a new file
% has been created, a new file annotation linking it to the image is
% created and uploaded to the server.
%
% omeroSave(movieObject)
%
% Input:
% 
%   movieObject - A MovieData object
%
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

% Sebastien Besson, Jun 2012 (last modified May 2013)

% To be replaced by omero.constants....
namespace = 'hms-tracking';
zipName = 'HMS-tracking.zip';

% Input check
ip=inputParser;
ip.addRequired('movieObject',@(x) isa(x, 'MovieObject') && x.isOmero() && x.canUpload());
ip.parse(movieObject);

% Zip output directory for attachment
zipPath = fileparts(movieObject.outputDirectory_);
zipFullPath = fullfile(zipPath,zipName);
zip(zipFullPath, movieObject.outputDirectory_)

% Create java io File
file = java.io.File(zipFullPath);
name = file.getName();
absolutePath = file.getAbsolutePath();
path = absolutePath.substring(0, absolutePath.length()-name.length());

% Load existing file annotations
if isa(movieObject, 'MovieData')
    fas = getImageFileAnnotations(movieObject.getOmeroSession(),...
        movieObject.getOmeroId(), 'include', namespace);
else
    fas = getDatasetFileAnnotations(movieObject.getOmeroSession(),...
        movieObject.getOmeroId(), 'include', namespace);
end

if ~isempty(fas)
    % Read file of first found file annotation
    originalFile = fas(1).getFile;
else
    originalFile = omero.model.OriginalFileI;
end
originalFile.setName(rstring(name));
originalFile.setPath(rstring(path));
originalFile.setSize(rlong(file.length()));
originalFile.setSha1(rstring(''));
originalFile.setMimetype(rstring('application/zip'));

% now we save the originalFile object
iUpdate = movieObject.getOmeroSession().getUpdateService();
originalFile = iUpdate.saveAndReturnObject(originalFile);

% Initialize the service to load the raw data
rawFileStore = movieObject.getOmeroSession().createRawFileStore();
rawFileStore.setFileId(originalFile.getId().getValue());

%  open file and read it

%code for small file.
fid = fopen(zipFullPath);
byteArray = fread(fid,[1, file.length()], 'uint8');
rawFileStore.write(byteArray, 0, file.length());
fclose(fid);

originalFile = rawFileStore.save();
% Important to close the service
rawFileStore.close();
% Delete zip file
delete(zipFullPath);

if isempty(fas)
    
    % Create link the image and the annotation
    if isa(movieObject, 'MovieData')
        image = getImages(movieObject.getOmeroSession(), movieObject.getOmeroId());
        assert(isa(image, 'omero.model.ImageI'));
        link = omero.model.ImageAnnotationLinkI;
        link.setParent(image)
    else
        dataset = getDatasets(movieObject.getOmeroSession(), movieObject.getOmeroId());
        assert(isa(dataset, 'omero.model.DatasetI'));
        link = omero.model.DatasetAnnotationLinkI;
        link.setParent(dataset)
    end
        
    % now we have an original File in DB and raw data uploaded.
    % We now need to link the Original file to the image using the File annotation object. That's the way to do it.
    fa = omero.model.FileAnnotationI;
    fa.setFile(originalFile);
    fa.setDescription(rstring('HMS tracking')); % The description set above e.g. PointsModel
    fa.setNs(rstring(namespace)) % The name space you have set to identify the file annotation.
    fa = iUpdate.saveAndReturnObject(fa); % save the file annotation
  
    % Add file annotation to the link and save it
    link.setChild(fa);
    iUpdate.saveAndReturnObject(link);
end
