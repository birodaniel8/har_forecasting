function fit = fitHAR(data,config)
% fitHAR function
% fitting HAR models for in sample and out of sample analysis
%
% data: Input data structure
% config: HAR configuration
    
    % Input checking:
    fn = fieldnames(data);
    for i=2:numel(fn)
        if size(data.(fn{i}),1)~=size(data.(fn{1}),1)
            error('The variables in DATA must have the same size')
        end
    end
    config.Size = size(data.(fn{1}),1);
    if config.T == 0
        config.T = [1 size(data.(fn{1}),1)];
    end
    if config.T(2)>size(data.(fn{1}),1)
        error('T(2) must be less than the number of observations in DATA')
    end
    if config.w>(config.T(2)-config.T(1))
        error('W (window size) must be less than the number of used observations')
    end
    
    tic % start timer
    
    % Create lagged variables:
    x = createVar(data,config,0);
    x=orderfields(x);
    x=struct2table(x);
    
    % Specify HAR configuration:
    configHAR.k = config.k;
    configHAR.Intercept = config.Intercept;
    configHAR.Transform = config.Transform;
    configHAR.Display = config.Display;

    for h = config.h
        if config.Display
            disp(strcat('Model estimation, h=',num2str(h)))
        end
        % Create h-step ahead variables:
        configHAR.h = h;
        y = createVar(data,config,h);
        y = struct2table(y);
        y0 = array2table(zeros(h,size(y,2)));
        y0.Properties.VariableNames = y.Properties.VariableNames;
        y = [y; y0];
        % Concatenate and cut variables:
        input = horzcat(y,x);
        input = input(config.T(1):config.T(2),:);
        for i = 1:numel(config.ModelNames)
            configHAR.Model = config.Models{i};
            configHAR.ModelName = config.ModelNames{i};
            if strcmp(config.Type,'insample') % In sample estimation:
                configHAR.NW = 1;
                configHAR.Forecast = 0;
                [m,m_t,m_p] = estimateHARX(input,configHAR);
                fit.(strcat('h',num2str(h))).(config.ModelNames{i}).model = m;
                fit.(strcat('h',num2str(h))).(config.ModelNames{i}).t = m_t;
                fit.(strcat('h',num2str(h))).(config.ModelNames{i}).p = m_p;
            else % Out of sample estimation:
                configHAR.NW = 0;
                configHAR.Forecast = 1;
                m = (size(input,1)-config.w-h+1);
                f = zeros(m,1);
                f_hat = zeros(m,1);
                sse = zeros(m,1);
                df = zeros(m,1);
                neg = zeros(m,1);
                parfor j = 1:m
                    [~,~,~,f(j),f_hat(j),sse(j),df(j),~,neg(j)] = estimateHARX(input(j:config.w+j-1,:),configHAR); %,coeff(j,:)
                end
                fit.(strcat('h',num2str(h))).(config.ModelNames{i}).f = f;
                fit.(strcat('h',num2str(h))).(config.ModelNames{i}).f_hat = f_hat;
                fit.(strcat('h',num2str(h))).(config.ModelNames{i}).sse = sse;
                fit.(strcat('h',num2str(h))).(config.ModelNames{i}).df = df;
                fit.(strcat('h',num2str(h))).(config.ModelNames{i}).neg = neg;
                %fit.(strcat('h',num2str(h))).(config.ModelNames{i}).coeff = coeff;
            end
            if config.Display
                disp(strcat(sprintf(' \t @'),config.ModelNames{i},' done...'))
            end
        end
    end
    if config.Display
        toc
    end
end