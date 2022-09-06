function place = getPlace(img, i, j)
    [width, height, dim] = size(img);
    place_size = width / 8;
    
    starti = i * place_size + 1;
    endi = starti + place_size -1;
    
    startj = j * place_size + 1;
    endj = startj + place_size - 1;
    
    place = img(starti:endi, startj:endj, :);
end