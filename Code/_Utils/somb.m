function z=somb(x)

z=ones(size(x));
x = abs(x);
idx=find(x);
z(idx)=2.0*besselj(1,pi*x(idx))./(pi*x(idx));
