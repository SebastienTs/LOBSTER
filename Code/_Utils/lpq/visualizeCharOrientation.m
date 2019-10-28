function []=visualizeCharOrientation(charOrientation)
% function []=visualizeCharOrientation(charOrientation) visualized the characteristic orientation
%
% Inputs:
% charOri = N*N double, Characteristic orientation for each pixel (computed using charOrientation.m)
%
%

% Version published in 2010 by Janne Heikkilä, Esa Rahtu, and Ville Ojansivu 
% Machine Vision Group, University of Oulu, Finland

% Default inputs
samplingStep=5; % Show vector field of orientation using only part of the pixels

% Read image size
[imgRow,imgCol]=size(charOrientation);

% Form unit vectors corresponding to characteristic orientation angle
vecX=cos(charOrientation);
vecY=sin(charOrientation);

% Draw a vector field using the characteristic orientation
figure;
quiver(1:samplingStep:imgCol,imgRow:-samplingStep:1,vecX(1:samplingStep:end,1:samplingStep:end),vecY(1:samplingStep:end,1:samplingStep:end));
axis([1,imgCol,1,imgRow]);
title(sprintf('Unit vectors illustrating the estimated characteristic orientations. (Show using step size %i)',samplingStep));

% Draw a gray scale image illustrating the orientation angles
figure;
imshow(double(charOrientation)/(2*pi));
title('Characteristic orientation angles as gray values. (white corresponds to 2xpi)');
