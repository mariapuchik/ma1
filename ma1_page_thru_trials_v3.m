function out  = ma1_page_thru_trials_v3(runpath, list_successful_only, plot_trials)
% ma1_page_thru_trials ('Lincombined2015-05-06_03.mat',1,1)


%% SETTING

ALIGN_STATE		= []; % if empty, derived from task type
PSTH_BIN		= 0.02; % s
PSTH_BEFORE_TRIGGER	= -1; % s
PSTH_AFTER_TRIGGER	= []; % s, if empty, derived from task type

RASTER_OFFSET = 50; % spikes/s, start of raster on the y-axis
EYE_DISPLAY_OFFSET_MULTIPLIER = [100 0.5];
PLOT_UNSMOOTHED_HISTO = 0;
EXCLUDE_CHANNELS = [4:6];

USE_TDT_STATES = 1;
DETECT_SACCADES = 1;
SORT_TRIALS_BY = 0; % 0 - do not sort, STATE number - by this state, -1 - by saccade onset
ADD_PREVIOUS_TRIAL_SPIKES = 1; % append spikes from previous trial to beginning of the current trial
% see https://drive.google.com/open?id=1Ae7OnZuQN00sPL7mlINuDRvAmsHGEJ1kh9vLNaELaW4

% For task-specific settings, see % Time intervals for each task

%% END OF SETTINGS

if nargin < 2,
	list_successful_only = 0;
end

if nargin < 3,
	plot_trials = 0;
end

load(runpath);
disp(runpath);


%% Time intervals for each task
switch trial(1).type,
	
	case 2,
		if isempty(ALIGN_STATE),
			ALIGN_STATE = 4;
		end
		PSTH_AFTER_TRIGGER = 2;
		task_type = 'direct';
		RESPONSE_STATE = 4;
		
		% for each interval, 4 elements: "state start" "start" "state end" "end", start and end in s
		% if state end is -1, next state after state start is taken
		FR_INTERVALS		= [1 -0.3 2 0; 2 0 3 0.15; 3 0.2 -1 0; 4 0 5 -0.025; 5 -0.025 5 0.1; 5 0.1 -1 0]; 
		FR_INTERVAL_NAMES	= {'ITI','fix acq','fix hold','pre-sac','peri-sac','post-sac'};
		
	case 3,
		if isempty(ALIGN_STATE),
			ALIGN_STATE = 6;
		end
		PSTH_AFTER_TRIGGER = 3;
		task_type = 'memory';
		RESPONSE_STATE = 9;
		
		FR_INTERVALS		= [1 -0.3 2 0; 2 0 3 0.15; 3 0.2 -1 0; 6 0.05 -1 0; 7 0.2 -1 0; 9 0 10 -0.025; 10 -0.025 10 0.1; 5 0 -1 0]; 
		FR_INTERVAL_NAMES	= {'ITI','fix acq','fix hold','cue','mem','pre-sac','peri-sac','post-sac'};
end


switch trial(1).effector
	case 0
		task_effector = 'sac';
		task_hand = '';
		
	case {1,6}
		task_effector = 'reach';
		hand = {'l hand','r hand'};
		task_hand = hand{task.reach_hand};
		
		
end


%%


ucolor = ['r','g','b','m','c','k'];
uname = {'a' 'b' 'c' 'd' 'e' 'f'};
trial_type = {'instr' 'choice'};

instr_color = 'b';
choice_color = 'r';

eye_ver_color = [0.4000         0    0.6000];
eye_hor_color = [ 0    0.4980         0];
hnd_ver_color = [0.3490    0.2000    0.3294];
hnd_hor_color = [0.0706    0.2118    0.1412];


int_color = copper(length(FR_INTERVALS)+2);

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
		
		switch task_effector
			case 'sac'
				SEL_POS = [SEL_POS; trial(k).eye(1).cue(1).pos(1:2)];
			case 'reach'
				SEL_POS = [SEL_POS; trial(k).hnd(1).cue(1).pos(1:2)];
		end
		
		for ch=1:n_chans,
			if length(trial(k).TDT_eNeu_t)
				n_units_per_channel(ch) = max([n_units_per_channel(ch) length(find(~cellfun(@isempty,trial(k).TDT_eNeu_t(ch,:))))]);
			end
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
	otherwise
		disp('unknown number of target positions'); return;
end
U_POS = single(U_POS(resort_idx,:)); % use single to address crazy precision bug

% Need to initialize only those variables that are used for counter (e.g. var = var + 1) or vector accumulation (var = [var new_var])
% other fields do not require initialization

[PSTH_instr(1:n_pos).n_trials] = deal(0);
[PSTH_instr(1:n_pos).align_time] = deal([]);
[SPK_instr(1:n_chans,1:n_units,1:n_pos).all_spike_times] = deal([]);
[SPK_instr(1:n_chans,1:n_units,1:n_pos).trial] = deal([]);

[PSTH_choice(1:n_pos).n_trials] = deal(0);
[PSTH_choice(1:n_pos).align_time] = deal([]);
[SPK_choice(1:n_chans,1:n_units,1:n_pos).all_spike_times] = deal([]);
[SPK_choice(1:n_chans,1:n_units,1:n_pos).trial] = deal([]);

if plot_trials,
	hft = figure('Name','Plot trial','Position',[500 500 1200 800],'CurrentChar',' ');
end



valid_trial_idx = 0;
for k = 1:length(trial),

	
	if (list_successful_only && trial(k).success) || ~list_successful_only
		valid_trial_idx = valid_trial_idx + 1;
		
		if USE_TDT_STATES, % use TDT states and not monkeypsych states
			
			trial(k).use_states = trial(k).TDT_states(1:end-1)'; % exclude state 1 for next trial
			trial(k).use_states_onset = trial(k).TDT_state_onsets(1:end-1)'; % TDT states are already aligned to trial start (state 2)
		else
			trial(k).use_states = trial(k).states;
			trial(k).use_states_onset = trial(k).states_onset - trial(k).tSample_from_time_start(1);
		end
			
		n_states = length(trial(k).use_states);
		
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
		
		if strcmp(task_effector,'sac'),
			trial_cue_pos_idx = find(ismember(U_POS,trial(k).eye(1).cue(trial(k).target_selected(1)).pos(1:2),'rows'));
		else
			trial_cue_pos_idx = find(ismember(U_POS,trial(k).hnd(1).cue(trial(k).target_selected(2)).pos(1:2),'rows'));
		end
		
		
		if DETECT_SACCADES,
			response_state_idx = find(trial(k).use_states==RESPONSE_STATE);
			response_state_onset	= trial(k).use_states_onset(response_state_idx);
			response_state_offset	= trial(k).use_states_onset(response_state_idx+1);
			
			em = em_saccade_blink_detection(trial(k).tSample_from_time_start,trial(k).x_eye,trial(k).y_eye,...
					'ma1_em_settings_monkey_220Hz');
			trial_saccade_onsets = em.sac_onsets(em.sac_onsets>response_state_onset & em.sac_onsets<response_state_offset);
			if ~isempty(trial_saccade_onsets), trial(k).saccade_onset = trial_saccade_onsets(1); end
		end
		
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
					PSTH_instr(trial_cue_pos_idx).trial(PSTH_instr(trial_cue_pos_idx).n_trials).hnd_hor = trial(k).x_hnd;
					PSTH_instr(trial_cue_pos_idx).trial(PSTH_instr(trial_cue_pos_idx).n_trials).hnd_ver = trial(k).y_hnd;
					PSTH_instr(trial_cue_pos_idx).trial(PSTH_instr(trial_cue_pos_idx).n_trials).reward_time = reward_time;
					PSTH_instr(trial_cue_pos_idx).trial(PSTH_instr(trial_cue_pos_idx).n_trials).saccade_onset = trial(k).saccade_onset;
					
				case 1 % choice
					
					PSTH_choice(trial_cue_pos_idx).n_trials = PSTH_choice(trial_cue_pos_idx).n_trials + 1;
					PSTH_choice(trial_cue_pos_idx).align_time = [PSTH_choice(trial_cue_pos_idx).align_time trial(k).use_states_onset(align_state_idx)];
					PSTH_choice(trial_cue_pos_idx).trial(PSTH_choice(trial_cue_pos_idx).n_trials).states = trial(k).use_states;
					PSTH_choice(trial_cue_pos_idx).trial(PSTH_choice(trial_cue_pos_idx).n_trials).states_onset = trial(k).use_states_onset;
					PSTH_choice(trial_cue_pos_idx).trial(PSTH_choice(trial_cue_pos_idx).n_trials).eye_time = trial(k).tSample_from_time_start - trial(k).use_states_onset(align_state_idx);
					PSTH_choice(trial_cue_pos_idx).trial(PSTH_choice(trial_cue_pos_idx).n_trials).eye_hor = trial(k).x_eye;
					PSTH_choice(trial_cue_pos_idx).trial(PSTH_choice(trial_cue_pos_idx).n_trials).eye_ver = trial(k).y_eye;
					PSTH_choice(trial_cue_pos_idx).trial(PSTH_choice(trial_cue_pos_idx).n_trials).hnd_hor = trial(k).x_hnd;
					PSTH_choice(trial_cue_pos_idx).trial(PSTH_choice(trial_cue_pos_idx).n_trials).hnd_ver = trial(k).y_hnd;
					PSTH_choice(trial_cue_pos_idx).trial(PSTH_choice(trial_cue_pos_idx).n_trials).reward_time = reward_time;
					PSTH_choice(trial_cue_pos_idx).trial(PSTH_choice(trial_cue_pos_idx).n_trials).saccade_onset = trial(k).saccade_onset;
			end
		end
		
		if plot_trials,
			subplot(2,1,1); hold on;
			title(sprintf('Trial %d, %s cue %.2f %.2f (pos %d)',...
				k,trial_type{trial(k).choice+1},trial(k).eye(1).cue(trial(k).target_selected(1)).pos(1:2),trial_cue_pos_idx));
			
			plot(trial(k).tSample_from_time_start,trial(k).state,'k');
			plot(trial(k).tSample_from_time_start,trial(k).x_eye,'Color',eye_hor_color);
			plot(trial(k).tSample_from_time_start,trial(k).y_eye,'Color',eye_ver_color);
			
			if strcmp(task_effector,'reach')
				plot(trial(k).tSample_from_time_start,trial(k).x_hnd,'Color',hnd_hor_color);
				plot(trial(k).tSample_from_time_start,trial(k).y_hnd,'Color',hnd_ver_color);
			end
			
			ig_add_multiple_vertical_lines(reward_time,'Color','c');
			plot((0:length(trial(k).TDT_RWRD)-1)/trial(k).TDT_RWRD_samplingrate,trial(k).TDT_RWRD,'c');
			% plot((0:length(trial(k).TDT_stat)-1)/trial(k).TDT_stat_samplingrate,trial(k).TDT_stat,'c:');
			
			ig_add_multiple_vertical_lines(trial(k).states_onset- trial(k).initial_tSample_from_time_start,'Color','k');
			
			if DETECT_SACCADES,
				ig_add_multiple_vertical_lines(trial(k).saccade_onset,'Color','m','LineStyle',':');
			end
			
			figure(hft);
			subplot(2,1,2); hold on;
		end
		
		for ch=1:n_chans,
			for u = 1:n_units_per_channel(ch), % n_units,
				
				if ~isempty(trial(k).TDT_eNeu_t{ch,u})
					trial_spike_arrival_times = trial(k).TDT_eNeu_t{ch,u}';
					if ADD_PREVIOUS_TRIAL_SPIKES && k>1,
						prev_trial_spike_arrival_times = trial(k-1).TDT_eNeu_t{ch,u}' - ...
							trial(k-1).TDT_state_onsets(end) + trial(k).TDT_state_onsets(1);
						trial_spike_arrival_times = [prev_trial_spike_arrival_times trial_spike_arrival_times];
					end
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
					
					% spike waveforms
					if all(size(trial(k).TDT_eNeu_w{ch,u}) > [1 29])
						trial_spike_waveform_mean = mean(trial(k).TDT_eNeu_w{ch,u},1);
						trial_spike_waveform_std = std(trial(k).TDT_eNeu_w{ch,u},0,1);
					else
						trial_spike_waveform_mean = nan(1,30);
						trial_spike_waveform_std = nan(1,30);
					end
					if all(size(trial(k).TDT_eNeu_w{ch,u}) > [0 29])
						trial_spike_waveform_all = trial(k).TDT_eNeu_w{ch,u};
					else
						trial_spike_waveform_all = nan(1,30);
					end
					
					SPK_wf(ch,u).mean(valid_trial_idx,:)	= trial_spike_waveform_mean;
					SPK_wf(ch,u).std(valid_trial_idx,:)	= trial_spike_waveform_std;
					SPK_wf(ch,u).all(valid_trial_idx,:)	= {trial_spike_waveform_all};
					
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
			if get(gcf,'CurrentChar')=='q',
				return; break;
				
			end
			clf;
		end
	end
	
end % for each trial


for ch=1:n_chans,
	
	for u = 1:n_units_per_channel(ch),
		n_l_pos = 0; % counter for left positions
		n_r_pos = 0; % counter for right positions
		
		ig_figure('Name',sprintf('%s Ch %d, unit %s, aligned to state %d, %s %s %s',runpath,ch,uname{u},ALIGN_STATE,task_type,task_effector,task_hand),'Position',[100 100 1600 1200]);
		for p = 1:n_pos,
			hs(p) = subplot(n_pos/n_subplot_col,n_subplot_col,p);
			
			% INSTRUCTED
			spike_arrival_times = SPK_instr(ch,u,p).all_spike_times;
			spike_arrival_times_in = spike_arrival_times(spike_arrival_times>PSTH_BEFORE_TRIGGER & spike_arrival_times<PSTH_AFTER_TRIGGER);
			[histo,bins] = hist(spike_arrival_times_in,[PSTH_BEFORE_TRIGGER:PSTH_BIN:PSTH_AFTER_TRIGGER]);
			
			histo = (histo/PSTH_BIN)/PSTH_instr(p).n_trials; % convert PSTH y-axis to spikes/s
			histo_s_in = smooth(histo,1,1.5);
			if PLOT_UNSMOOTHED_HISTO, plot(bins,histo,instr_color); hold on; end
			plot(bins,histo_s_in,instr_color,'LineWidth',2);
			
			% plot raster and eye position
			if ~isempty(SPK_instr(ch,u,p).trial),
				switch SORT_TRIALS_BY
					case -1 % by saccade
						[dummy,sorted_idx] = sort([PSTH_instr(p).trial.saccade_onset]-PSTH_instr(p).align_time);
						PSTH_instr(p).trial = PSTH_instr(p).trial(sorted_idx);
						PSTH_instr(p).align_time = PSTH_instr(p).align_time(sorted_idx);
					otherwise
				end
				for k=1:PSTH_instr(p).n_trials,
					ig_make_raster(SPK_instr(ch,u,p).trial(k).spikes,RASTER_OFFSET+k,0.1,0,'Color',instr_color,'LineWidth',1); hold on;
					plot(PSTH_instr(p).trial(k).states_onset - PSTH_instr(p).align_time(k),RASTER_OFFSET+k,'ks','MarkerSize',2);
					plot(PSTH_instr(p).trial(k).reward_time - PSTH_instr(p).align_time(k),RASTER_OFFSET+k,'cv','MarkerSize',2);
					plot(PSTH_instr(p).trial(k).saccade_onset - PSTH_instr(p).align_time(k),RASTER_OFFSET+k,'mv','MarkerSize',2);
					
					
					plot(PSTH_instr(p).trial(k).eye_time,EYE_DISPLAY_OFFSET_MULTIPLIER(1)+PSTH_instr(p).trial(k).eye_hor*EYE_DISPLAY_OFFSET_MULTIPLIER(2),'Color',eye_hor_color); hold on;
					plot(PSTH_instr(p).trial(k).eye_time,EYE_DISPLAY_OFFSET_MULTIPLIER(1)+PSTH_instr(p).trial(k).eye_ver*EYE_DISPLAY_OFFSET_MULTIPLIER(2),'Color',eye_ver_color); hold on;
					
					if strcmp(task_effector,'reach')
						plot(PSTH_instr(p).trial(k).eye_time,EYE_DISPLAY_OFFSET_MULTIPLIER(1)+PSTH_instr(p).trial(k).hnd_hor*EYE_DISPLAY_OFFSET_MULTIPLIER(2),'Color',hnd_hor_color); hold on;
						plot(PSTH_instr(p).trial(k).eye_time,EYE_DISPLAY_OFFSET_MULTIPLIER(1)+PSTH_instr(p).trial(k).hnd_ver*EYE_DISPLAY_OFFSET_MULTIPLIER(2),'Color',hnd_ver_color); hold on;
					end
			
				end
				
				set(gca,'Ydir','normal','Xlim',[PSTH_BEFORE_TRIGGER PSTH_AFTER_TRIGGER]);
				line([PSTH_BEFORE_TRIGGER PSTH_AFTER_TRIGGER],[RASTER_OFFSET+k+0.2 RASTER_OFFSET+k+0.2],'Color',instr_color);
			end
					
	
			% CHOICE
			RASTER_OFFSET_choice = RASTER_OFFSET + PSTH_instr(p).n_trials; % put choice raster on top of instructed
			
			spike_arrival_times = SPK_choice(ch,u,p).all_spike_times;
			spike_arrival_times_ch = spike_arrival_times(spike_arrival_times>PSTH_BEFORE_TRIGGER & spike_arrival_times<PSTH_AFTER_TRIGGER);
			[histo,bins] = hist(spike_arrival_times_ch,[PSTH_BEFORE_TRIGGER:PSTH_BIN:PSTH_AFTER_TRIGGER]);
			
			histo = (histo/PSTH_BIN)/PSTH_choice(p).n_trials; % convert PSTH y-axis to spikes/s
			histo_s_ch = smooth(histo,1,1.5);
			if PLOT_UNSMOOTHED_HISTO, plot(bins,histo,choice_color); hold on; end
			plot(bins,histo_s_ch,choice_color,'LineWidth',2);
			
			% plot raster
			if ~isempty(SPK_choice(ch,u,p).trial),
				switch SORT_TRIALS_BY
					case -1 % by saccade
						[dummy,sorted_idx] = sort([PSTH_choice(p).trial.saccade_onset]-PSTH_choice(p).align_time);
						PSTH_choice(p).trial = PSTH_choice(p).trial(sorted_idx);
						PSTH_choice(p).align_time = PSTH_choice(p).align_time(sorted_idx);
					otherwise
				end
				
				for k=1:PSTH_choice(p).n_trials,
					ig_make_raster(SPK_choice(ch,u,p).trial(k).spikes,RASTER_OFFSET_choice+k,0.1,0,'Color',choice_color,'LineWidth',1); hold on;
					plot(PSTH_choice(p).trial(k).states_onset - PSTH_choice(p).align_time(k),RASTER_OFFSET_choice+k,'ks','MarkerSize',2);
					plot(PSTH_choice(p).trial(k).reward_time - PSTH_choice(p).align_time(k),RASTER_OFFSET_choice+k,'cv','MarkerSize',2);
					plot(PSTH_choice(p).trial(k).saccade_onset - PSTH_choice(p).align_time(k),RASTER_OFFSET_choice+k,'mv','MarkerSize',2);
					
					plot(PSTH_choice(p).trial(k).eye_time,EYE_DISPLAY_OFFSET_MULTIPLIER(1)+PSTH_choice(p).trial(k).eye_hor*EYE_DISPLAY_OFFSET_MULTIPLIER(2),'Color',eye_hor_color/1.5); hold on;
					plot(PSTH_choice(p).trial(k).eye_time,EYE_DISPLAY_OFFSET_MULTIPLIER(1)+PSTH_choice(p).trial(k).eye_ver*EYE_DISPLAY_OFFSET_MULTIPLIER(2),'Color',eye_ver_color/1.5); hold on;
					
					if strcmp(task_effector,'reach')
						plot(PSTH_choice(p).trial(k).eye_time,EYE_DISPLAY_OFFSET_MULTIPLIER(1)+PSTH_choice(p).trial(k).hnd_hor*EYE_DISPLAY_OFFSET_MULTIPLIER(2),'Color',hnd_hor_color/1.2); hold on;
						plot(PSTH_choice(p).trial(k).eye_time,EYE_DISPLAY_OFFSET_MULTIPLIER(1)+PSTH_choice(p).trial(k).hnd_ver*EYE_DISPLAY_OFFSET_MULTIPLIER(2),'Color',hnd_ver_color/1.2); hold on;
					end
								
				end
				set(gca,'Ydir','normal','Xlim',[PSTH_BEFORE_TRIGGER PSTH_AFTER_TRIGGER]);
				line([PSTH_BEFORE_TRIGGER PSTH_AFTER_TRIGGER],[RASTER_OFFSET_choice+k+0.2 RASTER_OFFSET_choice+k+0.2],'Color',choice_color);
			end
			
			
			title(sprintf('cue %.2f %.2f (pos %d), %d instr, %d choice trials',U_POS(p,:),p,PSTH_instr(p).n_trials,PSTH_choice(p).n_trials));
			xlabel('Time to trigger (s)');
			ylabel('Spikes/s');
			
			
			if U_POS(p,1) < 0, % left space
				n_l_pos = n_l_pos + 1;
				out.PSTH_l(n_l_pos).in = histo_s_in;
				out.PSTH_l(n_l_pos).ch = histo_s_ch;
				out.PSTH_l(n_l_pos).n_trials_in = PSTH_instr(p).n_trials;
				out.PSTH_l(n_l_pos).n_trials_ch = PSTH_choice(p).n_trials;
				out.SPK_l(n_l_pos).in = spike_arrival_times_in;
				out.SPK_l(n_l_pos).ch = spike_arrival_times_ch;
				
			elseif U_POS(p,1) > 0, % right space
				n_r_pos = n_r_pos + 1;
				out.PSTH_r(n_r_pos).in = histo_s_in;
				out.PSTH_r(n_r_pos).ch = histo_s_ch;
				out.PSTH_r(n_r_pos).n_trials_in = PSTH_instr(p).n_trials;
				out.PSTH_r(n_r_pos).n_trials_ch = PSTH_choice(p).n_trials;
				out.SPK_r(n_r_pos).in = spike_arrival_times_in;
				out.SPK_r(n_r_pos).ch = spike_arrival_times_ch;

			end
			
			mean_states_onset_in(p,:)		= get_mean_onset(PSTH_instr(p),'states_onset',n_states);
			mean_reward_onset_offset_in(p,:)	= get_mean_onset(PSTH_instr(p),'reward_time',2);
			mean_saccade_onset_in(p,:)		= get_mean_onset(PSTH_instr(p),'saccade_onset',1);
			
			mean_states_onset_ch(p,:)		= get_mean_onset(PSTH_choice(p),'states_onset',n_states);			
			mean_reward_onset_offset_ch(p,:)	= get_mean_onset(PSTH_choice(p),'reward_time',2);
			mean_saccade_onset_ch(p,:)		= get_mean_onset(PSTH_choice(p),'saccade_onset',1);
			
			% extract mean firing rates in pre-defined intervals
			for i = 1:size(FR_INTERVALS,1),
				
				[out.FR_instr(p,i).FR out.FR_instr(p,i).INT] = get_interval_FR(PSTH_instr,FR_INTERVALS(i,:),mean_states_onset_in,p,histo_s_in,bins);
				[out.FR_choice(p,i).FR out.FR_choice(p,i).INT] = get_interval_FR(PSTH_choice,FR_INTERVALS(i,:),mean_states_onset_ch,p,histo_s_ch,bins);

			end
	
						
		end % for each position
		out.PSTH_bins = bins;
		
		ig_set_axes_equal_lim;
		
		% add trial timing markers to PSTH (needs to go after ig_set_axes_equal_lim)
		for p=1:n_pos,
			
			set(gcf,'CurrentAxes',hs(p));
			if PSTH_instr(p).n_trials
				ig_add_multiple_vertical_lines(mean_states_onset_in(p,:),'Color',[0.5 0.5 0.8]);
				ig_add_multiple_vertical_lines(mean_reward_onset_offset_in(p,:),'Color',[0    0.7490    0.7490]);
					
				text(double(mean_states_onset_in(p,:)),-5*ones(size(mean_states_onset_in(p,:))),num2str(PSTH_instr(p).trial(1).states'),...
				'FontSize',6,'Color',[0.8706    0.4902         0]);
			end
			if PSTH_choice(p).n_trials				
				ig_add_multiple_vertical_lines(mean_states_onset_ch(p,:),'Color',[0.8 0.5 0.5]);
				ig_add_multiple_vertical_lines(mean_reward_onset_offset_ch(p,:),'Color',[0    0.7490    0.7490]);
			end
			add_trial_timing;
			
			
		end
		
		% unit summary
		switch task_type
			case 'direct'
				n_intervals = 6;
			case 'memory'
				n_intervals = 8;
		end
			
		sp_gap = [0.02 0.02];
		ig_figure('Name',sprintf('%s Summary Ch %d, unit %s, aligned to state %d, %s %s %s',runpath,ch,uname{u},ALIGN_STATE,task_type,task_effector,task_hand),...
			'Position',[100 100 1600 1200]);
		set(gcf, 'renderer', 'Zbuffer'); 
		% set(gcf, 'renderer', 'OpenGL');
		
		% Left | Right PSTH
		subtightplot(4,n_intervals,[1:n_intervals-2],sp_gap)

		% average PSTH - flawed if unequal amount of trials for each target location
		if 0
		hl(1) = ig_errorband(out.PSTH_bins,mean(cat(1,out.PSTH_l.in),1),sterr(cat(1,out.PSTH_l.in),1),1,'Color',[0.0784    0.1686    0.5490],'LineWidth',2); hold on
		hl(2) = ig_errorband(out.PSTH_bins,mean(cat(1,out.PSTH_l.ch),1),sterr(cat(1,out.PSTH_l.ch),1),1,'Color',[0.6000    0.2000         0],'LineWidth',2); hold on
		hl(3) = ig_errorband(out.PSTH_bins,mean(cat(1,out.PSTH_r.in),1),sterr(cat(1,out.PSTH_r.in),1),1,'Color',[0.2000    0.8000    1.0000],'LineWidth',2); hold on
		hl(4) = ig_errorband(out.PSTH_bins,mean(cat(1,out.PSTH_r.ch),1),sterr(cat(1,out.PSTH_r.ch),1),1,'Color',[1.0000    0.4000         0],'LineWidth',2); hold on
		end
		
		out.PSTH_l_in = spikes2psth(cat(2,out.SPK_l.in),out.PSTH_bins,0.02) / sum(cat(1,out.PSTH_l.n_trials_in));
		out.PSTH_l_ch = spikes2psth(cat(2,out.SPK_l.ch),out.PSTH_bins,0.02) / sum(cat(1,out.PSTH_l.n_trials_ch));
		out.PSTH_r_in = spikes2psth(cat(2,out.SPK_r.in),out.PSTH_bins,0.02) / sum(cat(1,out.PSTH_r.n_trials_in));
		out.PSTH_r_ch = spikes2psth(cat(2,out.SPK_r.ch),out.PSTH_bins,0.02) / sum(cat(1,out.PSTH_r.n_trials_ch));
		
		hl(1) = plot(out.PSTH_bins,out.PSTH_l_in,'Color',[0.0784    0.1686    0.5490],'LineWidth',2); hold on
		hl(2) = plot(out.PSTH_bins,out.PSTH_l_ch,'Color',[0.6000    0.2000         0],'LineWidth',2); hold on
		hl(3) = plot(out.PSTH_bins,out.PSTH_r_in,'Color',[0.2000    0.8000    1.0000],'LineWidth',2); hold on
		hl(4) = plot(out.PSTH_bins,out.PSTH_r_ch,'Color',[1.0000    0.4000         0],'LineWidth',2); hold on

		
		% plot FR intervals
		for i=1:size(FR_INTERVALS,1),
			int = mean(cat(1,out.FR_instr(:,i).INT),1);
			line(int,[0 0],'Color',int_color(i,:),'LineWidth',3);
			text(int(1)+0.05,1,get_state_name(FR_INTERVALS(i,1)),'Color',int_color(i,:),'HorizontalAlignment','Left','FontSize',7);
		end
		
		ig_add_multiple_vertical_lines(mean(mean_states_onset_in,1),'Color',[0.5 0.5 0.8]);
		ig_add_multiple_vertical_lines(mean(mean_states_onset_ch,1),'Color',[0.8 0.5 0.5]);
		ig_add_multiple_vertical_lines(mean(mean_reward_onset_offset_in,1),'Color',[0    0.7490    0.7490]);
		ig_add_multiple_vertical_lines(mean(mean_reward_onset_offset_ch,1),'Color',[0    0.7490    0.7490]);
		
		set(gca,'TickDir','out','box','off');
		
		legend(hl,{'left instr','left choice','right instr','right choice'},'Interpreter','none','Location','best');
		
		hs(3) = subtightplot(4,n_intervals,n_intervals-1,sp_gap);
		all_spikes_wf = cat(1,SPK_wf(ch,u).all{:});
		n_all_spikes_wf = size(all_spikes_wf,1);
		n_sel_spike_wf = length(1:50:n_all_spikes_wf);
		n_trials = length(SPK_wf(ch,u).all);
		
		set(gca,'ColorOrder',jet(n_sel_spike_wf)),hold on % early trials: blue, late trials: red
		plot(all_spikes_wf(1:50:end,:)');
		title(sprintf('%d out of %d spikes \n %d trials',n_sel_spike_wf,n_all_spikes_wf,n_trials));
		
		hs(4) = subtightplot(4,n_intervals,n_intervals,sp_gap);
		ig_errorband(1:1:size(all_spikes_wf,2),mean(all_spikes_wf,1),std(all_spikes_wf,0,1),1,'Color',ucolor(u),'LineWidth',1.5);
		set_axes_equal_lim(hs(3:4),'all');
		set(hs(3:4),'TickDir','out','box','off','Xlim',[0 30]);
		
		
		% FR heatmaps
		for i = 1:length(FR_INTERVALS),
			hi(i) = subtightplot(4,n_intervals,2*n_intervals+i,sp_gap); % cue interval
			plot_firing_rate_heatmap([out.FR_instr(:,i).FR]);
			title(FR_INTERVAL_NAMES{i},'Color',int_color(i,:));
			hc(i) = subtightplot(4,n_intervals,3*n_intervals+i,sp_gap); % memory interval
			plot_firing_rate_heatmap([out.FR_choice(:,i).FR]);
			
		end
		ig_set_caxis_equal_lim([hi hc]);
		axes(hi(1));
		hcol = colorbar('location','EastOutside');
		set(get(hcol,'title'),'String','Spikes/s');
		axes(hc(1));
		hcol = colorbar('location','EastOutside');
		set(get(hcol,'title'),'String','Spikes/s');
		
		
		% FR interval plots and stats
		
		
		
			
	end % for each unit
end % for each channel

function mean_onset = get_mean_onset(PSTH,fieldname,n_states)
if PSTH.n_trials,
	onset_matrix = cat(1,PSTH.trial.(fieldname)); % trials (rows) x states (col)
	onset_matrix = onset_matrix - repmat(PSTH.align_time',1,size(onset_matrix,2));
	mean_onset  = mean(onset_matrix,1);
else
	mean_onset = NaN(1,n_states);
end

function plot_firing_rate_heatmap(R,cb)
if nargin < 2,
	cb = 0;
end
X = shiftdim(reshape(R,4,3),1);
map = jet;
colormap(map);
X = [[X nan(size(X,1),1)] ; nan(1,size(X,2)+1)];
pcolor(X); set(gca,'Ydir','reverse');

if cb,
	hc = colorbar;
	set(get(hc,'title'),'String','Spikes/s');
end
axis equal; axis off; 


function [psth] = spikes2psth(spike_arrival_times,bins,sigma,resample_bin)
if nargin < 3,
	sigma = bins(2)-bins(1); % in s
end
if nargin < 4,
	resample_bin = bins(2)-bins(1);
end
binned1ms = hist(spike_arrival_times,bins(1):0.001:bins(end));
kernel = normpdf([-3*sigma:0.001:3*sigma],0,sigma);
psth = clean_convolve(binned1ms,kernel); % 1 ms sampling
if resample_bin ~= 1,
	% psth_binned = downsample(psth,fix(sigma*1000)); % no filtering
	psth = decimate(psth,fix(resample_bin*1000));
end
	

function [FR INT] = get_interval_FR(PSTH,FR_INTERVALS,mean_states_onset,p,histo_s,bins)
% FR_INTERVALS: "state start" "start" "state end" "end", start and end in s
% if state end is -1, next state after state start is taken

if PSTH(p).n_trials,
	state1_idx = find(PSTH(p).trial(1).states==FR_INTERVALS(1));
	state2_idx = find(PSTH(p).trial(1).states==FR_INTERVALS(3));	
	int1 = mean_states_onset(p,state1_idx)+FR_INTERVALS(2);
	if FR_INTERVALS(3)==-1,
		int2 = mean_states_onset(p,state1_idx+1)+FR_INTERVALS(4);
	else
		int2 = mean_states_onset(p,state2_idx)+FR_INTERVALS(4);
	end
	FR = mean(histo_s(bins>int1 & bins<int2));
	INT = [int1 int2];
else
	FR = NaN;
	INT = [NaN NaN];
end

function add_trial_timing
ig_add_multiple_vertical_lines(0,'Color','k');

function state_name = get_state_name(state)

STATE.INI_TRI = 1; % initialize trial
STATE.FIX_ACQ = 2; % fixation acquisition
STATE.FIX_HOL = 3; % fixation hold
STATE.TAR_ACQ = 4; % target acquisition
STATE.TAR_HOL = 5; % target hold
STATE.CUE_ON  = 6; % cue on
STATE.MEM_PER = 7; % memory period
STATE.DEL_PER = 8; % delay period
STATE.TAR_ACQ_INV = 9; % target acquisition invisible
STATE.TAR_HOL_INV = 10; % target hold invisible
STATE.MAT_ACQ = 11; % target acquisition in sample to match
STATE.MAT_HOL = 12; % target acquisition in sample to match
STATE.MAT_ACQ_MSK = 13; % target acquisition in sample to match
STATE.MAT_HOL_MSK = 14; % target acquisition in sample to match
STATE.SEN_RET     = 15; % return to sensors for poffenberger
STATE.ABORT     = 19;
STATE.SUCCESS   = 20;
STATE.REWARD    = 21;
STATE.ITI       = 50;
STATE.CLOSE     = 99;

fnames = fieldnames(STATE);
state_name = lower(fnames(struct2array(STATE)==state));
state_name = strrep(state_name,'_',' ');


