function Y=dctfltadp(I,n,mode,thr,NoiseStdEst)

I = im2double(I);

T = dctmtx(n);
dct = @(x)T * x * T';
B = blkproc(I,[n n], dct);

switch mode
    case 0
        B2 = blkproc(B,[n n], @(x)(abs(x)/max(x(:))>thr).* x);
    case 1
        B2 = blkproc(B,[n n], @(x)(abs(x)/max(x(:))>thr).*(abs(x)-max(x(:))*thr).*sign(x));
    case 2
        B2 = blkproc(B,[n n], @(x)(abs(x)/std(x(:))>thr).* x);
    case 3
        B2 = blkproc(B,[n n],@(x)(abs(x)>(sqrt(2)*NoiseStdEst^2/std(x(:)))).*(abs(x)-std(x(:))*(sqrt(2)*(NoiseStdEst/std(x(:)))^2)).*sign(x));
end

invdct = @(x)T' * x * T;
Y = blkproc(B2,[n n], invdct);