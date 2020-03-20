function output = createVar(data,config,h)
% createVar function
% Calculating variables for the regression
%
% data: Input data structure
% config: HAR configuration
% h: Forecasting horizon

    if h == 0
        % lag structure:
        if config.Overlap == 0
            k0 = [1 config.k(1)+1 config.k(2)+1];
        else
            k0 = [1 1 1];
        end

        % explanatory variables:
        vars = fieldnames(data);
        for i = 1:3
            temp = lagVar(data,k0(i),config.k(i),config);
            for j = 1:numel(vars)
                varname = strcat(vars{j},num2str(i));
                output.(varname) = temp.(vars{j});
            end
        end
    else
        % dependent variables:
        output = leadVar(data,h,config);
    end
end
