close all
clear all;

load('cmap');
load('gain');
load('offset');

%%
NA = 0.8;
lambda_channels = [420,520,605,665];
PxSize = 11/20;
weight=0.25;
%% Get current directory >> chnage it to select Folder containing tiff files
folderpath = uigetdir;


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
    
    fprintf('Processing %s ...\n', fileList(f).name);

    %% Load TIFF
    raw = double(loadtiff(fullfile(folderpath, fileList(f).name)));
    channel_no = regexp(filename, 'C(\d+)-', 'tokens');
    num = str2double(channel_no{1}{1});
    Lambda = lambda_channels(num);   % wavelength for this slice
    %% Prepare ACSN output array
    acsn = zeros(size(raw));

    %% Process each slice
%    for i = 1:size(raw,3)
        
        im = raw;

        % --- ACSN processing ---
        acsn = ACSN(im, NA, Lambda, PxSize, ...
            'Offset', Offset, 'Gain', Gain, 'Weight', weight, 'Mode', 'Fast');

        % --- Your preview ---
        im(im < 100) = 100;
        figure;
        imagesc(imfuse(im(:,:,100) - 100, acsn(:,:,100), 'montage'));
        colormap(blow); axis off; axis image;
 %   end
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
