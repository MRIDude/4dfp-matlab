function tcorr_4dfp(fMRIfilename,format,ROI_Filename,DFND_Filename, CorrelMatFileRoot, varargin )
	%tcorr_4dfp is designed replicate seed_correl program avi has
	%created. There Are some major diffences between Avi's implementation
	%and this matlab script. First lets look at the simularities. As with
	%Avi's code it will generated a CCR file, tcorr file and a zfrm file.
	%This is as far as it goes.
	%
	%Inputs
	%First argument: filename of either a conc file or 4dfp functional image.
	%Second argument: filename of expanded format string
	%Third argument: filename of 4dfp that designates the ROIs. There are
	%	two different types of 4dfps it can handle. First, by default
	%	it assumes that each volume in the 4dfp represents a ROI. Using
	%	the argument 'ROISingleVol', assumes that the values of each
	%	voxel represents which ROI it belongs to. 
	%Forth argument: filename of defined regions. 
	%Fifth argument: output root name of the correlations.
	%Other argument:
	%'CCR' if you only want the CCR matrix
	%'CCRbin' if you only want the CCR matix in binary format. This is meant to.
	%	save space. ASCI takes up more space.
	%'tcorr' This for when you want the tcorr 4dfp
	%'zfrm' if you want the fischer z-transformed tcorr file.
	%'ROISingleVol' informes the program that the ROI file has only one
	%	volume and the voxels values represents the ROI it belongs to. 
	%'ROIs' and followed my a list of numbers, specifies which ROI to use from the ROI file. 
	%
	% By default CCR, tcorr, and zfrm images are create. Using any one or
	% more of the optional arguments with cause it to only output what
	% you specify. 
	%
	%	The major difference between Avi's implimentation and mine is when an
	%ROI lies entirely in an undefined region as specifed by the DNFD
	%4dfp file.Avi's program is not helpful when this happens when this happens.
	%In my implimentation, all undefined ROIs are labeled with a 1e-37.
	%for the tcorr and the zfrm Images the volumes representing that
	%these ROIs will be replaces with a whole volume of 1e-37.
	%Another major different is the the file with the suffix
	%seed_regressor.dat which appears in Avi's implimentation. I name it
	%with the suffix ROIavg.dat. There is no header in this file and the
	%very first row gives the number of voxels that lie in the defined
	%regions. If the whole ROI lies entirely in undefined regions, the
	%size will be 0 and that whole column with 1e-37.
	
	disp('tcorr_4dfp version 2');
	
	all = 1;
	CCR = 0;
	tcorr = 0;
	zfrm = 0;
	ROISingleVol = 0;
	
	if ( exist(format,'file') ) 
		fileID = fopen(format,'r');
		FHCR = fscanf(fileID,'%s');
		fclose(fileID);
	else
		FHCR = format;
	end
	[status, FHCR] = unix(['format2lst -e ' '"' FHCR '"']);
	if ( status ) 
		error('Something went wrong with formatlst');
	end
	if ( sum(FHCR == '+') + sum(FHCR=='x') ~= length(FHCR) ) 
		error('Format str is not a must have only + and and x');
	end
	if ( ~exist('ROI_Filename','var') )
		error('There is no ROI_Filename')
	end
	if ( ~exist('DFND_Filename','var'))
		error('There is no DFND filename')
	end
	if ( ~exist(fMRIfilename,'file') )
		error('fMRI files does not exist')
	end
	i = 1;
	while ( i <= length(varargin)) 
	
		switch varargin{i}
			case 'CCR'
				all = 0;
				CCR = 1;
			case 'tcorr'
				all = 0;
				tcorr = 1;
			case 'zfrm'
				all = 0;
				zfrm = 1;
			case 'CCRbin'
				all = 0;
				CCR = 2;
			case 'ROISingleVol'
				ROISingleVol=1;
			case 'ROIs'
				if length(varargin) >= i + 1
					i = i + 1;
					lst = varargin{i};
					if isnumeric(lst)
						ROIs = lst;
					else
						error('ROIs is not a list')
					end
				else
					error('missing list of ROIs to use')
				end
			case 'AVG'
				tcorr = 0;
				all = 0;
				zfrm = 0;
				CCR = 0;
		end
		i = i + 1;
	end
	%getting FHCR
	
	
	%downloading 4dfp fmri image
	if ( strcmp ( fMRIfilename( end-4:end), '.conc'))
		Image = Load_4dfp_conc(fMRIfilename, 2, 0);
	else 
		if ( strcmp(fMRIfilename( end-8:end),'.4dfp.ifh') )
			fMRIfilename = strjoin({fMRIfilename(1:end-9),'.4dfp.img'},'');
		elseif ( strcmp(fMRIfilename( end-8:end),'.4dfp.img') == 0 )
			fMRIfilename = strjoin({fMRIfilename,'.4dfp.img'},'');
		end
		Image = Load_4dfp_img(fMRIfilename);
	end
	
	nFrames = size(Image.voxel_data,2);
	
	%setting up ROI file
	if ( strcmp(ROI_Filename( end-8:end),'.4dfp.ifh') )
		ROI_Filename = strjoin({ROI_Filename(1:end-9),'.4dfp.img'},'');
	elseif ( strcmp(ROI_Filename( end-8:end),'.4dfp.img') == 0 )
		ROI_Filename = strjoin({ROI_Filename,'.4dfp.img'},'');
	end
	ROI_4dfp = Load_4dfp_img(ROI_Filename);
	if ( Image.ifh_info.matrix_size(1:3) ~= ROI_4dfp.ifh_info.matrix_size(1:3) )
		error('fcMRI image and ROI Image do not have the same volume dimensions')
	end
	
	
	if( ROISingleVol == 1)
		
		if (ROI_4dfp.ifh_info.matrix_size(4) == 1)
			availableROIs =  unique(ROI_4dfp.voxel_data(:));
			availableROIs = availableROIs(availableROIs ~= 0 );
			if ~exist('ROIs','var')
				ROIs =availableROIs;
				nROI = numel(ROIs);
			else
				nROI = numel(ROIs);
			end 
				
		else
			error('There is more then one volume in the ROI file');
		end
	else
		availableROIs = 1:ROI_4dfp.ifh_info.matrix_size(4);
		if ~exist('ROIs','var')
			ROIs = availableROIs;
			nROI = numel(ROIs);
		else
			nROI = numel(ROIs);
		end
	end
			
	
	
	
	%setting DFND
	if ( strcmp(DFND_Filename( end-8:end),'.4dfp.ifh') )
		DFND_Filename = [ DFND_Filename(1:end-9) '.4dfp.img'];
	elseif ( strcmp(DFND_Filename( end-8:end),'.4dfp.img') == 0 )
		DFND_Filename = [ DFND_Filename '.4dfp.img'];
	end
	dfnd_4dfp = Load_4dfp_img(DFND_Filename);
	dfnd = dfnd_4dfp.voxel_data ~= 0; 
	if ( Image.ifh_info.matrix_size(1:3) ~= dfnd_4dfp.ifh_info.matrix_size(1:3) )
		error('fcMRI image and dfnd image do not have the same volume dimensions')
	end
	
	nROIFromFile = ROI_4dfp.ifh_info.matrix_size(4);
	
	% DFNDing everything
	ROI_4dfp = ROI_4dfp.voxel_data(dfnd,:);
	Image    = Image.voxel_data(dfnd,:);
	
	%setting up arrays
	ROIsSize = zeros([nROI,1]);
	ROIAvg = zeros([nFrames,nROI]);
	
	
	%calculating ROIavg
	
	for i = 1:nROI
		ROI = ROIs(i);
		% check to see if ROI is defined
		if( ROISingleVol == 0 ) 
			if ROI <= nROIFromFile
				dfndROI = squeeze(ROI_4dfp(:,ROI)) ~=0;
			else
				warning(['ROI,' ROI ' does not exist in the ROI 4dfp'])
				ROIsSize(i) = 0;
				ROIAvg(:,i) = 1e-37;
				continue
			end
		else 
			dfndROI = ROI_4dfp == ROI;
		end
		
		ROIsSize(i) = sum(dfndROI(:));
		if (ROIsSize(i) ~= 0 )
			ROIAvg(:,i) = mean(Image(dfndROI,:),1)';
		else
			ROIAvg(:,i) = 1e-37;
		end
	end
	
	
	Filename = [ CorrelMatFileRoot '_ROIavg.dat'];
	fid = fopen(Filename,'w');
	fprintf( fid, '#%s\n', fMRIfilename);
	fprintf( fid, '#%s\n', FHCR);
	fprintf( fid, '#%s\n', ROI_Filename);
	for i = 1:(nROI-1)
		fprintf( fid, '%d\t', ROIs(i));
	end
	fprintf( fid, '%d\n', ROIs(nROI));
	for i = 1:(nROI-1)
		fprintf( fid, '%d\t', ROIsSize(i));
	end
	fprintf( fid, '%d\n', ROIsSize(nROI));
	str = sprintf([repmat('%e\t', 1, nROI) '\n'], ROIAvg');
	str = strrep(str,[char(9) char(10)],char(10));
	fprintf(fid,'%s',str);
	fclose(fid);

	
	% computing the CCR matrix
	if ( all == 1 || CCR > 0  )
		if ( nROI ~= 1)
			%compute correlation matrix
			CorrelMat = zeros( nROI , nROI);
			CorrelMat(:) = 1e-37;
			CorrelMat(ROIsSize ~= 0,ROIsSize ~= 0) = correl1( ROIAvg(FHCR == '+',ROIsSize ~= 0))';
			%CorrelMat = vertcat(ROIsSize,CorrelMat);
		
			if ( all == 1 || CCR == 1)
				Filename = strjoin({CorrelMatFileRoot, '_CCR.dat'},'');
				dlmwrite(Filename,CorrelMat,'\t');
			else
				Filename = strjoin({CorrelMatFileRoot, '_CCR.bin'},'');	
				fid = fopen(Filename,'w');
				fwrite(fid,CorrelMat,'single');
				fclose(fid);
			end
		else
			warning('This is only one ROI can create CCR matrix')
		end
	end

	
	%computing tcorr and/or zfrm image
	if ( all == 1 || tcorr == 1 || zfrm == 1)
		Filename = strjoin({CorrelMatFileRoot, '_tcorr_dfnd.4dfp.img'},'');
		CorrelImg = Blank_4dfp(Filename,nROI,'ref',DFND_Filename);
		CorrelImg.voxel_data = ones([size(dfnd,1),nROI])*1e-37;
		CorrelImg.voxel_data(dfnd, ROIsSize ~= 0) = correl2(Image(:, FHCR == '+')',ROIAvg(FHCR == '+',ROIsSize ~= 0));
		if ( all == 1 || tcorr == 1)
			Write_4dfp_img(CorrelImg,'');
		end 
		
		if ( all == 1 || zfrm == 1)
			CorrelImg.voxel_data(dfnd, ROIsSize ~= 0)  = atanh(CorrelImg.voxel_data(dfnd, ROIsSize ~= 0));
			Filename = strjoin({CorrelMatFileRoot, '_tcorr_dfnd_zfrm.4dfp.img'},'');
			CorrelImg.ifh_info.name_of_data_file = Filename;
			Write_4dfp_img(CorrelImg,'');
		end
		
	end
	
end

function  r = correl1(a)
	meana = mean(a,1);
	a = bsxfun(@minus,a,meana); 
	maga = sqrt(sum(a.^2,1))';
	r = a'*a./(maga*maga');
end

function  r = correl2(a,b)
	meana = mean(a,1);
	meanb = mean(b,1);
	a = bsxfun(@minus,a,meana);
	b = bsxfun(@minus,b,meanb);
	maga = sqrt(sum(a.^2,1))';
	magb = sqrt(sum(b.^2,1));
	r = a'*b./(maga * magb);
end
