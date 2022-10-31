
for i = randperm(350)
    im0 = double(data{i})/255;
    ax = get_f(im0, 5);
    for ang = 0:60
        set(ax, 'view', [ang*2, 30 - ang])
        pause(0.05);
    end
end


function ax = get_f(im0, d)
    imq = round(im0 * d);
    qps = reshape(imq + 1, [], 3);
    [uqp, ~, uqpi] = unique(qps, 'rows');
    ccs = accumarray(uqpi, 1);

    subplot(1, 2, 1);
    scatter3(uqp(:, 1), uqp(:, 2), uqp(:, 3), ccs, uqp/10, 'filled');
    ax = gca;
    subplot(1, 2, 2);
    imshow(im0);
end