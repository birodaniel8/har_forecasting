function [mdl,mdl_t,mdl_p,f,f_hat,SSE,DF,coeff,neg] = estimateHARX(x,configHAR)
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

    % select the model:
    switch configHAR.Model
        case 'HAR' % HAR
            m = 'RV~RV1+RV2+RV3';
        case 'LHAR' % LHAR
            m = 'RV~L1+RV1+RV2+RV3';
        case 'HAR_J' % HAR_J
            m = 'RV~RV1+RV2+RV3+J1';
        case 'HAR_TJ' % HAR_TJ
            m = 'RV~RV1+RV2+RV3+TJ1';    
        case 'HAR_CJ' % HAR_CJ
            m = 'RV~C1+J1+RV2+RV3';
        case 'HAR_TCJ' % HAR_TCJ
            m = 'RV~TC1+TJ1+RV2+RV3';
        case 'HAR_RS' % HAR_RS
            m = 'RV~RSVN1+RSVP1+RV2+RV3';
        case 'HAR_RS2' % HAR_RS2
            m = 'RV~RV1+GJR1+RV2+RV3';
        case 'HAR_SJ' % HAR_SJ
            m = 'RV~BPV1+SJ1+RV2+RV3';
        case 'HAR_SJ2' % HAR_SJ2
            m = 'RV~BPV1+SJN1+SJP1+RV2+RV3';
        case 'HAR_RSK' % HAR_RSK
            m = 'RV~RV1+RV2+RV3+RSK1';
        case 'HAR_RSK_RKU' % HAR_RSK_RKU
            m = 'RV~RV1+RV2+RV3+RSK1+RKU1'; 
        case 'HAR_IV' % HAR_IV
            m = 'RV~RV1+RV2+RV3+IV1';
        case 'HAR_IVS' % HAR_IVS
            m = 'RV~RV1+RV2+RV3+IVS1';
        case 'HAR_IS' % HAR_IS
            m = 'RV~RV1+RV2+RV3+IS1';
        case 'HAR_IK' % HAR_IK
            m = 'RV~RV1+RV2+RV3+IK1';
        case 'HAR_IV_IS' % HAR_IV_IS
            m = 'RV~RV1+RV2+RV3+IV1+IS1';
        case 'HAR_IV_IK' % HAR_IV_IK
            m = 'RV~RV1+RV2+RV3+IV1+IK1';
        case 'HAR_IV_IS_IK' % HAR_IV_IS_IK
            m = 'RV~RV1+RV2+RV3+IV1+IS1+IK1';
        case 'HARQ' % HARQ
            m = 'RV~RV1+RQRV1+RV2+RV3';
        otherwise
            m = configHAR.Model;
    end
    % extract variable names:
    temp = split(m,'~');
    temp2 = split(temp{2},'+');
    vars = [temp{1}; temp2];

    % fit HAR model
    % dependent variable:
    Tbl = x.(vars{1});
    % lagged variables:
    for i=2:numel(vars)
        Tbl = [Tbl x.(vars{i})];
    end
    % convert to table:
    Tbl = array2table(Tbl);
    Tbl.Properties.VariableNames = vars;
    % cut to the right size:
    data = Tbl(max(configHAR.k):size(Tbl,1)-configHAR.h,:);
    % fit OLS:
    mdl = fitlm(data,m,'Intercept',configHAR.Intercept);

    % NW t-stat (with bandwidth 2+2h):
    if configHAR.NW == 1
        [~,se,coeff] = hac(mdl,'display','off','bandwidth', 2+2*configHAR.h);
        mdl_t = coeff./se;
        v = mdl.DFE;
        mdl_p = (betainc(v./(v+mdl_t.^2),v./2,0.5));
    else
        mdl_t = 0;
        mdl_p = 0;
    end
    
    % Forecast:
    if configHAR.Forecast == 1
        f = table2array(Tbl(end,1)); % actual value
        f_hat = predict(mdl,table2array(Tbl(end,2:end))); % forecasted value
        neg = 0;
        % if not log-model and f_hat is negative, replace it with mean
        if f_hat<=0 && ~strcmp(configHAR.Transform,'log') && ~strcmp(configHAR.Transform,'logsqrt')
            if configHAR.Display
                disp(strcat( 'Warning: Negative forecasted value replaced with the last value, Model: ', configHAR.ModelName))
            end
            neg = 1;
            f_hat = table2array(Tbl(size(Tbl,1)-configHAR.h,1));
        end
        SSE = mdl.SSE;
        DF = mdl.DFE;
        coeff = mdl.Coefficients.Estimate';
    else
        f = 0;
        f_hat = 0;
        SSE = 0;
        DF = 0;
        coeff = 0;
        neg = 0;
    end
end