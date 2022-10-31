function model = train_model(xtrain, ytrain, SC)
    model = fitcecoc(xtrain, ytrain, 'FitPosterior', true);
end

