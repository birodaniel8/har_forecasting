function fit = fitAR(data,config,lags,ext)
% fitAR function
% fitting AR models for in sample and out of sample analysis
%
% data: Input data vector
% config: AR configuration
% lags: Number of autoregressive lags
    
    % Input checking:
%     fn = fieldnames(data);
%     for i=2:numel(fn)
%         if size(data.(fn{i}),1)~=size(data.(fn{1}),1)
%             error('The variables in DATA must have the same size')
%         end
%     end
%     config.Size = size(data.(fn{1}),1);
%     if config.T == 0
%         config.T = [1 size(data.(fn{1}),1)];
%     end
%     if config.T(2)>size(data.(fn{1}),1)
%         error('T(2) must be less than the number of observations in DATA')
%     end
%     if config.w>(config.T(2)-config.T(1))
%         error('W (window size) must be less than the number of used observations')
%     end
    
    tic % start timer

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
                for j = 1:(size(input,1)-config.w-h+1)
                    [~,~,~,f,f_hat,sse,df,coeff] = estimateHARX(input(j:config.w+j-1,:),configHAR);
                    fit.(strcat('h',num2str(h))).(config.ModelNames{i}).f(j,1) = f;
                    fit.(strcat('h',num2str(h))).(config.ModelNames{i}).f_hat(j,1) = f_hat;
                    fit.(strcat('h',num2str(h))).(config.ModelNames{i}).sse(j,1) = sse;
                    fit.(strcat('h',num2str(h))).(config.ModelNames{i}).df(j,1) = df;
                    fit.(strcat('h',num2str(h))).(config.ModelNames{i}).coeff(j,:) = coeff;
                end
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