function fpoint = extract_feature_point(img, SC)
    rows = reshape(mode(img), [], 1, 3);
    cols = mode(img, 2);
    ift = double([rows, cols]) / 255;
%     imshow(ift, 'InitialMagnification', [800, 5000]);
    fpoint = reshape(ift, 1, []);
end