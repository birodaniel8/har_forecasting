function output = lagVar(data,lag1,lag2,config)
% LagVar function
% Calculating lagged average values for the regression
%
% data: Input data structure
% lag1: Lag(start)
% lag2: Lag(end)
% config: HAR configuration

    n = config.Size;
    vars = fieldnames(data);
    if config.TransformSum == 0
        % Calculation of the mean between x(lag1) and x(lag2):
        for j = 1:numel(vars)
            for i = lag2:n
                mdata.(vars{j})(i,1) = mean(data.(vars{j})(i-lag2+1:i-lag1+1));
            end
        end

        % Calculation of the normalizing variable:
        if ~isempty(find(strcmp(config.TransformType,'+%X'),1))
            if ~ismember(config.NormVar,vars)
                error('NORMVAR must be one of the variables in DATA')
            else
                normvar = zeros(n,1);
                for i = lag2:n
                    normvar(i) = mean(data.(config.NormVar)(i-lag2+1:i-lag1+1));
                end
            end
        end
    else
        mdata = data;
        normvar = data.(config.NormVar);
    end
    
    % Transformation:
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
                    case 'no2+'
                        y = log(1+y);
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
        % Calculation of the mean between f(x(lag1)) and f(x(lag2)):
        for j = 1:numel(vars)
            for i = lag2:n
                output.(vars{j})(i,1) = mean(transformed.(vars{j})(i-lag2+1:i-lag1+1));
            end
        end
    else
        output = transformed;
    end
end