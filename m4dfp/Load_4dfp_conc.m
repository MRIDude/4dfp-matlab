function [ img_4dfp_stack ] = Load_4dfp_conc( ConcFile, OutputMethod, mode )
	%load_4dfp_conc reads a 4dfp conc file (avi or fidl format) and returns
	%that 4dfp images declared with the conc file as either a 4dfp img struct
	%or 4dfp img matrix (voxels = rows, frames = columns). If OutputMethod is 1
	%then data is output as a struct. If set to 2, then the runs will be output
	%as a 4dfp matrix.
	
	img_4dfp_stack = [];
	
	if(~exist(ConcFile,'file'))
		disp([ConcFile ' does not exist!']);
		return;
	end
	
	if(OutputMethod > 2 || OutputMethod < 1)
		disp('Invalid output method!')
		return;
	end
	
	switch(OutputMethod)
		case 1
			disp('Creating 4dfp struct...');
			img_4dfp_stack = struct('voxel_data',[],'ifh_info',[]);
		case 2
			disp('Creating 4dfp matrix...'); % already been created
			img_4dfp_stack = struct('voxel_data',[],'ifh_info',[]);
	end
	
	% Import the file
	ConcData = {};
	fid = fopen(ConcFile,'r');
	line = fgetl(fid);
	line = fgetl(fid);
	
	
	%determine if it is an Avi conc or fIDL conc
	%strip off the file: so that we are left with just a path
	i = 1;
	while(ischar(line))
		n = find(line==':');
		ConcData{i} = line((n+1):end);
		line = fgetl(fid);
		i = i + 1;
	end
	
	
	%start reading the 4dfp files
	for i = 1:length(ConcData)
		disp(['Reading ' ConcData{i}]);
		if ( mode == 1)
			img_file = Load_4dfp_img(ConcData{i},'3D');
		else
			img_file = Load_4dfp_img(ConcData{i});
		end
		if(~isempty(img_file))
			switch(OutputMethod)
				case 1
					img_4dfp_stack(i).voxel_data = img_file.voxel_data;
					img_4dfp_stack(i).ifh_info = img_file.ifh_info;
				case 2
					if (mode == '1')
						img_4dfp_stack.voxel_data = cat(4,img_4dfp_stack.voxel_data, img_file.voxel_data);
					else
						img_4dfp_stack.voxel_data = cat(2,img_4dfp_stack.voxel_data, img_file.voxel_data);
					end
					img_4dfp_stack.ifh_info = img_file.ifh_info;
			end
		end
	end
end

