function [movieInfo,ecube,etlm]=qteND2(mdata,trackChannel,maxDiam, minD, minF, diagnostic)
% movieInfo = qteND2(mdata,2,100,14,.4,1);
%  [pre,post,tstr]=getNames(3,1,1,5,1,5,'xy01',1,2,'2014-02-15-ekarfra','c1','c2','c3','c4','tif',[10 50]);

slice =  mdata{1,1}(:,1);
maxDiameter=maxDiam;
maxNucArea=round(pi*maxDiameter^2/4);
minDiameter=minD;
minNucArea=round(pi*minDiameter^2/4);
minFormfactor=minF;
hy = fspecial('sobel');                                                    %Create a predefined 2d filter. "Sobel horizontal edge-emphasizing filter"
hx = hy';
if diagnostic==1
vidObj = VideoWriter(['Diagnostic1.avi']);           %Name
open(vidObj);
end
slices = [trackChannel:3:size(slice,1)]

for t=1:length(slices)
    t
    %     filename=[namePre{trackChannel} tstr{t} namePost{trackChannel}];        %Open Image.
    %     im=imread(filename);                                                    %Reads Image.
    im = cell2mat(slice(slices(t)));
    Iy = imfilter(double(im), hy, 'replicate');                             %N-D filtering on 2D filtered image.
    Ix = imfilter(double(im), hx, 'replicate');                             %Across x axis.
    e = sqrt(Ix.^2 + Iy.^2);                                                %Create vector of distances between corresponding points.
    er=reshape(e,size(e,1)*size(e,2),1);                                    %Reshape array according to distance by sizes of distance of both points.
    q1=quantile(er,0.05);                                                 	%Find the value at which 10% of points falls beneath.
    q9=quantile(er,0.9);                                                    %Find the value at which 90% of points falls beneath.
    thresholds=fliplr(linspace(q1,q9,10));
    etlm=zeros(size(im));
    for j=1:length(thresholds)
        
        et=e>thresholds(j);                                                 %Create an vector from distances that are greater than threshholds
        etl=bwlabel(~et);
        S = regionprops(etl,'EquivDiameter','Area','Perimeter');            %Finds region properties of CC and stores into S.
        nucArea=cat(1,S.Area);                                              %Gets the Area of S.
        nucPerim=cat(1,S.Perimeter);                                        %Gets Perimeter of S.
        nucEquiDiameter=cat(1,S.EquivDiameter);                             %Gets the diameter of a circle with the same area as the region. Computed as sqrt(4*Area/pi).
        nucFormfactor=4*pi*nucArea./(nucPerim.^2);                          %Gets the shape value for threshholding.
        sizeScore = nucArea>minNucArea*0.3 & nucArea<maxNucArea;            %Returns 1 if both statements are true. Else returns 0.
        shapeScore=nucFormfactor>minFormfactor;                         %Returns 1 if statement is true. Else returns 0.
        totalScore=sizeScore&shapeScore;
        scorenz=find(totalScore);
        for k=1:length(scorenz)                                             %% FILTER BY SCORE
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
        %         s1 = struct('xCoord', [zeros(976)], 'yCoord', [zeros(976)], 'am', [zeros(976)]);
        s1.xCoord=xC;
        s1.yCoord=yC;
        s1.amp=am;
        mI(t)=s1;
        ecube(:,:,t)=etlm;
    end
    % create movie if diagnostic is on
    if diagnostic==1
        h=figure(1); clf; hold on;
        imshow(im,[]); hold on;
        nmask=etlm;
        nb=bwboundaries(nmask);
        for c=1:size(nb,1)
            mycell=nb(c,:);
            if isempty(mycell{1})
                continue
            else
                dim=mycell{1};
                dim2 = cat(2, dim(:,1),dim(:,2));
                hold on, plot(dim2(:,2),dim2(:,1),'y-');
            end
        end
    set(0,'CurrentFigure',1);
    frame = getframe;
    writeVideo(vidObj,frame);
    end
end
if diagnostic==1
    close(vidObj);
end
try
    movieInfo=mI;
catch
    disp('An error occurred while retrieving information from the internet.');
    disp('Execution will continue.');
end