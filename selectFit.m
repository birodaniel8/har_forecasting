function sfit = selectFit(fit,varargin)
% selectFit function
% Select models and forecasting horizons from a HAR fit structure
%
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
    
    % Back transformation:
    for i = 1:numel(modeltypes)
        for h = 1:numel(horizon)
            sfit.(horizon{h}).(modeltypes{i}) = fit.(horizon{h}).(modeltypes{i});
        end
    end
end