function y = evalForecasts(fit,var,varargin)
% evalForecast function
% Evaluate forecast with different methods
%
% var: Forecast evaluation method
%       loss: Loss values based on QLIKE or MSE loss functions
%       meanloss: Average loss values based on QLIKE or MSE loss functions
%       MZ: Mincer-Zarnowitz regression R2
%       DM: Diebold Mariano test for all models pair on every horizon
%       DMpair: Diebold Mariano test for a pair of models on every horizon
%       GW: Giacomini White test for all model pairs on every horizon
%       GWpair: Giacomini White test for a pair of models on every horizon
%       MCS: Model Confidence Set for all models on every horizon (block length = max(5,h))
% h: Select forecast horizons (default = 0 ie all)
% Models: Select models (default = 0 ie all)
% LossFun: Loss function: 'QLIKE' or 'MSE' (default = 'QLIKE')
% Pval: Return p values (default = false)
% MCSp: P value for MSE (default = 0.2)
% MCSiter: Number of MCS iterations (default = 5000)

    p = inputParser;
    addOptional(p,'h',0,@(x) isnumeric(x));  
    addOptional(p,'Models',0,@(x) isstring(x) || iscellstr(x));  
    addOptional(p,'LossFun','QLIKE',@(x) isstring(x) || ischar(x));
    addOptional(p,'Pval',false,@(x) islogical(x));
    addOptional(p,'MCSp',0.2,@(x) isnumeric(x));
    addOptional(p,'MCSiter',5000,@(x) isnumeric(x));
    parse(p,varargin{:});
    
    % Filter horizons:
    horizon = fieldnames(fit);
    if p.Results.h ~= 0
        horizon = horizon(ismember(cellfun(@str2num,erase(horizon,"h")),p.Results.h));
    end
    hs = cellfun(@str2num,erase(horizon,"h"));
    
    % Filter models:
    if isstring(p.Results.Models)
        modeltypes = cellstr(p.Results.Models);
    elseif iscell(p.Results.Models)
        modeltypes = p.Results.Models;
    else
        modeltypes = fieldnames(fit.(horizon{1}));
    end
    
    % Evaluate forecasts:
    switch var
        % Loss values based on QLIKE or MSE loss functions:
        case 'loss'
            y = getLoss(fit,horizon,modeltypes,p.Results.LossFun);
        % Average loss values based on QLIKE or MSE loss functions:
        case 'meanloss'
            y = zeros(numel(horizon),numel(modeltypes));
            loss = getLoss(fit,horizon,modeltypes,p.Results.LossFun);
            for h = 1:numel(horizon)
                y(h,:) = mean(loss.(horizon{h}));
            end
        % Mincer-Zarnowitz regression R2:
        case 'MZ'
            y = zeros(numel(horizon),numel(modeltypes));
            for h = 1:numel(horizon)
                for j = 1:numel(modeltypes)
                    mdl = fitlm(fit.(horizon{h}).(modeltypes{j}).f_hat,fit.(horizon{h}).(modeltypes{j}).f);
                    y(h,j) = mdl.Rsquared.Ordinary;
                end
            end
        % Diebold Mariano test for all models pair on every horizon:
        case 'DM'
            loss = getLoss(fit,horizon,modeltypes,p.Results.LossFun);
            for h = 1:numel(horizon)
                dm = zeros(numel(modeltypes));
                loss_h = loss.(horizon{h});
                for i = 1:(numel(modeltypes)-1)
                    for j = i+1:numel(modeltypes)
                        dm(i,j) = dmtest(loss_h(:,i),loss_h(:,j),hs(h));
                    end
                end
                if p.Results.Pval
                    y.(horizon{h}) = ((1-normcdf(abs(dm)))*2)+((1-normcdf(abs(dm)))*2)'-1;
                else
                    y.(horizon{h}) = dm-dm';
                end
            end
        % Diebold Mariano test for a pair of models on every horizon:
        case 'DMpair'
            loss = getLoss(fit,horizon,modeltypes(1:2),p.Results.LossFun); 
            y = zeros(numel(horizon),1);
            for h = 1:numel(horizon)
                loss_h = loss.(horizon{h});
                teststat = dmtest(loss_h(:,1),loss_h(:,2),hs(h));
                if p.Results.Pval
                    y(h) = (1-normcdf(abs(teststat)))*2;
                else
                    y(h) = teststat;
                end
            end
        % Giacomini White test for all model pairs on every horizon:
        case 'GW'
            loss = getLoss(fit,horizon,modeltypes,p.Results.LossFun);
            for h = 1:numel(horizon)
                gw = zeros(numel(modeltypes));
                loss_h = loss.(horizon{h});
                for i = 1:(numel(modeltypes)-1)
                    for j = i+1:numel(modeltypes)
                        gw(i,j) = CPAtest(loss_h(:,i),loss_h(:,j),hs(h),0,1)*sign(mean(loss_h(:,i)-loss_h(:,j)));
                    end
                end
                if p.Results.Pval
                    y.(horizon{h}) = (1 - cdf('chi2',abs(gw),1))+(1 - cdf('chi2',abs(gw),1))'-1;
                else
                    y.(horizon{h}) = gw-gw';
                end
            end
        % Giacomini White test for a pair of models on every horizon:
        case 'GWpair'
            loss = getLoss(fit,horizon,modeltypes(1:2),p.Results.LossFun); 
            y = zeros(numel(horizon),1);
            for h = 1:numel(horizon)
                loss_h = loss.(horizon{h});
                teststat = CPAtest(loss_h(:,1),loss_h(:,2),hs(h),0,1)*sign(mean(loss_h(:,1)-loss_h(:,2)));
                if p.Results.Pval
                    y(h) = 1 - cdf('chi2',abs(teststat),1);
                else
                    y(h) = teststat;
                end
            end
        % Model Confidence Set for all models on every horizon:
        case 'MCS'
            pvals = zeros(numel(horizon),numel(modeltypes));
            loss = getLoss(fit,horizon,modeltypes,p.Results.LossFun); 
            for h = 1:numel(horizon)
                % MCS with max(5,h) block length
                [includedR,pvalsR,excludedR]=mcs(loss.(horizon{h}),p.Results.MCSp,p.Results.MCSiter,max(5,hs(h)));
                if p.Results.Pval
                    allR = [excludedR;includedR];
                    [~,ordR] = ismember(1:numel(modeltypes),allR);
                    pvals(h,:) = pvalsR(ordR)';
                else
                    y.(horizon{h}) = modeltypes(includedR);
                end
            end
            if p.Results.Pval
                y = pvals;
            end
    end
end

function y = getLoss(fit,horizon,modeltypes,lossfun)
% Get loss function values based on QLIKE or MSE loss functions:
    for h = 1:numel(horizon)
        loss = zeros(numel(fit.(horizon{h}).(modeltypes{1}).f),numel(modeltypes));
        for i = 1:size(loss,1)
            for j = 1:numel(modeltypes)
                if strcmp(lossfun,'MSE') % MSE
                    loss(i,j) = (fit.(horizon{h}).(modeltypes{j}).f(i)-fit.(horizon{h}).(modeltypes{j}).f_hat(i))^2;
                else % QLIKE
                    loss(i,j) = QLIKE(fit.(horizon{h}).(modeltypes{j}).f(i),fit.(horizon{h}).(modeltypes{j}).f_hat(i));
                end
            end
        end
        y.(horizon{h}) = loss;
    end
end