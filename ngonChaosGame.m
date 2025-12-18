function out = ngonChaosGame(N, varargin)
%NGONCHAOSGAME Chaos game on a regular N-gon (N >= 5), with optional exclusion rules
%and a "reel-like" animation where the diagonal appears, the point is fixed,
%and the diagonal disappears.
%
%   out = ngonChaosGame(N) runs with defaults (ratio='auto', animated).
%   out = ngonChaosGame(N, 'Name',Value, ...) customizes behavior.
%
% REQUIRED
%   N (integer) : number of sides, N >= 5
%
% NAME-VALUE OPTIONS (defaults)
%   'nIter'          : 200000          number of iterations/points
%   'Ratio'          : 'auto'          'auto' uses kissing/optimal ratio by N mod 4
%                                      or numeric scalar with 0 < Ratio < 1.5
%   'Seed'           : []              RNG seed (integer). [] => do not touch rng
%   'BurnIn'         : 50              do not display/store first BurnIn points
%
% Exclusion rules (precedence: RuleFcn > ExcludeOffsets > Rule)
%   'Rule'           : 'none'          'none' | 'noRepeat' | 'noAdjacent' | 'noNeighbors'
%   'ExcludeOffsets' : []              integer offsets forbidden wrt previous vertex
%                                      e.g. [0 1 -1] forbids same and neighbors
%   'RuleFcn'        : []              @(prev, hist, N) allowedIndices
%   'HistoryLength'  : 10              how many previous vertex indices to pass in hist
%
% Plot/animation
%   'Plot'           : true
%   'Animate'        : true
%   'AnimateSteps'   : 4000            iterations with diagonal on/off each step
%   'BatchSize'      : 1500            batch size for adding points after AnimateSteps
%   'Pause'          : 0               seconds pause per animated iteration (optional)
%   'ShowCursor'     : false            show current point marker during animation
%   'StorePoints'    : false
%
% Geometry / style (polygon is ALWAYS drawn when plotting/exporting)
%   'Radius'         : 1
%   'Center'         : [0 0]
%   'Rotation'       : pi/2            rotate polygon (pi/2 => a vertex at the top)
%   'Background'     : [0 0 0]
%   'EdgeColor'      : [1 1 1]
%   'EdgeLineWidth'  : 2
%   'PointColor'     : [1 1 1]
%   'PointMarker'    : '.'
%   'PointMarkerSize': 6
%   'DiagColor'      : [1 1 1]
%   'DiagLineWidth'  : 1
%   'CursorColor'    : [1 0.8 0]       (if ShowCursor=true)
%   'CursorSize'     : 40              scatter size
%
% Export (optional)
%   'PngFile'        : ''              e.g. 'ngon.png'
%   'Dpi'            : 300
%   'VideoFile'      : ''              e.g. 'ngon.mp4' (records only while animating)
%   'Fps'            : 30
%
% OUTPUT (struct; if not requested, simulation still runs and plots/exports)
%   out.vertices   : (N x 2) polygon vertices
%   out.ratioUsed  : scalar
%   out.ruleUsed   : struct describing the effective rule
%   out.points     : (nIter x 2) points if stored, otherwise []
%   out.handles    : figure/axes/graphics handles (if plotted)
%
% Examples:
%   ngonChaosGame(7); % heptagon, ratio auto, animated
%   ngonChaosGame(9, 'Animate', false, 'nIter', 800000); % fast render
%   ngonChaosGame(7, 'Rule', 'noAdjacent'); % constrained variant
%   ngonChaosGame(11, 'Ratio', 0.73, 'PngFile', 'ngon11.png');
%
%           Created by Giuseppe Cardillo
%           giuseppe.cardillo.75@gmail.com
%           GitHub: https://github.com/dnafinder/ChaosGame

    % -------- input parsing
    p = inputParser;
    p.FunctionName = 'ngonChaosGame';

    addRequired(p, 'N', @(x) validateattributes(x, {'numeric'}, {'scalar','integer','>=',5}));

    addParameter(p, 'nIter', 200000, @(x) validateattributes(x, {'numeric'}, {'scalar','integer','>=',1}));
    addParameter(p, 'Ratio', 'auto', @(x) ischar(x) || isstring(x) || (isnumeric(x) && isscalar(x)));
    addParameter(p, 'Seed', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x)));
    addParameter(p, 'BurnIn', 50, @(x) validateattributes(x, {'numeric'}, {'scalar','integer','>=',0}));

    addParameter(p, 'Rule', 'none', @(x) ischar(x) || isstring(x));
    addParameter(p, 'ExcludeOffsets', [], @(x) isempty(x) || (isnumeric(x) && isvector(x) && all(isfinite(x))));
    addParameter(p, 'RuleFcn', [], @(x) isempty(x) || isa(x,'function_handle'));
    addParameter(p, 'HistoryLength', 10, @(x) validateattributes(x, {'numeric'}, {'scalar','integer','>=',0}));

    addParameter(p, 'Plot', true, @(x) islogical(x) && isscalar(x));
    addParameter(p, 'Animate', true, @(x) islogical(x) && isscalar(x));
    addParameter(p, 'AnimateSteps', 4000, @(x) validateattributes(x, {'numeric'}, {'scalar','integer','>=',0}));
    addParameter(p, 'BatchSize', 1500, @(x) validateattributes(x, {'numeric'}, {'scalar','integer','>=',1}));
    addParameter(p, 'Pause', 0, @(x) validateattributes(x, {'numeric'}, {'scalar','>=',0}));
    addParameter(p, 'ShowCursor', false, @(x) islogical(x) && isscalar(x));
    addParameter(p, 'StorePoints', false, @(x) islogical(x) && isscalar(x));

    addParameter(p, 'Radius', 1, @(x) validateattributes(x, {'numeric'}, {'scalar','>',0}));
    addParameter(p, 'Center', [0 0], @(x) validateattributes(x, {'numeric'}, {'vector','numel',2}));
    addParameter(p, 'Rotation', pi/2, @(x) validateattributes(x, {'numeric'}, {'scalar','finite'}));

    addParameter(p, 'Background', [0 0 0], @(x) isnumeric(x) && numel(x)==3);
    addParameter(p, 'EdgeColor', [1 1 1], @(x) (ischar(x) || isstring(x) || (isnumeric(x) && numel(x)==3)));
    addParameter(p, 'EdgeLineWidth', 2, @(x) validateattributes(x, {'numeric'}, {'scalar','>',0}));
    addParameter(p, 'PointColor', [1 1 1], @(x) (ischar(x) || isstring(x) || (isnumeric(x) && numel(x)==3)));
    addParameter(p, 'PointMarker', '.', @(x) ischar(x) || isstring(x));
    addParameter(p, 'PointMarkerSize', 6, @(x) validateattributes(x, {'numeric'}, {'scalar','>',0}));
    addParameter(p, 'DiagColor', [1 1 1], @(x) (ischar(x) || isstring(x) || (isnumeric(x) && numel(x)==3)));
    addParameter(p, 'DiagLineWidth', 1, @(x) validateattributes(x, {'numeric'}, {'scalar','>',0}));
    addParameter(p, 'CursorColor', [1 0.8 0], @(x) (ischar(x) || isstring(x) || (isnumeric(x) && numel(x)==3)));
    addParameter(p, 'CursorSize', 40, @(x) validateattributes(x, {'numeric'}, {'scalar','>',0}));

    addParameter(p, 'PngFile', '', @(x) ischar(x) || isstring(x));
    addParameter(p, 'Dpi', 300, @(x) validateattributes(x, {'numeric'}, {'scalar','>=',72}));
    addParameter(p, 'VideoFile', '', @(x) ischar(x) || isstring(x));
    addParameter(p, 'Fps', 30, @(x) validateattributes(x, {'numeric'}, {'scalar','>',0}));

    parse(p, N, varargin{:});
    opt = p.Results;

    % -------- ratio selection/validation
    if ischar(opt.Ratio) || isstring(opt.Ratio)
        rstr = lower(string(opt.Ratio));
        if rstr ~= "auto"
            error('ngonChaosGame:Ratio', "If Ratio is text, it must be 'auto'.");
        end
        ratioUsed = kissingRatio(N);
    else
        ratioUsed = opt.Ratio;
        if ~(isfinite(ratioUsed) && isscalar(ratioUsed) && ratioUsed > 0 && ratioUsed < 1.5)
            error('ngonChaosGame:Ratio', 'Numeric Ratio must satisfy 0 < Ratio < 1.5.');
        end
    end

    if ~isempty(opt.Seed)
        rng(opt.Seed);
    end

    nIter = opt.nIter;
    burn = min(opt.BurnIn, nIter);

    % -------- polygon vertices
    cx = opt.Center(1);
    cy = opt.Center(2);
    R  = opt.Radius;

    theta = (0:N-1)' * (2*pi/N) + opt.Rotation;
    vertices = [cx + R*cos(theta), cy + R*sin(theta)];

    % Start at center (stable, deterministic)
    x = [cx, cy];

    % -------- rule bookkeeping
    ruleUsed = struct();
    ruleUsed.Rule = string(opt.Rule);
    ruleUsed.ExcludeOffsets = opt.ExcludeOffsets;
    ruleUsed.RuleFcn = opt.RuleFcn;
    ruleUsed.HistoryLength = opt.HistoryLength;

    % Store points only if needed
    storePoints = opt.StorePoints || (nargout > 0);
    
    pts = [];
    if storePoints
        pts = zeros(nIter, 2);  % prealloc sempre quando serve
    end
    
    function recordPoint(kIdx, xNow)
        if storePoints
            pts(kIdx, :) = xNow;
        end
    end


    % -------- plotting / exporting setup
    wantPlot = opt.Plot || (strlength(string(opt.PngFile)) > 0) || (strlength(string(opt.VideoFile)) > 0);

    h = struct();
    vw = [];
    if wantPlot
        h.fig = figure('Color', opt.Background);
        h.ax  = axes(h.fig);
        h.ax.Color = opt.Background;
        hold(h.ax, 'on');

        % polygon ALWAYS drawn
        poly = [vertices; vertices(1,:)];
        h.poly = plot(h.ax, poly(:,1), poly(:,2), ...
            'Color', opt.EdgeColor, 'LineWidth', opt.EdgeLineWidth);

        % points (use animatedline for efficient incremental plotting)
        h.pts = animatedline(h.ax, ...
            'LineStyle', 'none', ...
            'Marker', char(opt.PointMarker), ...
            'MarkerSize', opt.PointMarkerSize, ...
            'Color', opt.PointColor);

        % diagonal handle (reused)
        h.diag = line(h.ax, [NaN NaN], [NaN NaN], ...
            'Color', opt.DiagColor, 'LineWidth', opt.DiagLineWidth, 'Visible', 'off');

        % cursor (optional)
        if opt.ShowCursor
            h.cursor = scatter(h.ax, x(1), x(2), opt.CursorSize, opt.CursorColor, 'filled');
        end

        % Zoom-out if ratioUsed > 1 (overshoot possible)
        if ratioUsed <= 1
            M = R;
        else
            M = (ratioUsed * R) / (2 - ratioUsed);
        end
        lim = 1.15 * M;

        xlim(h.ax, [cx-lim, cx+lim]);
        ylim(h.ax, [cy-lim, cy+lim]);
        axis(h.ax, 'equal');
        axis(h.ax, 'off');

        % video (records frames during animation only)
        vfile = string(opt.VideoFile);
        if strlength(vfile) > 0
            vw = VideoWriter(char(vfile), 'MPEG-4');
            vw.FrameRate = opt.Fps;
            open(vw);
        end
    end

    % -------- preallocated history (ring buffer) for RuleFcn
    H = opt.HistoryLength;
    if H > 0
        idxHistBuf = zeros(1, H);
        histHead = 0;   % points to most recent entry
        histLen  = 0;   % number of valid entries (<= H)
    else
        idxHistBuf = [];
        histHead = 0;
        histLen  = 0;
    end

    % -------- main iteration state
    prev = NaN; % previous vertex index

    animateSteps = min(opt.AnimateSteps, nIter);
    doAnimate = wantPlot && opt.Animate && animateSteps > 0;

    % helper: choose next vertex index (build histVec only if RuleFcn is used)
    function j = chooseVertex(prevIdx)
        if ~isempty(opt.RuleFcn)
            if H == 0 || histLen == 0
                histVec = [];
            else
                ii = histHead:-1:(histHead-histLen+1);
                ii = mod(ii-1, H) + 1;
                histVec = idxHistBuf(ii);
            end

            allowed = opt.RuleFcn(prevIdx, histVec, N);
            allowed = allowed(:)';

            if isempty(allowed) || any(~isfinite(allowed)) || any(mod(allowed,1)~=0)
                error('ngonChaosGame:RuleFcn', 'RuleFcn must return a non-empty vector of integer indices.');
            end

            allowed = unique(allowed);
            if any(allowed < 1) || any(allowed > N)
                error('ngonChaosGame:RuleFcn', 'RuleFcn returned indices outside 1..N.');
            end

        elseif ~isempty(opt.ExcludeOffsets)
            if isnan(prevIdx)
                allowed = 1:N;
            else
                offs = opt.ExcludeOffsets(:)';
                forb = mod((prevIdx-1) + offs, N) + 1;
                allowed = setdiff(1:N, unique(forb));
            end

        else
            rule = lower(string(opt.Rule));
            if rule == "none" || isnan(prevIdx)
                allowed = 1:N;
            elseif rule == "norepeat"
                allowed = setdiff(1:N, prevIdx);
            elseif rule == "noadjacent"
                forb = mod((prevIdx-1) + [-1 0 1], N) + 1;
                allowed = setdiff(1:N, unique(forb));
            elseif rule == "noneighbors"
                forb = mod((prevIdx-1) + [-1 1], N) + 1;
                allowed = setdiff(1:N, unique(forb));
            else
                error('ngonChaosGame:Rule', "Unknown Rule: '%s'.", opt.Rule);
            end
        end

        if isempty(allowed)
            error('ngonChaosGame:RuleEmpty', 'Exclusion rule produced an empty allowed set (N=%d).', N);
        end

        j = allowed(randi(numel(allowed)));
    end

    % helper: update ring buffer with new vertex j
    function updateHistory(jNew)
        if H <= 0
            return;
        end
        histHead = histHead + 1;
        if histHead > H
            histHead = 1;
        end
        idxHistBuf(histHead) = jNew;
        if histLen < H
            histLen = histLen + 1;
        end
    end

    % ---- animated part (diagonal on/off each step)
    for k = 1:animateSteps
        j = chooseVertex(prev);
        v = vertices(j, :);

        if doAnimate
            set(h.diag, 'XData', [x(1) v(1)], 'YData', [x(2) v(2)], 'Visible', 'on');
        end

        x = (1 - ratioUsed) * x + ratioUsed * v;

        if storePoints
            recordPoint(k, x);
        end

        if wantPlot
            if k > burn
                addpoints(h.pts, x(1), x(2));
            end
            if opt.ShowCursor
                set(h.cursor, 'XData', x(1), 'YData', x(2));
            end
            if doAnimate
                set(h.diag, 'Visible', 'off');
                drawnow limitrate;

                if ~isempty(vw)
                    writeVideo(vw, getframe(h.fig));
                end
                if opt.Pause > 0
                    pause(opt.Pause);
                end
            end
        end

        prev = j;
        updateHistory(j);
    end

    % ---- fast tail (no diagonal), still respecting exclusion rules
    if animateSteps < nIter
        batchX = zeros(1, opt.BatchSize);
        batchY = zeros(1, opt.BatchSize);
        bCount = 0;

        for k = (animateSteps+1):nIter
            j = chooseVertex(prev);
            v = vertices(j, :);

            x = (1 - ratioUsed) * x + ratioUsed * v;

            if storePoints
                recordPoint(k, x);
            end

            if wantPlot && (k > burn)
                bCount = bCount + 1;
                batchX(bCount) = x(1);
                batchY(bCount) = x(2);

                if bCount == opt.BatchSize || k == nIter
                    addpoints(h.pts, batchX(1:bCount), batchY(1:bCount));
                    bCount = 0;
                    drawnow limitrate;
                end
            end

            prev = j;
            updateHistory(j);
        end
    end

    if wantPlot && opt.ShowCursor && isfield(h,'cursor')
        set(h.cursor, 'Visible', 'off');
    end

    % finalize video (one last frame for the final state)
    if ~isempty(vw)
        if wantPlot
            writeVideo(vw, getframe(h.fig));
        end
        close(vw);
    end

    % PNG export
    pfile = string(opt.PngFile);
    if wantPlot && strlength(pfile) > 0
        exportgraphics(h.ax, char(pfile), 'Resolution', opt.Dpi);
    end

    % -------- output
    if nargout > 0
        out = struct();
        out.vertices  = vertices;
        out.ratioUsed = ratioUsed;
        out.ruleUsed  = ruleUsed;
        out.points    = pts;
        out.handles   = h;
    end
end

% ---- local helper: kissing/optimal ratio for regular N-gon (N>=5)
function r = kissingRatio(N)
    m = mod(N, 4);
    if m == 0
        r = 1 / (1 + tan(pi / N));
    elseif m == 2
        r = 1 / (1 + sin(pi / N));
    else % m == 1 or 3
        r = 1 / (1 + 2 * sin(pi / (2*N)));
    end
end
