function est = getEstimates(fit,var,varargin)
% getEstimates function
% Get estimated values from in sample regressions
%
% var: Rstimated parameters to return
%       coeff: Estimated coefficients
%       t: Estimated NW t statistics
%       p: Estimated NW p values
%       R2: R2 of the regressions
%       R2adj: Adjusted R2 of regressions
% h: Select forecast horizons (default = 0 ie all)
% Models: Select models (default = 0 ie all)

    p = inputParser;
    addOptional(p,'h',0,@(x) isnumeric(x));  
    addOptional(p,'Models',0,@(x) isstring(x) || iscellstr(x));  
    parse(p,varargin{:});
    
    % Filter horizons:
    horizon = fieldnames(fit);
    if p.Results.h ~= 0
        horizon = horizon(ismember(cellfun(@str2num,erase(horizon,"h")),p.Results.h));
    end
    
    % Filter models:
    if isstring(p.Results.Models)
        modeltypes = cellstr(p.Results.Models);
    elseif iscell(p.Results.Models)
        modeltypes = p.Results.Models;
    else
        modeltypes = fieldnames(fit.(horizon{1}));
    end
        
    % Get estimated values:
    if ismember(var,["t","coeff","p"])
        for i = 1:numel(modeltypes)
            x = zeros(numel(horizon),numel(fit.(horizon{1}).(modeltypes{i}).model.CoefficientNames));
            for h = 1:numel(horizon)
                switch var
                    case 'coeff' % Estimated coefficients
                        x(h,:) = fit.(horizon{h}).(modeltypes{i}).model.Coefficients.Estimate';
                    case 't' % Estimated NW t statistics
                        x(h,:) = fit.(horizon{h}).(modeltypes{i}).t';
                    case 'p' % Estimated NW p values
                        x(h,:) = fit.(horizon{h}).(modeltypes{i}).p';
                end
            end
            est.(modeltypes{i}) = x;
        end
    else
        est = zeros(numel(horizon),numel(fit.(horizon{1})));
        for i = 1:numel(modeltypes)
            for h = 1:numel(horizon)
                switch var
                    case 'R2' % Estimated R2
                        est(h,i) = fit.(horizon{h}).(modeltypes{i}).model.Rsquared.Ordinary;
                    case 'R2adj' % Estimated adjusted R2
                        est(h,i) = fit.(horizon{h}).(modeltypes{i}).model.Rsquared.Adjusted;
                end
            end
        end
    end
end