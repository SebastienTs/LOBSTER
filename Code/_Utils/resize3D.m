function I2 = resize3D(I,FinalSize,Method)

    I2 = imresize(I,[FinalSize(1) FinalSize(2)],'Method',Method);
    if size(I,3) > 1 && FinalSize(3) ~= size(I,3)
        I2 = permute(I2,[3 2 1]);
        I2 = imresize(I2,[FinalSize(3) size(I2,2)],'Method',Method);
        I2 = permute(I2,[3 2 1]);
    end
    
end