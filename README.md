CellAnalysisND2
===============

READ_ME - CellAnalysisND2
University of California - Davis
Albeck Lab

This software analyses an ND2 movie file and 	
tracks cells through time. The output contains	
intensities of the tracks in different channels	
as well as the ratios of those channels.

********
*Scripts*
********
1. autourun.m		This script invokes the pipeline for cell analysis.
2. bfopen2.m		This is a modified script that opens bioformat files.
3. qteND2p.m		This script identifies cells based on a set of given parameters.
4. scriptTrackgeneral.m	This modified script creates tracks of identified cells.
5. ContourTrackND2p.m	This script grabs the nuclear and cytosolic intensity values from the tracked cells.

********
*Packages used(included)*
********
1. bfmatlab		Contains scripts to open bioformat files. (https://www.openmicroscopy.org/site/support/bio-formats5/users/matlab/)
2. u-track_2.1.0	Containts scripts to track based on cell position. (http://lccb.hms.harvard.edu/software.html)

********
*Dependencies*
********
1. Matlab R2013A or newer
2. ND2 file to analyze
3. Enough RAM to have open ~16 GB of data
4. Scripts and files should be on the Matlab Path
5. Initialized parallel environment (done by typing at command line: matlabpool local)

********
*To Invoke*
********
On the Command Prompt:
matlabpool local	%You should see an icon on the bottom right corner with the numbers of worker initialized.
autorun(file, positions, maxDiam, minDiam, circularity, c1Background, c2Background, c3Background, workers)

Replace the variables as follows:

- file - file name in quotes. 'test.nd2'

- positions - the number of positions in the nd2 file. If xy 1-50, this field should be 50

- maxDiam - maximum cell diamater for identification. Usu. 30-75
 
- minDiam - minimum cell diameter for identification. Usu. 12-20

- circularity - circularity for cell identification. Usu. 0-1. Closer to 1 the more circular

- c1Background - Background values for the 1st channel. This is to get rid of noise in the output.

-workers - The number of processors you want this job to take. More cores the more intensive it is on your computer, but the faster the output will come. Most computer have 4 cores. Matlab has one core for processing by default. This value adds extra workers. 3 workers = 4 cores.

sample invoke script: 

-matlabpool local		%initialize

-autorun('test.nd2', 48, 100, 14, 0.6, 345, 200, 500, 3)

-See what your program is tracking:

%Open first position

-mdata = bfopen2(file,1);	%where file is in quotes 'test.nd2'

-slice = mdata{i,1}(:,1);

-slices = [1:size(slice,1)/3];

-movieInfo = qteND2(mdata,2,maxDiam,minDiam,circularity,1); %Replace the variables with your best guess and adjust according.

********
*Output*
********

The output is data_xy[position number].mat in the same folder the autorun script was invoked.
Open this and look in the workspace for the matrix 'valcube'

	valcube is a track x time x data cube of flourescent intensities for the position/xy
	valcube(:,:,1) - 1st channel cell track nuclear intensity
	valcube(:,:,2) - 2nd channel cell track nuclear intensity
	valcube(:,:,3)	- 3rd channel cell track nuclear intensity
	valcube(:,:,4) - 1st channel cell track cytosolic intensity
	valcube(:,:,5) - 2nd channel cell track cytosolic intensity
	valcube(:,:,6)	- 3rd channel cell track cytosolic intensity
	valcube(:,:,7) - 1st channel divided by 2nd channel cell track nuclear intensity
	valcube(:,:,8) - 1st channel divided by 2nd channel cell track cytosolic intensity
	valcube(:,:,9) - 1st channel divided by 2nd channel cell track nuclear intensity minus background
	valcube(:,:,10) - 1st channel divided by 3rd channel cell track nuclear intensity
	valcube(:,:,11) - 1st channel divided by 3rd channel cell track cytosolic intensity
	valcube(:,:,12) - 1st channel divided by 3rd channel cell track nuclear intensity minus background

To plot the tracks:
figure, imagesc(valcube(:,:,9))	

***************************
*Algorithms on Each Script*
***************************
1. autourun.m		This script invokes the pipeline for cell analysis.
	a.) Runs the scripts below in order
	b.) Automatically partitions each initialized worker
	c.) Output is ['data_xy' b '.mat'] where b is the xy

2. bfopen2.m		This is a modified script that opens bioformat files.
	a.) Open bioformat files in matlab such as nd2
	b.) Loads a whole position (xy01) and its images (time and channels) into a matrix called mdata
	c.) RAM intensive. Cannot open each image individually due to how it is coded.

3. qteND2p.m		This script identifies cells based on a set of given parameters.
	a.) Uses user input parameters(cell min/max diameter, circularity) to identify cell nuclei in each each image through time.
		1. Uses a combination of image blurring, dilating, scoring, and contouring to identify cells the best.
	b.) Records those cells' x and y coordinates in a matrix 'movieInfo' and passes this information to scripTrackgeneral
	c.) Can modify which channel this script uses to identify the cells. Change line 8 in autorun:
		movieInfo{i} = qteND2p(slice,slices(i),2, maxDiam, minDiam, circularity,0); %default channel to use it 2

4. scriptTrackgeneral.m	This modified script creates tracks of identified cells.
	a.) This script uses movieInfo variable and generates tracks based on parameters
	b.) Can modify track creation parameters by editing the script.
	c.) Output is tracksFinal which houses the x and y coordinates of each cell and their associated tracks through time.

5. ContourTrackND2p.m	This script grabs the nuclear and cytosolic intensity values from the tracked cells.
	a.) This script uses tracksFinal and recapitulates each cell in a matrix valcube.
		1. Uses contours to identify the cell nucleus.
		2. Dilates from the cell nucleus and gets the cytosolic region this way.
	b.) With the nucleic and cytosolic region for each cell track, this script gets the average intensities for each region.
	c.) The output is a matrix valcube. Its details are explained above.
