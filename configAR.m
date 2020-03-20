function config = configAR(varargin)
% configHAR function
% Configure HAR model specifications
%
% Config: Previous configuration (default = [])
% Type: 'insample' or 'outofsample' modelling (default = 'insample')
% Models: List of models (default = 'HAR')
% ModelNames: List of model names (default is set to the list of models)
% h: Vector of forecasting horizons (default = 1)
% k: 1x3 vector of lag structure (default = [1 5 22])
% T: 1x2 of time interval or 0 (default = 0 ie all datapoints)
% w: Rolling window size for out of sample forecast (default = 1000)
% Overlap: 1 - The original lag structure with overlap (Corsi 2009)
%          0 - Lag structure without overlap (Patton & Sheppard 2015)
% Transform: Transformation of the variables (default = 'no' ie no transformation)
% TransformType: Cell of transformation type (default = 'no' ie basic transformation)
% TransformSum: Summation order: 1 (sum(f(x))) or 0 (f(sum(x))) (default = 0)
% NormVar: Normalizing Variable (e.g.: Realized Variance)
% Intercept: Models with intercept (default = true)
% Display: Displaying the process of estimation: true - on, false - off (default = false)  

% Default values:
    defaultConfig = [];
    defaultType = 'insample';
    defaultModels = {'HAR'};
    defaultModelNames = 0;
    defaultH = 1;
    defaultK = [1 5 22];
    defaultT = 0;
    defaultW = 2;
    defaultOverlap = 1;
    defaultTransf = 'no';
    defaultTransfType = 'no';
    defaultTransfSum = 0;
    defaultNormVar = '';
    defaultIntercept = true;
    defaultDisplay = false;
    
% ImputParser:
    p = inputParser;
    addOptional(p,'Config',defaultConfig,@valConfig);  
    addOptional(p,'Type',defaultType,@valType);  
    addOptional(p,'Models',defaultModels,@valModels);
    addOptional(p,'ModelNames',defaultModelNames,@valModelNames);
    addOptional(p,'h',defaultH,@valH);
    addOptional(p,'k',defaultK,@valK);
    addOptional(p,'T',defaultT,@valT);
    addOptional(p,'w',defaultW,@valW);
    addOptional(p,'Overlap',defaultOverlap,@valOverlap);    
    addOptional(p,'Transform',defaultTransf,@valTransf);
    addOptional(p,'TransformType',defaultTransfType,@valTransfType);
    addOptional(p,'TransformSum',defaultTransfSum,@valTransfSum);
    addOptional(p,'NormVar',defaultNormVar,@valNormVar);
    addOptional(p,'Intercept',defaultIntercept,@valIntercept);
    addOptional(p,'Display',defaultDisplay,@valDisplay);
    parse(p,varargin{:});
    
% Addittional validation checks and transformations:
    if isempty(p.Results.Config)
        % Convert MODELS to cell if it is a string:
        if isstring(p.Results.Models)
            models = cellstr(p.Results.Models);
        else
            models = p.Results.Models;
        end
    else
        models = p.Results.Config.Models;
    end
    
    % Convert MODELNAMES to cell if it is a string:
    if isstring(p.Results.ModelNames)
        modelnames = cellstr(p.Results.ModelNames);
    else
        % If MODELNAMES are not given, set it to MODELS:
        if isnumeric(p.Results.ModelNames)
            modelnames = models;
        else
            modelnames = p.Results.ModelNames;
        end
    end
    
    % MODELS and MODELNAMES must be vectors have the same size:
    if numel(models)~=numel(modelnames) && isvector(models) && isvector(modelnames)
        error('MODELS and MODELNAMES must be vectors have the same size')
    end
    
    % Contert TRANSFORMTYPE to cell if it is a string:
    if isstring(p.Results.TransformType)
        ttype = cellstr(p.Results.TransformType);
    else
        ttype = p.Results.TransformType;
    end
    % Reshape TRANSFORMTYPE to a vector:
    if size(ttype,2) == 2 && ~sum(sum(strcmp(ttype,'no')))
        ttype = reshape(ttype',[numel(ttype),1]);
    end
    
    if isstruct(p.Results.Config) % Modifying previous configuration:
        config = p.Results.Config;
        modif = varargin(3:2:numel(varargin));
        for i = 1:numel(modif)
            if strcmp(modif{i},'Models')
                config.(modif{i}) = models;
            elseif strcmp(modif{i},'ModelNames')
                config.(modif{i}) = modelnames;
            elseif strcmp(modif{i},'TransformType')
                config.(modif{i}) = ttype;
            else
                config.(modif{i}) = p.Results.(modif{i});
            end
        end
    else % Create new configuration:
        config.Type = p.Results.Type;
        config.Models = models;
        config.ModelNames = modelnames;
        config.h = p.Results.h;
        config.k = p.Results.k;
        config.T = p.Results.T;
        config.w = p.Results.w;
        config.Overlap = p.Results.Overlap;
        config.Transform = p.Results.Transform;
        config.TransformType = ttype;
        config.TransformSum = p.Results.TransformSum;
        config.NormVar = p.Results.NormVar;
        config.Intercept = p.Results.Intercept;
        config.Display = p.Results.Display;
    end
end

% Validation functions:
% CONFIG must be a logical value:
function val = valConfig(x)
    val = false;
    if ~isstruct(x)
        error('CONFIG must be a structure')
    else
        val = true;
    end
end
% TYPE must be insample or outofsample:
function val = valType(x)
    val = false;
    if ~isstring(x) && ~ischar(x)
        error('TYPE must be a string or char')        
    elseif ~ismember(x,["insample";"outofsample"])
        error('TYPE must be insample or outofsample')
    else
        val = true;
    end
end

% MODELS must be a vector or cell of strings:
function val = valModels(x)
    val = false;
    if ~isstring(x) && ~iscellstr(x)
        error('MODELS must be a vector or cell of strings')
    else
        val = true;
    end
end

% MODELNAMES must be a vector or cell of strings with format applicable to variable names:
function val = valModelNames(x)
    val = false;
    if ~isstring(x) && ~iscellstr(x)
        error('MODELNAMES must be a vector or cell of strings')
    else
        if isstring(x)
            x = cellstr(x);
        end
        % check whether model names can be variable names:
        for i = 1:numel(x)
            if ~isvarname(x{i})
                error('MODELNAMES must be applicable to variable names');
            end
        end
        val = true;
    end
end

% H must be a numeric vector:
function val = valH(x)
    val = false;
    if ~isvector(x) || ~isnumeric(x)
        error('H must be a numeric vector')
    else
        val = true;
    end
end

% K must be a numeric 1x3 with increasing numbers:
function val = valK(x)
    val = false;
    if ~isvector(x) || ~isnumeric(x) || numel(x)~=3
        error('K must be a numeric 1x3 vector')      
    elseif x(1)>=x(2) || x(2)>=x(3)
        error('Values of K must increase')      
    else
        val = true;
    end
end

% T must be a positive numeric 1x2 vector with T(2)>T(1), or 0:
function val = valT(x)
    val = false;
    if ~isvector(x) || ~isnumeric(x)
        error('T must be a numeric 1x2 vector')
    elseif numel(x)~=2 && sum(x==0)~=1
        error('T must be a numeric 1x2 vector')
    elseif numel(x)==2 
        if x(1) >= x(2)
            error('T(2) must be set larger than T(1)')
        elseif x(1)<1
            error('T must be a positive numeric vector')
        end
        val = true;
    else
        val = true;
    end
end

% W must be a numeric value:
function val = valW(x)
    val = false;
    if ~isnumeric(x) || numel(x)~=1
        error('W must be a numeric value')        
    else
        val = true;
    end
end

% OVERLAP must be set to 0 (overlapping) or 1 (non-overlapping):
function val = valOverlap(x)
    val = false;
    if ~isnumeric(x) 
        error('OVERLAP must be set to 0 (overlapping) or 1 (non-overlapping)')                
    elseif ~ismember(x, [0,1])
        error('OVERLAP must be set to 0 (overlapping) or 1 (non-overlapping)')        
    else
        val = true;
    end
end

% TRANSFORM must be "no" or "log" or "sqrt":
function val = valTransf(x)
    val = false;
    if ~isstring(x) && ~ischar(x)
        error('TRANSFORM must be "no" or "log" or "sqrt" or "logsqrt"');   
    elseif ~ismember(x,["no","log","sqrt","logsqrt"])
        error('TRANSFORM must be "no" or "log" or "sqrt" or "logsqrt"');   
    else
        val = true;
    end
end

% TRANSFORMTYPE must be a vector/matrix or cell of strings with an even number of elements, or 'no':
function val = valTransfType(x)
    val = false;
    if ~isstring(x) && ~iscellstr(x)
        error('TRANSFORMTYPE must be a vector/matrix or cell of strings')
    elseif ~sum(sum(strcmp(x,"no"))) && mod(numel(x),2)~=0 
        error('TRANSFORMTYPE must contain an even number of elements')
    else
        val = true;
    end
end

% TRANSFORMSUM must be 1 (sum(f(x))) or 0 (f(sum(x))):
function val = valTransfSum(x)
    val = false;
    if ~isnumeric(x)
        error('TRANSFORMSUM must be 1 (sum(f(x))) or 0 (f(sum(x)))')
    elseif x~=0 && x~=1
        error('TRANSFORMSUM must be 1 (sum(f(x))) or 0 (f(sum(x)))')        
    else
        val = true;
    end
end

% NORMVAR must be a string or char:
function val = valNormVar(x)
    val = false;
    if ~isstring(x) && ~ischar(x)
        error('NORMVAR must be a string or char')
    else
        val = true;
    end
end

% INTERCEPT must be a logical value:
function val = valIntercept(x)
    val = false;
    if ~islogical(x)
        error('INTERCEPT must be a logical value')
    else
        val = true;
    end
end

% DISPLAY must be a logical value:
function val = valDisplay(x)
    val = false;
    if ~islogical(x)
        error('DISPLAY must be a logical value')
    else
        val = true;
    end
end