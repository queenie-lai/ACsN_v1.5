close all
clear all;

load('cmap');
load('gain');
load('offset');

%%
NA = 1.3; % NA of objective
lambda_channels = [405,560,640];
PxSize = 11/40; %the second value corresponding to 40x objective
weight=0.5;
%% Get current directory
%folderpath = uigetdir;
folderpath = 'E:\Queenie\DNAFiber';

%% Create Processed folder
outputFolder = fullfile(folderpath, 'Processed');
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

%% Find all .tif files
fileList = dir(fullfile(folderpath, '*.tif'));
Max_val(1)= 0;
%% Loop through all TIFF files
for f = 1:length(fileList)

    % Extract filename (without extension)
    [~, filename, ~] = fileparts(fileList(f).name);
    % Erase both extensions by passing them in a cell array
    clean_filename = erase(filename, {'.sld', '.tif'});
    filename = clean_filename;

    fprintf('Processing %s ...\n', fileList(f).name);

    %% Load TIFF
    raw = double(loadtiff(fullfile(folderpath, fileList(f).name)));

    %% Prepare ACSN output array
    acsn = zeros(size(raw));

    %% Process each slice
    for i = 1:size(raw,3)
        Lambda = lambda_channels(i);   % wavelength for this slice
        im = raw(:,:,i);

        % --- ACSN processing ---
        acsn(:,:,i) = ACSN(im, NA, Lambda, PxSize, ...
            'Offset', Offset, 'Gain', Gain, 'Weight', weight, 'Mode', 'Fast');

        % --- Your preview ---
        im(im < 100) = 100;
        figure(i);
        imagesc(imfuse(im - 100, acsn(:,:,i), 'montage'));
        colormap(blow); axis off; axis image;
    end
    Max_val(end+1)= max(acsn(:));
    %% Save processed stack
    outputFile = fullfile(outputFolder, strcat(filename, '_acsn.tif'));
    options.color = false;
    options.overwrite = true;
    acsn = uint8(acsn);
    saveastiff(acsn, outputFile, options);

    fprintf('Saved: %s\n', outputFile);
end

disp('All TIFF files processed!');
