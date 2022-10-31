function fpoint = extract_feature_point(img, SC)
    img = im2double(img); % normalise the image
%     d = SC.featrparams.colorDim;
%     
%     % Make color channels discreate integers in the range [1, d] 
%     imq = round(img * (d - 1)) + 1;
% 
%     % Count frequency of each descreate color
%     qps = reshape(imq, [], 3);
%     ccs = accumarray(qps, 1);
%     ccs = padarray(ccs, [d, d, d] - size(ccs), 0, 'post');
    
    % Feature space becomes the list of all d^3 color frequencies
    fpoint = reshape(img, 1, []);
    
%     fpoint = 
end