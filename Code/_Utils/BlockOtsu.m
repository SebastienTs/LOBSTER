function [out] = BlockOtsu(in, Lvl)

    if (std(single(in(:)))/mean(in(:)) >= Lvl)
        thresh = graythresh(in);
        out = im2bw(in,thresh);
    else
        out = zeros(size(in));
    end

end 