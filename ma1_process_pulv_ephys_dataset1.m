function ma1_process_pulv_ephys_dataset1(dataset_id,Dropbox_PATH)
% ma1_process_pulv_ephys_dataset1('Curius_direct_ds1');
% ma1_process_pulv_ephys_dataset1('Curius_memory_ds1');

if nargin < 2,
	Dropbox_PATH = 'F:';
end

% dPul_r Linus, Curus

% Linus: dPul_r, dataset1: 20150508 - 20150916 
% file_list = findfiles('X:\Data\Linus_phys_combined_monkeypsych_TDT','*.mat')

% Curius: dPul_r, dataset1: ???????? - ???????? 
% file_list = findfiles('X:\Data\Curius_phys_combined_monkeypsych_TDT','*.mat')


switch dataset_id
	case 'Linus_direct_ds1'
		sorting_table_path = [Dropbox_PATH filesep 'Dropbox\DAG\phys\Linus_phys_dpz\Lin_sorted_neurons_20150508_to_20160120.xlsx'];
	file_list = {% Linus direct >60 trials	
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150508\Lincombined2015-05-08_08_block_01.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150513\Lincombined2015-05-13_05_block_02.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150513\Lincombined2015-05-13_07_block_04.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150514\Lincombined2015-05-14_04_block_02.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150515\Lincombined2015-05-15_02_block_01.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150515\Lincombined2015-05-15_05_block_04.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150520\Lincombined2015-05-20_03_block_01.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150521\Lincombined2015-05-21_08_block_03.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150522\Lincombined2015-05-22_08_block_05.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150522\Lincombined2015-05-22_13_block_10.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150527\Lincombined2015-05-27_03_block_02.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150527\Lincombined2015-05-27_06_block_05.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150529\Lincombined2015-05-29_04_block_03.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150529\Lincombined2015-05-29_06_block_05.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150624\Lincombined2015-06-24_04_block_02.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150625\Lincombined2015-06-25_03_block_02.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150625\Lincombined2015-06-25_05_block_04.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150625\Lincombined2015-06-25_07_block_06.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150625\Lincombined2015-06-25_09_block_08.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150626\Lincombined2015-06-26_03_block_02.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150626\Lincombined2015-06-26_05_block_04.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150701\Lincombined2015-07-01_07_block_04.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150702\Lincombined2015-07-02_04_block_02.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150702\Lincombined2015-07-02_08_block_05.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150703\Lincombined2015-07-03_03_block_02.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150703\Lincombined2015-07-03_06_block_05.mat'
	    % 'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150703\Lincombined2015-07-03_10_block_09.mat' % issue with response_state_onset
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150812\Lincombined2015-08-12_03_block_02.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150812\Lincombined2015-08-12_06_block_05.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150813\Lincombined2015-08-13_03_block_02.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150813\Lincombined2015-08-13_06_block_05.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150814\Lincombined2015-08-14_05_block_02.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150814\Lincombined2015-08-14_07_block_04.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150820\Lincombined2015-08-20_04_block_02.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150826\Lincombined2015-08-26_04_block_03.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150826\Lincombined2015-08-26_06_block_05.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150827\Lincombined2015-08-27_03_block_02.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150827\Lincombined2015-08-27_06_block_05.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150827\Lincombined2015-08-27_08_block_07.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150828\Lincombined2015-08-28_03_block_02.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150828\Lincombined2015-08-28_04_block_03.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150828\Lincombined2015-08-28_07_block_06.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150903\Lincombined2015-09-03_03_block_02.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150904\Lincombined2015-09-04_04_block_02.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150904\Lincombined2015-09-04_06_block_04.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150910\Lincombined2015-09-10_02_block_01.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150911\Lincombined2015-09-11_05_block_03.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150911\Lincombined2015-09-11_06_block_04.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150916\Lincombined2015-09-16_06_block_05.mat'
	     };

	case 'Linus_memory_ds1'
		sorting_table_path = [Dropbox_PATH filesep 'Dropbox\DAG\phys\Linus_phys_dpz\Lin_sorted_neurons_20150508_to_20160120.xlsx'];
	file_list = {% Linus memory, >60 trials	
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150508\Lincombined2015-05-08_09_block_02.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150513\Lincombined2015-05-13_04_block_01.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150513\Lincombined2015-05-13_06_block_03.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150514\Lincombined2015-05-14_03_block_01.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150515\Lincombined2015-05-15_03_block_02.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150515\Lincombined2015-05-15_04_block_03.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150520\Lincombined2015-05-20_04_block_02.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150521\Lincombined2015-05-21_09_block_04.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150521\Lincombined2015-05-21_10_block_05.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150522\Lincombined2015-05-22_07_block_04.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150527\Lincombined2015-05-27_04_block_03.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150527\Lincombined2015-05-27_05_block_04.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150529\Lincombined2015-05-29_03_block_02.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150529\Lincombined2015-05-29_05_block_04.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150624\Lincombined2015-06-24_03_block_01.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150625\Lincombined2015-06-25_02_block_01.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150625\Lincombined2015-06-25_04_block_03.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150625\Lincombined2015-06-25_06_block_05.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150625\Lincombined2015-06-25_08_block_07.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150626\Lincombined2015-06-26_02_block_01.mat'
	    % 'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150626\Lincombined2015-06-26_04_block_03.mat' % issue with response_state_onset
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150626\Lincombined2015-06-26_06_block_05.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150701\Lincombined2015-07-01_05_block_02.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150701\Lincombined2015-07-01_06_block_03.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150702\Lincombined2015-07-02_03_block_01.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150702\Lincombined2015-07-02_07_block_04.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150703\Lincombined2015-07-03_02_block_01.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150703\Lincombined2015-07-03_04_block_03.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150703\Lincombined2015-07-03_05_block_04.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150703\Lincombined2015-07-03_09_block_08.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150812\Lincombined2015-08-12_02_block_01.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150812\Lincombined2015-08-12_04_block_03.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150812\Lincombined2015-08-12_05_block_04.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150813\Lincombined2015-08-13_02_block_01.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150813\Lincombined2015-08-13_04_block_03.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150813\Lincombined2015-08-13_05_block_04.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150814\Lincombined2015-08-14_04_block_01.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150814\Lincombined2015-08-14_06_block_03.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150819\Lincombined2015-08-19_02_block_01.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150820\Lincombined2015-08-20_03_block_01.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150826\Lincombined2015-08-26_02_block_01.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150826\Lincombined2015-08-26_03_block_02.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150826\Lincombined2015-08-26_05_block_04.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150827\Lincombined2015-08-27_02_block_01.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150827\Lincombined2015-08-27_05_block_04.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150827\Lincombined2015-08-27_07_block_06.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150827\Lincombined2015-08-27_09_block_08.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150828\Lincombined2015-08-28_02_block_01.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150828\Lincombined2015-08-28_05_block_04.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150828\Lincombined2015-08-28_06_block_05.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150903\Lincombined2015-09-03_02_block_01.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150903\Lincombined2015-09-03_04_block_03.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150903\Lincombined2015-09-03_05_block_04.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150904\Lincombined2015-09-04_03_block_01.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150904\Lincombined2015-09-04_05_block_03.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150910\Lincombined2015-09-10_03_block_02.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150910\Lincombined2015-09-10_06_block_05.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150911\Lincombined2015-09-11_04_block_02.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150911\Lincombined2015-09-11_07_block_05.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150916\Lincombined2015-09-16_03_block_02.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150916\Lincombined2015-09-16_04_block_03.mat'
	    'X:\Data\Linus_phys_combined_monkeypsych_TDT\20150916\Lincombined2015-09-16_05_block_04.mat'
	   };
   
	case 'Curius_direct_ds1'
		sorting_table_path = [Dropbox_PATH filesep '...'];
		
	case 'Curius_memory_ds1'
		sorting_table_path = [Dropbox_PATH filesep '...'];
		
end % of which dataset
    
[dummy, name] = system('hostname');
db_filename = sprintf('db_%s_%s.txt',deblank(name),datestr(now,30));
disp([pwd filesep db_filename]);
diary(db_filename);
n_units = 0;
for k = 1:length(file_list),
	n_units_in_run = ma1_process_one_run_pulv_ephys_dataset1(file_list{k},'batch_counter',n_units,'sorting_table',sorting_table_path); 
% 	n_units_in_run = ma1_process_one_run_pulv_ephys_dataset1(file_list{k},'batch_counter',n_units,'sorting_table',sorting_table_path,...
% 		'save_figures','-dpng'); % with figure saving
	n_units = n_units + n_units_in_run;
	close all;
end
diary off;	
