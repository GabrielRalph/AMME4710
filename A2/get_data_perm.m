function [imgs, classes] = get_data_perm(n)
    SCENES = [
        "urban";
        "snow";
        "sky";
        "road";
        "park";
        "desert";
        "ball_pit";
    ];
    n = floor(n/7);
    tn = n * 7;
    
    imgs = cell(tn, 1);
    classes = zeros(tn, 1);
    k = 1;
    for i = 1:7
        files = dir(sprintf("dataset/%s/*.jpg", SCENES(i)));
        p = randperm(length(files));
        for j = p(1:n)
            imgs{k} = imread(sprintf("dataset/%s/%s", SCENES(i), files(j).name));
            classes(k) = i;
            k = k + 1;
        end
    end
end