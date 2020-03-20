function [mdl,mdl_t,mdl_p,f_hat,SSE,DF,coeff] = estimateARX(data,lags,h,nw)
% estimateHARX function
% HAR-RV model with exogen variables

% Output:
% mdl: Estimated model
% mdl_t: Estimated NW t statistics
% mdl_p: Estimated NW p values
% f: Realized value of the forecast
% f_hat: Forecasted value
% SSE: SSE of the forecasting model
% DF: DF of the forecasting model
% coeff: All estimated coefficients (rolling window)

    % input check:
    if nargin == 2
        h = 0;
        nw = false;
    elseif nargin == 3
        if islogical(h)
            nw = h;
            h = 0;
        else
            nw = false;
        end
    end
    
    x = [];
    for i=1:numel(lags)
        if i == 1
            x = lagmatrix(data(:,i),0:1:lags(i));
        else
            x = [x lagmatrix(data(:,i),1:1:lags(i))];
        end
    end
    x = x(max(lags)+1:end,:);
    mdl = fitlm(x(:,2:end),x(:,1));

    % NW t-stat (with bandwidth max(lags)):
    if nw == 1
        [~,se,coeff] = hac(mdl,'display','off','bandwidth', max(lags));
        mdl_t = coeff./se;
        v = mdl.DFE;
        mdl_p = (betainc(v./(v+mdl_t.^2),v./2,0.5));
    else
        mdl_t = 0;
        mdl_p = 0;
    end
    
    % Forecast:
    if h > 0
        data_flipped = flip(data);
        pred_x = [];
        for i=1:numel(lags)
            pred_x = [pred_x; data_flipped(1:lags(i),i)];
        end
        %f_hat = forecast(mdl,pred_x',h,'InitialCondition','e'); % forecasted value - forecasting function is not working!!!
        f_hat = h;
        SSE = mdl.SSE;
        DF = mdl.DFE;
        coeff = mdl.Coefficients.Estimate';
    else
        f_hat = 0;
        SSE = 0;
        DF = 0;
        coeff = 0;
    end
end