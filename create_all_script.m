function create_all_script(params)

% Writes shell scripts to preprocess anatomical and functional MRI data
%
%   Usage:
%   create_all_script(params)
%
%   Written by Andrew S Bock Nov 2015

%% Set initial parameters
fname = fullfile(params.outDir,[params.jobName '_all.sh']);
fid = fopen(fname,'w');
fprintf(fid,'#!/bin/bash\n');
fprintf(fid,['SESS=' params.sessionDir '\n']);
fprintf(fid,['SUBJ=' params.subjectName '\n\n']);
%% Add anatomical scripts
if params.reconall % If a new subject, for which recon-all has not been run
    fprintf(fid,'matlab -nodisplay -nosplash -r "sort_nifti(''$SESS'');"\n');
    fprintf(fid,'recon-all -i $SESS/MPRAGE/001/ACPC/MPRAGE.ACPC.nii.gz -s $SUBJ -all\n');
    matlab_string = ([...
        '"skull_strip(''$SESS'',''$SUBJ'');' ...
        'segment_anat(''$SESS'',''$SUBJ'');' ...
        'xhemi_check(''$SESS'',''$SUBJ'');']);
else
    matlab_string = ([...
        '"sort_nifti(''$SESS'');' ...
        'skull_strip(''$SESS'',''$SUBJ'');' ...
        'segment_anat(''$SESS'',''$SUBJ'');' ...
        'xhemi_check(''$SESS'',''$SUBJ'');']);
end
%% Add motion correction scripts
for rr = 1:params.numRuns
    matlab_string = ([matlab_string ...
        'motion_slice_correction(''$SESS'',1,' num2str(params.slicetiming) ...
        ',' num2str(rr) ',' num2str(params.refvol) ',' num2str(params.regFirst) ');']);
end
%% Add functional scripts
for rr = 1:params.numRuns
    func = 'rf';
    if ~params.localWM
        matlab_string = ([matlab_string ...
            'register_func(''$SESS'',''$SUBJ'',' num2str(rr) ',1,''' func ''');' ...
            'project_anat2func(''$SESS'',' num2str(rr) ',''' func ''');' ...
            'create_regressors(''$SESS'',' num2str(rr) ',''' func ''',''detrend'',' ...
            num2str(params.lowHz) ',' num2str(params.highHz) ',' num2str(params.physio) ',' ...
            num2str(params.motion) ',' num2str(params.anat) ');' ...
            'remove_noise(''$SESS'',' num2str(rr) ',''' func ''',' ...
            num2str(params.task) ',' num2str(params.anat) ',' num2str(params.motion) ',' ...
            num2str(params.physio) ');' ...
            'temporal_filter(''$SESS'',' num2str(rr) ',''d' func ''',''' params.filtType ''',' ...
            num2str(params.lowHz) ',' num2str(params.highHz) ');' ...
            'smooth_vol_surf(''$SESS'',' num2str(rr) ',5,''d' func '.tf'');']);
    else
        matlab_string = ([matlab_string ...
            'register_func(''$SESS'',''$SUBJ'',' num2str(rr) ',1,''' func ''');' ...
            'project_anat2func(''$SESS'',' num2str(rr) ',''' func ''');' ...
            'create_regressors(''$SESS'',' num2str(rr) ',''' func ''',''detrend'',' ...
            num2str(params.lowHz) ',' num2str(params.highHz) ',' num2str(params.physio) ',' ...
            num2str(params.motion) ',' num2str(params.anat) ');' ...
            'remove_noise(''$SESS'',' num2str(rr) ',''' func ''',' ...
            num2str(params.task) ',' num2str(params.anat) ',' num2str(params.motion) ',' ...
            num2str(params.physio) ');' ...
            'remove_localWM(''$SESS'',' num2str(rr) ',''d' func ''');' ...
            'temporal_filter(''$SESS'',' num2str(rr) ',''wd' func ''',''' params.filtType ''',' ...
            num2str(params.lowHz) ',' num2str(params.highHz) ');' ...
            'smooth_vol_surf(''$SESS'',' num2str(rr) ',5,''wd' func '.tf'');']);
    end
end
fprintf(fid,['matlab -nodisplay -nosplash -r ' matlab_string '"\n']);
fclose(fid);