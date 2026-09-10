%% CAMERA CALIBRATION
% This script evaluates the offset and gain maps of a digital camera
% according to the procedure reported in [1]. Other useful information for
% an accurate gain calibration can be found in [2].
%
% Please, be aware that some sCMOS cameras have two gain regimes (low and
% high intensity), in which case two different gain maps should be
% produced. Refer to the camera manual or manufacturer's website for more
% specific information about your device.
%
% [1] Huang, F., Hartwich, T., Rivera-Molina, F. et al. Video-rate
%     nanoscopy using sCMOS camera–specific single-molecule localization
%     algorithms. Nat Methods 10, 653–658 (2013).
%     https://doi.org/10.1038/nmeth.2488
%
% [2] James R. Janesick, Photon Transfer, SPIE (2007)
%     https://doi.org/10.1117/3.725073 

% It may be convenient to store all calibration variables in one file 
% but, when using the ACsN GUI, it is necessary to store offset and gain 
% in different .mat files.
clear all
save_one_file  = 0; 

%% Offset and Variance

% Offset and Variance calibration is performed evaluating respectively
% average and variance of one or more data stacks acquired with no light
% entering the camera.

% This code assumes that all data stacks for Offset and Variance
% calibration share the same initials. However this can be changed by
% modifying the argument of dir function.

[file,path] = uigetfile('*.tif*');
if isequal(file,0)
    disp('User selected Cancel');
    return
else
    D = dir([path, file(1:4), '*.tif*']);
    L = length(D);
    t = 0;
    for i = 1:L
        disp(['Loading ', fullfile(path,D(i).name)]);
        im = double(loadtiff(fullfile(path,D(i).name)));
        if i == 1
            row = size(im,1);
            col = size(im,2);
            Offset = zeros(row,col);
            M2 = zeros(row,col);
        end

        for j = 1:size(im,3)
            t = t + 1;
            % Store the previous mean to avoid "infection" and maintain accuracy
            oldOffset = Offset;

            % 1. Update the Mean (Offset)
            Offset = oldOffset + (im(:,:,j) - oldOffset) / t;

            % 2. Update the Variance
            % Modified Variance to prevent NaN
            if t > 1
                % Use the mean from the PREVIOUS step to get the correct variance
                M2 = M2 + (im(:,:,j) - oldOffset) .* (im(:,:,j) - Offset);
               % Variance = ((t-1)/t).*Variance + ((im(:,:,j) - oldOffset).^2)./t;
            end            
            %Offset = ((t-1)/t).*Offset + im(:,:,j)./t;
            %Variance = ((t-1)/t).*Variance + ((im(:,:,j)-Offset).^2)./(t-1); <- only output NaN
        end
        if t > 1
            Variance = M2 / (t - 1); % This gives you the UNBIASED sample variance (ADU)^2
        else
            Variance = zeros(row, col);
        end
    end
end

if save_one_file
    save('Camera_Calibration','Offset','Variance');
else
    save('Offset','Offset');
    save('Variance','Variance');
end



%% modified
%% Gain calibration (files in one folder)

folder = uigetdir('', 'Select folder containing Gain_*.tiff files');
if folder == 0
    disp('User cancelled.');
    return
end

files = dir(fullfile(folder, '*count*.ome.tiff'));

% Extract unique illumination levels from filenames
levels = [];
for k = 1:length(files)
    fname = files(k).name;
    token = regexp(fname, '(\d+)count', 'tokens');
    if ~isempty(token)
        levels(end+1) = str2double(token{1}{1});
    end
end
unique_levels = unique(levels);

N = numel(unique_levels);
row = size(Offset,1);
col = size(Offset,2);
G = zeros(row, col, N);
V = zeros(row, col, N);

%% Loop through each illumination level
for i = 1:N
    level = unique_levels(i);
    disp(['Processing illumination: ', num2str(level), ' counts']);

    % Get all files matching this level (e.g. Gain_100count_*.tif)
    pattern = sprintf('%dcount*.tiff', level);
    D = dir(fullfile(folder, pattern));

    t = 0;
    for k = 1:length(D)
        fname = fullfile(folder, D(k).name);
        disp(['Loading ', fname]);
        im = double(loadtiff(fname));

        for j = 1:size(im,3)
            frame = im(:,:,j);
            t = t + 1;

            % Compute mean
            G(:,:,i) = ((t-1)/t).*G(:,:,i) + frame./t;

            % Compute variance (online formula)
            if t > 1
                V(:,:,i) = ((t-1)/t).*V(:,:,i) + ((frame - G(:,:,i)).^2)/(t-1);
            end
        end
        
    end
end

% Fit gain pixelwise
Gain = zeros(row, col);

for i = 1:row
    for j = 1:col
        A = squeeze(V(i,j,:) - Variance(i,j));  % y = variance - offset variance
        B = squeeze(G(i,j,:) - Offset(i,j));    % x = mean - offset
        Gain(i,j) = lsqminnorm(B, A);
    end
end

% Save
if save_one_file
    save('Camera_Calibration','Gain','-append');
else
    save('Gain','Gain');
end