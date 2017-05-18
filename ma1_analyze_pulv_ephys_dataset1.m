function ma1_analyze_pulv_ephys_dataset1(db_name)

% dPul_r Linus, Curus

% Linus: dPul_r, dataset1: 20150508 - 20150916 


% direct fields:
% N runpath task ch unit 
% n in l n ch l	n in r n ch r
% epoch	space interaction fix acq fix hold sac peri sac post sac	
% tun pre-sac tun peri-sac tun post-sac

% memory fields:
% N runpath task ch unit 
% n in l n ch l	n in r n ch r
% epoch	space interaction fix acq fix hold cue mem pre sac peri sac post sac	
% tun cue tun mem tun pre-sac tun peri-sac tun post-sac


switch db_name
	case 'Linus_dPul_r_ds1_direct_saccade'
		D = dataset('XLSFile','X:\Data\Linus_ephys_analysis\first_dataset_dPul_r_memory_direct_saccades\direct\db_IKDAG_20160214T181704.xlsx');
	case 'Linus_dPul_r_ds1_memory_saccade'
		D = dataset('XLSFile','X:\Data\Linus_ephys_analysis\first_dataset_dPul_r_memory_direct_saccades\memory\db_IKDAG_20160203T153450.xlsx');					
end