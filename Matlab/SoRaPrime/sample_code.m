close all
clear all;

load('cmap');
load('gain');
load('offset');

%%
NA = 0.8;
lambda_cahnnels = [420,520,605];
PxSize = 11/20;
weight=0.25;

%%

folderpath = pwd:

filename = 'NikonLowSNR_Prime - Confocal_12p - Position 3';
raw = double(loadtiff(strcat(filename, '.tif')));
 
 %%
 for i = 1:size(raw,3)
     Lambda = lambda_cahnnels(i);
     im = raw(:,:,i);
     
     acsn(:,:,i) = ACSN(im,NA,Lambda,PxSize,'Offset',Offset,'Gain',Gain,'Weight',weight,'Mode','Fast'); 
     im(im<100)=100;
     figure; 
    imagesc(imfuse(im-100,acsn(:,:,i),'montage'));
    colormap(blow); axis off; axis image;
 end
figure
%%

% The first time the runtime can be longer if the parallel pool is not already active

%%
figure; 
imagesc(imfuse(raw(:,:,3),acsn(:,:,3),'montage'));
colormap(blow); axis off; axis image;
%% save the denoised image in folderpath/Processed
path = strcat(filename,'_acsn.tif');
options.color = false;
options.overwrite = true;
res = saveastiff(acsn, path);