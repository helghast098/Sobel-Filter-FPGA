%Convert to image to gray scale to hex
clear all
close all
clc
width = 160;
height = 120;
RGB = imread('color_image.jpeg');
I = imresize(RGB, [height, width]); % [height, width]
Z = rgb2gray(I);
imshow(Z);
s = (double(Z)/255.0) * 15.0;
a = uint8(s);
holder = a';
img1D = holder(:);
imgHex = dec2hex(img1D);
fd = fopen('../sobel_core/input_image/gray_image.txt', 'wt');
fprintf(fd, '%x\n', img1D);
fclose(fd);
