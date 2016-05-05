function mri_robust_register(inVol,outVol,outDir)

% Motion corrects a 4D volume using Freesurfer's 'mri_robust_register'
%
%   Usage:
%   mri_robust_register(inVol,outVol,outDir)
%
%   Based on:
%   Highly Accurate Inverse Consistent Registration: A Robust Approach
%   M. Reuter, H.D. Rosas, B. Fischl.
%   NeuroImage 53(4), pp. 1181-1196, 2010.
%
%   Written by Andrew S Bock May 2016

%% move to output directory
cd(outDir);
%% Split input 4D volume into 3D volumes
system(['fslsplit ' inVol ' split_f']);
%% Register volumes
inVols = listdir(fullfile(outDir,'split_f0*'),'files');
progBar = ProgressBar(length(inVols),'mri_robust_registering...');
for i = 1:length(inVols)
    inFile = fullfile(outDir,inVols{i});
    dstFile = fullfile(outDir,inVols{1}); % register to first volume
    outFile = fullfile(outDir,['tmp_' num2str(i) '.nii.gz']);
    [~,~] = system(['mri_robust_register --mov ' inFile ...
        ' --dst ' dstFile ' --lta ' num2str(i) '.lta --satit --mapmov ' ...
        outFile]);
    progBar(i);
end
system(['rm ' fullfile(outDir,'split_f0*')]); % remove split volumes
%% Merge into output 4D volume
commandc = ['fslmerge -t ' outVol];
for i = 1:length(inVols)
    outFile = fullfile(outDir,['tmp_' num2str(i) '.nii.gz']);
    commandc = [commandc ' ' outFile];
end
system(commandc);
system(['rm ' fullfile(outDir,'tmp_*nii.gz')]); % remove tmp volumes
%% Convert .lta files to translations and rotations
clear x y z pitch yaw roll
ltaFiles = listdir(fullfile(outDir,'*.lta'),'files');
for i = 1:length(ltaFiles);
    inFile = fullfile(outDir,ltaFiles{i});
    [x(i),y(i),z(i),pitch(i),yaw(i),roll(i)] = convertlta2tranrot(inFile);
end
motion_params = [pitch',yaw',roll',x',y',z'];
dlmwrite(fullfile(outDir,'motion_params.txt'),motion_params,'delimiter',' ','precision','%10.5f');