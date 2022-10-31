function fpoint = extract_feature_point(img, SC)
    img = im2double(img); % normalise the image


    fpoint = zeros(1,3);
    
    imlab = rgb2lab(img);
    fpoint(1) = mean(imlab(:,:,1), 'all');
    fpoint(2) = mean(imlab(:,:,2), 'all');
    fpoint(3) = mean(imlab(:,:,3), 'all');
    
end