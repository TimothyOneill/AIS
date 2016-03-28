%% Initialisation
close all;
clear all;
addpath('utils');
addpath('featureExtraction');
addpath('classification');
addpath('testing');

%% Global parameters used throughout project.
% Sampling rate for loading images.
sampling = 50;
% Image dimensions
imX = 96;
imY = 160;
% PCA parameters
pcaScale = 0.5;
pcaNumDimensions = 10;

%% Load training and testing data.
disp('Loading training and testing images.');
[training testing] = loadTrainingTestingImages(1, sampling);
negativeTraining = training.images(training.labels == -1, :);
positiveTraining = training.images(training.labels == 1, :);
negativeTesting = testing.images(testing.labels == -1, :);
positiveTesting = testing.images(testing.labels == 1, :);
disp('Loaded training and testing images.');

%% Load video data.
disp('Loading video data.');
video = loadVideoFrames('pedestrian/');
disp('Loaded video data.');

%% Show some images from training data.
%{
figure('Name','Negative Images','NumberTitle','Off','Position', [100, 100, 960, 800]);
for ii = 1 : min(size(negativeTraining, 1), 100)
    subplot_tight(5, 10, ii);
    im = negativeTraining(ii, :);
    im = reshape(im, [imY, imX]);
    imshow(im);
end

figure('Name','Positive Images','NumberTitle','Off','Position', [100, 100, 960, 800]);
for ii = 1 : min(size(positiveTraining, 1), 100)
    subplot_tight(5, 10, ii);
    im = positiveTraining(ii, :);
    im = reshape(im, [imY, imX]);
    imshow(im);
end
clear ii im;

colormap(gray);
%}

%% Feature Extraction.
% Raw pixel based uses training.images
% Dimensionality reduction uses PCA - WARNING: SLOWER THAN A CUP OF DIRT
disp('Rescaling images for PCA.');
trainingImagesRescaled = rescaleImages(training.images, pcaScale, imX, imY);
testingImagesRescaled = rescaleImages(testing.images, pcaScale, imX, imY);
disp('Starting dimensionality reduction with PCA.');
[eigenVectors, eEigenValues, imMean, pcaTrainingImages] = applyPCA(trainingImagesRescaled, 29);
% Apply PCA to testing images separately.
pcaTestImages = [];
for i = 1 : size(testingImagesRescaled, 1)
    pcaTestImages = [pcaTestImages; ((testingImagesRescaled(i, :) - imMean) * eigenVectors)];
end

% HOG Feature Extraction
disp ('Extracting HOG Feature Vectors.');
trainingFeatureVectors = extractHogFeatures(training.images, imY, imX);
testingFeatureVectors = extractHogFeatures(testing.images, imY, imX);

%% Classification
% NN Classification
trainingFunction = @NNTraining;
testingFunction = @NNTesting;
classificationName = 'NN';
testingResults(training.images, testing.images, trainingFeatureVectors, testingFeatureVectors, pcaTrainingImages, pcaTestImages, training.labels, testing.labels, trainingFunction,testingFunction,classificationName);
        
% KNN Classification
trainingFunction = @NNTraining;
testingFunction = @KNN3Testing;
classificationName = 'KNN3';
testingResults(training.images, testing.images, trainingFeatureVectors, testingFeatureVectors, pcaTrainingImages, pcaTestImages, training.labels, testing.labels, trainingFunction,testingFunction,classificationName);

trainingFunction = @NNTraining;
testingFunction = @KNN9Testing;
classificationName = 'KNN9';
testingResults(training.images, testing.images, trainingFeatureVectors, testingFeatureVectors, pcaTrainingImages, pcaTestImages, training.labels, testing.labels, trainingFunction,testingFunction,classificationName);

%Fuzzy KNN Classification
trainingFunction = @NNTraining;
testingFunction = @FuzzyKNN9Testing;
classificationName = 'Fuzzy KNN9';
testingResults(training.images, testing.images, trainingFeatureVectors, testingFeatureVectors, pcaTrainingImages, pcaTestImages, training.labels, testing.labels, trainingFunction,testingFunction,classificationName);

trainingFunction = @NNTraining;
testingFunction = @FuzzyKNN9LowWeightTesting;
classificationName = 'Fuzzy Low Weight KNN9';
testingResults(training.images, testing.images, trainingFeatureVectors, testingFeatureVectors, pcaTrainingImages, pcaTestImages, training.labels, testing.labels, trainingFunction,testingFunction,classificationName);

trainingFunction = @NNTraining;
testingFunction = @FuzzyKNN9HighWeightTesting;
classificationName = 'Fuzzy High Weight KNN9';
testingResults(training.images, testing.images, trainingFeatureVectors, testingFeatureVectors, pcaTrainingImages, pcaTestImages, training.labels, testing.labels, trainingFunction,testingFunction,classificationName);

% SVM Classification
trainingFunction = @SVMTraining;
testingFunction = @SVMTesting;
classificationName = 'SVM';
testingResults(training.images, testing.images, trainingFeatureVectors, testingFeatureVectors, pcaTrainingImages, pcaTestImages, training.labels, testing.labels, trainingFunction,testingFunction,classificationName);

[accuracy, results] = trainAndTest(pcaTrainingImages, training.labels, ...
    @SVMTraining, pcaTestImages, testing.labels, @SVMTesting);
rr = evaluateResults(testing.labels, results);
displayResults(testing.images, testing.labels, results, imX, imY);

%Adaboost Classification
trainingFunction = @AdaboostTraining;
testingFunction = @AdaboostTesting;
classificationName = 'Adaboost';
testingResults(training.images, testing.images, trainingFeatureVectors, testingFeatureVectors, pcaTrainingImages, pcaTestImages, training.labels, testing.labels, trainingFunction,testingFunction,classificationName);

%Cross Validation
CrossValidateResults([training.images;testing.images], [trainingFeatureVectors;testingFeatureVectors],[pcaTrainingImages;pcaTestImages],[training.labels;testing.labels]);

implay(video);
