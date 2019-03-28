module EnhancedLogging

using Printf, Logging
import Logging: handle_message, shouldlog, min_enabled_level, catch_exceptions, LogLevel

export ProgressLevel, EnhancedConsoleLogger

const ProgressLevel = LogLevel(-1)

include("EnhancedConsoleLogger.jl")

end # module
