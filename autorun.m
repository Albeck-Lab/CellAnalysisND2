function autorun(file, positions, maxDiam, minDiam, circularity, c1Background, c2Bacgkround, c3Background, workers) 
for i=1:positions
    i
    mdata = bfopen2(file,i);
    slice = mdata{i,1}(:,1);
    slices = [1:size(slice,1)/3];
    parfor i=1:length(slices)
        movieInfo{i} = qteND2p(slice,slices(i),2, maxDiam, minDiam, circularity,0);
    end
    movieInfo = cat(2, movieInfo{:});
    scriptTrackGeneral
    
	%Initialize worker jobs
    nWorkers = workers;
    nTime = numel(slice)/3;
    
    %Pre-define the cell containing the spliced data
    slices = cell(nWorkers,1);  indexes = cell(nWorkers,1);
	
    %Calculate the max number of points to put in each cell
    nPer = ceil(nTime/nWorkers);
    
    index = [1:nTime];
    
    for s = 1:nWorkers
        %Define start and end indices, based on worker count and max points to use
        iSt = (s-1)*nPer; iEnd = min(s*nPer, nTime);
        slices{s} = slice(iSt*3+1:iEnd*3);
        indexes{s} = index(iSt+1:iEnd);
    end
    b=num2str(i);
      
    parfor j = 1:nWorkers
        valcube{j} = ContourTrackND2p(slices{j}, indexes{j}, tracksFinal, maxDiam, minDiam, circularity, c1Background, c2Bacgkround, c3Background, 0);
    end
    valcube = cat(2, valcube{:});
    
    save(['data_xy' b '.mat'], 'valcube');
    displaytext=['-------------------xy' b ' is done-------------------------'];
    disp(displaytext)
    clear all 
end
