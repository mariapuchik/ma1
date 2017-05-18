function current_unit = ma1_get_unit_from_sorting_table(current_unit,excel_sorting_table_fullpath,sheet)

if nargin < 3,
	sheet = 'template 5ch';
elseif isempty(sheet),
	sheet = 'template 5ch';
end

verbose = 1;

if ~isempty(excel_sorting_table_fullpath),
	[xlsx_table.NUM,xlsx_table.STR,xlsx_table.RAW] = xlsread(excel_sorting_table_fullpath,sheet);
else
	current_unit.Neuron_ID			= {'?'};
	current_unit.SNR_rating                 = {NaN};
	current_unit.Single_rating              = {NaN};
	current_unit.electrode_depth            = {NaN};
	current_unit.stability_rating           = {NaN};
	current_unit.x                          = {NaN};
	current_unit.y                          = {NaN};
	return;
end


% idx_Date=[]; idx_Run=[]; idx_Block=[]; idx_Channel=[]; idx_Neuron_found_in=[]; idx_Unit=[]; idx_Neuron_ID=[]; idx_SNR=[]; idx_Single=[]; idx_Electrode_depth=[]; idx_Difficult_sorting=[]; idx_other_sorting_issues=[];

idx_Date		= find_column_index(xlsx_table.STR,'Date');
idx_Run			= find_column_index(xlsx_table.STR,'Run');
idx_Block		= find_column_index(xlsx_table.STR,'Block');
idx_Channel		= find_column_index(xlsx_table.STR,'Chan');
% idx_Neuron_found_in	= find_column_index(xlsx_table.STR,'Neuron_found_in');
idx_Unit		= find_column_index(xlsx_table.STR,'Unit');
idx_Neuron_ID		= find_column_index(xlsx_table.STR,'Neuron_ID');
idx_SNR			= find_column_index(xlsx_table.STR,'SNR rank');
idx_Single		= find_column_index(xlsx_table.STR,'Single rank');
idx_Electrode_depth	= find_column_index(xlsx_table.STR,'Aimed electrode_depth');
idx_Stability		= find_column_index(xlsx_table.STR,'Stability rank');
idx_x			= find_column_index(xlsx_table.STR,'x');
idx_y			= find_column_index(xlsx_table.STR,'y');

% && exist('idx_Neuron_found_in','var')
if exist('idx_Date','var') && exist('idx_Run','var') && exist('idx_Block','var') && exist('idx_Channel','var') && exist('idx_Unit','var') && exist('idx_Neuron_ID','var')
	r_Date	= [xlsx_table.RAW{2:end,idx_Date}]	== str2num(current_unit.date);
	r_Block = [xlsx_table.RAW{2:end,idx_Block}]	== current_unit.block;
	r_Run	= [xlsx_table.RAW{2:end,idx_Run}]	== current_unit.run;
	r_Chan	= [xlsx_table.RAW{2:end,idx_Channel}]	== current_unit.channel;
	
	r_Uname	= strcmp({xlsx_table.RAW{2:end,idx_Unit}},current_unit.uname);
	
	
	neuron_idx                         =find(r_Date & r_Block & r_Run & r_Chan & r_Uname) + 1; % + 1 to account for header row
	if isempty(neuron_idx)
		current_unit.Neuron_ID			= {'?'};
		current_unit.SNR_rating                 = {NaN};
		current_unit.Single_rating              = {NaN};
		current_unit.electrode_depth            = {NaN};
		current_unit.stability_rating           = {NaN};
		current_unit.x                          = {NaN};
		current_unit.y                          = {NaN};
		if verbose
			disp('NO MATCHING SORTING EXISTS!!!');
		end
	else
		current_unit.Neuron_ID			=xlsx_table.RAW(neuron_idx,idx_Neuron_ID);
		current_unit.SNR_rating                 =xlsx_table.RAW(neuron_idx,idx_SNR);
		current_unit.Single_rating              =xlsx_table.RAW(neuron_idx,idx_Single);
		current_unit.electrode_depth            =xlsx_table.RAW(neuron_idx,idx_Electrode_depth);
		current_unit.stability_rating           =xlsx_table.RAW(neuron_idx,idx_Stability);
		current_unit.x                          =xlsx_table.RAW(neuron_idx,idx_x);
		current_unit.y                          =xlsx_table.RAW(neuron_idx,idx_y);
	end
	
else
	current_unit.Neuron_ID			= {'?'};
	current_unit.SNR_rating                 = {NaN};
	current_unit.Single_rating              = {NaN};
	current_unit.electrode_depth            = {NaN};
	current_unit.stability_rating           = {NaN};
	current_unit.x                          = {NaN};
	current_unit.y                          = {NaN};
	if verbose
		disp('CHECK TABLE FIELD NAMES!');
	end
	
	
end


function column_index=find_column_index(inputcell,title)
column_index = find(strcmp({inputcell{1,:}},title)); % one liner

% DAG_toolbox version: with loop
% column_index=[];
% for m=1:size(inputcell,2)
% 	if strcmp(inputcell{1,m},title)
% 		column_index=m;
% 	end
% end



