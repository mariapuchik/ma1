function out  = ma1_page_thru_trials(runpath, list_successful_only, plot_trials)
% ma1_page_thru_trials ('Lincombined2015-05-06_03.mat',1,1)


%% SETTING

ALIGN_STATE		= []; % if empty, derived from task type
PSTH_BIN		= 0.02; % s
PSTH_BEFORE_TRIGGER	= -1; % s
PSTH_AFTER_TRIGGER	= []; % s, if empty, derived from task type

RASTER_OFFSET = 50; % spikes/s, start of raster on the y-axis
EYE_DISPLAY_OFFSET_MULTIPLIER = [100 0.5];
EXCLUDE_CHANNELS = [4:6];

USE_TDT_STATES = 1;

%% END OF SETTINGS

if nargin < 2,
	list_successful_only = 0;
end

if nargin < 3,
	plot_trials = 0;
end

load(runpath);
disp(runpath);

ucolor = ['r','g','b','m','c','y','r','g','b','m','c','y'];
uname = {'a' 'b' 'c' 'd' 'e' 'f'};
trial_type = {'instr' 'choice'};

instr_color = 'b';
choice_color = 'r';

if ~isempty(EXCLUDE_CHANNELS), % remove unwanted channels
	channels2take = setdiff(1:size(trial(1).TDT_eNeu_t,1),EXCLUDE_CHANNELS);
	trial(1).TDT_eNeu_t = trial(1).TDT_eNeu_t(channels2take,:);
end
	

n_chans = size(trial(1).TDT_eNeu_t,1);
n_units = size(trial(1).TDT_eNeu_t,2); % maximal number of units across all channels
n_units_per_channel(1:n_chans) = deal(0);


% make a quick loop to find unique cue positions, and number of units per channel (UGLY SOLITION!)
SEL_POS = []; % cue positions per selected trial
for k = 1:length(trial),
	if (list_successful_only && trial(k).success) || ~list_successful_only
		SEL_POS = [SEL_POS; trial(k).eye(1).cue(1).pos(1:2)];
		for ch=1:n_chans,
			n_units_per_channel(ch) = max([n_units_per_channel(ch) length(find(~cellfun(@isempty,trial(k).TDT_eNeu_t(ch,:))))]);
		end
	end
end

U_POS = unique(SEL_POS,'rows');
n_pos = size(U_POS,1);

% resort cue positions so that subplots correspond to spatial locations
switch n_pos
	case 6
		resort_idx = [3 5 1 6 2 4]; n_subplot_col = 2;
	case 12
		resort_idx = [3 6 8 11 1 4 9 12 2 5 7 10]; n_subplot_col = 4;
end
U_POS = single(U_POS(resort_idx,:)); % use single to address crazy precision bug


[PSTH_instr(1:n_pos).n_trials] = deal(0);
[PSTH_instr(1:n_pos).align_time] = deal([]);
[SPK_instr(1:n_chans,1:n_units,1:n_pos).all_spike_times] = deal([]);
[SPK_instr(1:n_chans,1:n_units,1:n_pos).trial] = deal([]);

[PSTH_choice(1:n_pos).n_trials] = deal(0);
[PSTH_choice(1:n_pos).align_time] = deal([]);
[SPK_choice(1:n_chans,1:n_units,1:n_pos).all_spike_times] = deal([]);
[SPK_choice(1:n_chans,1:n_units,1:n_pos).trial] = deal([]);

if plot_trials,
	figure('Name','Plot trial','Position',[500 500 1200 800]);
end


switch trial(k).type,
	
	case 2,
		if isempty(ALIGN_STATE),
			ALIGN_STATE = 4;
		end
		PSTH_AFTER_TRIGGER = 2;
		task_type = 'direct';
	case 3,
		if isempty(ALIGN_STATE),
			ALIGN_STATE = 6;
		end
		PSTH_AFTER_TRIGGER = 3;
		task_type = 'memory';
end


for k = 1:length(trial),

	
	if (list_successful_only && trial(k).success) || ~list_successful_only
		
		if USE_TDT_STATES, % use TDT states and not monkeypsych states
			
			trial(k).use_states = trial(k).TDT_states(1:end-1)'; % exclude 1 for next trial
			trial(k).use_states_onset = trial(k).TDT_state_onsets(1:end-1)'; % TDT states are already aligned to trial start
			
		else
			trial(k).use_states = trial(k).states;
			trial(k).use_states_onset = trial(k).states_onset - trial(k).tSample_from_time_start(1);
		end
			
		
		% align time axis to trial start
		trial(k).initial_tSample_from_time_start = trial(k).tSample_from_time_start(1); % time from run start 
		trial(k).tSample_from_time_start = trial(k).tSample_from_time_start - trial(k).tSample_from_time_start(1);
		
		align_state_idx = find(trial(k).use_states == ALIGN_STATE);
		
		% reward TTL from TDT
		reward_time_axis = (0:length(trial(k).TDT_RWRD)-1)/trial(k).TDT_RWRD_samplingrate;
		trial(k).TDT_stream_duration_from_state2 = reward_time_axis(end);
		
		reward_time = reward_time_axis(trial(k).TDT_RWRD>0);
		if ~isempty(reward_time),
			reward_time = [reward_time(1) reward_time(end)];
		else
			reward_time = [];
		end
		
		
		trial_cue_pos_idx = find(ismember(U_POS,trial(k).eye(1).cue(trial(k).target_selected(1)).pos(1:2),'rows'));
		
		if ~isempty(align_state_idx)
			
			switch trial(k).choice,
				
				case 0 % instr
					
					PSTH_instr(trial_cue_pos_idx).n_trials	= PSTH_instr(trial_cue_pos_idx).n_trials + 1;
					PSTH_instr(trial_cue_pos_idx).align_time = [PSTH_instr(trial_cue_pos_idx).align_time trial(k).use_states_onset(align_state_idx)];
					PSTH_instr(trial_cue_pos_idx).trial(PSTH_instr(trial_cue_pos_idx).n_trials).states = trial(k).use_states;
					PSTH_instr(trial_cue_pos_idx).trial(PSTH_instr(trial_cue_pos_idx).n_trials).states_onset = trial(k).use_states_onset;
					PSTH_instr(trial_cue_pos_idx).trial(PSTH_instr(trial_cue_pos_idx).n_trials).eye_time = trial(k).tSample_from_time_start - trial(k).use_states_onset(align_state_idx);
					PSTH_instr(trial_cue_pos_idx).trial(PSTH_instr(trial_cue_pos_idx).n_trials).eye_hor = trial(k).x_eye;
					PSTH_instr(trial_cue_pos_idx).trial(PSTH_instr(trial_cue_pos_idx).n_trials).eye_ver = trial(k).y_eye;
					PSTH_instr(trial_cue_pos_idx).trial(PSTH_instr(trial_cue_pos_idx).n_trials).reward_time = reward_time;
					
				case 1 % choice
					
					PSTH_choice(trial_cue_pos_idx).n_trials = PSTH_choice(trial_cue_pos_idx).n_trials + 1;
					PSTH_choice(trial_cue_pos_idx).align_time = [PSTH_choice(trial_cue_pos_idx).align_time trial(k).use_states_onset(align_state_idx)];
					PSTH_choice(trial_cue_pos_idx).trial(PSTH_choice(trial_cue_pos_idx).n_trials).states = trial(k).use_states;
					PSTH_choice(trial_cue_pos_idx).trial(PSTH_choice(trial_cue_pos_idx).n_trials).states_onset = trial(k).use_states_onset;
					PSTH_choice(trial_cue_pos_idx).trial(PSTH_choice(trial_cue_pos_idx).n_trials).eye_time = trial(k).tSample_from_time_start - trial(k).use_states_onset(align_state_idx);
					PSTH_choice(trial_cue_pos_idx).trial(PSTH_choice(trial_cue_pos_idx).n_trials).eye_hor = trial(k).x_eye;
					PSTH_choice(trial_cue_pos_idx).trial(PSTH_choice(trial_cue_pos_idx).n_trials).eye_ver = trial(k).y_eye;
					PSTH_choice(trial_cue_pos_idx).trial(PSTH_choice(trial_cue_pos_idx).n_trials).reward_time = reward_time;
					
			end
		end
		
		if plot_trials,
			subplot(2,1,1); hold on;
			title(sprintf('Trial %d, %s cue %.2f %.2f (pos %d)',...
				k,trial_type{trial(k).choice+1},trial(k).eye(1).cue(trial(k).target_selected(1)).pos(1:2),trial_cue_pos_idx));
			
			plot(trial(k).tSample_from_time_start,trial(k).state,'k');
			plot(trial(k).tSample_from_time_start,trial(k).x_eye,'g');
			plot(trial(k).tSample_from_time_start,trial(k).y_eye,'m');
			
			ig_add_multiple_vertical_lines(reward_time,'Color','c');
			plot((0:length(trial(k).TDT_RWRD)-1)/trial(k).TDT_RWRD_samplingrate,trial(k).TDT_RWRD,'c');
			% plot((0:length(trial(k).TDT_stat)-1)/trial(k).TDT_stat_samplingrate,trial(k).TDT_stat,'c:');
			
			ig_add_multiple_vertical_lines(trial(k).states_onset- trial(k).initial_tSample_from_time_start,'Color','k');
			
			subplot(2,1,2); hold on;
		end
		
		for ch=1:n_chans,
			for u = 1:n_units_per_channel(ch), % n_units,
				
				if ~isempty(trial(k).TDT_eNeu_t{ch,u})
					trial_spike_arrival_times = trial(k).TDT_eNeu_t{ch,u}';
					if plot_trials, 
						plot(trial_spike_arrival_times,(ch-1)*5+u,[ucolor(u) '.']); 
						text(0.1,(ch-1)*5+u,uname{u},'Color',ucolor(u));
						text(-0.15,(ch-1)*5,['Ch' num2str(ch)]);
					end
					
					switch trial(k).choice
						
						case 0
							% all spike arrival times in one concatenated vector
							SPK_instr(ch,u,trial_cue_pos_idx).all_spike_times = [SPK_instr(ch,u,trial_cue_pos_idx).all_spike_times ...
								trial_spike_arrival_times - trial(k).use_states_onset(align_state_idx)]; % aligned to align_state_onset
							% spikes by trial
							SPK_instr(ch,u,trial_cue_pos_idx).trial(PSTH_instr(trial_cue_pos_idx).n_trials).spikes = ...
								[trial_spike_arrival_times - trial(k).use_states_onset(align_state_idx)]; % aligned to align_state_onset
							
						case 1
							% all spike arrival times in one concatenated vector
							SPK_choice(ch,u,trial_cue_pos_idx).all_spike_times = [SPK_choice(ch,u,trial_cue_pos_idx).all_spike_times ...
								trial_spike_arrival_times - trial(k).use_states_onset(align_state_idx)]; % aligned to align_state_onset
							% spikes by trial
							SPK_choice(ch,u,trial_cue_pos_idx).trial(PSTH_choice(trial_cue_pos_idx).n_trials).spikes = ...
								[trial_spike_arrival_times - trial(k).use_states_onset(align_state_idx)]; % aligned to align_state_onset			
					end
					
				else
					switch trial(k).choice
						case 0
							SPK_instr(ch,u,trial_cue_pos_idx).trial(PSTH_instr(trial_cue_pos_idx).n_trials).spikes = ...
								[]; % aligned to align_state_onset
						case 1
							SPK_choice(ch,u,trial_cue_pos_idx).trial(PSTH_choice(trial_cue_pos_idx).n_trials).spikes = ...
								[]; % aligned to align_state_onset
					end
					
				end
				
			end
			
			if plot_trials
				ig_add_multiple_vertical_lines(trial(k).states_onset - trial(k).initial_tSample_from_time_start,'Color','k');
				if USE_TDT_STATES,
					ig_add_multiple_vertical_lines(trial(k).TDT_state_onsets','Color','c','LineStyle',':');
					text(trial(k).TDT_state_onsets,-0.2*ones(size(trial(k).TDT_state_onsets)),num2str(trial(k).TDT_states),...
					'FontSize',8,'Color',[0.8706    0.4902         0]);
			
				end
				

			end
		end % of for each channel
		

		if plot_trials,
			if USE_TDT_STATES,
				ig_set_all_axes('Xlim',[trial(k).TDT_state_onsets(1) trial(k).TDT_state_onsets(end)]);
			else
				ig_set_all_axes('Xlim',[trial(k).tSample_from_time_start(1) trial(k).tSample_from_time_start(end)]);
			end
			drawnow; pause;
			clf;
		end
	end
	
end % for each trial


if 1 % summary per unit

n_l_pos = 0; % counter for left positions
n_r_pos = 0; % counter for right positions

for ch=1:n_chans,
	
	for u = 1:n_units_per_channel(ch),
		ig_figure('Name',sprintf('%s Ch %d, unit %s, aligned to state %d, %s',runpath,ch,uname{u},ALIGN_STATE,task_type),'Position',[100 100 1600 1200]);
		for p = 1:n_pos,
			hs(p) = subplot(n_pos/n_subplot_col,n_subplot_col,p);
			
			% INSTRUCTED
			spike_arrival_times = SPK_instr(ch,u,p).all_spike_times;
			spike_arrival_times = spike_arrival_times(spike_arrival_times>PSTH_BEFORE_TRIGGER & spike_arrival_times<PSTH_AFTER_TRIGGER);
			[histo,bins] = hist(spike_arrival_times,[PSTH_BEFORE_TRIGGER:PSTH_BIN:PSTH_AFTER_TRIGGER]);
			
			histo = (histo/PSTH_BIN)/PSTH_instr(p).n_trials; % convert PSTH y-axis to spikes/s
			histo_s_in = smooth(histo,1,1.5);
			plot(bins,histo,instr_color); hold on;
			plot(bins,histo_s_in,instr_color,'LineWidth',2);
		

			% plot raster and eye position
			if ~isempty(SPK_instr(ch,u,p).trial),
				for k=1:PSTH_instr(p).n_trials,
					ig_make_raster(SPK_instr(ch,u,p).trial(k).spikes,RASTER_OFFSET+k,0.1,0,'Color',instr_color,'LineWidth',1); hold on;
					plot(PSTH_instr(p).trial(k).states_onset - PSTH_instr(p).align_time(k),RASTER_OFFSET+k,'ks','MarkerSize',2);
					plot(PSTH_instr(p).trial(k).reward_time - PSTH_instr(p).align_time(k),RASTER_OFFSET+k,'cv','MarkerSize',2);
					
					
					plot(PSTH_instr(p).trial(k).eye_time,EYE_DISPLAY_OFFSET_MULTIPLIER(1)+PSTH_instr(p).trial(k).eye_hor*EYE_DISPLAY_OFFSET_MULTIPLIER(2),'Color',[0.2314    0.4431    0.3373]); hold on;
					plot(PSTH_instr(p).trial(k).eye_time,EYE_DISPLAY_OFFSET_MULTIPLIER(1)+PSTH_instr(p).trial(k).eye_ver*EYE_DISPLAY_OFFSET_MULTIPLIER(2),'Color',[0.5137    0.3804    0.4824]); hold on;
			
				end
				set(gca,'Ydir','normal','Xlim',[PSTH_BEFORE_TRIGGER PSTH_AFTER_TRIGGER]);
			end
			
	
			
			% CHOICE
			RASTER_OFFSET_choice = RASTER_OFFSET + PSTH_instr(p).n_trials;
			spike_arrival_times = SPK_choice(ch,u,p).all_spike_times;
			spike_arrival_times = spike_arrival_times(spike_arrival_times>PSTH_BEFORE_TRIGGER & spike_arrival_times<PSTH_AFTER_TRIGGER);
			[histo,bins] = hist(spike_arrival_times,[PSTH_BEFORE_TRIGGER:PSTH_BIN:PSTH_AFTER_TRIGGER]);
			
			histo = (histo/PSTH_BIN)/PSTH_choice(p).n_trials; % convert PSTH y-axis to spikes/s
			histo_s_ch = smooth(histo,1,1.5);
			plot(bins,histo,choice_color); hold on;
			plot(bins,histo_s_ch,choice_color,'LineWidth',2);
			
			% plot raster
			if ~isempty(SPK_choice(ch,u,p).trial),
				for k=1:PSTH_choice(p).n_trials,
					ig_make_raster(SPK_choice(ch,u,p).trial(k).spikes,RASTER_OFFSET_choice+k,0.1,0,'Color',choice_color,'LineWidth',1); hold on;
					plot(PSTH_choice(p).trial(k).states_onset - PSTH_choice(p).align_time(k),RASTER_OFFSET_choice+k,'ks','MarkerSize',2);
					plot(PSTH_choice(p).trial(k).reward_time - PSTH_choice(p).align_time(k),RASTER_OFFSET_choice+k,'cv','MarkerSize',2);
					
					plot(PSTH_choice(p).trial(k).eye_time,EYE_DISPLAY_OFFSET_MULTIPLIER(1)+PSTH_choice(p).trial(k).eye_hor*EYE_DISPLAY_OFFSET_MULTIPLIER(2),'Color',[0.2314    0.4431    0.3373]/1.5); hold on;
					plot(PSTH_choice(p).trial(k).eye_time,EYE_DISPLAY_OFFSET_MULTIPLIER(1)+PSTH_choice(p).trial(k).eye_ver*EYE_DISPLAY_OFFSET_MULTIPLIER(2),'Color',[0.5137    0.3804    0.4824]/1.5); hold on;
					
				end
				set(gca,'Ydir','normal','Xlim',[PSTH_BEFORE_TRIGGER PSTH_AFTER_TRIGGER]);
			end
			
			
			title(sprintf('cue %.2f %.2f (pos %d), %d instr, %d choice trials',U_POS(p,:),p,PSTH_instr(p).n_trials,PSTH_choice(p).n_trials));
			xlabel('Time to trigger (s)');
			ylabel('Spikes/s');
			
			
			if U_POS(p,1) < 0,
				n_l_pos = n_l_pos + 1;
				out.PSTH_l(n_l_pos).in = histo_s_in;
				out.PSTH_l(n_l_pos).ch = histo_s_ch;
			elseif U_POS(p,1) > 0,
				n_r_pos = n_r_pos + 1;
				out.PSTH_r(n_r_pos).in = histo_s_in;
				out.PSTH_r(n_r_pos).ch = histo_s_ch;
			end
			
						
		end % for each position
		out.PSTH_bins = bins;
		
		
		ig_set_axes_equal_lim;
		for p=1:n_pos,
			set(gcf,'CurrentAxes',hs(p));
			if PSTH_instr(p).n_trials
				states_onset_matrix = cat(1,PSTH_instr(p).trial.states_onset); % trials (raws) x states (col)
				states_onset_matrix = states_onset_matrix - repmat(PSTH_instr(p).align_time',1,size(states_onset_matrix,2));
				mean_states_onset_in = mean(states_onset_matrix,1);
				ig_add_multiple_vertical_lines(mean_states_onset_in,'Color',[0.5 0.5 0.8]);
			end
			text(double(mean(states_onset_matrix,1)),-5*ones(size(PSTH_instr(p).trial(1).states)),num2str(PSTH_instr(p).trial(1).states'),...
				'FontSize',6,'Color',[0.8706    0.4902         0]);
			
			if PSTH_choice(p).n_trials
				states_onset_matrix = cat(1,PSTH_choice(p).trial.states_onset); % trials (raws) x states (col)
				states_onset_matrix = states_onset_matrix - repmat(PSTH_choice(p).align_time',1,size(states_onset_matrix,2));
				mean_states_onset_ch = mean(states_onset_matrix,1);
				ig_add_multiple_vertical_lines(mean_states_onset_ch,'Color',[0.8 0.5 0.5]);
			end
			add_trial_timing;
			
		end
		
		ig_figure('Name',sprintf('%s Summary Ch %d, unit %s, aligned to state %d, %s',runpath,ch,uname{u},ALIGN_STATE,task_type),'Position',[100 100 1600 1200]);
		subplot(2,2,1)
		plot(out.PSTH_bins,mean(cat(1,out.PSTH_l.in),1),'Color',[0.0784    0.1686    0.5490],'LineWidth',2); hold on
		plot(out.PSTH_bins,mean(cat(1,out.PSTH_l.ch),1),'Color',[0.6000    0.2000         0],'LineWidth',2); hold on
		plot(out.PSTH_bins,mean(cat(1,out.PSTH_r.in),1),'Color',[0.2000    0.8000    1.0000],'LineWidth',2); hold on
		plot(out.PSTH_bins,mean(cat(1,out.PSTH_r.ch),1),'Color',[1.0000    0.4000         0],'LineWidth',2); hold on
		ig_add_multiple_vertical_lines(mean_states_onset_in,'Color',[0.5 0.5 0.8]);
		ig_add_multiple_vertical_lines(mean_states_onset_ch,'Color',[0.8 0.5 0.5]);
		legend({'left instr','left choice','right instr','right choice'},'Interpreter','none');
		
		
	end % for each unit
end % for each channel
end



% if 0 % summary per channel
% for ch=1:n_chans,
% 	
% 	ch_uname = {};
% 	for p = 1:n_pos,
% 		hs(p) = subplot(n_pos/2,2,p);
% 		
% 		for u = 1:n_units_per_channel(ch),
% 			
% 			spike_arrival_times = SPK_instr(ch,u,p).all_spike_times;
% 			spike_arrival_times = spike_arrival_times(spike_arrival_times>PSTH_BEFORE_TRIGGER & spike_arrival_times<PSTH_AFTER_TRIGGER);
% 			[histo,bins] = hist(spike_arrival_times,[PSTH_BEFORE_TRIGGER:PSTH_BIN:PSTH_AFTER_TRIGGER]);
% 			
% 			histo = (histo/PSTH_BIN)/PSTH_instr(p).n_trials; % convert PSTH to spikes/s
% 			plot(bins,histo,ucolor(u)); hold on;
% 			ch_uname{u} = [num2str(ch) uname{u}];
% 			
% 		end
% 		ig_add_multiple_vertical_lines(0,'Color','k');
% 		title(sprintf('cue %.2f %.2f (pos %d), %d trials',U_POS(p,:),p,PSTH_instr(p).n_trials));
% 		xlabel('Time to trigger (s)');
% 		ylabel('Spikes/s');
% 			
% 	end
% 	legend(ch_uname);
% end % for each channel
% end

function add_trial_timing
ig_add_multiple_vertical_lines(0,'Color','k');

