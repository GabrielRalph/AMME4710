function C = colors(size, color)
    dim = length(color);
    C = zeros([size, dim], class(color));
    for i = 1:dim
        C(:, :, i) = C(:, :, i) + color(i);
    end
end