%Convert from hex to image
clear all
close all
clc
width = 160;
height = 120;
fd = fopen('../sobel_core/output_image/image_out.txt', 'r');
img = fscanf(fd, '%x', [1 inf]);
fclose(fd);
outImg = reshape(img, [width-2, height-2]); % width height
outImg = outImg';
j = imresize(outImg, [480 640]); % height width
figure, imshow(j, []);
