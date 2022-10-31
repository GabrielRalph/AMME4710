function fpoint = extract_feature_point(img, SC)
    [h, w, ~] = size(img);
    points = cat(3, repmat(1:w, h, 1), repmat((1:h)', 1, w), double(img)/255);
    points = squeeze(reshape(points, [], 1, 5));
    
    [~, c, e] = kmeans(points, SC.featrparams.K);
    
    fpoint = cat(2, c(:, 1)', c(:, 2)', c(:, 3)', c(:, 4)', c(:, 5)', e');
end