"""
    EnhancedConsoleLogger(stream::IO==stderr; kwargs...)

Replacement for the standard library `ConsoleLogger` that adds several usability
improvements.
"""
mutable struct EnhancedConsoleLogger <: AbstractLogger
    stream::IO
    width::Int
    show_limited::Bool
    message_limits::Dict{Any, Int}
    last_id::Symbol
end
function EnhancedConsoleLogger(stream::IO=stderr; show_limited=true, width=80)
    EnhancedConsoleLogger(stream, width, show_limited, Dict{Any, Int}(), :nothing)
end

"""
    progress_string(progress, width)

Returns a string with a completion percentage and a progress bar. Uses Unicode characters
to render sub-character progress increments.
"""
function progress_string(progress, width)
    progress_chars = [' ', '▏', '▎', '▍', '▌', '▋',  '▊', '▉', '█']

    progress_bar_width = width - 9
    progress_width = progress_bar_width*progress

    if progress_width >= progress_bar_width
        return @sprintf "%5.1f%% ║%s" 100 '█'^progress_bar_width
    end
    full_blocks = floor(Int, progress_width)
    remaining_width = progress_width - full_blocks
    trailing_char = progress_chars[floor(Int, remaining_width*8)+1]

    blank_blocks = progress_bar_width-full_blocks-1
    blank_blocks < 0 && (blank_blocks = 0)

    @sprintf "%5.1f%% ║%s" progress*100 ('█'^full_blocks)*trailing_char*(' '^blank_blocks)
end

function log_label(level)
    level == Logging.Warn && return "Warning"
    level == ProgressLevel && return "Progress"
    return string(level)
end

function log_color(level)
    color = Logging.default_logcolor(level)
    level == ProgressLevel && (color = :green)
    return color
end

function log_location(mod, group, id, file, line)
    location = ""
    mod !== nothing && (location *= "$mod")
    if file !== nothing
        mod !== nothing && (location *= " ")
        location *= Base.contractuser(file)
        if line !== nothing
            location *= ":$(isa(line, UnitRange) ? "$(first(line))-$(last(line))" : line)"
        end
    end
    return location
end

function log_message(logger::EnhancedConsoleLogger, msg, kwargs)
    msglines = [(indent=0,msg=l) for l in split(chomp(string(msg)), '\n')]
    dsize = displaysize(logger.stream)
    if !isempty(kwargs)
        valbuf = IOBuffer()
        rows_per_value = max(1, dsize[1]/(length(kwargs)+1))
        valio = IOContext(IOContext(valbuf, logger.stream),
                          :displaysize => (rows_per_value, dsize[2]-5),
                          :limit => logger.show_limited)
        for (key,val) in pairs(kwargs)
            key == :progress && continue
            Logging.showvalue(valio, val)
            vallines = split(String(take!(valbuf)), '\n')
            if length(vallines) == 1
                push!(msglines, (indent=2,msg=SubString("$key = $(vallines[1])")))
            else
                push!(msglines, (indent=2,msg=SubString("$key =")))
                append!(msglines, ((indent=3,msg=l) for l in vallines))
            end
        end
    end

    return msglines
end

function handle_message(logger::EnhancedConsoleLogger, level, message, mod, group, id, file, line; kwargs...)
    label = log_label(level)
    color = log_color(level)
    location = log_location(mod, group, id, file, line)
    msglines = log_message(logger, message, kwargs)

    buf = IOBuffer()
    iob = IOContext(buf, logger.stream)
    justify_width = min(logger.width, displaysize(logger.stream)[2])
    location_width = 2 + (isempty(label) || length(msglines) > 1 ? 0 : length(label) + 1) +
                    msglines[end].indent + Logging.termlength(msglines[end].msg) +
                    (isempty(location) ? 0 : length(location)+2)
    if location_width > justify_width && !isempty(location)
        push!(msglines, (indent=0,msg=SubString("")))
    end
    if level == ProgressLevel
        progress_width = 2 + length(label) + 1 + msglines[1].indent + Logging.termlength(msglines[1].msg) + 20
        if progress_width > justify_width
            push!(msglines, (indent=0,msg=SubString("")))
        end
    end
    for (i,(indent,msg)) in enumerate(msglines)
        linewidth = 2
        boxstrs = length(msglines) == 1 ? ("║ ", "║") :
                  i == 1                ? ("╔ ", "╗") :
                  i < length(msglines)  ? ("║ ", "║") :
                                          ("╚ ", "╝")
        printstyled(iob, boxstrs[1], bold=true, color=color)
        if i == 1 && !isempty(label)
            printstyled(iob, label, " ", bold=true, color=color)
            linewidth += length(label) + 1
        end
        print(iob, ' '^indent, msg)
        linewidth += indent + length(msg)
        if level == ProgressLevel && i == 1
            prog_string = haskey(kwargs, :progress) ? progress_string(kwargs[:progress], 30) : "NO PROGRESS PROVIDED "
            prog_color  = haskey(kwargs, :progress) ? :green : :red
            npad = max(0, justify_width - linewidth - length(prog_string) - 3)
            printstyled(iob, ' ', '·'^npad, ' ', color=:light_black)
            printstyled(iob, prog_string, color=prog_color, bold=true)
            linewidth += npad + 32
            location=""
        end
        if i == length(msglines) && !isempty(location)
            npad = max(0, justify_width - linewidth - length(location) - 4)
            printstyled(iob, ' ', '·'^npad, ' ', location, color=:light_black)
            linewidth += npad + length(location) + 2
        end
        npad = max(0, justify_width - linewidth - 1)
        printstyled(iob, ' '^npad, boxstrs[2], bold=true, color=color)
        println(iob)
    end

    if id == logger.last_id && level == ProgressLevel && length(kwargs) == 1
        print(logger.stream, "\u1b[A")
    end
    logger.last_id = id
    write(logger.stream, take!(buf))
    nothing
end

shouldlog(::EnhancedConsoleLogger, args...) = true
min_enabled_level(::EnhancedConsoleLogger) = ProgressLevel
catch_exceptions(::EnhancedConsoleLogger) = false
