function trial = ma1_check_timing_streams(runpath, list_successful_only, plot_trials, matECG, matECG_block)
% ma1_check_timing_streams('Lincombined2015-05-06_03.mat',1,1)
% ma1_check_timing_streams('Magcombined2023-05-18_02_block_01.mat', 0, 1,'Y:\Data\BodySignals\ECG\Magnus\20230518\20230518_ecg.mat',1)


if nargin < 2,
    list_successful_only = 0;
end

if nargin < 3,
    plot_trials = 0;
end

if nargin < 4,
    matECG = '';
    matECG_block = 0;
end

load(runpath);
disp(runpath);

if ~isempty(matECG),
    load(matECG);
    Rpeak_t = out(matECG_block).Rpeak_t;
end

if plot_trials,
    figure('Name','Plot trial','Position',[500 500 1200 800]);
end

%% Alignment 
First_trial_INI_dur = length(First_trial_INI.ECG1)/trial(1).TDT_ECG1_samplingrate; % should be equal to trial(1).TDT_state_onsets(2) - trial(1).TDT_state_onsets(1)!
trialDuration = arrayfun(@(s) length(s.TDT_ECG1)/s.TDT_ECG1_samplingrate, trial); % trial durations from state 2 to next state 2
trialDuration(1) = trialDuration(1) + First_trial_INI_dur; 
trialOffset = cumsum(trialDuration); % relative to the first sample of First_trial_INI
trialOffset = [First_trial_INI_dur trialOffset(1:end-1)]; % insert first, remove last

%% Add new field TDT_state_onsets_aligned_to_1st_INI to trial
TDT_state_onsets_aligned_to_1st_INI = cellfun(@(x,y) x+y, {trial.TDT_state_onsets} ,num2cell(trialOffset), 'UniformOutput', false);

% Use cellfun to convert each element of TDT_state_onsets_aligned_to_1st_INI to a double array
convertedField = cellfun(@double, TDT_state_onsets_aligned_to_1st_INI, 'UniformOutput', false);

% Add the new fields to each element of 'trial' struct array
[trial.TDT_state_onsets_aligned_to_1st_INI] = convertedField{:};


%% loop over trials
for k = 1:length(trial),
    
    if (list_successful_only && trial(k).success) || ~list_successful_only
        
        % align time axis to trial start
        trial(k).tSample_from_trial_start = trial(k).tSample_from_time_start - trial(k).tSample_from_time_start(1);
        
        
        % reward TTL from TDT
        reward_time_axis = (0:length(trial(k).TDT_RWRD)-1)/trial(k).TDT_RWRD_samplingrate;
        trial(k).TDT_stream_duration_from_state2 = reward_time_axis(end);
        
        reward_time = reward_time_axis(trial(k).TDT_RWRD>0);
        if ~isempty(reward_time),
            reward_time = [reward_time(1) reward_time(end)];
        else
            reward_time = [];
        end
        
        
        if plot_trials,
            subplot(2,1,1); hold on;
            title(sprintf('Trial %d',k));
            
            plot(trial(k).tSample_from_trial_start,trial(k).state,'k');
            plot(trial(k).tSample_from_trial_start,trial(k).x_eye,'g');
            plot(trial(k).tSample_from_trial_start,trial(k).y_eye,'m');
            
         
            plot((0:length(trial(k).TDT_RWRD)-1)/trial(k).TDT_RWRD_samplingrate,trial(k).TDT_RWRD,'c');
            % plot((0:length(trial(k).TDT_stat)-1)/trial(k).TDT_stat_samplingrate,trial(k).TDT_stat,'c:');
            
            ig_add_multiple_vertical_lines(trial(k).states_onset - trial(k).tSample_from_time_start(1),'Color','r','LineStyle','-');    
            ig_add_multiple_vertical_lines(trial(k).TDT_state_onsets','Color','b','LineStyle','--');
            ylim = get(gca,'Ylim');
            
            text(trial(k).TDT_state_onsets,ylim(2)*ones(size(trial(k).TDT_state_onsets)),num2str(trial(k).TDT_states),...
                'FontSize',8,'Color',[0    0   1]);
            
            ig_set_all_axes('Xlim',[trial(k).TDT_state_onsets(1) trial(k).TDT_state_onsets(end)]);
        
            
            
            subplot(2,1,2); hold on; % plot using continuous time, relative to first sample of First_trial_INI - which is also the same reference for extracted R-peaks
            
            
            if k == 1, % first trial, special case
                plot( [0:length(First_trial_INI.ECG1)-1 + length(trial(k).TDT_ECG1)]/trial(k).TDT_ECG1_samplingrate, [First_trial_INI.ECG1 trial(k).TDT_ECG1],'k');
                % ig_add_multiple_vertical_lines(trial(k).TDT_state_onsets + trialOffset(k),'Color','b','LineStyle','--'); % 

            else              
                plot( trialOffset(k) + [0:length(trial(k).TDT_ECG1)-1]/trial(k).TDT_ECG1_samplingrate , trial(k).TDT_ECG1,'k');
                % ig_add_multiple_vertical_lines(trial(k).TDT_state_onsets + trialOffset(k),'Color','b','LineStyle','--'); % 
            end
            ylim = get(gca,'Ylim');
            ig_add_multiple_vertical_lines(trial(k).TDT_state_onsets_aligned_to_1st_INI,'Color','b','LineStyle','--');
            text(trial(k).TDT_state_onsets_aligned_to_1st_INI,ylim(2)*ones(size(trial(k).TDT_state_onsets_aligned_to_1st_INI)),num2str(trial(k).TDT_states),...
                'FontSize',8,'Color',[0    0   1]);
            
            set(gca,'Xlim',[trial(k).TDT_state_onsets_aligned_to_1st_INI(1) trial(k).TDT_state_onsets_aligned_to_1st_INI(end)]);

            if ~isempty(matECG),
                ig_add_multiple_vertical_lines(Rpeak_t(Rpeak_t > trial(k).TDT_state_onsets_aligned_to_1st_INI(1) &  Rpeak_t < trial(k).TDT_state_onsets_aligned_to_1st_INI(end)),'Color','y');
            end
            
            
            %% plot events aligned to start of SETTINGS.time_start (MP entering the main loop, just before the state 1 of trial 1)
            % subplot(2,1,2); hold on; % continuous time

            % ig_add_multiple_vertical_lines(trial(k).states_onset,'Color','r','LineStyle','-');    
            % ig_add_multiple_vertical_lines(trial(k).TDT_state_onsets + trial(k).tSample_from_time_start(1)','Color','b','LineStyle','--'); % using tSample_from_time_start(1), which within 1 ms corresponds to state MP state 2 onset
            % plot(arrayfun(@(s) s.states_onset(2), trial) - arrayfun(@(s) s.tSample_from_time_start(1), trial)); % check relative timing of state 2 onset and tSample_from_time_start(1) - should be <1 ms
            
            
            
            
            %%
            drawnow; pause;
            
            if get(gcf,'CurrentChar')=='q',
                % close;
                break;
            end
            
            clf;
        end
    end
    
    
    
    
    
end % for each trial



