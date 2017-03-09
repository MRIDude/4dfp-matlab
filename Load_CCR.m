function CCR = Load_CCR(CCRroot)

	ROIavg = [ CCRroot '_ROIavg.dat'];
	if ~exist(ROIavg, 'file')
	
		error('ROIavg file  does not exist');
	
	end
	fid = fopen(ROIavg,'r');
	l = fgetl(fid);
	InputImageFilename = l(2:end);
	
	l = fgetl(fid);
	FHCR = l(2:end);
	
	l = fgetl(fid);
	ROIFilename = l(2:end);
	
	
	l = fgetl(fid);
	ROIID = str2num(l);
	
	l = fgetl(fid);
	ROISize = str2num(l);
	fclose(fid);
	
	nROI = numel(ROIID);
	
	if exist([CCRroot '_CCR.dat'],'file')
		ccr= dlmread([CCRroot '_CCR.dat']);
		
	elseif exist([CCRroot '_CCR.bin'],'file')
		fid = fopen([CCRroot '_CCR.bin'],'r');
		ccr = fread(fid,[nROI nROI],'single');
		fclose(fid);
	else
		ccr = NaN;
	end

	CCR = struct('ImageFilename',InputImageFilename,'Format',FHCR,'ROIFilename',ROIFilename,'ROISize',ROISize,'ROIid',ROIID,'CCR',ccr);
	




end