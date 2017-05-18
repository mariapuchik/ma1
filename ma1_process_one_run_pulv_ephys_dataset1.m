function [n_unit,out] = ma1_process_one_run_pulv_ephys_dataset1(runpath, varargin)
% ma1_process_one_run_pulv_ephys_dataset1('Lincombined2015-09-16_05_block_04.mat','ma1_custom_settings_example');
% ma1_process_one_run_pulv_ephys_dataset1('X:\Data\Linus_phys_combined_monkeypsych_TDT\20150508\Lincombined2015-05-08_09_block_02.mat','sorting_table','F:\Dropbox\DAG\phys\Linus_phys_dpz\Lin_sorted_neurons_20150508_to_20160120.xlsx');

% Processing log
% up to PNM2016

% FR_EPOCHS	= [1 -0.3 2 0; 2 0 3 0.15; 3 0.2 -1 0; 4 0 5 -0.025; 5 -0.025 5 0.1; 5 0.1 -1 0];
% FR_EPOCH_NAMES	= {'ITI',      'fix acq',  'fix hold', 'pre-sac',   'peri-sac',     'post-sac'};
% settings.first_spatial_epoch = 4;
% 
% FR_EPOCHS	= [1 -0.3 2 0; 2 0 3 0.15; 3 0.2 -1 0; 6 0.05 -1 0; 7 0.2 -1 0; 9 0 10 -0.025; 10 -0.025 10 0.1; 5 0 -1 0];
% FR_EPOCH_NAMES	= {'ITI',     'fix acq',   'fix hold', 'cue',      'mem',       'pre-sac',    'peri-sac',       'post-sac'};
% settings.first_spatial_epoch = 4;


% default parameters
defpar = { ...
	'successful_trials_only',	'logical',	'nonempty',	true; ...
	'plot_trials',			'logical',	'nonempty',	false; ...
	'plot_summary',			'logical',	'nonempty',	true; ...
	'save_figures',			'char',		'nonempty',	''; ... % '-dpng', ...
	'figname_prefix',		'char',		'nonempty',	''; ...
	'batch_counter',		'double',	'nonempty',	0; ...
	'sorting_table',		'char',		'nonempty',	''; ...
	'sorting_sheet',		'char',		'nonempty',	''; ...
	};

if nargin > 1, % specified parameters
	if ~isstruct(varargin{1}),
		if length(varargin)==1, % specificed .m file with settings, as ma1_custom_settings_example.m
			run(varargin{1});
			par = struct(settings{:});
		else % parameter-value pair(s)
			par = struct(varargin{:});
		end
	else
		par = varargin{1};
	end
	par = checkstruct(par, defpar);
else
	par = checkstruct(struct, defpar);
end	


%% SETTING

settings.align_state		= []; % if empty, derived from task type
settings.psth_bin		= 0.02; % s
settings.sigma			= 0.02; % s.d. of smoothing gaussian kernel 
settings.psth_before_align	= -1; % s
settings.psth_after_align	= []; % s, if empty, derived from task type
settings.exclude_channels	= [4:6];
settings.use_TDT_states = 1;
settings.detect_saccades = 1;
settings.sort_trials = 0; % 0 - do not sort, STATE number - by this state, -1 - by saccade onset
settings.append_previous_trial_spikes = 1; % append spikes from previous trial to beginning of the current trial
% see https://drive.google.com/open?id=1Ae7OnZuQN00sPL7mlINuDRvAmsHGEJ1kh9vLNaELaW4

%% END OF SETTINGS


load(runpath);
% disp(runpath);


%% Time epochs for each task
switch trial(1).type,
	
	case 2,
		if isempty(settings.align_state),
			settings.align_state = 4;
		end
		settings.psth_after_align = 2;
		settings.task_type = 'direct';
		RESPONSE_STATE = 4;
		
		% for each epoch, 4 elements: "state start" "start" "state end" "end", start and end in s
		% if state end is -1, next state after state start is taken
		FR_EPOCHS	= [1 -0.3 2 0; 2 0 3 0.15; 3 0.2 -1 0; 4 0 5 -0.025; 5 -0.025 5 0.1; 5 0.1 -1 0]; 
		FR_EPOCH_NAMES	= {'ITI',      'fix acq',  'fix hold', 'pre-sac',   'peri-sac',     'post-sac'};
		settings.first_spatial_epoch = 4;
		
	case 3,
		if isempty(settings.align_state),
			settings.align_state = 6;
		end
		settings.psth_after_align = 3;
		settings.task_type = 'memory';
		RESPONSE_STATE = 9;
		
		FR_EPOCHS	= [1 -0.3 2 0; 2 0 3 0.15; 3 0.2 -1 0; 6 0.05 -1 0; 7 0.2 -1 0; 9 0 10 -0.025; 10 -0.025 10 0.1; 5 0 -1 0]; 
		FR_EPOCH_NAMES	= {'ITI',     'fix acq',   'fix hold', 'cue',      'mem',       'pre-sac',    'peri-sac',       'post-sac'};
		settings.first_spatial_epoch = 4;
end

settings.FR_epochs	= FR_EPOCHS;
settings.FR_epoch_names	= FR_EPOCH_NAMES;

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

% GRAPHIC SETTINGS
RASTER_OFFSET = 50; % spikes/s, start of raster on the y-axis
EYE_DISPLAY_OFFSET_MULTIPLIER = [100 0.5];
PLOT_UNSMOOTHED_HISTO = 0;
anova_display = 'off';

ucolor = ['r','g','b','m','c','k'];
uname = {'a' 'b' 'c' 'd' 'e' 'f'};
trial_type = {'instr' 'choice'};

instr_color = 'b';
choice_color = 'r';

eye_ver_color = [0.4000         0    0.6000];
eye_hor_color = [ 0    0.4980         0];
hnd_ver_color = [0.3490    0.2000    0.3294];
hnd_hor_color = [0.0706    0.2118    0.1412];

psth_colormap = [0.0784    0.1686    0.5490;...		% instr l
		0.6000    0.2000         0;...		% choice l
		0.2000    0.8000    1.0000;...		% instr r
		1.0000    0.4000         0];		% choice r

int_color = copper(length(FR_EPOCHS)+2);
% END GRAPHIC SETTINGS
 

if ~isempty(settings.exclude_channels), % remove unwanted channels
	channels2take = setdiff(1:size(trial(1).TDT_eNeu_t,1),settings.exclude_channels);
	trial(1).TDT_eNeu_t = trial(1).TDT_eNeu_t(channels2take,:);
end
	
n_chans = size(trial(1).TDT_eNeu_t,1);
n_units = size(trial(1).TDT_eNeu_t,2); % maximal number of units across all channels
n_units_per_channel(1:n_chans) = deal(0);


% make a quick loop to find unique cue positions, and number of units per channel (UGLY SOLITION!)
SEL_POS = []; % cue positions per selected trial
for k = 1:length(trial),
	if (par.successful_trials_only && trial(k).success) || ~par.successful_trials_only
		
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

% resort cue positions so that subplots visually correspond to spatial locations
switch n_pos
	case 6
		resort_idx = [3 5 1 6 2 4]; n_subplot_col = 2;
	case 12
		resort_idx = [3 6 8 11 1 4 9 12 2 5 7 10]; n_subplot_col = 4;
	otherwise
		disp(sprintf('%s: unknown number of target positions',runpath)); return;
end
U_POS = single(U_POS(resort_idx,:)); % use single to address crazy precision bug


% Need to initialize only those variables that are used for counter (e.g. var = var + 1) or vector accumulation (var = [var new_var])
% other fields do not require initialization

% PSTH contains non-unit-specific data (common for all units and all channels): states, eye mov, rew, etc.
[PSTH_instr(1:n_pos).n_trials] = deal(0);
[PSTH_instr(1:n_pos).align_time] = deal([]);

% SPK contains unit-specific spike data
[SPK_instr(1:n_chans,1:n_units,1:n_pos).all_spike_times] = deal([]);
[SPK_instr(1:n_chans,1:n_units,1:n_pos).trial] = deal([]);

[PSTH_choice(1:n_pos).n_trials] = deal(0);
[PSTH_choice(1:n_pos).align_time] = deal([]);
[SPK_choice(1:n_chans,1:n_units,1:n_pos).all_spike_times] = deal([]);
[SPK_choice(1:n_chans,1:n_units,1:n_pos).trial] = deal([]);





if par.plot_trials,
	hft = figure('Name','Plot trial','Position',[500 500 1200 800],'CurrentChar',' ');
end

valid_trial_idx = 0;
for k = 1:length(trial),

	
	if (par.successful_trials_only && trial(k).success) || ~par.successful_trials_only
		valid_trial_idx = valid_trial_idx + 1;
		
		if settings.use_TDT_states, % use TDT states and not monkeypsych states
			
			trial(k).use_states = trial(k).TDT_states(1:end-1)'; % exclude state 1 for next trial
			trial(k).use_states_onset = trial(k).TDT_state_onsets(1:end-1)'; % TDT states are already aligned to trial start (state 2)
			
			if k > 1,
				% patch for X:\Data\Linus_phys_combined_monkeypsych_TDT\20150910\Lincombined2015-09-10_05_block_04.mat
				if length(trial(k).use_states)<length(trial(k-1).use_states)
					trial(k).use_states = trial(k).TDT_states(1:end)'; 
					trial(k).use_states_onset = trial(k).TDT_state_onsets(1:end)';
				end
			end
			
		else
			trial(k).use_states = trial(k).states;
			trial(k).use_states_onset = trial(k).states_onset - trial(k).tSample_from_time_start(1);
		end
			
		n_states = length(trial(k).use_states);
		
		% align time axis to trial start
		trial(k).initial_tSample_from_time_start = trial(k).tSample_from_time_start(1); % time from run start 
		trial(k).tSample_from_time_start = trial(k).tSample_from_time_start - trial(k).tSample_from_time_start(1);
		
		align_state_idx = find(trial(k).use_states == settings.align_state);
		
		% reward TTL from TDT
		reward_time_axis = (0:length(trial(k).TDT_RWRD)-1)/trial(k).TDT_RWRD_samplingrate;
		if ~isempty(reward_time_axis)
			trial(k).TDT_stream_duration_from_state2 = reward_time_axis(end);
		
			reward_time = reward_time_axis(trial(k).TDT_RWRD>0);
			if ~isempty(reward_time),
				reward_time = [reward_time(1) reward_time(end)];
			else
				reward_time = [];
			end
		else % bug?, e.g. Lincombined2015-06-26_04_block_03.mat
			reward_time = [];
		end
			
		
		if strcmp(task_effector,'sac'),
			trial_cue_pos_idx = find(ismember(U_POS,trial(k).eye(1).cue(trial(k).target_selected(1)).pos(1:2),'rows'));
		else
			trial_cue_pos_idx = find(ismember(U_POS,trial(k).hnd(1).cue(trial(k).target_selected(2)).pos(1:2),'rows'));
		end
		
		trial(k).saccade_onset = NaN;
		if settings.detect_saccades,
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
		
		if par.plot_trials,
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
			
			if settings.detect_saccades,
				ig_add_multiple_vertical_lines(trial(k).saccade_onset,'Color','m','LineStyle',':');
			end
			
			figure(hft);
			subplot(2,1,2); hold on;
		end
		
		for ch=1:n_chans,
			for u = 1:n_units_per_channel(ch), % n_units,
				
				if ~isempty(trial(k).TDT_eNeu_t{ch,u}), % there are spikes in this trial
					trial_spike_arrival_times = trial(k).TDT_eNeu_t{ch,u}';
					if settings.append_previous_trial_spikes && k>1,
						prev_trial_spike_arrival_times = trial(k-1).TDT_eNeu_t{ch,u}' - ...
							trial(k-1).TDT_state_onsets(end) + trial(k).TDT_state_onsets(1);
						trial_spike_arrival_times = [prev_trial_spike_arrival_times trial_spike_arrival_times];
					end
					if par.plot_trials, 
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
							% firing rate per epoch
							SPK_instr(ch,u,trial_cue_pos_idx).trial(PSTH_instr(trial_cue_pos_idx).n_trials).FR_int = ...
								spk2FR_epoch(SPK_instr(ch,u,trial_cue_pos_idx).trial(PSTH_instr(trial_cue_pos_idx).n_trials).spikes,...
										trial(k).use_states, trial(k).use_states_onset - trial(k).use_states_onset(align_state_idx),...
										settings);
							
						case 1
							% all spike arrival times in one concatenated vector
							SPK_choice(ch,u,trial_cue_pos_idx).all_spike_times = [SPK_choice(ch,u,trial_cue_pos_idx).all_spike_times ...
								trial_spike_arrival_times - trial(k).use_states_onset(align_state_idx)]; % aligned to align_state_onset
							% spikes by trial
							SPK_choice(ch,u,trial_cue_pos_idx).trial(PSTH_choice(trial_cue_pos_idx).n_trials).spikes = ...
								[trial_spike_arrival_times - trial(k).use_states_onset(align_state_idx)]; % aligned to align_state_onset
							% firing rate per epoch
							SPK_choice(ch,u,trial_cue_pos_idx).trial(PSTH_choice(trial_cue_pos_idx).n_trials).FR_int = ...
								spk2FR_epoch(SPK_choice(ch,u,trial_cue_pos_idx).trial(PSTH_choice(trial_cue_pos_idx).n_trials).spikes,...
										trial(k).use_states, trial(k).use_states_onset - trial(k).use_states_onset(align_state_idx),...
										settings);
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
							SPK_instr(ch,u,trial_cue_pos_idx).trial(PSTH_instr(trial_cue_pos_idx).n_trials).FR_int = ...
								zeros(1,size(settings.FR_epochs,1)); % aligned to align_state_onset
							
						case 1
							SPK_choice(ch,u,trial_cue_pos_idx).trial(PSTH_choice(trial_cue_pos_idx).n_trials).spikes = ...
								[]; % aligned to align_state_onset
							SPK_choice(ch,u,trial_cue_pos_idx).trial(PSTH_choice(trial_cue_pos_idx).n_trials).FR_int = ...
								zeros(1,size(settings.FR_epochs,1)); % aligned to align_state_onset
					end
					
				end
				
			end
			
			if par.plot_trials
				ig_add_multiple_vertical_lines(trial(k).states_onset - trial(k).initial_tSample_from_time_start,'Color','k');
				if settings.use_TDT_states,
					ig_add_multiple_vertical_lines(trial(k).TDT_state_onsets','Color','c','LineStyle',':');
					text(trial(k).TDT_state_onsets,-0.2*ones(size(trial(k).TDT_state_onsets)),num2str(trial(k).TDT_states),...
					'FontSize',8,'Color',[0.8706    0.4902         0]);
			
				end
				

			end
		end % of for each channel
		

		if par.plot_trials,
			if settings.use_TDT_states,
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

if par.plot_summary, % summary figures

n_unit = 0;
for ch=1:n_chans,
	
	for u = 1:n_units_per_channel(ch),
		n_l_pos = 0; % counter for left positions
		n_r_pos = 0; % counter for right positions
		n_unit = n_unit + 1;
		
		slash_idx	= strfind(runpath,'\');
		us_idx		= strfind(runpath,'_');
		current_unit.date	= runpath(slash_idx(end-1)+1:slash_idx(end)-1);
		current_unit.run	= str2num(runpath(us_idx(end-2)+1:us_idx(end-1)-1));
		current_unit.block	= str2num(runpath(us_idx(end)+1:us_idx(end)+2));
		current_unit.channel	= ch;
		current_unit.uname	= uname{u};
		
		current_unit = ma1_get_unit_from_sorting_table(current_unit,par.sorting_table,par.sorting_sheet);
		
		hf1 = ig_figure('Name',sprintf('%s ch%d, unit %s, aligned to state %d, %s %s %s %s',...
			runpath,ch,uname{u},settings.align_state,settings.task_type,task_effector,task_hand,current_unit.Neuron_ID{:}),'Position',[100 100 1600 1200],'PaperPositionMode', 'auto');
		for p = 1:n_pos,
			hs(p) = subplot(n_pos/n_subplot_col,n_subplot_col,p);
			
			% INSTRUCTED
			spike_arrival_times = SPK_instr(ch,u,p).all_spike_times;
			spike_arrival_times_in = spike_arrival_times(spike_arrival_times>settings.psth_before_align & spike_arrival_times<settings.psth_after_align);
			[histo,bins] = hist(spike_arrival_times_in,[settings.psth_before_align:settings.psth_bin:settings.psth_after_align]);
			
			histo = (histo/settings.psth_bin)/PSTH_instr(p).n_trials; % convert PSTH y-axis to spikes/s
			histo_s_in = smooth(histo,1,1.5);
			if PLOT_UNSMOOTHED_HISTO, plot(bins,histo,instr_color); hold on; end
			plot(bins,histo_s_in,instr_color,'LineWidth',2);
			
			% plot raster and eye position
			if ~isempty(SPK_instr(ch,u,p).trial),
				switch settings.sort_trials
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
				
				set(gca,'Ydir','normal','Xlim',[settings.psth_before_align settings.psth_after_align]);
				line([settings.psth_before_align settings.psth_after_align],[RASTER_OFFSET+k+0.2 RASTER_OFFSET+k+0.2],'Color',instr_color);
			end
					
	
			% CHOICE
			RASTER_OFFSET_choice = RASTER_OFFSET + PSTH_instr(p).n_trials; % put choice raster on top of instructed
			
			spike_arrival_times = SPK_choice(ch,u,p).all_spike_times;
			spike_arrival_times_ch = spike_arrival_times(spike_arrival_times>settings.psth_before_align & spike_arrival_times<settings.psth_after_align);
			[histo,bins] = hist(spike_arrival_times_ch,[settings.psth_before_align:settings.psth_bin:settings.psth_after_align]);
			
			histo = (histo/settings.psth_bin)/PSTH_choice(p).n_trials; % convert PSTH y-axis to spikes/s
			histo_s_ch = smooth(histo,1,1.5);
			if PLOT_UNSMOOTHED_HISTO, plot(bins,histo,choice_color); hold on; end
			plot(bins,histo_s_ch,choice_color,'LineWidth',2);
			
			% plot raster
			if ~isempty(SPK_choice(ch,u,p).trial),
				switch settings.sort_trials
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
				set(gca,'Ydir','normal','Xlim',[settings.psth_before_align settings.psth_after_align]);
				line([settings.psth_before_align settings.psth_after_align],[RASTER_OFFSET_choice+k+0.2 RASTER_OFFSET_choice+k+0.2],'Color',choice_color);
			end
			
			
			title(sprintf('cue %.2f %.2f (pos %d), %d instr, %d choice trials',U_POS(p,:),p,PSTH_instr(p).n_trials,PSTH_choice(p).n_trials));
			xlabel('Time to trigger (s)');
			ylabel('Spikes/s');
			
			% mean onsets are aligned to trigger state
			PSTH_instr(p).mean_states_onset		= get_mean_onset(PSTH_instr(p),'states_onset',n_states);
			PSTH_instr(p).mean_reward_onset_offset	= get_mean_onset(PSTH_instr(p),'reward_time',2);
			PSTH_instr(p).mean_saccade_onset	= get_mean_onset(PSTH_instr(p),'saccade_onset',1);
			
			PSTH_choice(p).mean_states_onset	= get_mean_onset(PSTH_choice(p),'states_onset',n_states);
			PSTH_choice(p).mean_reward_onset_offset	= get_mean_onset(PSTH_choice(p),'reward_time',2);
			PSTH_choice(p).mean_saccade_onset	= get_mean_onset(PSTH_choice(p),'saccade_onset',1);
			
			% extract mean firing rates in pre-defined epochs, from PSTH
			for i = 1:size(FR_EPOCHS,1),				
				[out.FR_psth_instr(p,i).FR out.FR_psth_instr(p,i).INT]		= get_epoch_mean_FR(PSTH_instr,FR_EPOCHS(i,:),p,histo_s_in,bins);
				[out.FR_psth_choice(p,i).FR out.FR_psth_choice(p,i).INT]	= get_epoch_mean_FR(PSTH_choice,FR_EPOCHS(i,:),p,histo_s_ch,bins);
			end
			
			% Left/right space re-formatting
			if U_POS(p,1) < 0, % left space
				n_l_pos = n_l_pos + 1;
				out.PSTH_l(n_l_pos).in = histo_s_in;
				out.PSTH_l(n_l_pos).ch = histo_s_ch;
				out.PSTH_l(n_l_pos).n_trials_in = PSTH_instr(p).n_trials;
				out.PSTH_l(n_l_pos).n_trials_ch = PSTH_choice(p).n_trials;
				out.PSTH_l(n_l_pos).pos = U_POS(p,:);
				
				out.SPK_l(n_l_pos).in = spike_arrival_times_in;
				out.SPK_l(n_l_pos).ch = spike_arrival_times_ch;
				
				if ~isempty(SPK_instr(ch,u,p).trial)
					out.FR_l(n_l_pos).in = cat(1,SPK_instr(ch,u,p).trial.FR_int);
				end
				if ~isempty(SPK_choice(ch,u,p).trial)
					out.FR_l(n_l_pos).ch = cat(1,SPK_choice(ch,u,p).trial.FR_int);
				end
							
				
			elseif U_POS(p,1) > 0, % right space
				n_r_pos = n_r_pos + 1;
				out.PSTH_r(n_r_pos).in = histo_s_in;
				out.PSTH_r(n_r_pos).ch = histo_s_ch;
				out.PSTH_r(n_r_pos).n_trials_in = PSTH_instr(p).n_trials;
				out.PSTH_r(n_r_pos).n_trials_ch = PSTH_choice(p).n_trials;
				out.PSTH_r(n_r_pos).pos = U_POS(p,:);
				
				out.SPK_r(n_r_pos).in = spike_arrival_times_in;
				out.SPK_r(n_r_pos).ch = spike_arrival_times_ch;
				
				if ~isempty(SPK_instr(ch,u,p).trial)
					out.FR_r(n_r_pos).in = cat(1,SPK_instr(ch,u,p).trial.FR_int);
				end
				if ~isempty(SPK_choice(ch,u,p).trial)
					out.FR_r(n_r_pos).ch = cat(1,SPK_choice(ch,u,p).trial.FR_int);
				end
					

			end
			
						
		end % for each position
		out.PSTH_bins = bins;
		
		ig_set_axes_equal_lim;
		
		% add trial timing markers to PSTH (needs to go after ig_set_axes_equal_lim)
		for p=1:n_pos,
			
			set(gcf,'CurrentAxes',hs(p));
			if PSTH_instr(p).n_trials
				ig_add_multiple_vertical_lines(PSTH_instr(p).mean_states_onset,'Color',[0.5 0.5 0.8]);
				ig_add_multiple_vertical_lines(PSTH_instr(p).mean_reward_onset_offset,'Color',[0    0.7490    0.7490]);
					
				text(double(PSTH_instr(p).mean_states_onset),-5*ones(size(PSTH_instr(p).mean_states_onset)),num2str(PSTH_instr(p).trial(1).states'),...
				'FontSize',6,'Color',[0.8706    0.4902         0]);
			end
			if PSTH_choice(p).n_trials				
				ig_add_multiple_vertical_lines(PSTH_choice(p).mean_states_onset,'Color',[0.8 0.5 0.5]);
				ig_add_multiple_vertical_lines(PSTH_choice(p).mean_reward_onset_offset,'Color',[0    0.7490    0.7490]);
			end
			add_trial_timing;
			
			
		end
		

		n_epochs = length(FR_EPOCH_NAMES);
			
		sp_gap = [0.02 0.02]; % subplot gap
		hf2 = ig_figure('Name',sprintf('%s Summary ch%d, unit %s, aligned to state %d, %s %s %s %s',...
			runpath,ch,uname{u},settings.align_state,settings.task_type,task_effector,task_hand,current_unit.Neuron_ID{:}),...
			'Position',[100 100 1600 1200],'PaperPositionMode', 'auto');
		set(gcf, 'renderer', 'Zbuffer'); 
		% set(gcf, 'renderer', 'OpenGL');
		
		% Left | Right PSTH
		subtightplot(4,n_epochs,[1:n_epochs-2],sp_gap)

		% average across individual target PSTHs - flawed if unequal amount of trials for each target location
% 		if 0
% 		hl(1) = ig_errorband(out.PSTH_bins,mean(cat(1,out.PSTH_l.in),1),sterr(cat(1,out.PSTH_l.in),1),1,'Color',[0.0784    0.1686    0.5490],'LineWidth',2); hold on
% 		hl(2) = ig_errorband(out.PSTH_bins,mean(cat(1,out.PSTH_l.ch),1),sterr(cat(1,out.PSTH_l.ch),1),1,'Color',[0.6000    0.2000         0],'LineWidth',2); hold on
% 		hl(3) = ig_errorband(out.PSTH_bins,mean(cat(1,out.PSTH_r.in),1),sterr(cat(1,out.PSTH_r.in),1),1,'Color',[0.2000    0.8000    1.0000],'LineWidth',2); hold on
% 		hl(4) = ig_errorband(out.PSTH_bins,mean(cat(1,out.PSTH_r.ch),1),sterr(cat(1,out.PSTH_r.ch),1),1,'Color',[1.0000    0.4000         0],'LineWidth',2); hold on
% 		end
		
		out.n_trials.in_l = sum(cat(1,out.PSTH_l.n_trials_in));
		out.n_trials.ch_l = sum(cat(1,out.PSTH_l.n_trials_ch));
		out.n_trials.in_r = sum(cat(1,out.PSTH_r.n_trials_in));
		out.n_trials.ch_r = sum(cat(1,out.PSTH_r.n_trials_ch));
		
		% average across left/right trials (not across individual target PSTHs)
		out.PSTH_l_in = spikes2psth(cat(2,out.SPK_l.in),out.PSTH_bins,settings.sigma) / out.n_trials.in_l;
		out.PSTH_l_ch = spikes2psth(cat(2,out.SPK_l.ch),out.PSTH_bins,settings.sigma) / out.n_trials.ch_l;
		out.PSTH_r_in = spikes2psth(cat(2,out.SPK_r.in),out.PSTH_bins,settings.sigma) / out.n_trials.in_r;
		out.PSTH_r_ch = spikes2psth(cat(2,out.SPK_r.ch),out.PSTH_bins,settings.sigma) / out.n_trials.ch_r;
		
		hl(1) = plot(out.PSTH_bins,out.PSTH_l_in,'Color',psth_colormap(1,:),'LineWidth',2); hold on
		hl(2) = plot(out.PSTH_bins,out.PSTH_l_ch,'Color',psth_colormap(2,:),'LineWidth',2); hold on
		hl(3) = plot(out.PSTH_bins,out.PSTH_r_in,'Color',psth_colormap(3,:),'LineWidth',2); hold on
		hl(4) = plot(out.PSTH_bins,out.PSTH_r_ch,'Color',psth_colormap(4,:),'LineWidth',2); hold on

		
		% plot FR epochs on the time axis
		for i=1:size(FR_EPOCHS,1),
			int = mean(cat(1,out.FR_psth_instr(:,i).INT),1);
			line(int,[0 0],'Color',int_color(i,:),'LineWidth',4);
			% text(int(1)+0.05,1,get_state_name(FR_EPOCHS(i,1)),'Color',int_color(i,:),'HorizontalAlignment','Left','FontSize',7);
			text(int(1)+0.05,1,FR_EPOCH_NAMES{i},'Color',int_color(i,:),'HorizontalAlignment','Left','FontSize',7);
		end
		
		ig_add_multiple_vertical_lines(mean(cat(1,PSTH_instr.mean_states_onset),1),'Color',[0.5 0.5 0.8]);
		ig_add_multiple_vertical_lines(mean(cat(1,PSTH_choice.mean_states_onset),1),'Color',[0.8 0.5 0.5]);
		ig_add_multiple_vertical_lines(mean(cat(1,PSTH_instr.mean_reward_onset_offset),1),'Color',[0    0.7490    0.7490]);
		ig_add_multiple_vertical_lines(mean(cat(1,PSTH_choice.mean_reward_onset_offset),1),'Color',[0    0.7490    0.7490]);
		
		ylim = get(gca,'Ylim');
		set(gca,'TickDir','out','box','off','Ylim',[0 ylim(2)]);
		
		legend(hl,{['l in ' num2str(out.n_trials.in_l)],['l ch ' num2str(out.n_trials.ch_l)],['r in ' num2str(out.n_trials.in_r)],['r ch ' num2str(out.n_trials.ch_r)]},...
			'Interpreter','none','Location','best');
		title(sprintf('%s %s ch%d  %s',settings.task_type,runpath,ch,uname{u}),'Interpreter','none');
		
		% WAVEFORMS
		hs(3) = subtightplot(4,n_epochs,n_epochs-1,sp_gap);
		all_spikes_wf = cat(1,SPK_wf(ch,u).all{:});
		n_all_spikes_wf = size(all_spikes_wf,1);
		n_sel_spike_wf = length(1:50:n_all_spikes_wf);
		n_trials = length(SPK_wf(ch,u).all);
		
		set(gca,'ColorOrder',jet(n_sel_spike_wf)),hold on % early trials: blue, late trials: red
		plot(all_spikes_wf(1:50:end,:)');
		title(sprintf('%d out of %d spikes \n %d trials',n_sel_spike_wf,n_all_spikes_wf,n_trials));
		
		hs(4) = subtightplot(4,n_epochs,n_epochs,sp_gap);
		ig_errorband(1:1:size(all_spikes_wf,2),mean(all_spikes_wf,1),std(all_spikes_wf,0,1),1,'Color',ucolor(u),'LineWidth',1.5);
		set_axes_equal_lim(hs(3:4),'all');
		set(hs(3:4),'TickDir','out','box','off','Xlim',[0 30]);
		
		% FR left/right			
		
		FR_i_l = cat(1,out.FR_l.in); % matrix trial x epoch
		FR_i_l_mean = mean(FR_i_l,1);
		FR_i_l_se = sterr(FR_i_l,1);
		n_i_l = size(FR_i_l,1);
		
		FR_i_r = cat(1,out.FR_r.in);
		FR_i_r_mean = mean(FR_i_r,1);
		FR_i_r_se = sterr(FR_i_r,1);
		n_i_r = size(FR_i_r,1);
		
		FR_c_l = cat(1,out.FR_l.ch);
		FR_c_l_mean = mean(FR_c_l,1);
		FR_c_l_se = sterr(FR_c_l,1);
		n_c_l = size(FR_c_l,1);
		
		FR_c_r = cat(1,out.FR_r.ch);
		FR_c_r_mean = mean(FR_c_r,1);
		FR_c_r_se = sterr(FR_c_r,1);
		n_c_r = size(FR_c_r,1);
		
		% need to transpose so that when making a vector for anova all epochs are in one column in the following way: 
		% trial 1 int 1...n, trial 2 int 1...n
		FR_i_l = FR_i_l';
		FR_c_l = FR_c_l';
		FR_i_r = FR_i_r';
		FR_c_r = FR_c_r';

% 		% 3-way anova: space x trial type x epoch
% 		space = [zeros(1,(n_i_l+n_c_l)*n_epochs) ones(1,(n_i_r+n_c_r)*n_epochs)]';
% 		ttype = [zeros(1,n_i_l*n_epochs) ones(1,n_c_l*n_epochs) zeros(1,n_i_r*n_epochs) ones(1,n_c_r*n_epochs)]';
% 		epoch = repmat([1:n_epochs]',sum([n_i_l n_c_l n_i_r n_c_r]) ,1);
% 		
% 		[p,table,stats,terms] = anovan([FR_i_l(:) ; FR_c_l(:) ; FR_i_r(:) ; FR_c_r(:)],[space ttype epoch],... % all epochs in one column: trial 1 int 1-n, trial 2 int 1-n
% 			'model','full','varnames',{'space' 'type' 'epoch'},'display',anova_display);
		
		% 2-way anova: space x epoch INSTR
		[ANOVA_i.p,ANOVA_i.table,ANOVA_i.stats,ANOVA_i.terms] = anovan([FR_i_l(:) ; FR_i_r(:)],[[zeros(1,(n_i_l)*n_epochs) ones(1,(n_i_r)*n_epochs)]' repmat([1:n_epochs]',sum([n_i_l n_i_r]) ,1)],...
			'model','full','varnames',{'space' 'epoch'},'display',anova_display);
				
		% 2-way anova: space x epoch CHOICE
		[ANOVA_c.p,ANOVA_c.table,ANOVA_c.stats,ANOVA_c.terms] = anovan([FR_c_l(:) ; FR_c_r(:)],[[zeros(1,(n_c_l)*n_epochs) ones(1,(n_c_r)*n_epochs)]' repmat([1:n_epochs]',sum([n_c_l n_c_r]) ,1)],...
			'model','full','varnames',{'space' 'epoch'},'display',anova_display);
		
		
		% decide about task (epoch) modulation and spatial tuning
		alpha = 0.05;
		ANOVA_i.epoch_main_effect = ANOVA_i.p(2) < alpha;
		ANOVA_i.space_main_effect = ANOVA_i.p(1) < alpha;
		ANOVA_i.space_epoch_inter = ANOVA_i.p(3) < alpha;
		ANOVA_i.epoch_modulation	= analyze_epoch_modulation(ANOVA_i,settings,FR_i_l,FR_i_r);
		ANOVA_i.space_tuning		= analyze_space_tuning(ANOVA_i,settings,FR_i_l,FR_i_r);
		

		out.ANOVA_i = ANOVA_i;
		out.ANOVA_c = ANOVA_c;

		subtightplot(4,n_epochs,n_epochs+1:2*n_epochs,sp_gap+0.02);
		[handles,x_axis,y,e] = barweb([FR_i_l_mean' FR_c_l_mean' FR_i_r_mean' FR_c_r_mean'], [FR_i_l_se' FR_c_l_se' FR_i_r_se' FR_c_r_se'], 1,...
			'','','','',psth_colormap);
		freezeColors;
		
		ylim = get(gca,'Ylim');
		xlim = get(gca,'Xlim');
		text((xlim(2)-xlim(1))/5,0.95*ylim(2),['  ANOVA(instr): ' sprintf('epoch %.2f space %.2f int %.2f | %s',ANOVA_i.p(2),ANOVA_i.p(1),ANOVA_i.p(3)), num2str(ANOVA_i.epoch_modulation.mod_pattern) ]);
		
		if ANOVA_i.space_main_effect || ANOVA_i.space_epoch_inter, % indicate significant space tuning
			text(x_axis(1:n_epochs),ones(1,n_epochs),ANOVA_i.space_tuning.pref_space,'Color',[1 1 1],'FontSize',16);
		else
			text(x_axis(1:n_epochs),ones(1,n_epochs),ANOVA_i.space_tuning.pref_space,'Color',[1 1 0],'FontSize',16);
		end
		
		% for debugging - compare FR estimates on trial-by-trial with those from averaged PSTH
% 		for pp=1:6,
% 			FRR(pp,:) = mean(out.FR_l(pp).ch,1);
% 		end
% 		for pp=1:6,
% 			FRR(6+pp,:) = mean(out.FR_r(pp).ch,1);
% 		end
% 		FRR = FRR([1 2 7 8 3 4 9 10 5 6 11 12],:);
% 		for i = 1:length(FR_EPOCHS),
%  			hx(i) = subtightplot(4,n_epochs,1*n_epochs+i,sp_gap);
% 			plot_firing_rate_heatmap([FRR(:,i)]);
% 		end		
		
		% FR heatmaps
		for i = 1:length(FR_EPOCHS),
			hi(i) = subtightplot(4,n_epochs,2*n_epochs+i,sp_gap);
			plot_firing_rate_heatmap([out.FR_psth_instr(:,i).FR]);
			title(FR_EPOCH_NAMES{i},'Color',int_color(i,:));
			hc(i) = subtightplot(4,n_epochs,3*n_epochs+i,sp_gap); 
			plot_firing_rate_heatmap([out.FR_psth_choice(:,i).FR]);
		end
		
		ig_set_caxis_equal_lim([hi hc]);
		axes(hi(1));
		hcol = colorbar('location','EastOutside');
		set(get(hcol,'title'),'String','Spikes/s');
		axes(hc(1));
		hcol = colorbar('location','EastOutside');
		set(get(hcol,'title'),'String','Spikes/s');
		

		
		% print info about each unit
		fprintf('%d %s %s ch%d %s %d %d %d %d  %d %d %d %s %s %s %d %d %.2f %d %d %d\n', ...
			par.batch_counter+n_unit,runpath,settings.task_type,ch,uname{u},...
			out.n_trials.in_l,out.n_trials.ch_l,out.n_trials.in_r,out.n_trials.ch_r,...
			ANOVA_i.epoch_main_effect, ANOVA_i.space_main_effect, ANOVA_i.space_epoch_inter,...
			num2str(ANOVA_i.epoch_modulation.mod_pattern),...
			char(ANOVA_i.space_tuning.pref_space{:})',...
			current_unit.Neuron_ID{:},current_unit.x{:},current_unit.y{:},current_unit.electrode_depth{:},...
			current_unit.SNR_rating{:},current_unit.Single_rating{:},current_unit.stability_rating{:});
		
		if ~isempty(par.save_figures),
			[dummy,runname,dummy] = fileparts(runpath); 
			print(hf1,sprintf('%d%s raster %s %s ch%d %s .%s', par.batch_counter+n_unit,par.figname_prefix,settings.task_type,runname,ch,uname{u},par.save_figures(end-2:end)),par.save_figures,'-r0');
			print(hf2,sprintf('%d%s summary %s %s ch%d %s .%s', par.batch_counter+n_unit,par.figname_prefix,settings.task_type,runname,ch,uname{u},par.save_figures(end-2:end)),par.save_figures,'-r0');	
		end
			
	end % for each unit
end % for each channel

end % of if plot_summary




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
map = jet(50);
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
	

function [FR INT] = get_epoch_mean_FR(PSTH,FR_EPOCHS,p,histo_s,bins)
% FR_EPOCHS: "state start" "start" "state end" "end", start and end in s
% if state end is -1, "state start"+1 is taken
mean_states_onset = PSTH(p).mean_states_onset; % aligned to trigger states

if PSTH(p).n_trials,
	state1_idx = find(PSTH(p).trial(1).states==FR_EPOCHS(1));
	state2_idx = find(PSTH(p).trial(1).states==FR_EPOCHS(3));	
	int1 = mean_states_onset(state1_idx)+FR_EPOCHS(2);
	if FR_EPOCHS(3)==-1,
		int2 = mean_states_onset(state1_idx+1)+FR_EPOCHS(4);
	else
		int2 = mean_states_onset(state2_idx)+FR_EPOCHS(4);
	end
	FR = mean(histo_s(bins>int1 & bins<int2));
	INT = [int1 int2];
else
	FR = NaN;
	INT = [NaN NaN];
end

function fr_int_trial = spk2FR_epoch(spikes,trial_states,trial_states_onset,settings)
% spikes are aligned to trigger state onset
% need to know about state onsets in this specific trial

fr_int_trial = NaN*ones(1,size(settings.FR_epochs,1));
for i = 1:size(settings.FR_epochs,1), % for each epoch
	FR_EPOCHS = settings.FR_epochs(i,:);
	state1_idx = find(trial_states==FR_EPOCHS(1));
	state2_idx = find(trial_states==FR_EPOCHS(3));
	int1 = trial_states_onset(state1_idx)+FR_EPOCHS(2);
	if FR_EPOCHS(3)==-1,
		int2 = trial_states_onset(state1_idx+1)+FR_EPOCHS(4);
	else
		int2 = trial_states_onset(state2_idx)+FR_EPOCHS(4);
	end
	fr_int_trial(i) = sum(spikes>int1 & spikes<int2)/(int2-int1); % spikes/s
end

function out = analyze_epoch_modulation(a,settings,FR_i_l,FR_i_r)

		
[out.c,out.m] = multcompare(a.stats,'dimension',2,'alpha',0.05,'display','off');
out.ch = ig_get_multicompare_significance(out.c); % column of pair-wise comparisons

% direct pattern
% 1  1.0000    2.0000   -6.1439   -3.6120   -1.0801
% 2  1.0000    3.0000   -2.7118   -0.1799    2.3520
% 3  1.0000    4.0000   -5.1633   -2.6314   -0.0995
% 4  1.0000    5.0000   -4.2903   -1.7584    0.7735
% 5  1.0000    6.0000   -1.8732    0.6587    3.1906
% 6  2.0000    3.0000    0.9002    3.4321    5.9640
% 7  2.0000    4.0000   -1.5513    0.9806    3.5125
% 8  2.0000    5.0000   -0.6782    1.8536    4.3855
% 9  2.0000    6.0000    1.7388    4.2707    6.8026
% 10 3.0000    4.0000   -4.9834   -2.4515    0.0804
% 11 3.0000    5.0000   -4.1103   -1.5785    0.9534
% 12 3.0000    6.0000   -1.6933    0.8386    3.3705
% 13 4.0000    5.0000   -1.6588    0.8730    3.4049
% 14 4.0000    6.0000    0.7582    3.2901    5.8220
% 15 5.0000    6.0000   -0.1148    2.4171    4.9490

% memory pattern
% 1  1.0000    2.0000   -6.0274   -3.6302   -1.2330
% 2  1.0000    3.0000    0.0616    2.4587    4.8559
% 3  1.0000    4.0000    0.8587    3.2559    5.6531
% 4  1.0000    5.0000    5.4271    7.8243   10.2215
% 5  1.0000    6.0000    6.6751    9.0723   11.4695
% 6  1.0000    7.0000    0.9934    3.3906    5.7878
% 7  1.0000    8.0000    0.6000    2.9972    5.3944
% 8  2.0000    3.0000    3.6917    6.0889    8.4861
% 9  2.0000    4.0000    4.4889    6.8861    9.2833
% 10 2.0000    5.0000    9.0573   11.4545   13.8517
% 11 2.0000    6.0000   10.3053   12.7025   15.0997
% 12 2.0000    7.0000    4.6236    7.0208    9.4180
% 13 2.0000    8.0000    4.2302    6.6274    9.0246
% 14 3.0000    4.0000   -1.6000    0.7972    3.1944
% 15 3.0000    5.0000    2.9684    5.3656    7.7627
% 16 3.0000    6.0000    4.2163    6.6135    9.0107
% 17 3.0000    7.0000   -1.4654    0.9318    3.3290
% 18 3.0000    8.0000   -1.8587    0.5385    2.9357
% 19 4.0000    5.0000    2.1712    4.5684    6.9656
% 20 4.0000    6.0000    3.4192    5.8164    8.2136
% 21 4.0000    7.0000   -2.2625    0.1347    2.5319
% 22 4.0000    8.0000   -2.6559   -0.2587    2.1385
% 23 5.0000    6.0000   -1.1492    1.2480    3.6452
% 24 5.0000    7.0000   -6.8309   -4.4337   -2.0365
% 25 5.0000    8.0000   -7.2243   -4.8271   -2.4299
% 26 6.0000    7.0000   -8.0789   -5.6817   -3.2845
% 27 6.0000    8.0000   -8.4723   -6.0751   -3.6779
% 28 7.0000    8.0000   -2.7906   -0.3934    2.0038

switch settings.task_type
	case 'direct'
		% direct pattern
		% fix_acq vs ITI, fix_hol vs ITI, pre-sac vs fix_hol, peri_sac vs fix_hol, post-sac vs fix_hol
		% 1 means 2nd > 1st epoch, -1 2nd < 1st epoch, 0 - no significant difference
		out.mod_pattern =	-1*[out.ch(1)*sign(out.c(1,4))...
					 out.ch(2)*sign(out.c(2,4))...
					 out.ch(10)*sign(out.c(10,4))...
					 out.ch(11)*sign(out.c(11,4))...
					 out.ch(12)*sign(out.c(12,4))];
					 
		
	case 'memory'
		% memory pattern
		% fix_acq vs ITI, fix_hol vs ITI, cue vs fix_hol, mem vs fix_hol, pre-sac vs mem, peri_sac vs mem, post-sac vs mem
		% 1 means 2nd > 1st epoch, -1 2nd < 1st epoch, 0 - no significant difference
		out.mod_pattern =	-1*[out.ch(1)*sign(out.c(1,4))...
					 out.ch(2)*sign(out.c(2,4))...
					 out.ch(14)*sign(out.c(14,4))...
					 out.ch(15)*sign(out.c(15,4))...
					 out.ch(23)*sign(out.c(23,4))...
					 out.ch(24)*sign(out.c(24,4))...					 
					 out.ch(25)*sign(out.c(25,4))];
					 
		
end




function out = analyze_space_tuning(a,settings,FR_i_l,FR_i_r)
% FR is matrix [epoch x trial]
[out.c,out.m] = multcompare(a.stats,'dimension',1,'alpha',0.05,'display','off');
out.ch = ig_get_multicompare_significance(out.c);
alpha_corrected = 0.05/(length(settings.first_spatial_epoch:length(settings.FR_epochs)));
for k = settings.first_spatial_epoch:length(settings.FR_epochs),
	[h(k),p(k)] = ttest2(FR_i_l(k,:),FR_i_r(k,:),alpha_corrected,[],'unequal');
	if ~isnan(h(k))
		if h(k),
			if mean(FR_i_l(k,:))>mean(FR_i_r(k,:)),
				pref_space{k} = 'L ';
			else
				pref_space{k} = 'R ';
			end
		else
			pref_space{k} = '- ';
		end
	else
		h(k) = 0;
		p(k) = 1;
		pref_space{k} = '- ';
	end
end
		

out.h = h;
out.p = p;
out.pref_space = pref_space;




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


