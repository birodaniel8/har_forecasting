%% Testing HAR modelling functions
%% Import data
load('snp.mat')
%% In sample run HAR és HAR-J models with h = 1, 2, 3, 4, 5:
config0 = configHAR('Type','insample','Models',["HAR","HAR_J"],'ModelNames',["HAR","HAR_J"],'h',1:5)  % set config
fit0 = fitHAR(x,config0)  % estimate models

coeffs = getEstimates(fit0,'coeff')  % get insample fit coefficients
r2_HAR = getEstimates(fit0,'R2','Models',"HAR",'h',3:5)  % get Rsquared values for only HAR model with h = 3, 4, 5

%% Out of sample forecast with HAR és HAR-J models with h = 1, 2 and window size 2000:
config1 = configHAR('Type','outofsample','Models',["HAR","HAR_J"],'h',1:2,'w',2000,'Display',true)  % set config
fit1 = fitHAR(x,config1)  % estimate models and show details in Command Window

% Estimate the same models but the log transformed version:
config2 = configHAR('Config',config1,'ModelNames',["logHAR","logHAR_J"],'Transform','log','TransformType',["J","+"])
% here I used the previous configuration (config1) and I just changed name of the models and set the transformation to 'log'
% I also set the transform type for the J variable to "+" which means it is transformed by log(1+J)
fit2 = fitHAR(x,config2)

%% transforming the log models back to variance forecasts and merge the two set of forecasts:
fit2back = backTransform(fit2)
mfit = mergeFit(fit1,fit2back)

%% Forecast evaluation:
avgloss = evalForecasts(mfit,'meanloss')  % mean QLIKE loss
avgloss2 = evalForecasts(mfit,'meanloss','LossFun','MSE')  % MSE loss
% result: log type models performs better both in terms of QLIKE and MSE

DM = evalForecasts(mfit,'DM')  % DM test
DM_p = evalForecasts(mfit,'DM','Pval',true)  % DM test p-values
% result: log type models are significantly better forecasters

GW = evalForecasts(mfit,'GWpair','Models',["HAR", "logHAR"]) % GW test between HAR and logHAR models (with sign)
MCS = evalForecasts(mfit,'MCS','MCSp',0.05) % Model Confidence Set with p = 5% (only the two log type model is in the MCSet)

%% Examples for wrong configuration
% warning helps:
configHAR('Type','insampleASDASD')
configHAR('Type','outofsample','Models',["HAR","HAR_J"],'ModelNames',["HAR"])
configHAR('Type','outofsample','w','ASDASD')