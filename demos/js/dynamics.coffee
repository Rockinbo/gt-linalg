
######################################################################
# Shaders

easeCode = \
    """
    #define M_PI 3.1415926535897932384626433832795

    float easeInOutSine(float pos) {
        return 0.5 * (1.0 - cos(M_PI * pos));
    }
    """

rotateShader = easeCode + \
    """
    uniform float deltaAngle;
    uniform float scale;
    uniform float time;
    uniform float duration;

    vec4 getPointSample(vec4 xyzw);

    vec4 rotate(vec4 xyzw) {
        vec4 point = getPointSample(xyzw);

        float start = point.z;
        float pos = (time - start) / abs(duration);
        if(duration < 0.0) pos = 1.0 - pos;
        if(pos < 0.0) return vec4(point.xy, 0.0, 0.0);
        if(pos > 1.0) pos = 1.0;
        pos = easeInOutSine(pos);
        float c = cos(deltaAngle * pos);
        float s = sin(deltaAngle * pos);
        point.xy = vec2(point.x * c - point.y * s, point.x * s + point.y * c)
            * pow(scale, pos);
        return vec4(point.xy, 0.0, 0.0);
    }
    """

diagShader = easeCode + \
    """
    uniform float scaleX;
    uniform float scaleY;
    uniform float time;
    uniform float duration;

    vec4 getPointSample(vec4 xyzw);

    vec4 rotate(vec4 xyzw) {
        vec4 point = getPointSample(xyzw);

        float start = point.z;
        float pos = (time - start) / abs(duration);
        if(duration < 0.0) pos = 1.0 - pos;
        if(pos < 0.0) return vec4(point.xy, 0.0, 0.0);
        if(pos > 1.0) pos = 1.0;

        pos = easeInOutSine(pos);
        point.x *= pow(scaleX, pos);
        point.y *= pow(scaleY, pos);
        return vec4(point.xy, 0.0, 0.0);
    }
    """

shearShader = easeCode + \
    """
    uniform float scale;
    uniform float translate;
    uniform float time;
    uniform float duration;

    vec4 getPointSample(vec4 xyzw);

    vec4 shear(vec4 xyzw) {
        vec4 point = getPointSample(xyzw);

        float start = point.z;
        float pos = (time - start) / abs(duration);
        if(duration < 0.0) pos = 1.0 - pos;
        if(pos < 0.0) return vec4(point.xy, 0.0, 0.0);
        if(pos > 1.0) pos = 1.0;

        pos = easeInOutSine(pos);
        float s = pow(scale, pos);
        point.x  = s * (point.x + translate * pos * point.y);
        point.y *= s;
        return vec4(point.xy, 0.0, 0.0);
    }
    """

colorShader = easeCode + \
    """
    uniform float time;
    uniform float duration;

    vec4 getPointSample(vec4 xyzw);
    vec4 getColorSample(vec4 xyzw);

    vec3 hsv2rgb(vec3 c) {
      vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
      vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
      return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
    }

    #define TRANSITION 0.2

    vec4 getColor(vec4 xyzw) {
        vec4 color = getColorSample(xyzw);
        vec4 point = getPointSample(xyzw);

        float start = point.z;
        float pos, ease;
        pos = (time - start) / abs(duration);
        if(duration < 0.0) pos = 1.0 - pos;
        if(pos < 0.0) pos = 0.0;
        else if(pos > 1.0) pos = 1.0;

        if(pos < TRANSITION) {
            ease = easeInOutSine(pos / TRANSITION);
            color.w *= ease * 0.6 + 0.4;
            color.y *= ease * 0.6 + 0.4;
        }
        else if(pos > 1.0 - TRANSITION) {
            ease = easeInOutSine((1.0 - pos) / TRANSITION);
            color.w *= ease * 0.6 + 0.4;
            color.y *= ease * 0.6 + 0.4;
        }
        return vec4(hsv2rgb(color.xyz), color.w);
    }
    """

sizeShader = easeCode + \
    """
    uniform float time;
    uniform float small;
    uniform float duration;

    vec4 getPointSample(vec4 xyzw);

    #define TRANSITION 0.2
    #define BIG (small * 7.0 / 5.0)

    vec4 getSize(vec4 xyzw) {
        vec4 point = getPointSample(xyzw);

        float start = point.z;
        float pos, ease, size = BIG;
        pos = (time - start) / abs(duration);
        if(duration < 0.0) pos = 1.0 - pos;
        if(pos < 0.0) pos = 0.0;
        else if(pos > 1.0) pos = 1.0;

        if(pos < TRANSITION) {
            ease = easeInOutSine(pos / TRANSITION);
            size = small * (1.0-ease) + BIG * ease;
        }
        else if(pos > 1.0 - TRANSITION) {
            ease = easeInOutSine((1.0 - pos) / TRANSITION);
            size = small * (1.0-ease) + BIG * ease;
        }
        return vec4(size, 0.0, 0.0, 0.0);
    }
    """


######################################################################
# Utility functions

HSVtoRGB = (h, s, v) ->
    i = Math.floor(h * 6);
    f = h * 6 - i;
    p = v * (1 - s);
    q = v * (1 - f * s);
    t = v * (1 - (1 - f) * s);
    switch i % 6
        when 0 then [v, t, p]
        when 1 then [q, v, p]
        when 2 then [p, v, t]
        when 3 then [p, q, v]
        when 4 then [t, p, v]
        when 5 then [v, p, q]

expLerp = (a, b) -> (t) -> Math.pow(b, t) * Math.pow(a, 1-t)
linLerp = (a, b) -> (t) -> b*t + a*(1-t)
polyLerp = (a, b, n) -> (t) -> Math.pow(t, n) * (b-a) + a
discLerp = (a, b, n) -> (t) -> Math.floor(Math.random() * (n+1)) * (b-a)/n + a
randElt = (l) -> l[Math.floor(Math.random() * l.length)]
randSign = () -> randElt [-1, 1]

mult22 = (m, v) -> [m[0]*v[0]+m[1]*v[1], m[2]*v[0]+m[3]*v[1]]
inv22 = (m) ->
    det = m[0]*m[3] - m[1]*m[2]
    [m[3]/det, -m[1]/det, -m[2]/det, m[0]/det]

extend = (obj, src) ->
    for key, val of src
        obj[key] = val if src.hasOwnProperty key


######################################################################
# Controller class

class Controller
    constructor: (mathbox, opts) ->
        opts ?= {}
        opts.numPointsRow ?= 50
        opts.numPointsCol ?= 100
        opts.duration     ?= 3.0
        opts.continuous   ?= true
        opts.axisColors   ?= []

        @axisOpts =
            end:     false
            width:   3
            zBias:   -1
            depth:   1
            color:   "black"
            range:   [-10,10]
        extend @axisOpts, (opts.axisOpts ? {})

        @axisColors = opts.axisColors.slice()
        @axisColors[0] ?= [0, 0, 0, 0.3]
        @axisColors[1] ?= [0, 0, 0, 0.3]

        @mathbox = mathbox

        # Current demo
        @current = null
        # Playing forward or backward
        @direction = 1

        @continuous = opts.continuous
        @numPointsRow = opts.numPointsRow
        @numPointsCol = opts.numPointsCol
        @numPoints = @numPointsRow * @numPointsCol - 1
        @duration = opts.duration
        @curTime = 0
        @startTime = -@duration  # when continuous is off
        @points = [[0, 0, -1, 1e15]]

        # Colors
        @colors = [[0, 0, 0, 1]].concat([Math.random(), 1, 0.7, 1] for [0...@numPoints])

        # Un-transformed view
        @view0 = mathbox.cartesian
            range: [[-1, 1], [-1, 1]]
            scale: [1, 1]

        # The variables below are set when the first type is installed
        # Transformed view
        @view = null
        # View extents
        @extents =
            x:   0
            y:   0
            rad: 0

        @initialized  = false
        @shaderElt    = null
        @linesElt     = null
        @linesDataElt = null

    install: (type, opts) =>
        @current = new type @extents, opts
        canvas = @mathbox._context.canvas

        for i in [1..@numPoints]
            @points[i] = @current.newPoint()
            @points[i][2] = @curTime + @delay(true)

        if @initialized
            @shaderElt.set @current.shaderParams()
            @linesDataElt.set @current.linesParams()
            @linesElt.set "closed", @current.refClosed()

        else
            @pointsElt = @view
                .matrix
                    id:       "points-orig"
                    channels: 4
                    width:    @numPointsRow
                    height:   @numPointsCol
                    data:     @points
            @shaderElt = @pointsElt.shader @current.shaderParams(),
                time: (t) => @curTime = t,
                duration: () => @duration * @direction
            @shaderElt.resample id: "points"

            # Coloring pipeline
            @view0
                .matrix
                    channels: 4
                    width:    @numPointsRow
                    height:   @numPointsCol
                    data:     @colors
                    live:     false
                .shader
                    code:    colorShader
                    sources: [@pointsElt]
                ,
                    time: (t) -> t
                    duration: () => @duration * @direction
                .resample id: "colors"

            # Size pipeline
            @view0
                .shader
                    code:   sizeShader
                ,
                    time:  (t) -> t
                    small: () -> 5 / 739 * canvas.clientWidth
                    duration: () => @duration * @direction
                .resample
                    source: @pointsElt
                    id:     "sizes"

            @view
                .point
                    points: "#points"
                    color:  "white"
                    colors: "#colors"
                    size:   1
                    sizes:  "#sizes"
                    zBias:  1
                    zIndex: 2

            # Reference lines
            @linesDataElt = @view.matrix @current.linesParams()
            @linesElt = @view.line
                color:    "rgb(80, 120, 255)"
                width:    2
                opacity:  0.4
                zBias:    0
                zIndex:   1
                closed:   @current.refClosed()

            @initialized = true

    goBackwards: () =>
        for point in @points
            [point[0], point[1]] = mult22 @current.stepMat, point

    goForwards: () =>
        for point in @points
            [point[0], point[1]] = mult22 @current.inverse.stepMat, point

    step: () =>
        if not @continuous
            return if @startTime + @duration > @curTime
            @startTime = @curTime
        @goForwards() if @direction == -1
        @direction = 1
        for point, i in @points
            if i == 0  # Origin
                continue
            if point[2] + @duration <= @curTime
                # Reset point
                [point[0], point[1]] = mult22 @current.stepMat, point
                [point[0], point[1]] = @current.updatePoint point
                # Reset timer
                point[2] = @curTime + @delay()
        null

    unStep: () =>
        if not @continuous
            return if @startTime + @duration > @curTime
            @startTime = @curTime
        @goBackwards() if @direction == 1
        @direction = -1
        inv = @current.inverse
        for point, i in @points
            if i == 0  # Origin
                continue
            if point[2] + @duration <= @curTime
                # Reset point
                [point[0], point[1]] = inv.updatePoint point
                [point[0], point[1]] = mult22 inv.stepMat, point
                # Reset timer
                point[2] = @curTime + @delay()
        null

    start: () => setInterval @step, 100

    # Choose random (but not too wonky) coordinate system
    randomizeCoords: () =>
        v1 = [0, 0]
        v2 = [0, 0]

        # Vector length between 1/2 and 2
        distribution = linLerp 0.5, 2
        len = distribution Math.random()
        θ = Math.random() * 2 * π
        v1[0] = Math.cos(θ) * len
        v1[1] = Math.sin(θ) * len
        # Angle between vectors between 45 and 135 degrees
        θoff = randSign() * linLerp(π/4, 3*π/4)(Math.random())
        len = distribution Math.random()
        v2[0] = Math.cos(θ + θoff) * len
        v2[1] = Math.sin(θ + θoff) * len

        @installCoords [v1[0], v2[0], v1[1], v2[1]]

    installCoords: (coordMat) =>
        # coordMat = [1,0,0,1]
        # Find the farthest corner in the un-transformed coord system
        coordMatInv = inv22 coordMat
        corners = [[1, 1], [-1, 1]].map (c) -> mult22 coordMatInv, c
        rad = Math.max.apply null, corners.map (c) -> c[0]*c[0] + c[1]*c[1]
        @extents =
            rad: Math.sqrt rad
            x:   Math.max.apply null, corners.map (c) -> Math.abs c[0]
            y:   Math.max.apply null, corners.map (c) -> Math.abs c[1]

        transformMat = [coordMat[0], coordMat[1], 0, 0,
                        coordMat[2], coordMat[3], 0, 0,
                        0, 0, 1, 0,
                        0, 0, 0, 1]
        if @view
            @view.set 'matrix', transformMat
        else
            @view = @view0.transform matrix: transformMat
            for i in [1, 2]
                @axisOpts.axis    = i
                @axisOpts.color   = @axisColors[i-1]
                @axisOpts.opacity = @axisColors[i-1][3]
                @view.axis @axisOpts

    delay: (first) =>
        if not @continuous
            return if first then -@duration else 0
        scale = @numPoints / 1000
        pos = Math.random() * scale
        if first
            pos - 0.5 * scale
        else
            pos


######################################################################
# Dynamics base class

class Dynamics
    constructor: (@extents) ->

    linesParams: () =>
        @reference = @makeReference()
        channels: 2
        height:   @reference.length
        width:    @reference[0].length
        items:    @reference[0][0].length
        data:     @reference
        live:     false

    refClosed: () => false


######################################################################
# Complex eigenvalues

class Complex extends Dynamics
    constructor: (extents, opts) ->
        super extents, opts
        opts ?= {}
        @θ     = opts.θ     ? randSign() * linLerp(π/6, 5*π/6)(Math.random())
        @scale = opts.scale ? @randomScale()

        @stepMat = [Math.cos(@θ) * @scale, -Math.sin(@θ) * @scale,
                    Math.sin(@θ) * @scale,  Math.cos(@θ) * @scale]

        @makeDistributions opts

    newPoint: (oldPoint) =>
        distribution = if not oldPoint then @origDist else @newDist
        r = distribution Math.random()
        θ = Math.random() * 2 * π
        [Math.cos(θ) * r, Math.sin(θ) * r, 0, 0]

    shaderParams: () =>
        code: rotateShader,
        uniforms:
            deltaAngle: { type: 'f', value: @θ }
            scale:      { type: 'f', value: @scale }


class Circle extends Complex
    descr: () -> "Ovals"

    constructor: (extents, opts) ->
        super extents, opts
        @inverse = opts?.inverse ? new Circle extents,
            θ: -@θ
            scale: 1/@scale
            inverse: @

    randomScale: () => 1

    makeDistributions: (opts) =>
        @newDist = @origDist = polyLerp 0.01, @extents.rad, 1/2

    makeReference: () =>
        ret = []
        for t in [0...2*π] by π/72
            row = []
            for s in [@extents.rad/10...@extents.rad] by @extents.rad/10
                row.push [s * Math.cos(t), s * Math.sin(t)]
            ret.push row
        [ret]

    updatePoint: (point) -> point

    refClosed: () => true


class Spiral extends Complex
    makeReference: () =>
        ret = []
        close = 0.05
        # How many iterations does it take to get from close to farthest?
        s = if @scale > 1 then @scale else 1/@scale
        iters = (Math.log(@extents.rad) - Math.log(close))/Math.log(s)
        # How many full rotations in that many iterations?
        rotations = Math.ceil(@θ * iters / 2*π)
        d = @direction
        # Have to put this in a matrix to avoid texture size limits
        for i in [0..rotations]
            row = []
            for t in [0..100]
                u = (i + t/100) * 2*π
                ss = close * Math.pow(s, u / @θ)
                items = []
                for j in [0...2*π] by π/4
                    items.push [ss * Math.cos(d*(u+j)), ss * Math.sin(d*(u+j))]
                row.push items
            ret.push row
        ret


class SpiralIn extends Spiral
    descr: () -> "Spiral in"

    constructor: (extents, opts) ->
        super extents, opts
        @direction = -1
        @inverse = opts?.inverse ? new SpiralOut extents,
            θ: -@θ
            scale: 1/@scale
            inverse: @

    randomScale: () -> linLerp(0.3, 0.8)(Math.random())

    makeDistributions: (opts) =>
        @close  = 0.01
        @medium = @extents.rad
        @far    = @extents.rad / @scale

        distType = opts.dist ? randElt ['cont', 'disc']

        switch distType
            when 'cont'
                @origDist = expLerp @close, @far
                @newDist = expLerp @medium, @far
            when 'disc'
                distances = []
                distance = @far
                while distance > @close
                    distances.push distance
                    distance *= @scale
                @origDist = (t) -> distances[Math.floor(t * distances.length)]
                @newDist = (t) => @far

    updatePoint: (point) =>
        if point[0]*point[0] + point[1]*point[1] < @close*@close
            @newPoint point
        else
            point


class SpiralOut extends Spiral
    descr: () -> "Spiral out"

    constructor: (extents, opts) ->
        super extents, opts
        @direction = 1
        @inverse = opts?.inverse ? new SpiralIn extents,
            θ: -@θ
            scale: 1/@scale
            inverse: @
            dist: @distType

    randomScale: () => linLerp(1/0.8, 1/0.3)(Math.random())

    makeDistributions: (opts) =>
        @veryClose = 0.01 / @scale
        @close     = 0.01
        @medium    = @extents.rad

        @distType = opts.dist ? randElt ['cont', 'disc']

        switch @distType
            when 'cont'
                @origDist = expLerp @veryClose, @medium
                @newDist = expLerp @veryClose, @close
            when 'disc'
                distances = []
                distance = @veryClose
                while distance < @medium
                    distances.push distance
                    distance *= @scale
                @origDist = (t) -> distances[Math.floor(t * distances.length)]
                @newDist = (t) => @veryClose

    updatePoint: (point) =>
        if point[0]*point[0] + point[1]*point[1] > @medium * @medium
            @newPoint point
        else
            point


######################################################################
# Real eigenvalues, diagonalizable

class Diagonalizable extends Dynamics
    constructor: (extents, opts) ->
        super extents, opts
        opts ?= {}
        @swapped = false
        @makeScales opts
        @stepMat = if @swapped then [@λ2, 0, 0, @λ1] else [@λ1, 0, 0, @λ2]

    swap: () =>
        [@λ2, @λ1] = [@λ1, @λ2]
        [@extents.y, @extents.x] = [@extents.x, @extents.y]
        @swapped = true

    shaderParams: () =>
        code: diagShader,
        uniforms:
            scaleX: { type: 'f', value: if @swapped then @λ2 else @λ1 }
            scaleY: { type: 'f', value: if @swapped then @λ1 else @λ2 }


class Hyperbolas extends Diagonalizable
    descr: () -> "Hyperbolas"

    constructor: (extents, opts) ->
        super extents, opts
        [λ1, λ2] = if @swapped then [@λ2, @λ1] else [@λ1, @λ2]
        @inverse = opts?.inverse ? new Hyperbolas extents,
            λ1: 1/λ1
            λ2: 1/λ2
            inverse: @

    makeScales: (opts) =>
        @λ1 = opts.λ1 ? linLerp(0.3, 0.8)(Math.random())
        @λ2 = opts.λ2 ? linLerp(1/0.8, 1/0.3)(Math.random())
        @swap() if @λ1 > @λ2
        # Implicit equations for paths are x^{log(λ2)}y^{-log(λ1)} = r
        @logScaleX = Math.log @λ1
        @logScaleY = Math.log @λ2
        # @close means (@close, @close) is the closest point to the origin
        @close = 0.05
        @closeR = Math.pow(@close, @logScaleY - @logScaleX)
        @farR = Math.pow(@extents.x, @logScaleY) * Math.pow(@extents.y, -@logScaleX)
        @lerpR = linLerp(@closeR, @farR)

    newPoint: (oldPoint) =>
        # First choose r uniformly between @closeR and @farR
        r = @lerpR Math.random()
        if not oldPoint
            # x value on that hyperbola at y = @extents.y
            closeX = Math.pow(r * Math.pow(@extents.y, @logScaleX), 1/@logScaleY)
            # Choose x value exponentially along that hyperbola
            x = expLerp(closeX, @extents.x / @λ1)(Math.random())
        else
            # As above, but out of sight
            x = expLerp(@extents.x, @extents.x / @λ1)(Math.random())
        # Corresponding y
        y = Math.pow(1/r * Math.pow(x, @logScaleY), 1/@logScaleX)
        if @swapped
            [randSign() * y, randSign() * x, 0, 0]
        else
            [randSign() * x, randSign() * y, 0, 0]

    makeReference: () =>
        ret = []
        for t in [0...20]
            r = @lerpR t/20
            closeX = Math.pow(r * Math.pow(@extents.y, @logScaleX), 1/@logScaleY)
            lerp = expLerp closeX, @extents.x
            row = []
            for i in [0..100]
                x = lerp i/100
                y = Math.pow(1/r * Math.pow(x, @logScaleY), 1/@logScaleX)
                if @swapped
                    row.push [[y,  x], [ y, -x], [-y,  x], [-y, -x]]
                else
                    row.push [[x,  y], [-x,  y], [ x, -y], [-x, -y]]
            ret.push row
        ret

    updatePoint: (point) =>
        if Math.abs(if @swapped then point[0] else point[1]) > @extents.y
            @newPoint point
        else
            point


class AttractRepel extends Diagonalizable
    makeScales: (opts) =>
        # Implicit equations for paths are x^{log(λ2)}y^{-log(λ1)} = r
        @logScaleX = Math.log @λ1
        @logScaleY = Math.log @λ2
        # Choose points on paths between the ones going through
        # (.95,.05) and (.05,.95)
        offset = 0.05
        # Interpolate r by choosing the path that goes through a random point on
        # the line y = 1-x
        @lerpR = (t) ->
            t = linLerp(offset, 1-offset)(t)
            Math.pow(t, @logScaleY) * Math.pow(1-t, -@logScaleX)
        # Assume this is >1
        a = @logScaleY/@logScaleX
        # Points expand in/out in "wave fronts" of the form x^a + y = s
        # Acting (x,y) by stepMat multiplies this equation by λ2
        # Last wave front is through (@extents.x, @extents.y)
        @sMin = 0.01
        @sMax = Math.pow(@extents.x, a) + @extents.y
        # The y-value of the point of intersection of the curves
        # x^a+y=s and x^lsy y^{-lsx} = r
        @yValAt = (r, s) -> s / (1 + Math.pow(r, 1/@logScaleX))
        # x as a function of y on the curve blah=r
        @xOfY = (y, r) -> Math.pow(r * Math.pow(y, @logScaleX), 1/@logScaleY)

    makeReference: () =>
        ret = []
        for i in [0...15]
            r = @lerpR i/15
            lerp = expLerp 0.01, @extents.y
            row = []
            for i in [0..100]
                y = lerp i/100
                x = @xOfY y, r
                row.push [[x,  y], [-x,  y], [ x, -y], [-x, -y]]
            ret.push row
        ret


class Attract extends AttractRepel
    descr: () -> "Attracting point"

    constructor: (extents, opts) ->
        super extents, opts
        @inverse = opts?.inverse ? new Repel extents,
            λ1: 1/@λ1
            λ2: 1/@λ2
            inverse: @

    makeScales: (opts) =>
        @λ1 = opts.λ1 ? linLerp(0.3, 0.9)(Math.random())
        @λ2 = opts.λ2 ? linLerp(0.3, @λ1)(Math.random())
        if @λ1 < @λ2
            throw "Must pass smaller eigenvalue second"
        # λ1 >= λ2 implies logScaleY/logScaleX > 1
        super opts

    newPoint: (oldPoint) =>
        # First choose r
        r = @lerpR Math.random()
        farY = @yValAt r, @sMax / @λ2
        if not oldPoint
            closeY = @yValAt r, @sMin
        else
            closeY = @yValAt r, @sMax
        y = expLerp(closeY, farY)(Math.random())
        x = @xOfY y, r
        [randSign() * x, randSign() * y, 0, 0]

    updatePoint: (point) =>
        if Math.abs(point[1]) < .01
            @newPoint point
        else
            point


class Repel extends AttractRepel
    descr: () -> "Repelling point"

    constructor: (extents, opts) ->
        super extents, opts
        @inverse = opts?.inverse ? new Attract extents,
            λ1: 1/@λ1
            λ2: 1/@λ2
            inverse: @

    makeScales: (opts) =>
        @λ2 = opts.λ2 ? linLerp(1/0.9, 1/0.3)(Math.random())
        @λ1 = opts.λ1 ? linLerp(1/0.9, @λ2)(Math.random())
        if @λ1 > @λ2
            throw "Must pass smaller eigenvalue first"
        # λ1 <= λ2 implies logScaleY/logScaleX > 1
        super opts

    newPoint: (oldPoint) =>
        # First choose r
        r = @lerpR Math.random()
        closeY = @yValAt r, @sMin / @λ2
        if not oldPoint
            farY = @yValAt r, @sMax
        else
            farY = @yValAt r, @sMin
        y = expLerp(closeY, farY)(Math.random())
        x = @xOfY y, r
        [randSign() * x, randSign() * y, 0, 0]

    updatePoint: (point) =>
        if Math.abs(point[0]) > @extents.x or Math.abs(point[1]) > @extents.y
            @newPoint point
        else
            point


class AttractRepelLine extends Diagonalizable
    makeScales: (opts) =>
        @λ1 = 1
        @lerpX = linLerp -@extents.x, @extents.x

    newPoint: (oldPoint) =>
        x = @lerpX Math.random()
        y = (if not oldPoint then @origLerpY else @newLerpY)(Math.random())
        [x, randSign() * y, 0, 0]

    makeReference: () =>
        item1 = []
        item2 = []
        for i in [0...20]
            x = @lerpX (i+.5)/20
            item1.push [x, -@extents.y]
            item2.push [x,  @extents.y]
        [[item1, item2]]


class AttractLine extends AttractRepelLine
    descr: () -> "Attracting line"

    constructor: (extents, opts) ->
        super extents, opts
        @inverse = opts?.inverse ? new RepelLine extents,
            λ1: 1/@λ1
            λ2: 1/@λ2
            inverse: @

    makeScales: (opts) =>
        super opts
        @λ2 = opts.λ2 ? linLerp(0.3, 0.8)(Math.random())
        @origLerpY = expLerp 0.01, @extents.y / @λ2
        @newLerpY = expLerp @extents.y, @extents.y / @λ2

    updatePoint: (point) =>
        if Math.abs(point[1]) < 0.01
            @newPoint point
        else
            point


class RepelLine extends AttractRepelLine
    descr: () -> "Repelling line"

    constructor: (extents, opts) ->
        super extents, opts
        @inverse = opts?.inverse ? new AttractLine extents,
            λ1: 1/@λ1
            λ2: 1/@λ2
            inverse: @

    makeScales: (opts) =>
        super opts
        @λ2 = opts.λ2 ? linLerp(1/0.8, 1/0.3)(Math.random())
        @origLerpY = expLerp 0.01 / @λ2, @extents.y
        @newLerpY = expLerp 0.01 / @λ2, 0.01

    updatePoint: (point) =>
        if Math.abs(point[1]) > @extents.y
            @newPoint point
        else
            point


######################################################################
# Real eigenvalues, not diagonalizable

class Shear extends Dynamics
    descr: () -> "Shear"

    constructor: (extents, opts) ->
        super extents, opts
        opts ?= {}
        @translate = opts.translate ? randSign() * linLerp(0.2, 2.0)(Math.random())
        @stepMat = [1, @translate, 0, 1]
        @lerpY = linLerp 0.01, @extents.y
        # For reference
        @lerpY2 = linLerp -@extents.y, @extents.y

        @inverse = opts?.inverse ? new Shear extents,
            translate: -@translate
            inverse: @

    newPoint: (oldPoint) =>
        a = @translate
        if not oldPoint
            y = @lerpY Math.random()
            # Put a few points on the x-axis
            if Math.random() < 0.005
                y = 0
                x = linLerp(-@extents.x, @extents.x)(Math.random())
            else
                if a < 0
                    x = linLerp(-@extents.x, @extents.x - a*y)(Math.random())
                else
                    x = linLerp(-@extents.x - a*y, @extents.x)(Math.random())
        else
            # Don't change path
            y = Math.abs oldPoint[1]
            if a < 0
                x = linLerp(@extents.x, @extents.x - a*y)(Math.random())
            else
                x = linLerp(-@extents.x - a*y, -@extents.x)(Math.random())
        s = randSign()
        [s*x, s*y, 0, 0]

    shaderParams: () =>
        code: shearShader,
        uniforms:
            scale:     { type: 'f', value: 1.0 }
            translate: { type: 'f', value: @translate }

    makeReference: () =>
        item1 = []
        item2 = []
        for i in [0...20]
            y = @lerpY2 (i+.5)/20
            item1.push [-@extents.x, y]
            item2.push [@extents.x, y]
        [[item1, item2]]

    updatePoint: (point) =>
        if Math.abs(point[0]) > @extents.x
            @newPoint point
        else
            point


class ScaleInOutShear extends Dynamics
    constructor: (extents, opts) ->
        super extents, opts
        opts ?= {}
        @translate = opts.translate ? randSign() * linLerp(0.2, 2.0)(Math.random())
        λ = @scale
        a = @translate
        @stepMat = [λ, λ*a, 0, λ]
        # Paths have the form λ^t(r+ta, 1)
        @xOfY = (r, y) -> y * (r + a*Math.log(y)/Math.log(λ))
        # tan gives a nice looking plot
        @lerpR = (t) -> Math.tan((t - 0.5) * π)
        # for points
        @lerpR2 = (t) -> Math.tan((t/0.99 + 0.005 - 0.5) * π)

    newPoint: (oldPoint) =>
        # Choose a path
        r = @lerpR2 Math.random()
        y = (if not oldPoint then @lerpY else @lerpYNew)(Math.random())
        x = @xOfY r, y
        s = randSign()
        [s*x, s*y, 0, 0]

    shaderParams: () =>
        code: shearShader,
        uniforms:
            scale:     { type: 'f', value: @scale }
            translate: { type: 'f', value: @translate }

    makeReference: () =>
        ret = []
        numLines = 40
        for i in [1...numLines]
            r = @lerpR i/numLines
            row = []
            for j in [0...100]
                y = @lerpY j/100
                x = @xOfY r, y
                row.push [[x, y], [-x, -y]]
            ret.push row
        return ret


class ScaleOutShear extends ScaleInOutShear
    descr: () -> "Scale-out shear"

    constructor: (@extents, opts) ->
        opts ?= {}
        @scale = opts.scale ? linLerp(1/0.7, 1/0.3)(Math.random())
        @lerpY = expLerp 0.01/@scale, @extents.y
        @lerpYNew = expLerp 0.01/@scale, 0.01
        super @extents, opts

        @inverse = opts?.inverse ? new ScaleInShear @extents,
            translate: -@translate
            scale: 1/@scale
            inverse: @

    updatePoint: (point) =>
        if Math.abs(point[1]) > @extents.y
            @newPoint point
        else
            point


class ScaleInShear extends ScaleInOutShear
    descr: () -> "Scale-in shear"

    constructor: (@extents, opts) ->
        opts ?= {}
        @scale = opts.scale ? linLerp(0.3, 0.7)(Math.random())
        @lerpY = expLerp 0.01, @extents.y / @scale
        @lerpYNew = expLerp @extents.y, @extents.y / @scale
        super @extents, opts

        @inverse = opts?.inverse ? new ScaleOutShear @extents,
            translate: -@translate
            scale: 1/@scale
            inverse: @

    updatePoint: (point) =>
        if Math.abs(point[1]) < .01
            @newPoint point
        else
            point


######################################################################
# Exports

window.dynamics = {}

window.dynamics.Controller    = Controller

window.dynamics.Circle        = Circle
window.dynamics.SpiralIn      = SpiralIn
window.dynamics.SpiralOut     = SpiralOut
window.dynamics.Hyperbolas    = Hyperbolas
window.dynamics.Attract       = Attract
window.dynamics.Repel         = Repel
window.dynamics.AttractLine   = AttractLine
window.dynamics.RepelLine     = RepelLine
window.dynamics.Shear         = Shear
window.dynamics.ScaleOutShear = ScaleOutShear
window.dynamics.ScaleInShear  = ScaleInShear
