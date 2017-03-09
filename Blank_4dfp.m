function img_4dfp = Blank_4dfp(File,t,varargin)
	ArgIn = 1;
	Convert3D = 0;
	img_4dfp = [];
	while ( ArgIn <= length(varargin) )
		str = varargin{ArgIn};
		if ( strcmp(str,'ref'))
			ArgIn = ArgIn + 1;
			RefFilename = varargin{ArgIn};
			if ( strcmp(RefFilename( end-8:end),'.4dfp.img') )
				RefFilename = strjoin({RefFilename(1:end-9),'.4dfp.ifh'},'');
			elseif ( strcmp(RefFilename( end-8:end),'.4dfp.ifh') == 0 )
				RefFilename = strjoin({RefFilename,'.4dfp.ifh'},'');
			end
			ifh_info = Load_4dfp_ifh(RefFilename);
			ifh_info.name_of_data_file = File;
			ifh_info.matrix_size(4) = t;
			img_4dfp.ifh_info = ifh_info;
		elseif ( strcmp(str,'template') ) 
			ArgIn = ArgIn + 1;
			str = varargin{ArgIn};
			%setting up ifh Info			
			switch str
				case '711-333'
					dim = [48,64,48,1];
					scale = [3,3,3];
					mmppix = [3, -3, -3];
					center = [73.5,-87,-84];
				case '711-222'
					dim = [128,128,75,1];
					scale = [2,2,2];
					mmppix = [2, -2, -2];
					center = [129,-129,-82];
				case '711-111'
					dim = [176,208,176,1];
					scale = [1,1,1];
					mmppix = [1, -1, -1];
					center = [89,-85,-101];
				case 'MNI-333'
					dim = [61,73,61,1];
					scale = [3,3,3];
					mmppix = [3, -3, -3];
					center = [92,-92,-110];
				case 'MNI-222'
					dim = [91,109,91,1];
					scale = [2,2,2];
					mmppix = [2, -2, -2];
					center = [92,-92,-110];
				case 'MNI-111'
					dim = [182,218,182,1];
					scale = [1,1,1];
					mmppix = [1, -1, -1];
					center = [92,-92,-110];
				otherwise 
					error('UnKnown Template');
			end
			
			ifh_info.INTERFILE = '';
			ifh_info.number_format = 'float';
			ifh_info.name_of_data_file = File;
			ifh_info.version_of_keys = 3.3;
			ifh_info.number_of_bytes_per_pixel = 4;
			ifh_info.orientation = 2;
			ifh_info.number_of_dimensions = 4;
			ifh_info.matrix_size(1) = dim(1);
			ifh_info.matrix_size(2) = dim(2);
			ifh_info.matrix_size(3) = dim(3);
			ifh_info.matrix_size(4) = dim(4);
			ifh_info.scaling_factor(1) = scale(1);
			ifh_info.scaling_factor(2) = scale(2);
			ifh_info.scaling_factor(3) = scale(3);	
			ifh_info.mmppix = mmppix;
			ifh_info.center = center;
		
			[ ~, ~,endian] = computer;
			if endian == 'L'
				ifh_info.imagedata_byte_order = 'littleendian';	
			else
				ifh_info.imagedata_byte_order = 'bigendian';
			end
			
			ifh_info.matrix_size(4) = t;
			img_4dfp.voxel_data = zeros(dim);
			img_4dfp.ifh_info = ifh_info;
			
		elseif ( strcmp(str,'3D'))
			Convert3D = 1;		
		end
		ArgIn = ArgIn + 1;
	end
	if Convert3D
		img_4dfp.voxel_data = zeros([ifh_info.matrix_size(1),ifh_info.matrix_size(2),ifh_info.matrix_size(3),ifh_info.matrix_size(4)]);
	else
		img_4dfp.voxel_data = zeros([ifh_info.matrix_size(1)*ifh_info.matrix_size(2)*ifh_info.matrix_size(3),ifh_info.matrix_size(4)]);	
	end
end


