function ma1_list_run_trials (runpath, list_successful_only)
% list trials

if nargin < 2,
	list_successful_only = 0;
end

load(runpath);
disp(runpath);

for k = 1:length(trial),
	
	% fprintf('trial %3d: task %d suc %d microstim %d task.microstim.fraction %d \n',k,trial(k).type,trial(k).success,trial(k).microstim,trial(k).task.microstim.fraction);
	if (list_successful_only && trial(k).success) || ~list_successful_only
		fprintf('trial %3d: task %d suc %d microstim %d task.microstim.fraction %d \n',k,trial(k).type,trial(k).success,trial(k).microstim,trial(k).task.microstim.fraction);
	end
	
end
