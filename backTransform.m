function fit = backTransform(logfit,varargin)
% backTransform function
% Back transformation of forecasts from log-linear normal model
%
% h: Select forecast horizons (default = 0 ie all)
% Models: Select models (default = 0 ie all)

    p = inputParser;
    addOptional(p,'h',0,@(x) isnumeric(x));  
    addOptional(p,'Models',0,@(x) isstring(x) || iscellstr(x));  
    parse(p,varargin{:});
    
    % Filter horizons:
    horizon = fieldnames(logfit);
    if p.Results.h ~= 0
        horizon = horizon(ismember(cellfun(@str2num,erase(horizon,"h")),p.Results.h));
    end
    
    % Filter models:
    if isstring(p.Results.Models)
        modeltypes = cellstr(p.Results.Models);
    elseif iscell(p.Results.Models)
        modeltypes = p.Results.Models;
    else
        modeltypes = fieldnames(logfit.(horizon{1}));
    end
    
    % Back transformation:
    for i = 1:numel(modeltypes)
        for h = 1:numel(horizon)
            fit.(horizon{h}).(modeltypes{i}).f = exp(logfit.(horizon{h}).(modeltypes{i}).f);
            fit.(horizon{h}).(modeltypes{i}).f_hat = exp(logfit.(horizon{h}).(modeltypes{i}).f_hat+ ...
                             (logfit.(horizon{h}).(modeltypes{i}).sse./logfit.(horizon{h}).(modeltypes{i}).df)/2);
            fit.(horizon{h}).(modeltypes{i}).sse = 0; % Set to 0
            fit.(horizon{h}).(modeltypes{i}).df = logfit.(horizon{h}).(modeltypes{i}).df; % Keep values
            %fit.(horizon{h}).(modeltypes{i}).coeff = logfit.(horizon{h}).(modeltypes{i}).coeff; % Keep values

        end
    end
end