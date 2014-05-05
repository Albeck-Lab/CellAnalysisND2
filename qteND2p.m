function [movieInfo]=qteND2p(slice,slices,trackChannel,maxDiam, minD, minF, diagnostic)

%% Get parameters for Nuclei Detection
maxDiameter=maxDiam;
maxNucArea=round(pi*maxDiameter^2/4);
minDiameter=minD;
minNucArea=round(pi*minDiameter^2/4);
minFormfactor=minF;
hy = fspecial('sobel');
hx = hy';

% Initialize partitions for parallel computing
slicetrack = [trackChannel:3:size(slice,1)];                                

%% Loop Structure to detect cell nuclei positions
for t=1:length(slices)
    im = cell2mat(slice(slicetrack(slices(t))));
    slices
    %Gaussian filter (smoothes noise)
    gaussianFilter = fspecial('gaussian', [3, 3], 10);
    im2 = imfilter(im, gaussianFilter, 'replicate');
    
    % Remove background
    nbins = numel(unique(im2(:)))*sqrt(2); %Get number of unique values
    %Robustly identify first peak of histogram
    for s = 1:100
        %Iterate nbins
        nbins = ceil(nbins./sqrt(2));
        %Get histogram of image
        [hh, xx] = hist( double(im2(:)), nbins );
        %Check for empty bins in front tail
        fi = find(hh,1,'first');
        if ~any( hh(fi:fi+floor(nbins/10)) == 0 ); break; end
        %   Note: heurisitc value used for 'low' region
    end
    %Smooth histogram to exclude small variations
    hh = smooth(hh, 5, 'moving');
    hh = [0; hh]; %#ok<AGROW> %Pad in case first bin is a peak
    %Find extrema (where derivative sign changes)
    extma = find( sign(hh(3:end) - hh(2:end-1)) ~=...
        sign(hh(2:end-1) - hh(1:end-2)) ) + 1;
    %Peaks only (exclude minima, by second derivative)
    pks = xx(extma(hh(extma+1) + hh(extma-1) - 2*hh(extma) < 0) - 1);
    %Remove background by subtracting first peak
    im2 = im2 - pks(1);  %Subtract first peak
%---------------------------------------------------------------------
    Iy = imfilter(double(im), hy, 'replicate');                             %N-D filtering on 2D filtered image.
    Ix = imfilter(double(im), hx, 'replicate');                             %Across x axis.
    e = sqrt(Ix.^2 + Iy.^2);                                                %Create vector of distances between corresponding points.
    er=reshape(e,size(e,1)*size(e,2),1);                                    %Reshape array according to distance by sizes of distance of both points.
    q1=quantile(er,0.05);                                                 	%Find the value at which 10% of points falls beneath.
    q9=quantile(er,0.98);                                                    %Find the value at which 90% of points falls beneath.
    thresholds=fliplr(linspace(q1,q9,30));
    etlm=zeros(size(im));
    for j=1:length(thresholds)
        
        et=e>thresholds(j);                                                 %Create an vector from distances that are greater than threshholds
        et = imdilate(et, strel('disk',1));                                	%Dilate image
        et = imerode(et, strel('disk',2));                                 	%Erode image to get rid of background noise.
        et = imdilate(et, strel('disk',1));                                	%Dilate image
        etl=bwlabel(~et);
        S = regionprops(etl,'EquivDiameter','Area','Perimeter');            %Finds region properties of CC and stores into S.
        nucArea=cat(1,S.Area);                                              %Gets the Area of S.
        nucPerim=cat(1,S.Perimeter);                                        %Gets Perimeter of S.
        nucEquiDiameter=cat(1,S.EquivDiameter);                             %Gets the diameter of a circle with the same area as the region. Computed as sqrt(4*Area/pi).
        nucFormfactor=4*pi*nucArea./(nucPerim.^2);                          %Gets the shape value for thresholding.
        sizeScore = nucArea>minNucArea*0.3 & nucArea<maxNucArea;            %Returns 1 if both statements are true. Else returns 0.
        shapeScore=nucFormfactor>minFormfactor;                             %Returns 1 if statement is true. Else returns 0.
        totalScore=sizeScore&shapeScore;
        scorenz=find(totalScore);
        for k=1:length(scorenz)                                             %Filter by Score
            etlm(etl==scorenz(k))=1;
        end
    end
    C=regionprops(etlm>0,'Centroid','Area');
    P1 = cat(1, C.Centroid);
    P2 = cat(1, C.Area);
    if ~isempty(P1)
        z=zeros(length(P1),1);
        P1(:,1);
        if size(P1,1)==1
            z=zeros(1,1);
        end
        xC=cat(2,P1(:,1),z);
        yC=cat(2,P1(:,2),z);
        am=cat(2,P2(:,1),z);
        s1.xCoord=xC;
        s1.yCoord=yC;
        s1.amp=am;
        mI(t)=s1;
        ecube(:,:,t)=etlm;
    end
end
try
    movieInfo=mI;
catch
    disp('An error occured');
    disp('Execution stop.');
end