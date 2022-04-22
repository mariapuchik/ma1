# ma1 (monkeypsych analysis 1)

A collection of demo scripts for quick reading and processing of monkeypsych-generated mat files, and associated use of em toolbox (saccade detection)

Monkeypsych DAG ephys analysis **initial** version (from 2016)

## ma1_page_thru_trials_binoriv

Plots the eye-movements of the binocular rivalry task. It works for the different versions of the task: fixation and directed saccade. For the (early) fixation task, it plots eye-movements and the last point of the eye fixations for the whole trial period. For the (later) direct saccade task, it plots eye-movements only for the saccade time course ignoring the previous fixation period.

2D trial-by-trial mode:
- The light red circle depicts the area of fixation around the fixation spot / target
- Blue line depicts gaze direction before the fixation hold
- Green line depicts gaze direction after the fixation hold (showing the acquired fixation)
- Red line – gaze direction after the fixation break
- Black line – gaze direction either in-between the saccade and fixation hold or in-between fixation hold and fixation break
- Black spot – the last point of the fixation hold


Example uses:
ma1_page_thru_trials_binoriv(filepath,0,0,0,1) - plot fixation hold summary only
ma1_page_thru_trials_binoriv(filepath,-1,0,1,0) - plot 2D failed trials

