%Tutorial 1

chess = imread("chess/chess.png");


for i = 0:7
    for j = 0:7
        place = getPlace(chess, i, j);
        peice = getPeice(place);
        fprintf("\n%d, %d: %s\n\n", i, j, peice);
        imshow(place);
        pause(0.5);
    end
end
