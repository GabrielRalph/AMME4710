% SNAKE_DEMO Demo showing the usage of snake 
%
% adapted from CMP Vision algorithms http://visionbook.felk.cvut.cz

%% DEMO 1
% The first example shows how to use snakes to find the inner boundary of the
% heart cavity in a magnetic resonance image 
% The initial position of the snake
% is a small circle located inside the cavity. We will make the snake
% expand until it reaches the bright wall.

img = imread( ['..',filesep,'example_images_week6',filesep,'heart.pgm'] );
figure, imagesc(img), colormap(gray), axis image;  axis off;  

% manually select points in a clockwise order inside the heart cavity 
% left click to select points, right click to finalize selection
[x,y]= snakeinit;

% The external energy is a smoothed version of the image, normalized for
% convenience 
h = fspecial( 'gaussian', 20, 3 );
f = imfilter( double(img), h, 'symmetric' );
f = f-min(f(:));  f = f/max(f(:));

figure, imagesc(f) ; colormap(jet) ; colorbar ;
axis image ; axis off ; 

% The external force is a negative gradient of the energy. 
% We start the snake evolution with alpha=0.1, beta=0.01,
% kappa=0.2, lambda=0.05.
% Note that the normalization constant is incorporated into kappa.

[px,py] = gradient(-f);
kappa=1/max(abs( [px(:) ; py(:)])) ;
[x,y]=snake(x,y,0.1,0.01,0.2*kappa,0.05,px,py,0.4,1,img);

% The final position of the snake is shown 
% We can see that the boundary is well
% recovered. It is instructive to run the snake evolution for different
% values of the parameters and note how the evolution speed and the final
% shape changes. Start with small changes first; big changes make the
% snake behave in unpredictable ways.

figure, imagesc(img) ; colormap(gray) ; hold on ;
axis image ; axis off ;
plot([x;x(1)],[y;y(1)],'r','LineWidth',2) ; hold off ;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEMO 2
%
% The second example deals with segmenting an object (a bird) in a color
% image 
% This time we set the
% initial snake position manually around the object using
% a function snakeinit and let the snake
% shrink until it hits the object.

img=imread(['..',filesep,'example_images_week6',filesep,'bird.png']) ;

figure, imagesc(img) ; axis image ; axis off ;

% manually select points in a clockwise order outside the bird
% left click to select points, right click to finalize selection
% For convenience, the initial snake position can be saved and reloaded
[x,y]= snakeinit;

% To calculate the external energy 
% the image is first converted into grayscale
% using a particular linear combination of color channels that
% emphasizes the difference between the foreground and the
% background. The result is normalized and small values are suppressed
% using thresholding. Finally, the energy image is smoothed.

f=double(img) ; f=f(:,:,1)*0.5+f(:,:,2)*0.5-f(:,:,3)*1 ;
f=f-min(f(:)) ; f=f/max(f(:)) ;
f=(f>0.25).*f ;
h=fspecial('gaussian',20,3) ;
f=imfilter(double(f),h,'symmetric') ;

figure, imagesc(f) ; colormap(jet) ; colorbar ;
axis image ; axis off ; 
% exportfig(gcf,'output_images/snake_energy2.eps') ;

% We calculate the external force from the energy and start the minimization
% with parameters alpha=0.1, beta=0.1, kappa=0.3. Note the
% negative value of the balloon force coefficient lambda=-0.05 that
% makes the snake shrink instead of expand (this depends on the clockwise
% orientation of the snake points). 
% The final result is shown 
% Observe that the bird is well
% delineated, although the snake stops a few pixels away from the boundary. 
% This behavior is fairly typical for the simple external energy used. 
% It can be partly eliminated by using less smoothing at the expense of
% robustness. 

[px,py] = gradient(-f);
kappa=1/(max(max(px(:)),max(py(:)))) ;
[x,y]=snake(x,y,0.1,0.1,0.3*kappa,-0.05,px,py,0.4,1,f);

figure, imagesc(img) ;  axis image ; axis off ; hold on ;
plot([x;x(1)],[y;y(1)],'r','LineWidth',2) ; hold off ;


