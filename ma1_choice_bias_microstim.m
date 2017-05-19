function ma1_choice_bias_microstim(filepath)
% initial version of quick choice bias assessment

if nargin < 1,
	 [filename, pathname] = uigetfile('*.mat', 'Select data file');
	 filepath = [pathname filesep filename];
end
load(filepath);

idx_choice		= find([trial.choice]==1);
idx_success		= find([trial.success]==1);
idx_choice_successful	= intersect(idx_choice,idx_success);

target_selected_temp=cat(1,trial(idx_choice_successful).target_selected);
target_selected =target_selected_temp(:,1); % eye

eye = cat(1,trial(idx_choice_successful).eye);
tar = cat(1,eye.tar);
tar = tar(sub2ind(size(tar),[1:size(tar,1)],target_selected')); % sub2ind is important function converting subscripts to linear index
pos = cat(1,tar.pos);


if isfield(trial,'microstim'),
	microstim_status = cat(1,[trial(idx_choice_successful).microstim]);
	ind_microstim = find(microstim_status==1);
	ind_nomicrostim = find(microstim_status==0);
	left_selected = double(pos(:,1)<0);
	
	n_r_microstim =sum(pos(ind_microstim,1)>0); 
	n_l_microstim =sum(pos(ind_microstim,1)<0);
	n_r_nomicrostim =sum(pos(ind_nomicrostim,1)>0);
	n_l_nomicrostim =sum(pos(ind_nomicrostim,1)<0);
	
	p = fexact(left_selected,microstim_status');
%       y is a vector of status (1=microstim/0=control). 
%	X is a MxP matrix of binary results (left=1/right=0).

	str = sprintf('\n no microstim: L %d, R %d | microstim: L %d, R %d | Fisher exact test p=%.3f',n_l_nomicrostim,n_r_nomicrostim,n_l_microstim,n_r_microstim,p);

	
else
	n_r_microstim = NaN;
	n_l_microstim = NaN;
	n_r_nomicrostim = sum(pos(:,1)>0);
	n_l_nomicrostim = sum(pos(:,1)<0);
	
	str = sprintf('L %d, R %d',n_l_nomicrostim,n_r_nomicrostim);
	
end

ig_figure('Name',filepath);
bar(1,n_l_nomicrostim/(n_r_nomicrostim+n_l_nomicrostim)); hold on
bar(2,n_l_microstim/(n_r_microstim+n_l_microstim),'g'); hold on
set(gca,'Xlim',[0 3],'XTick',[1 2],'XTickLabel',{'no microstim','microstim'},'Ylim',[0 1]);
ylabel('left choice ratio');
title(str);

ig_figure('Name',filepath);
bar(1,n_l_nomicrostim/(n_r_nomicrostim)); hold on
bar(2,n_l_microstim/(n_r_microstim),'g'); hold on
set(gca,'Xlim',[0 3],'XTick',[1 2],'XTickLabel',{'no microstim','microstim'});
ylabel('left/right ratio');
title(str);	
