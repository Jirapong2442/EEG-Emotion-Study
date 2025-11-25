%% Set-up
clear; clc; 

%Please change to your own working directory
working_dir = '/Users/brosebrose601/Documents/CUHK/TA/2425S1_BMEG3330/BMEG3330 Project 2 Sample Code';
cd(working_dir); %Change the working directory to where your Sample Code folder is stored

FileName = 'Eden'; %Change to your file name
DataFolder = ['training_data/' FileName];
load([DataFolder '/EEGData.mat']);
fs = SampleRate;

%% Restructure the EEG data into the traininfg dataset for the classifier
% For each 4s trials, extract 5 1-second interval for training samples
% 0.5-1.5s, 1.5-2.5s, 2.5-3.5s 3.5-4.5 4.5-5.5%discard first and last 0.5s 
duration = 3; %Sample data only consist of 4s trials, Change to 5 for your own data!!!!!
AllData = zeros(4, fs,0); %(chan x time x trials) 
for i = 1:length(Stimulus_Type)
    start = Stimulus_TimeMark(2*i-1);
    stop = Stimulus_TimeMark(2*i);
    data = EEGData(1+round(start*fs):round(stop*fs), :); 
    for j = 1:duration
        interval = round(1+(j-0.5)*fs) : round((j+0.5)*fs);
        tmp = data(interval,:);
        tmp = tmp'; %convert to (chan x time) dimension
        AllData(:,:,end+1) = tmp;
    end
end
AllLabel = repelem(Stimulus_Type, 5); %For each data, 3 1s data is extracted 
%Save data
save([DataFolder '/AllData.mat'], 'AllData', 'AllLabel');

%% intialize eeglab
[~, EEG,~,~] = eeglab;

%% Visual inspection to remove unwanted data
load([DataFolder '/AllData.mat']);
%Use EEGlab to review and reject data
EEG = pop_importdata('dataformat','array','nbchan',0,'data','AllData','setname','AllData','srate',fs,'pnts',0,'xmin',0);
EEG = eeg_checkset(EEG);
pop_eegplot(EEG,1,1,0);
waitfor(findobj('parent', gcf, 'string', 'UPDATE MARKS'), 'userdata'); %click UPDATE MARKS
EEG = eeg_checkset(EEG);
reject_trials = EEG.reject.rejmanual; 
%remove marked trials (both data and label) and save as new data
EEG = pop_rejepoch(EEG, reject_trials);

if isempty(reject_trials)
    label = AllLabel;
else
    label = AllLabel(~reject_trials); 
end
AllData = EEG.data; 
save([DataFolder '/rAllData.mat'], 'AllData', 'label') % AllDate after trial rejected

%% Feature extraction procedure (IMPORTANT: You can work on your own)
load([DataFolder '/rAllData.mat'])
AllData = double(AllData);
EEG = pop_importdata('dataformat','array','nbchan',0,'data','AllData','setname','AllData','srate',fs,'pnts',0,'xmin',0);

%Choose what frequency band you want to extract
%Example 
%FilterBand = {[8 13]}; Extract alpha power only
%FilterBand = {[8,30]}; Extract power from 8-30Hz (one feature)
%FilterBand = {[8 13], [13,30]};Extract alpha and beta power(two
%features)

FilterBand = {[8 13], [13 30]}; 

SavedFilter = {}; 
X = [];
for i = 1:length(FilterBand);
    [EEGFiltered ,~, SavedFilter{i}] = pop_eegfiltnew(EEG, 'locutoff',FilterBand{i}(1),'hicutoff',FilterBand{i}(2));
    EEGFiltered = permute(EEGFiltered.data,[2,1,3]);
    Power = sum(EEGFiltered.^2,1)/size(EEGFiltered,1);
    Power = squeeze(Power); 
    X = [X Power']; %Horizontal concatenation to append features of different band 
end
NumTrials = size(X,1);
%Save all filter obtained from EEGLAB
save([DataFolder '/SavedFilter.mat'], 'SavedFilter')

%Save feature matrix
save([DataFolder '/X.mat'], 'X', 'label'); % size: trials*(second*features)

%% Model training (IMPORTANT)
load([DataFolder '/X.mat'])
NumTrials = length(label); NumClasses = 4; 

%k-fold cross validation procedures
%1. Split data into k-blocks
%2. Use k-1 blocks of data to train the model, and use the results to
%make prediction of the remaining block, to obtain accuracy of the model
%3. Repeat the above process with differnet combinations, to obtain average
%   accuracy of the model
%4. Example, k=4, Train [1 2 3] block, predict [4], then Train [1 2 4],
%   predict [3], Then Train [2,3,4], predict[1] etc 

k = 4; BlockLength = floor(NumTrials/k); 
index = randperm(NumTrials); 
%generate random blocks of data
data_block = {}; 
TrainAccuracy = zeros(1,k); %k accuracy value 
TestAccuracy = zeros(1,k);
for i = 1:k
    
    % Prepare the labels for the training and testing dataset.
    % Data is the input to the classifier (e.g. question)
    % Label is the desired output from the classifier (e.g. answer)
    TmpIndex = (1:BlockLength) + (i-1)*BlockLength ;
    TmpIndex = TmpIndex(TmpIndex<=NumTrials); %Prevent index out of range
    TrainData = X(index(setdiff(1:NumTrials, TmpIndex)),:);
    TrainLabel = label(index(setdiff(1:NumTrials, TmpIndex))); 
    TestData = X(index(TmpIndex),:);
    TestLabel = label(index(TmpIndex));
    
    %Train the model
%     %LDA classifier
    Mdl = fitcdiscr(TrainData,TrainLabel,'DiscrimType','linear');
    
    %Calculate accuracy using TrainingLabel
    PredictedLabel = predict(Mdl, TrainData);
    TrainAccuracy(i) = sum(TrainLabel == PredictedLabel)./length(PredictedLabel);
    
    %Predict TestData using Trained Models
    PredictedLabel = predict(Mdl,TestData);
    TestAccuracy(i) = sum(TestLabel == PredictedLabel)./length(PredictedLabel);
   
end

mean(TestAccuracy)


%% Model Performance Evaluation and save trained model

NumClasses = 4;
TrainData = X;
TrainLabel = label;
Mdl = fitcdiscr(TrainData,TrainLabel,'DiscrimType','linear');
PredictedLabel = predict(Mdl, TrainData);

PredictionMatrix = zeros(NumClasses); %Predicted response, actual response
for i = 1:length(PredictedLabel)
    PredictionMatrix(PredictedLabel(i)+1,label(i)+1) = PredictionMatrix(PredictedLabel(i)+1,label(i)+1) + 1;
end

PredictionMatrix

%Precision and Recall
%Precision is the proportion of all the model's positive classifications
%that are actually positive.
%Recall is the proportion of all actual positives that were classified
%correctly as positives.

Precision = diag(PredictionMatrix)./sum(PredictionMatrix,2);
Recall = diag(PredictionMatrix)'./sum(PredictionMatrix,1);

%Save learned model
save([DataFolder '/Trained_Mdl.mat'], 'Mdl');







                                     








    
    



