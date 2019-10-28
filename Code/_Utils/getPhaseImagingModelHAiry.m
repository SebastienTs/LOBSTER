function [H, airykernel] = getPhaseImagingModelHAiry(nrows, ncols, R, W, radius)

N = nrows*ncols;

if nargin<5
    radius = 3;
end

diameter = 2*radius + 1;
[xx,yy] = meshgrid(-radius:radius,-radius:radius);
rr = sqrt(xx.^2 + yy.^2);

kernel1 = pi*R^2*somb(2*R*rr);     
kernel2 = pi*(R-W)^2*somb(2*(R-W)*rr);    
kernel1 = kernel1/sum(abs(kernel1(:))); kernel2 = kernel2/sum(abs(kernel2(:)));
kernel = kernel1 - kernel2;
kernel = -kernel/sum(abs(kernel(:)));  
kernel(radius+1,radius+1) = kernel(radius+1,radius+1) + 1;
airykernel = kernel;
kernel = -kernel(:);
    
%build the sparse H matrix
nzidx = abs(kernel) > 0.001; %very important to save memory and speed up

inds = reshape(1:N, nrows, ncols);
inds_pad = padarray(inds,[radius radius],'symmetric'); %deal with the boundary

row_inds = repmat(1:N, sum(nzidx), 1);
col_inds = im2col(inds_pad, [diameter,diameter], 'sliding'); %slide col and then row
col_inds = col_inds(repmat(nzidx, [1,N]));
vals = repmat(kernel(nzidx), N, 1);
H = sparse(row_inds(:), col_inds(:), vals, N, N); 

