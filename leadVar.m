function output = leadVar(data,h,config)
% LeadVar function
% Calculating h-step ahead average values for the regression
%
% data: Input data structure
% h: Forecasting horizon
% config: HAR configuration

    n = config.Size;
    vars = fieldnames(data);
    if config.TransformSum == 0    
        % Calculation of the mean between x(l) and x(h):
        for j = 1:numel(vars)
            for i = 1:(n-h)
                mdata.(vars{j})(i,1) = mean(data.(vars{j})(i+1:i+h)); 
            end
        end

        % Calculation of the normalizing variable:
        if ~isempty(find(strcmp(config.TransformType,'+%X'),1))
            if ~ismember(config.NormVar,vars)
                error('NORMVAR must be one of the variables in DATA')
            else
                normvar = zeros(n-h,1);
                for i = 1:(n-h)
                    normvar(i) = mean(data.(config.NormVar)(i+1:i+h));
                end
            end
        end 
    else
        mdata = data;
        normvar = data.(config.NormVar);
    end

    % transformation:
    for i = 1:numel(vars)
        y = mdata.(vars{i});
        idx = find(strcmp(config.TransformType, vars{i}));
        if isempty(idx) 
            TType = ''; 
        else
            TType = config.TransformType{idx+1}; 
        end
        switch config.Transform
            case 'log'
                switch TType
                    case '+'
                        y = log(1+y);
                    case '+%'
                        y = log(1+y/100);
                    case '+%X'
                        y = log(1+y./normvar);
                    case 'no'
                    otherwise
                        if min(y)>0
                            y = log(y);
                        end
                end
            case 'sqrt'
                switch TType
                    case '+'
                        y = sqrt(1+y);
                    case '+%'
                        y = sqrt(1+y/100);
                    case '+%X'
                        y = sqrt(1+y./normvar);
                    case 'no'
                    otherwise
                        if min(y)>=0
                            y = sqrt(y);
                        end
                end   
            case 'logsqrt'
                switch TType
                    case '+'
                        y = log(sqrt(1+y));
                    case '+%'
                        y = log(sqrt(1+y/100));
                    case '+%X'
                        y = log(sqrt(1+y./normvar));
                    case 'no'
                        y = sqrt(y);
                    case '+2'
                        y = log(1+sqrt(y));
                    case '+%2'
                        y = log(1+sqrt(y)/100);
                    case '+%X2'
                        y = log(1+sqrt(y)./normvar);
                    case 'no2'
                        y = log(y);
                    case 'no3'
                    otherwise
                        if min(y)>0
                        y = log(sqrt(y));
                        end
                end 
        end
        transformed.(vars{i}) = y;
    end
    if config.TransformSum == 1
        % Calculation of the mean between f(x(l)) and f(x(h)):
        for j = 1:numel(vars)
            for i = 1:(n-h)
                output.(vars{j})(i,1) = mean(transformed.(vars{j})(i+1:i+h)); 
            end
        end
    else
        output = transformed;
    end
end