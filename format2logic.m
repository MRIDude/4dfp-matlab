function FHCR = format2logic( Filename )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
	if ( exist(Filename,'file') ) 
		fileID = fopen(Filename,'r');
		FHCR = fscanf(fileID,'%s');
		fclose(fileID);
	else
		error([Filename ' does not exist'])
	end
	
	[status, FHCR] = unix(['format2lst -e ' '"' FHCR '"']);
	if ( status ) 
		error('Something went wrong with formatlst');
	end
	
	if ( sum(FHCR == '+') + sum(FHCR=='x') ~= length(FHCR) ) 
		error('Format str is not a must have only + and and x');
	end
	
	FHCR = FHCR == '+';

end

