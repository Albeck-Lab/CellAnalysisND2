function [valcube] = ContourTrackND2p(sdata, sindex, tracksFinal, maxDiam, minD, minF, CFP, YFP, RFP, diagnostic)

% Dilate pixel size from nucleus to get cytosolic region
dilatesize=5;

%Default Values for Contour Filtering
maxDiameter=maxDiam;
maxNucArea=round(pi*maxDiameter^2/4);
minDiameter=minD;
minNucArea=round(pi*minDiameter^2/4);
minFormfactor=minF;

% Initialize diagnostic
if diagnostic==1
    vidObj = VideoWriter(['CDiagnostic1.avi']);           %Name
    open(vidObj);
    for f=1:length(tracksFinal)
        track=tracksFinal(f);
        tca=track.tracksCoordAmpCG;
        soe=track.seqOfEvents;
        xInd=1:8:length(tca);
        yInd=2:8:length(tca);
        startFrame=soe(1,1);
        timeRange=startFrame:(length(xInd)+startFrame-1);
        xCoord(f,timeRange)=tca(1,xInd);
        yCoord(f,timeRange)=tca(1,yInd);
    end
end

%Get track coordinates at time from tracksFinal in a Matrix: xC and yC
for i=1:length(tracksFinal)
    %Get track coordinates in a matrix from tracksFinal.trackCoordAmpCG
    for j=1:length(tracksFinal(i).tracksCoordAmpCG)/8 - 1
        start = tracksFinal(i).seqOfEvents(1);
        %get X coordinates from tracksfinal
        xC(j+start,i) = tracksFinal(i).tracksCoordAmpCG(1+8*j);
        %get Y coordinates from tracksfinal
        yC(j+start,i) = tracksFinal(i).tracksCoordAmpCG(2+8*j);
    end
end

%Convert 0s to NaNs for interpolation
xC(xC==0)=NaN;
yC(yC==0)=NaN;
xC2=xC(1:end,1:end);
yC2=yC(1:end,1:end);

% Find NaNs in X-coordinate matrix and interpolate
for i=1:size(xC,2)
    data=xC2(:,i);
    % If column of NaNs
    if isnan(max(data))==1
        xC(:,i)=NaN;
    else
        nanData = isnan(data);
        index = 1:numel(data);
        data2=data;
        % If only one value to interpolate
        if sum(~isnan(data2))==1
            xC(:,i)=data2;
            % Interpolate
        else
            data2(nanData) = interp1(index(~nanData), data(~nanData), index(nanData));
            xC(:,i)=data2;
        end
    end
end

% Interpolate Y Coordinates the same way as X coordinates.
for i=1:size(yC,2)
    data=yC2(:,i);
    % If column of NaNs
    if isnan(max(data))==1
        yC(:,i)=NaN;
    else
        nanData = isnan(data);
        index = 1:numel(data);
        data2=data;
        % If only one value to interpolate.
        if sum(~isnan(data2))==1
            yC(:,i)=data2;
            % Interpolate
        else
            data2(nanData) = interp1(index(~nanData), data(~nanData), index(nanData));
            yC(:,i)=data2;
        end
    end
end

% Initialize values cube for parrallel computing
valcube=zeros(size(tracksFinal,1), numel(sindex), 12);
slicecfp = [1:3:size(sdata,1)];
sliceyfp = [2:3:size(sdata,1)];
slicerfp = [3:3:size(sdata,1)];

% Loop through time getting intensities for each track
for t=1:length(sindex)
    sindex
    % Read images from nd2 file
    filenameCFP= cell2mat(sdata(slicecfp(t)));
    filenameYFP= cell2mat(sdata(sliceyfp(t)));
    filenameRFP= cell2mat(sdata(slicerfp(t)));
    im=filenameYFP;
    % Get x and y coordinates for current track from current time.
    currentspots=find(xC(sindex(t),:));
    currentX=floor(xC(sindex(t),currentspots));
    currentY=floor(yC(sindex(t),currentspots));
    
    [maxY maxX] = size(im);
    
    % Turn coords into indices.
    for j=1:length(currentX)
        if currentX(j)>maxX
            currentX(j)=NaN;
        end
    end
    for i=1:length(currentY)
        if currentY(i)>maxY
            currentY(i)=NaN;
        end
    end
    
    currentInd=sub2ind(size(im),currentY,currentX);
    filInd=currentInd(currentInd>0);										%Get filtered index for nonzero value tracks
    
    % Create contour matrix
    er=reshape(im,size(im,1)*size(im,2),1);                              	
    q1=double(quantile(er,0.05));                                           
    q9=double(quantile(er,0.98));
    thresholds=fliplr(linspace(q1,q9,30));
    ctm=zeros(size(im));
    k=1;
    
    % While loop to filter best contour slice for each coordinate. Start at
    % biggest contour and work way down. Break loop when first contour 
    % that satisfies conditions is met. This also filters out bad cells based
	% on parameters.
    
    while ~isempty(filInd) && k<=length(thresholds)
        tim=bwlabel(~(im>thresholds(k)));									% Label matrix of thresholds
        ct = imopen(tim,strel('disk',2));									% Minor background filtering
        currentLabels=ct(filInd);                                           % Find the labels of the regions in which current Indices fall
        ct=ismember(ct,currentLabels(currentLabels>1));                     % Remove regions in which no indices fall; ct is now binary
        ct=bwlabel(ct);                                                     % Convert ct back to a label matrix
        currentLabels=ct(filInd);                                           % Get the labels for the current Indices
        S = regionprops(ct,'EquivDiameter','Area','Perimeter');				% Get region information
        nucArea=cat(1,S.Area);												% Get Nucleus Area
        nucPerim=cat(1,S.Perimeter);										% Get Nucleus Perimeter
        nucEquiDiameter=cat(1,S.EquivDiameter);								% Get Nucleus Diameter
        nucFormfactor=4*pi*nucArea./(nucPerim.^2);							% Get Nucleus Circularity
        sizeScore = nucArea>minNucArea*.3 & nucArea<maxNucArea;				% Score the cell based on Diameter and Circularity
        shapeScore=nucFormfactor>minFormfactor;								% Score
        totalScore=sizeScore&shapeScore;									% Total score of each cell
        scorenz=find(totalScore);											% Scorenz is the position for each score
		
        % Keep contour for that satisfies condition for current coord.
        ctm(ismember(ct,scorenz))=1;
		
        % Remove found contours from list of indices to search for
        foundLabels=unique(ct(ismember(ct,scorenz)));
        filInd(ismember(currentLabels,foundLabels))=[];
        k=k+1;
    end
    
	% Find indices that passed the filtering above
    currentInd=sub2ind(size(im),currentY,currentX);
    goodInd=find(currentInd>0);
    ctml=bwlabel(ctm);
    nlabels=(ctml(currentInd(goodInd)));
    
	% Open the images to take intensities from
    CFPim = cell2mat(sdata(slicecfp(t)));
    YFPim = cell2mat(sdata(sliceyfp(t)));
    if RFP~=0
    RFPim = cell2mat(sdata(slicerfp(t)));
    end
    
	
    if diagnostic==1
        h=figure(1); clf; hold on;
        imshow(im,[]); hold on;
                for p=1:length(tracksFinal)
                    plot(xCoord(p,t),yCoord(p,t),'c.');
                    text(xCoord(p,t),yCoord(p,t),num2str(p),'Color','Green','FontSize',10);
                end
        set(0,'CurrentFigure',1);
        frame = getframe;
        writeVideo(vidObj,frame);
        
    end
	
    if diagnostic ==2
    figure(1); clf; hold on;
    imshow(im,[]); hold on;
    end
	
	% Loop to go through every good cell and get intensities to put into values cube (valcube)
    for n=1:length(goodInd)
        % Get intensity values for each region.
        if nlabels(n)~=0
            nmask=ctml==nlabels(n);
            nb=bwboundaries(nmask);
            nbound(t,goodInd(n))=nb(1);
            regOnly=ctml==nlabels(n);
            se=strel('disk',dilatesize);
            cmask=imdilate(regOnly,se);
            cmask(nmask)=0;
            cb=bwboundaries(cmask);
            cbound(t,goodInd(n))=cb(1);
            % Get intensities for nuclear region
            valcube(goodInd(n),t,1)=mean(CFPim(nmask));
            valcube(goodInd(n),t,2)=mean(YFPim(nmask));
            if RFP~=0
            valcube(goodInd(n),t,3)=mean(RFPim(nmask));
            end
            %Get intensities for cyto region
            valcube(goodInd(n),t,4)=mean(CFPim(cmask));
            valcube(goodInd(n),t,5)=mean(YFPim(cmask));
            if RFP~=0
            valcube(goodInd(n),t,6)=mean(RFPim(cmask));
            end
            if diagnostic==1 | 2
                %Plot dilation
                mycellc=cb(size(cb,1),:);
                if isempty(mycellc{1})
                    continue
                else
                    dim=mycellc{1};
                    dim2 = cat(2, dim(:,1),dim(:,2));
                    hold on, plot(dim2(:,2),dim2(:,1),'r-');
                end
                %Plot nuclear bound
                mycelln=nb(size(nb,1),:);
                if isempty(mycelln{1})
                    continue
                else
                    dim=mycelln{1};
                    dim2 = cat(2, dim(:,1),dim(:,2));
                    hold on, plot(dim2(:,2),dim2(:,1),'g-');
                end
            end
        else
            valcube(goodInd(n),t,1)=NaN;
            valcube(goodInd(n),t,2)=NaN;
            valcube(goodInd(n),t,3)=NaN;
            valcube(goodInd(n),t,4)=NaN;
            valcube(goodInd(n),t,5)=NaN;
            valcube(goodInd(n),t,6)=NaN;
        end
    end
    
    
end
if diagnostic==1
    close(vidObj);
end

% Get C1/C2 intensity ratio for nuclear region
valcube(:,:,7)=(valcube(:,:,1))./(valcube(:,:,2));
% Get C1/C2 intensity for cyto region
valcube(:,:,8)=(valcube(:,:,4))./(valcube(:,:,5));
cbg=valcube(:,:,4)-CFP;
ybg=valcube(:,:,5)-YFP;
ratio=cbg./ybg;
filter=cbg>0;
ratio2=ratio.*filter;
valcube(:,:,9)=ratio2;
% Get C1/C3 intensity ratio for nuclear region
valcube(:,:,10)=(valcube(:,:,1))./(valcube(:,:,3));
% Get C1/C3 intensity for cyto region
if RFP~=0
valcube(:,:,11)=(valcube(:,:,4))./(valcube(:,:,6));
cbg=valcube(:,:,4)-CFP;
ybg=valcube(:,:,6)-RFP;
ratio3=cbg./ybg;
filter=cbg>0;
ratio4=ratio3.*filter;
valcube(:,:,12)=ratio4;
filenameCFP='test';
end
save(['data_xy' filenameCFP '.mat']);

