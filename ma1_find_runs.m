function filtered_list = ma1_find_runs(file_list,varargin)
% list = ma1_find_runs(file_list,'type',3); % find memory runs
% list = ma1_find_runs(file_list,'type',2); % find direct runs

n_found_runs = 0;
for k=1:length(file_list),
	load(file_list{k},'trial');
	disp(file_list{k});
	if length(trial)>1,
		
		fulfil_criteria = 1;
		
		%% set additional criteria here
		
		if ~(sum([trial.success] & ~[trial.choice])>60) % 60 instr trials
			fulfil_criteria = 0;
		end
		
		if trial(1).effector > 0, % select only saccades
			fulfil_criteria = 0;
		end
		
		%% apply dynamic criteria	
		if fulfil_criteria && trial(1).(varargin{1}) == varargin{2},
			n_found_runs = n_found_runs + 1;
			filtered_list{n_found_runs} = file_list{k};
		end
		
	end
	
	
end





    
