clc;
clear;
SC = SceneClassifier();

% get data from director
data_path = "../dataset";
[data, y] = SceneClassifier.getDataset(data_path);

%% Revision 1
SC = SC.setRevision("SCRevisions/Revision 1");
SC.featrparams.K = 5;
SC = SC.makeModel(x, y);

%% Revision 2
SC = SC.setRevision("SCRevisions/Revision 2");

%% Revision 3
SC = SC.setRevision("SCRevisions/Revision 3");

%% Revision 4
SC = SC.setRevision("SCRevisions/Revision 6");
SC.featrparams.colorDim = 6;

%% EXTRACT
fprintf("extracting");
x = SC.extractFeatureSpace(data);
fprintf("\n\ndone\n");

%% TRAIN
fprintf("training ..\n");
SC.kfolds = 5;
SC = SC.makeModel(x, y);
fprintf("\n\ndone\n");

[conf, ktop] = SC.getValidationData();
confusionchart(conf, SceneClassifier.Scenes);

% save evaluation data as a latex table text file
latex_table = SC.modelEvaluation();
fid = fopen(SC.revision + "/results.txt",'wt');
fprintf(fid, "%s", latex_table);
fclose(fid);

%% FINAL COMPLETE MODEL
SC = SC.setRevision("SCRevisions/Revision 3");
fprintf("extracting");
x = SC.extractFeatureSpace(data);
fprintf("\n\ndone\n");

% train for entire dataset
model = fitcecoc(x, y);
save("classifier_model.mat", "model");

%%
