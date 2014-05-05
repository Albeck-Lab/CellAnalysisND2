function kdtree_compile( varargin )
% clc

p = inputParser;
p.CaseSensitive = false;
p.addParamValue( 'VerboseOn', false, @islogical );
p.parse( varargin{:} );
flagVerboseOn = p.Results.VerboseOn;

localpath = fileparts(which('kdtree_compile'));
fprintf(1,'Compiling kdtree library [%s]...\n', localpath);

% setup mex options
mex_options = {};
if flagVerboseOn    
    mex_options{end+1} = '-v';
end
if strfind( computer('arch'), '64' )
    mex_options{end+1} = '-largeArrayDims';
end   
    
% run mex commands to build all kdtree files
err = 0;
err = err | mex(mex_options{:},'-outdir',localpath, fullfile(localpath,'kdtree_build.cpp'));
err = err | mex(mex_options{:},'-outdir',localpath, fullfile(localpath, 'kdtree_delete.cpp'));
err = err | mex(mex_options{:},'-outdir',localpath, fullfile(localpath, 'kdtree_k_nearest_neighbors.cpp'));
err = err | mex(mex_options{:},'-outdir',localpath, fullfile(localpath, 'kdtree_ball_query.cpp'));
err = err | mex(mex_options{:},'-outdir',localpath, fullfile(localpath, 'kdtree_nearest_neighbor.cpp'));
err = err | mex(mex_options{:},'-outdir',localpath, fullfile(localpath, 'kdtree_range_query.cpp'));
err = err | mex(mex_options{:},'-outdir',localpath, fullfile(localpath, 'kdtree_io_from_mat.cpp'));
err = err | mex(mex_options{:},'-outdir',localpath, fullfile(localpath, 'kdtree_io_to_mat.cpp'));

if err ~= 0, 
   error('compile failed!'); 
else
   fprintf(1,'\bDone!\n');
end       