using Logging, EnhancedLogging

function test_logging()
    @debug "hello world"
    @logmsg ProgressLevel "status report" progress=0.32
    @logmsg ProgressLevel "status report"
    @info "everything seems to be fine..."
    @info "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse non dui vel est maximus consequat id sed turpis. Integer fringilla, odio nec condimentum laoreet, lorem metus malesuada lorem, vitae cursus lorem erat non velit. Aliquam tempus egestas aliquet. Etiam a nunc massa. Nunc gravida sed ipsum non molestie. Donec venenatis lorem tortor, at iaculis ipsum consectetur a. In congue, neque et pulvinar sagittis, massa sem vulputate sapien, tincidunt laoreet lacus turpis a nisi. Quisque enim ex, pretium in ex vitae, vestibulum mollis leo. Maecenas faucibus turpis non pretium tempor. Nunc vulputate lectus vel leo mattis rutrum. Mauris laoreet, arcu in volutpat viverra, arcu velit pulvinar leo, non molestie lacus turpis sed sapien. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Sed est elit, tristique at leo vel, sagittis scelerisque tellus. Donec tempus eros massa, vitae commodo libero rhoncus vitae. Ut sed sem massa."
    @info "everything seems to be fine...\nand its fine on this line...\nand this line...\nand also this line" asdf=2
    @warn "ummm this doesn't look good"
    @warn "ummm this doesn't look good" asdf="areallyreallyreallyreallyreallyreallylongstring"
    @error "bad stuff"

    for i in 0:0.001:1
        @logmsg ProgressLevel "hello" progress=i
        sleep(0.005)
    end
end

with_logger(test_logging, EnhancedConsoleLogger())
