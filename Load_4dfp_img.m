function img_4dfp = Load_4dfp_img(Filename, varargin)


	img_4dfp = [];    
	Verbose = false;
	Convert3D = false;
	Cast = '';
	frames = [];
    
    %set switches
	ArgIn = 1;
	while ( ArgIn <= length(varargin) )
		str = varargin{ArgIn};
		if ( strcmp(str,'verbose'))
			Verbose = true;
		elseif (strcmp(str,'3D'))
			Convert3D = true;
		elseif(strcmp(str, 'uint16') || strcmp(str, 'uint8') || strcmp(str, 'int16')  || strcmp(str, 'int8'))
            Cast = varargin{ArgIn};
		elseif ( strcmp(str,'frames'))
			ArgIn = ArgIn + 1;
			frames = varargin{ArgIn};
		end
		ArgIn = ArgIn + 1;
	end
	
	% 
	if ( strcmp(Filename( end-8:end),'.4dfp.ifh') )
		Filename = strjoin({Filename(1:end-9),'.4dfp.img'},'');
	elseif ( strcmp(Filename( end-8:end),'.4dfp.img') == 0 )
		Filename = strjoin({Filename,'.4dfp.img'},'');
	end
    
	% Extract the 4dfp filename
	img_4dfp_name = Filename;
	% Check to see if the file, img_4dfp_name, exists in the current
	% directory
	if(~exist(img_4dfp_name,'file'))
		error('Could not find %s. Check for hidden characters.',img_4dfp_name);
	end
	
	
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%Loading ifh file 
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%clear out trailing spaces
	while(img_4dfp_name(length(img_4dfp_name)) == ' ')
		img_4dfp_name(length(img_4dfp_name)) = [];
	end
	
	%get necessary info from the ifhfile
	%finds the indicies of the dots in the filename character array
	DotIndicies = find(img_4dfp_name == '.');
	
	%replace the img extension with ifh so that we can read the ifh
	%information associated with the img.
	ifh_4dfp_file = [img_4dfp_name(1:DotIndicies(length(DotIndicies))) 'ifh'];
	
	if(~exist(ifh_4dfp_file,'file'))
		error('Could not find %s',img_4dfp.ifh_4dfp_file);
	end
	
	%extract the ifh contents
	img_4dfp.ifh_info = Load_4dfp_ifh(ifh_4dfp_file, Verbose);
	
	img_4dfp.ifh_info.name_of_data_file = img_4dfp_name; %store this for easy writting later
	
	
	
	
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%Loading img file 
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	
	[fid, message] = fopen(img_4dfp_name,'r',img_4dfp.ifh_info.imagedata_byte_order(1));
	
	if(fid < 0)
		disp(['ERROR: ' message]);
		return;
	end
	if ( isempty(frames) )
		[InData, count] = fread(fid, img_4dfp.ifh_info.number_format);
		switch(Cast)
			case 'uint16'
				img_4dfp.voxel_data = uint16(InData);
			case 'uint8'
				img_4dfp.voxel_data = uint8(InData);
			case 'int16'
				img_4dfp.voxel_data = int16(InData);
			case 'int8'
				img_4dfp.voxel_data = int8(InData);
			otherwise
				img_4dfp.voxel_data = single(InData);
		end
		
		fclose(fid);
		
		voxels_per_volume = img_4dfp.ifh_info.matrix_size(1) * img_4dfp.ifh_info.matrix_size(2) * img_4dfp.ifh_info.matrix_size(3);
		
		
		
		if ~isequal(count, voxels_per_volume*img_4dfp.ifh_info.matrix_size(4))
			error('ifh volumes and img volumes do not match!');
			img_4dfp = [];
			return;
		end
		
		if(Convert3D)
			img_4dfp.voxel_data = reshape(img_4dfp.voxel_data,[img_4dfp.ifh_info.matrix_size]);
		else
			img_4dfp.voxel_data = reshape(img_4dfp.voxel_data,[voxels_per_volume img_4dfp.ifh_info.matrix_size(4)]);
		end
		
	else 
	
		voxels_per_volume = img_4dfp.ifh_info.matrix_size(1) * img_4dfp.ifh_info.matrix_size(2) * img_4dfp.ifh_info.matrix_size(3);
		Volume_Size = voxels_per_volume;
		
		if ( strcmp(img_4dfp.ifh_info.number_format, 'float'))
			Volume_Size = voxels_per_volume*4;
		end
		frames = unique(frames);
		
		
		switch(Cast)
			case 'uint16'
				img_4dfp.voxel_data = uint16(zeros([voxels_per_volume,length(frames)]));
			case 'uint8'
				img_4dfp.voxel_data = uint8(zeros([voxels_per_volume,length(frames)]));
			case 'int16'
				img_4dfp.voxel_data = int16(zeros([voxels_per_volume,length(frames)]));
			case 'int8'
				img_4dfp.voxel_data = int8(zeros([voxels_per_volume,length(frames)]));
			otherwise
				img_4dfp.voxel_data = single(zeros([voxels_per_volume,length(frames)]));
		end

		CurrentVolume = 1;
		i = 1;
		while ( i <= length(frames) )
			Offset = (frames(i) - 1)*Volume_Size;
			if( fseek(fid,Offset,-1) )
				error('Looks like you requested more frames greater then what the image had');
				img_4dfp = [];
			end
			[InData, count] = fread(fid, voxels_per_volume, img_4dfp.ifh_info.number_format);
			
			switch(Cast)
				case 'uint16'
					img_4dfp.voxel_data(:,i) = uint16(InData);
				case 'uint8'
					img_4dfp.voxel_data(:,i) = uint8(InData);
				case 'int16'
					img_4dfp.voxel_data(:,i) = int16(InData);
				case 'int8'
					img_4dfp.voxel_data(:,i) = int8(InData);
				otherwise
					img_4dfp.voxel_data(:,i) = single(InData);
			end
			if ( count ~= voxels_per_volume )
				error('ifh volumes and img volumes do not match!');
				img_4dfp = [];
				return;
			end
			CurrentVolume = frames(i);
			i = i + 1;
		end 
		
		fclose(fid);
		
		if(Convert3D)
			img_4dfp.voxel_data = reshape(img_4dfp.voxel_data,[img_4dfp.ifh_info.matrix_size(1:3) length(frames) ]);
			img_4dfp.ifh_info.matrix_size(4) = length(frames);
		end
	end

	
end

