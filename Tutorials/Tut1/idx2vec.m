function vecs = idx2vec(idxs, width)
    n = length(idxs);
    
    vecs = zeros(n, 2);
    for i = 1:n
        idx = idxs(i);
        vecs(i, :) = [mod(idx, width), floor(idx / width)];
    end
end