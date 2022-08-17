"""
    plot_signal_scaled(t, signal; <keyword arguments>)

Plot scaled multi-channel `signal`.

# Arguments

- `t::Union{Vector{<:Real}, AbstractRange}`
- `signal::AbstractArray`
- `labels::Vector{String}=[""]`: labels vector
- `xlabel::String="Time [s]"`: x-axis label
- `ylabel::String="Channel"`: y-axis label
- `title::String=""`: plot title
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function plot_signal_scaled(t::Union{Vector{<:Real}, AbstractRange}, signal::AbstractArray; labels::Vector{String}=[""], xlabel::String="Time [s]", ylabel::String="Channel", title::String="", mono::Bool=false, kwargs...)

    typeof(t) <: AbstractRange && (t = float(collect(t)))

    channel_n = size(signal, 1)

    # reverse so 1st channel is on top
    if mono == true
        palette = :grays
        channel_color = Vector{Symbol}()
        for idx in 1:channel_n
            push!(channel_color, :black)
        end
    else
        palette = :darktest
        channel_color = channel_n:-1:1
    end
    signal = reverse(signal[:, :], dims = 1)

    # normalize and shift so all channels are visible
    s_normalized = zeros(size(signal))
    variances = var(signal, dims=2)
    mean_variance = mean(variances)
    for idx in 1:channel_n
        s = @view signal[idx, :]
        s_normalized[idx, :] = (s .- mean(s)) ./ mean_variance .+ (idx - 1)
    end

    # plot channels
    p = Plots.plot(xlabel=xlabel,
             ylabel=ylabel,
             xlims=_xlims(t),
             xticks=_xticks(t),
             ylims=(-0.5, channel_n-0.5),
             title=title,
             palette=palette,
             titlefontsize=8,
             xlabelfontsize=6,
             ylabelfontsize=6,
             xtickfontsize=8,
             ytickfontsize=8;
             kwargs...)
    for idx in 1:channel_n
        p = Plots.plot!(t,
                  s_normalized[idx, 1:length(t)],
                  linewidth=0.5,
                  label="",
                  color=channel_color[idx])
    end

    p = Plots.plot!(yticks=((channel_n - 1):-1:0, labels))

    return p
end

"""
    plot_signal(t, signal; <keyword arguments>)

Plot single-channel `signal`.

# Arguments

- `t::Union{Vector{<:Real}, AbstractRange}`
- `signal::Vector{<:Real}`
- `ylim::Tuple{Real, Real}=(0, 0)`: y-axis limits
- `xlabel::String="Time [s]"`: x-axis label
- `ylabel::String="Amplitude [μV]"`: y-axis label
- `title::String=""`: plot title
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function plot_signal(t::Union{Vector{<:Real}, AbstractRange}, signal::Vector{<:Real}; ylim::Tuple{Real, Real}=(0, 0), xlabel::String="Time [s]", ylabel::String="Amplitude [μV]", title::String="", mono::Bool=false, kwargs...)

    mono == true ? palette = :grays : palette = :darktest

    typeof(t) <: AbstractRange && (t = float(collect(t)))

    ylim == (0, 0) && (ylim = (floor(minimum(signal), digits=0), ceil(maximum(signal), digits=0)))
    ylim = _tuple_max(ylim)
    ylim = tuple_order(ylim)

    hl = Plots.plot((size(signal, 2), 0), seriestype=:hline, linewidth=0.5, linealpha=0.5, linecolor=:gray, label="")
    p = Plots.plot!(t,
              signal[1:length(t)],
              color=:black,
              label="",
              legend=false,
              title=title,
              xlabel=xlabel,
              xlims=_xlims(t),
              xticks=_xticks(t),
              ylabel=ylabel,
              ylims=ylim,
              yguidefontrotation=0,
              yticks=[ylim[1], 0, ylim[2]],
              palette=palette,
              linewidth=0.5,
              grid=false,
              titlefontsize=8,
              xlabelfontsize=6,
              ylabelfontsize=6,
              xtickfontsize=4,
              ytickfontsize=4;
              kwargs...)

    Plots.plot(p)

    return p
end

"""
    plot_signal(t, signal; <keyword arguments>)

Plot multi-channel `signal`.

# Arguments

- `t::Union{Vector{<:Real}, AbstractRange}`
- `signal::AbstractArray`
- `labels::Vector{String}=[""]`: labels vector
- `xlabel::String="Time [s]"`: x-axis label
- `ylabel::String="Channel"`: y-axis label
- `title::String=""`: plot title
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function plot_signal(t::Union{Vector{<:Real}, AbstractRange}, signal::AbstractArray; labels::Vector{String}=[""], xlabel::String="Time [s]", ylabel::String="Channel", title::String="", mono::Bool=false, kwargs...)

    typeof(t) <: AbstractRange && (t = float(collect(t)))

    channel_n = size(signal, 1)

    ylim = extrema(signal[:, 1:length(t)])
    (abs(ylim[1]) >= 1 || abs(ylim[2]) >= 1) && (ylim = (floor(ylim[1]), ceil(ylim[2])))
    (abs(ylim[1]) >=10 || abs(ylim[2]) >= 10) && (ylim = (floor(ylim[1], digits=-1), ceil(ylim[2], digits=-1)))
    (abs(ylim[1]) >=100 || abs(ylim[2]) >= 100) && (ylim = (floor(ylim[1], digits=-2), ceil(ylim[2], digits=-2)))

    p = []
    if mono == true
        palette = :grays
        channel_color = Vector{Symbol}()
        for idx in 1:channel_n
            push!(channel_color, :black)
        end
    else
        palette = :darktest
        channel_color = 1:channel_n
    end

    pp = Plots.plot(t,
              signal[1, 1:length(t)],
              linewidth=0.5,
              label="",
              color=channel_color[1],
              title=title,
              xaxis=false,
              xticks=false,
              xlabel="",
              xlims=_xlims(t),
              ylims=ylim,
              yticks=([ylim[1], 0, ylim[2]], [string(ylim[1])*"\n\n", labels[1], "\n\n"*string(ylim[2])]),
              bottom_margin=-10Plots.px,
              size=(2400, 300))
    pp = Plots.plot!((length(t), 0), seriestype=:hline, linewidth=0.5, linealpha=0.5, linecolor=:gray, label="")
    push!(p, pp)
    if channel_n > 2
        for idx in 2:(channel_n - 1)
            pp = Plots.plot(t,
                      signal[idx, 1:length(t)],
                      linewidth=0.5,
                      label="",
                      color=channel_color[idx],
                      title="",
                      xaxis=false,
                      xticks=false,
                      xlabel="",
                      xlims=_xlims(t),
                      ylims=ylim,
                      yticks=([ylim[1], 0, ylim[2]], [string(ylim[1])*"\n\n", labels[idx], "\n\n"*string(ylim[2])]),
                      top_margin=-10Plots.px,
                      bottom_margin=-10Plots.px,
                      size=(2400, 300))
            pp = Plots.plot!((length(t), 0), seriestype=:hline, linewidth=0.5, linealpha=0.5, linecolor=:gray, label="")
            push!(p, pp)
        end
    end
    pp = Plots.plot(t,
              signal[channel_n, 1:length(t)],
              linewidth=0.5,
              label="",
              color=channel_color[end],
              title="",
              xaxis=true,
              xticks=_xticks(t),
              xlabel=xlabel,
              xlims=_xlims(t),
              ylims=ylim,
              yticks=([ylim[1], 0, ylim[2]], [string(ylim[1])*"\n\n", labels[channel_n], "\n\n"*string(ylim[2])]),
              top_margin=-10Plots.px,
              bottom_margin=50Plots.px,
              size=(2400, 200))
    pp = Plots.plot!((length(t), 0), seriestype=:hline, linewidth=0.5, linealpha=0.5, linecolor=:gray, label="")
    push!(p, pp)

    p = Plots.plot(p...,
              layout=(size(p, 1), 1),
              size=(2400, size(p, 1) * 200),
              left_margin=60Plots.px,
              right_margin=30Plots.px,
              grid=false,
              palette=palette,
              titlefontsize=20,
              xlabelfontsize=16,
              ylabelfontsize=16,
              xtickfontsize=16,
              ytickfontsize=16;
              kwargs...)

    return p
end

"""
    eeg_plot_signal(eeg; <keyword arguments>)

Plot `eeg` channel or channels.

# Arguments

- `eeg::NeuroJ.EEG`: EEG object
- `epoch::Union{Int64, AbstractRange}=0`: epochs to display
- `channel::Union{Int64, Vector{Int64}, AbstractRange}=0`: channels to display, default is all channels
- `scaled::Bool=false`: if true than scale signals before plotting so all signals will fit the plot
- `offset::Int64=0`: displayed segment offset in samples
- `len::Int64=0`: displayed segment length in samples, default is 1 epoch or 20 seconds
- `xlabel::String="Time [s]"`: x-axis label
- `ylabel::String=""`: y-axis label
- `title::String=""`: plot title
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_signal(eeg::NeuroJ.EEG; epoch::Union{Int64, AbstractRange}=0, channel::Union{Int64, Vector{Int64}, AbstractRange}=0, scaled::Bool=false, offset::Int64=0, len::Int64=0, xlabel::String="Time [s]", ylabel::String="", title::String="", mono::Bool=false, kwargs...)

    (epoch != 0 && len != 0) && throw(ArgumentError("Both epoch and len must not be specified."))

    epoch_tmp = epoch
    if epoch != 0
        # convert epochs to offset and len
        typeof(epoch) <: AbstractRange && (epoch = collect(epoch))
        _check_epochs(eeg, epoch)
        length(epoch) > 1 && sort!(epoch)
        len = eeg_epoch_len(eeg) * length(epoch)
        offset = eeg_epoch_len(eeg) * (epoch[1] - 1)
        epoch_tmp = epoch[1]:epoch[end]
        epoch = epoch[1]
    else
        # default length is one epoch or 20 seconds
        len == 0 && (len = _len(eeg, len, 20))
        epoch = floor(Int64, offset / eeg_epoch_len(eeg)) + 1
        epoch_tmp = (floor(Int64, offset / eeg_epoch_len(eeg)) + 1):(ceil(Int64, (offset + len) / eeg_epoch_len(eeg)))
    end

    # select channels, default is all up to 10 channels
    channel == 0 && (channel = _select_channels(eeg, channel, 10))
    _check_channels(eeg, channel)

    # set epoch markers if len > epoch_len
    eeg_tmp, epoch_markers = _get_epoch_markers(eeg, offset, len)

    labels = eeg_labels(eeg)[channel]

    # get time vector
    if length(epoch) == 1 && offset + len <= eeg_epoch_len(eeg)
        t = eeg.eeg_epochs_time[(1 + offset):(offset + len), epoch]
        t[1] = floor(t[1], digits=2)
        t[end] = ceil(t[end], digits=2)
    else
        t = _get_t(eeg_tmp, offset, len)
    end

    _check_offset_len(eeg_tmp, offset, len)

    signal = eeg_tmp.eeg_signals[channel, (1 + offset):(offset + length(t)), 1]

    if length(channel) == 1
        ylabel = "Amplitude [μV]"
        channel_name = labels
        labels = [""]
        signal = vec(signal)
    else
        channel_name = _channel2channel_name(channel)
    end

    t_1, t_s1, t_2, t_s2 = _convert_t(t)

    epoch_tmp = _t2epoch(eeg, offset, len, epoch_tmp)
    epoch_tmp[end] == epoch_tmp[1] && (epoch_tmp = epoch_tmp[1])
    length(channel) == 1 && (title == "" && (title = "Signal\n[channel: $(channel_name), epoch: $epoch_tmp, time window: $t_s1:$t_s2]"))
    length(channel) != 1 && (title == "" && (title = "Signals amplitude [μV]\n[channel: $(channel_name), epoch: $epoch_tmp, time window: $t_s1:$t_s2]"))

    scaled == false && (p = plot_signal(t,
                                        signal,
                                        labels=labels,
                                        xlabel=xlabel,
                                        ylabel=ylabel,
                                        title=title,
                                        mono=mono;
                                        kwargs...))
    scaled == true && (p = plot_signal_scaled(t,
                                              signal,
                                              labels=labels,
                                              xlabel=xlabel,
                                              ylabel=ylabel,
                                              title=title,
                                              mono=mono;
                                              kwargs...))
    # add epochs markers
    if length(channel) == 1 && scaled == true
        if length(epoch_markers) > 0 && len + offset > eeg_epoch_len(eeg) && eeg_epoch_n(eeg) > 1
            p = vline!(epoch_markers,
                       linestyle=:dash,
                       linewidth=0.2,
                       linecolor=:black,
                       label="")
            if typeof(signal) == Vector{Float64}
                for idx in 1:length(epoch_markers)
                    p = Plots.plot!(annotation=((epoch_markers[idx] - (length(signal) / eeg_sr(eeg) / 40)), maximum(ceil.(abs.(signal))), Plots.text("E$(floor(Int64, epoch_markers[idx] / (eeg_epoch_len(eeg) / eeg_sr(eeg))))", pointsize=4, halign=:left, valign=:top)))
                end
            else
                for idx in 1:length(epoch_markers)
                    p = Plots.plot!(annotation=((epoch_markers[idx] - (size(signal, 2) / eeg_sr(eeg) / 40)), length(channel)-0.5, Plots.text("E$(floor(Int64, epoch_markers[idx] / (eeg_epoch_len(eeg) / eeg_sr(eeg))))", pointsize=6, halign=:left, valign=:top)))
                end
            end
        end
    end

    Plots.plot(p)

    return p
end

"""
    eeg_plot_signal_details(eeg; <keyword arguments>)

Plot details of `eeg` channels: amplitude, histogram, power density, phase histogram and spectrogram.

# Arguments

- `eeg::NeuroJ.EEG`
- `epoch::Union{Int64, AbstractRange}=0`: epoch number to display
- `channel::Int64`: channel to display
- `offset::Int64=0`: displayed segment offset in samples
- `len::Int64=0`: displayed segment length in samples, default is 1 epoch or 20 seconds
- `norm::Bool=true`: normalize the `signal` prior to calculations
- `mw::Bool=false`: if true use Morlet wavelet convolution
- `mt::Bool=false`: if true use multi-tapered periodogram/spectrogram
- `frq_lim::Tuple{Real, Real}=(0, 0)`: y-axis limits
- `ncyc::Union{Int64, Tuple{Int64, Int64}}=6`: number of cycles for Morlet wavelet
- `xlabel::String="Time [s]"`: x-axis label
- `ylabel::String="Amplitude [μV]"`: y-axis label
- `title::String=""`: plot title
- `head::Bool=true`: add head plot
- `hist::Symbol=:hist`: histogram type: :hist, :kd
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `pc::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_signal_details(eeg::NeuroJ.EEG; epoch::Union{Int64, AbstractRange}=0, channel::Int64, offset::Int64=0, len::Int64=0, labels::Vector{String}=[""], xlabel::String="Time [s]", ylabel::String="", title::String="", head::Bool=true, hist::Symbol=:hist, norm::Bool=true, mw::Bool=false, mt::Bool=false, frq_lim::Tuple{Real, Real}=(0, 0), ncyc::Union{Int64, Tuple{Int64, Int64}}=6, mono::Bool=false, kwargs...)

    hist in [:hist, :kd] || throw(ArgumentError("hist must be :hist or :kd."))
    (epoch != 0 && len != 0) && throw(ArgumentError("Both epoch and len must not be specified."))
    _check_channels(eeg, channel)

    fs = eeg_sr(eeg)
    frq_lim == (0, 0) && (frq_lim = (0, div(fs, 2)))
    frq_lim = tuple_order(frq_lim)
    (frq_lim[1] < 0 || frq_lim[2] > fs / 2) && throw(ArgumentError("frq_lim must be ≥ 0 and ≤ $(fs / 2)."))

    epoch_tmp = epoch
    if epoch != 0
        # convert epochs to offset and len
        typeof(epoch) <: AbstractRange && (epoch = collect(epoch))
        _check_epochs(eeg, epoch)
        length(epoch) > 1 && sort!(epoch)
        len = eeg_epoch_len(eeg) * length(epoch)
        offset = eeg_epoch_len(eeg) * (epoch[1] - 1)
        epoch_tmp = epoch[1]:epoch[end]
        epoch = epoch[1]
    else
        # default length is one epoch or 20 seconds
        len == 0 && (len = _len(eeg, len, 20))
        epoch = floor(Int64, offset / eeg_epoch_len(eeg)) + 1
        epoch_tmp = (floor(Int64, offset / eeg_epoch_len(eeg)) + 1):(ceil(Int64, (offset + len) / eeg_epoch_len(eeg)))
    end

    # set epoch markers if len > epoch_len
    eeg_tmp, epoch_markers = _get_epoch_markers(eeg, offset, len)

    labels = eeg_labels(eeg)[channel]

    # get time vector
    if length(epoch) == 1 && offset + len <= eeg_epoch_len(eeg)
        t = eeg.eeg_epochs_time[(1 + offset):(offset + len), epoch]
        t[1] = floor(t[1], digits=2)
        t[end] = ceil(t[end], digits=2)
    else
        t = _get_t(eeg_tmp, offset, len)
    end

    _check_offset_len(eeg_tmp, offset, len)

    signal = eeg_tmp.eeg_signals[channel, (1 + offset):(offset + length(t)), 1]

    ylabel = "Amplitude [μV]"
    channel_name = labels
    labels = [""]
    signal = eeg_tmp.eeg_signals[channel, (1 + offset):(offset + length(t)), epoch]
    signal = vec(signal)

    t_1, t_s1, t_2, t_s2 = _convert_t(t)

    epoch_tmp = _t2epoch(eeg, offset, len, epoch_tmp)
    epoch_tmp[end] == epoch_tmp[1] && (epoch_tmp = epoch_tmp[1])
    title == "" && (title = "Signal\n[channel: $(channel_name), epoch: $epoch_tmp, time window: $t_s1:$t_s2]")

    p = plot_signal(t,
                    signal,
                    labels=labels,
                    xlabel=xlabel,
                    ylabel=ylabel,
                    title=title,
                    mono=mono;
                    kwargs...)

    # add epochs markers
    if length(epoch_markers) > 0 && len + offset > eeg_epoch_len(eeg) && eeg_epoch_n(eeg) > 1
        p = vline!(epoch_markers,
                   linestyle=:dash,
                   linewidth=0.2,
                   linecolor=:black,
                   label="")
        if typeof(signal) == Vector{Float64}
            for idx in 1:length(epoch_markers)
                p = Plots.plot!(annotation=((epoch_markers[idx] - (length(signal) / eeg_sr(eeg) / 40)), maximum(ceil.(abs.(signal))), Plots.text("E$(floor(Int64, epoch_markers[idx] / (eeg_epoch_len(eeg) / eeg_sr(eeg))))", pointsize=4, halign=:left, valign=:top)))
            end
        else
            for idx in 1:length(epoch_markers)
                p = Plots.plot!(annotation=((epoch_markers[idx] - (size(signal, 2) / eeg_sr(eeg) / 40)), length(channel)-0.5, Plots.text("E$(floor(Int64, epoch_markers[idx] / (eeg_epoch_len(eeg) / eeg_sr(eeg))))", pointsize=6, halign=:left, valign=:top)))
            end
        end
    end

    # cannot plot electrodes without locations
    eeg.eeg_header[:channel_locations] == false && (head = false)
    psd = eeg_plot_signal_psd(eeg, channel=channel, len=len, offset=offset, frq_lim=frq_lim, title="PSD\n[frequency limit: $(frq_lim[1])-$(frq_lim[2]) Hz]", norm=true, mt=mt, legend=false, ylabel="Power [dB]")
    s = eeg_plot_signal_spectrogram(eeg, channel=channel, len=len, offset=offset, mw=mw, mt=mt, frq_lim=frq_lim, ncyc=ncyc, title="Spectrogram\n[frequency limit: $(frq_lim[1])-$(frq_lim[2]) Hz]", mono=mono)
    ht_a = eeg_plot_histogram(eeg, channel=channel, len=len, offset=offset, type=hist, labels=[""], legend=false, title="Signal\nhistogram", mono=mono)
    _, _, _, s_phase = s_hspectrum(signal)
    ht_p = plot_histogram(rad2deg.(s_phase), offset=offset, len=len, type=:kd, labels=[""], legend=false, title="Phase\nhistogram", xticks=[-180, 0, 180], linecolor=:black, mono=mono)
    if head == true
        hd = eeg_plot_electrode(eeg, channel=channel, title="Channel: $channel\nLabel: $channel_name")
        l = @layout [a{0.33h} b{0.2w}; c{0.33h} d{0.2w}; e{0.33h} f{0.2w}]
        pc = eeg_plot_compose([p, ht_a, psd, ht_p, s, hd], layout=l)
    else
        l = @layout [a{0.33h} b{0.2w}; c{0.33h} d{0.2w}; e{0.33h} _]
        pc = eeg_plot_compose([p, ht_a, psd, ht_p, s], layout=l)
    end

    Plots.plot(pc)

    return pc
end

"""
    eeg_plot_component(eeg; <keyword arguments>)

Plot `eeg` external or embedded component.

# Arguments

- `eeg::NeuroJ.EEG`: EEG object
- `c::Union{Array{Float64, 3}, Symbol}`: values to plot; if symbol, than use embedded component
- `epoch::Int64`: epoch to display
- `channel::Union{Int64, Vector{Int64}, AbstractRange}=0`: channels to display, default is all channels
- `xlabel::String="Time [s]"`: x-axis label
- `ylabel::String=""`: y-axis label
- `title::String=""`: plot title
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_component(eeg::NeuroJ.EEG; c::Union{Array{Float64, 3}, Symbol}, epoch::Int64, channel::Union{Int64, Vector{Int64}, AbstractRange}=0, xlabel::String="Time [s]", ylabel::String="", title::String="", mono::Bool=false, kwargs...)

    typeof(c) == Symbol && (c, _ = _get_component(eeg, c))

    size(c) == size(eeg.eeg_signals) || throw(ArgumentError("Size of c ($(size(c))) does not match size of EEG signal ($(size(eeg.eeg_signals))), use another type of plotting function."))

    _check_epochs(eeg, epoch)

    # select channels, default is all up to 20 channels
    channel == 0 && (channel = _select_channels(eeg, channel, 20))
    _check_channels(eeg, channel)

    labels = eeg_labels(eeg)[channel]

    # get time vector
    t = eeg.eeg_epochs_time[:, epoch]

    t_1, t_s1, t_2, t_s2 = _convert_t(t)
    if length(channel) == 1
        channel_name = labels
        labels = [""]
        signal = vec(c)
    else
        channel_name = _channel2channel_name(channel)
    end
    title == "" && (title = "Component\n[channel: $channel_name, epoch: $epoch, time window: $t_s1:$t_s2]")

    c = c[channel, :, epoch]

    p = plot_signal(t,
                    c,
                    labels=labels,
                    xlabel=xlabel,
                    ylabel=ylabel,
                    title=title,
                    mono=mono;
                    kwargs...)

    Plots.plot(p)

    return p
end

"""
    eeg_plot_component_idx(eeg; <keyword arguments>)

Plot indexed `eeg` external or embedded component.

# Arguments

- `eeg::NeuroJ.EEG`: EEG object
- `c::Union{Array{Float64, 3}, Symbol}`: values to plot; if symbol, than use embedded component
- `epoch::Int64`: epoch to display
- `c_idx::Union{Int64, Vector{Int64}, AbstractRange}=0`: component index to display, default is all components
- `xlabel::String="Time [s]"`: x-axis label
- `ylabel::String=""`: y-axis label
- `title::String=""`: plot title
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_component_idx(eeg::NeuroJ.EEG; c::Union{Array{Float64, 3}, Symbol}, epoch::Int64, c_idx::Union{Int64, Vector{Int64}, AbstractRange}=0, xlabel::String="Time [s]", ylabel::String="", title::String="", mono::Bool=false, kwargs...)

    typeof(c) == Symbol && (c, _ = _get_component(eeg, c))

    _check_epochs(eeg, epoch)

    # select components, default is all up to 20
    if typeof(c) == Symbol
        c_idx == 0 && (c_idx = _select_cidx(eeg, c, c_idx, 20))
        _check_cidx(eeg, c, c_idx)
    else
        if c_idx == 0
            size(c, 1) > 20 && (c_idx = 1:20)
            size(c, 1) <= 20 && (c_idx = 1:size(c, 1))
        end
        for idx in 1:length(c_idx)
            (c_idx[idx] < 1 || c_idx[idx] > size(c, 1)) && throw(ArgumentError("c_idx must be ≥ 1 and ≤ $(size(c, 1))."))
        end
    end
    length(c_idx) == 1 && (c_idx = c_idx[1])

    labels = Vector{String}()
    for idx in 1:length(c_idx)
        push!(labels, string(c_idx[idx]))
    end

    # get time vector
    t = eeg.eeg_epochs_time[:, epoch]

    t_1, t_s1, t_2, t_s2 = _convert_t(t)
    if length(c_idx) == 1
        labels = [""]
        signal = vec(c)
    end
    title == "" && (title = "Component #$(lpad(string(c_idx), 3, "0"))\n[epoch: $epoch, time window: $t_s1:$t_s2]")

    c = c[c_idx, :, epoch]

    p = plot_signal(t,
                    c,
                    labels=labels,
                    xlabel=xlabel,
                    ylabel=ylabel,
                    title=title,
                    mono=mono;
                    kwargs...)

    Plots.plot(p)

    return p
end

"""
    eeg_plot_component_idx_avg(eeg; <keyword arguments>)

Plot indexed `eeg` external or embedded component: mean and ±95% CI.

# Arguments

- `eeg::NeuroJ.EEG`: EEG object
- `c::Union{Array{Float64, 3}, Symbol}`: values to plot; if symbol, than use embedded component
- `epoch::Int64`: epoch to display
- `c_idx::Union{Int64, Vector{Int64}, AbstractRange}=0`: component index to display, default is all components
- `xlabel::String="Time [s]"`: x-axis label
- `ylabel::String=""`: y-axis label
- `title::String=""`: plot title
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_component_idx_avg(eeg::NeuroJ.EEG; c::Union{Array{Float64, 3}, Symbol}, epoch::Int64, c_idx::Union{Int64, Vector{Int64}, AbstractRange}=0, xlabel::String="Time [s]", ylabel::String="", title::String="", mono::Bool=false, kwargs...)

    typeof(c) == Symbol && (c, _ = _get_component(eeg, c))

    _check_epochs(eeg, epoch)

    # select components, default is all
    if typeof(c) == Symbol
        c_idx == 0 && (c_idx = _select_cidx(eeg, c, c_idx, 0))
        _check_cidx(eeg, c, c_idx)
    else
        c_idx == 0 && (c_idx = 1:size(c, 1))
        for idx in 1:length(c_idx)
            (c_idx[idx] < 1 || c_idx[idx] > size(c, 1)) && throw(ArgumentError("c_idx must be ≥ 1 and ≤ $(size(c, 1))."))
        end
    end
    length(c_idx) == 1 && throw(ArgumentError("c_idx length must be ≥ 2."))

    labels = Vector{String}()
    for idx in 1:length(c_idx)
        push!(labels, string(c_idx[idx]))
    end

    # get time vector
    t = eeg.eeg_epochs_time[:, epoch]

    t_1, t_s1, t_2, t_s2 = _convert_t(t)
    if length(c_idx) == 1
        labels = [""]
        signal = vec(c)
    end
    title == "" && (title = "Component #$(lpad(string(c_idx), 3, "0"))\n[epoch: $epoch, time window: $t_s1:$t_s2]")

    c = c[c_idx, :, epoch]

    p = plot_signal_avg(t,
                        c,
                        labels=labels,
                        xlabel=xlabel,
                        ylabel=ylabel,
                        title=title,
                        mono=mono;
                        kwargs...)

    Plots.plot(p)

    return p
end

"""
    eeg_plot_component_idx_butterfly(eeg; <keyword arguments>)

Butterfly plot of indexed `eeg` external or embedded component.

# Arguments

- `eeg::NeuroJ.EEG`: EEG object
- `c::Union{Array{Float64, 3}, Symbol}`: values to plot; if symbol, than use embedded component
- `epoch::Int64`: epoch to display
- `c_idx::Union{Int64, Vector{Int64}, AbstractRange}=0`: component index to display, default is all components
- `xlabel::String="Time [s]"`: x-axis label
- `ylabel::String=""`: y-axis label
- `title::String=""`: plot title
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_component_idx_butterfly(eeg::NeuroJ.EEG; c::Union{Array{Float64, 3}, Symbol}, epoch::Int64, c_idx::Union{Int64, Vector{Int64}, AbstractRange}=0, xlabel::String="Time [s]", ylabel::String="", title::String="", mono::Bool=false, kwargs...)

    typeof(c) == Symbol && (c, _ = _get_component(eeg, c))

    _check_epochs(eeg, epoch)

    # select components, default is all
    if typeof(c) == Symbol
        c_idx == 0 && (c_idx = _select_cidx(eeg, c, c_idx, 0))
        _check_cidx(eeg, c, c_idx)
    else
        c_idx == 0 && (c_idx = 1:size(c, 1))
        for idx in 1:length(c_idx)
            (c_idx[idx] < 1 || c_idx[idx] > size(c, 1)) && throw(ArgumentError("c_idx must be ≥ 1 and ≤ $(size(c, 1))."))
        end
    end
    length(c_idx) == 1 && throw(ArgumentError("c_idx length must be ≥ 2."))

    labels = Vector{String}()
    for idx in 1:length(c_idx)
        push!(labels, string(c_idx[idx]))
    end

    # get time vector
    t = eeg.eeg_epochs_time[:, epoch]

    t_1, t_s1, t_2, t_s2 = _convert_t(t)
    if length(c_idx) == 1
        labels = [""]
        signal = vec(c)
    end
    title == "" && (title = "Component #$(lpad(string(c_idx), 3, "0"))\n[epoch: $epoch, time window: $t_s1:$t_s2]")

    c = c[c_idx, :, epoch]

    p = plot_signal_butterfly(t,
                              c,
                              labels=labels,
                              xlabel=xlabel,
                              ylabel=ylabel,
                              title=title,
                              mono=mono;
                              kwargs...)

    Plots.plot(p)

    return p
end

"""
    eeg_plot_component_idx_psd(eeg; <keyword arguments>)

Plot PSD of indexed `eeg` external or embedded component.

# Arguments

- `eeg::NeuroJ.EEG`: EEG object
- `c::Union{Array{Float64, 3}, Symbol}`: values to plot; if symbol, than use embedded component
- `epoch::Int64`: epoch to display
- `c_idx::Int64`: component index to display, default is all components
- `norm::Bool=true`: normalize powers to dB
- `frq_lim::Tuple{Real, Real}=(0, 0)`: x-axis limit
- `xlabel::String="Frequency [Hz]`: x-axis label
- `ylabel::String=""`: y-axis label
- `title::String=""`: plot title
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_component_idx_psd(eeg::NeuroJ.EEG; c::Union{Array{Float64, 3}, Symbol}, epoch::Int64, c_idx::Int64, norm::Bool=true, frq_lim::Tuple{Real, Real}=(0, 0), xlabel::String="Frequency [Hz]", ylabel::String="", title::String="", mono::Bool=false, kwargs...)

    ylabel == "" && (norm == true ? ylabel = "Power [dB]" : ylabel = "Power [μV^2/Hz]")

    typeof(c) == Symbol && (c, _ = _get_component(eeg, c))

    _check_epochs(eeg, epoch)

    (c_idx < 1 || c_idx > size(c, 1)) && throw(ArgumentError("c_idx must be ≥ 1 and ≤ $(size(c, 1))."))

    fs = eeg_sr(eeg)
    frq_lim == (0, 0) && (frq_lim = (0, div(fs, 2)))
    frq_lim = tuple_order(frq_lim)
    (frq_lim[1] < 0 || frq_lim[2] > fs / 2) && throw(ArgumentError("frq_lim must be ≥ 0 and ≤ $(fs / 2)."))

    labels = Vector{String}()
    for idx in 1:length(c_idx)
        push!(labels, string(c_idx[idx]))
    end

    # get time vector
    t = eeg.eeg_epochs_time[:, epoch]

    t_1, t_s1, t_2, t_s2 = _convert_t(t)
    if length(c_idx) == 1
        labels = [""]
        signal = vec(c)
    end
    title == "" && (title = "Component #$(lpad(string(c_idx), 3, "0")) PSD\n[frequency limit: $(frq_lim[1])-$(frq_lim[2]) Hz]\n[epoch: $epoch, time window: $t_s1:$t_s2]")

    c = c[c_idx, :, epoch]

    p = plot_psd(c,
                 fs=fs,
                 labels=labels,
                 norm=norm,
                 frq_lim=frq_lim,
                 xlabel=xlabel,
                 ylabel=ylabel,
                 title=title,
                 mono=mono;
                 kwargs...)

    Plots.plot(p)

    return p
end

"""
    eeg_plot_component_idx_psd_avg(eeg; <keyword arguments>)

Plot PSD of indexed `eeg` external or embedded component: mean ± 95% CI.

# Arguments

- `eeg::NeuroJ.EEG`: EEG object
- `c::Union{Array{Float64, 3}, Symbol}`: values to plot; if symbol, than use embedded component
- `epoch::Int64`: epoch to display
- `c_idx::Union{Int64, Vector{Int64}, AbstractRange}=0`: component index to display, default is all components
- `norm::Bool=true`: normalize powers to dB
- `frq_lim::Tuple{Real, Real}=(0, 0)`: x-axis limit
- `xlabel::String="Frequency [Hz]`: x-axis label
- `ylabel::String=""`: y-axis label
- `title::String=""`: plot title
- `mono::Bool=false`: use color or grey palette
- `ax::Symbol=:linlin`: type of axes scaling
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_component_idx_psd_avg(eeg::NeuroJ.EEG; c::Union{Array{Float64, 3}, Symbol}, epoch::Int64, c_idx::Union{Int64, Vector{Int64}, AbstractRange}=0, norm::Bool=true, frq_lim::Tuple{Real, Real}=(0, 0), xlabel::String="Frequency [Hz]", ylabel::String="", title::String="", mono::Bool=false, ax::Symbol=:linlin, kwargs...)

    ylabel == "" && (norm == true ? ylabel = "Power [dB]" : ylabel = "Power [μV^2/Hz]")
    ax in [:linlin, :loglin] || throw(ArgumentError("ax must be :linlin or :loglin."))

    typeof(c) == Symbol && (c, _ = _get_component(eeg, c))

    _check_epochs(eeg, epoch)

    # select components, default is all up to 20
    if typeof(c) == Symbol
        c_idx == 0 && (c_idx = _select_cidx(eeg, c, c_idx, 20))
        _check_cidx(eeg, c, c_idx)
    else
        if c_idx == 0
            size(c, 1) > 20 && (c_idx = 1:20)
            size(c, 1) <= 20 && (c_idx = 1:size(c, 1))
        end
        for idx in 1:length(c_idx)
            (c_idx[idx] < 1 || c_idx[idx] > size(c, 1)) && throw(ArgumentError("c_idx must be ≥ 1 and ≤ $(size(c, 1))."))
        end
    end
    length(c_idx) == 1 && throw(ArgumentError("c_idx length must be ≥ 2."))

    fs = eeg_sr(eeg)
    frq_lim == (0, 0) && (frq_lim = (0, div(fs, 2)))
    frq_lim = tuple_order(frq_lim)
    (frq_lim[1] < 0 || frq_lim[2] > fs / 2) && throw(ArgumentError("frq_lim must be ≥ 0 and ≤ $(fs / 2)."))

    labels = Vector{String}()
    for idx in 1:length(c_idx)
        push!(labels, string(c_idx[idx]))
    end

    # get time vector
    t = eeg.eeg_epochs_time[:, epoch]

    t_1, t_s1, t_2, t_s2 = _convert_t(t)
    if length(c_idx) == 1
        labels = [""]
        signal = vec(c)
    end
    title == "" && (title = "Component #$(lpad(string(c_idx), 3, "0")) PSD\n[frequency limit: $(frq_lim[1])-$(frq_lim[2]) Hz]\n[epoch: $epoch, time window: $t_s1:$t_s2]")

    c = c[c_idx, :, epoch]

    p = plot_psd_avg(c,
                     fs=fs,
                     labels=labels,
                     norm=norm,
                     frq_lim=frq_lim,
                     xlabel=xlabel,
                     ylabel=ylabel,
                     title=title,
                     mono=mono,
                     ax=ax;
                     kwargs...)

    Plots.plot(p)

    return p
end

"""
    eeg_plot_component_idx_psd_butterfly(eeg; <keyword arguments>)

Plot PSD of indexed `eeg` external or embedded component: mean ± 95% CI.

# Arguments

- `eeg::NeuroJ.EEG`: EEG object
- `c::Union{Array{Float64, 3}, Symbol}`: values to plot; if symbol, than use embedded component
- `epoch::Int64`: epoch to display
- `c_idx::Union{Int64, Vector{Int64}, AbstractRange}=0`: component index to display, default is all components
- `norm::Bool=true`: normalize powers to dB
- `frq_lim::Tuple{Real, Real}=(0, 0)`: x-axis limit
- `xlabel::String="Frequency [Hz]`: x-axis label
- `ylabel::String=""`: y-axis label
- `title::String=""`: plot title
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_component_idx_psd_butterfly(eeg::NeuroJ.EEG; c::Union{Array{Float64, 3}, Symbol}, epoch::Int64, c_idx::Union{Int64, Vector{Int64}, AbstractRange}=0, norm::Bool=true, frq_lim::Tuple{Real, Real}=(0, 0), xlabel::String="Frequency [Hz]", ylabel::String="", title::String="", mono::Bool=false, kwargs...)

    ylabel == "" && (norm == true ? ylabel = "Power [dB]" : ylabel = "Power [μV^2/Hz]")

    typeof(c) == Symbol && (c, _ = _get_component(eeg, c))

    _check_epochs(eeg, epoch)

    # select components, default is all up to 20
    if typeof(c) == Symbol
        c_idx == 0 && (c_idx = _select_cidx(eeg, c, c_idx, 20))
        _check_cidx(eeg, c, c_idx)
    else
        if c_idx == 0
            size(c, 1) > 20 && (c_idx = 1:20)
            size(c, 1) <= 20 && (c_idx = 1:size(c, 1))
        end
        for idx in 1:length(c_idx)
            (c_idx[idx] < 1 || c_idx[idx] > size(c, 1)) && throw(ArgumentError("c_idx must be ≥ 1 and ≤ $(size(c, 1))."))
        end
    end
    length(c_idx) == 1 && throw(ArgumentError("c_idx length must be ≥ 2."))

    fs = eeg_sr(eeg)
    frq_lim == (0, 0) && (frq_lim = (0, div(fs, 2)))
    frq_lim = tuple_order(frq_lim)
    (frq_lim[1] < 0 || frq_lim[2] > fs / 2) && throw(ArgumentError("frq_lim must be ≥ 0 and ≤ $(fs / 2)."))

    labels = Vector{String}()
    for idx in 1:length(c_idx)
        push!(labels, string(c_idx[idx]))
    end

    # get time vector
    t = eeg.eeg_epochs_time[:, epoch]

    t_1, t_s1, t_2, t_s2 = _convert_t(t)
    if length(c_idx) == 1
        labels = [""]
        signal = vec(c)
    end
    title == "" && (title = "Component #$(lpad(string(c_idx), 3, "0")) PSD\n[frequency limit: $(frq_lim[1])-$(frq_lim[2]) Hz]\n[epoch: $epoch, time window: $t_s1:$t_s2]")

    c = c[c_idx, :, epoch]

    p = plot_psd_butterfly(c,
                           fs=fs,
                           labels=labels,
                           norm=norm,
                           frq_lim=frq_lim,
                           xlabel=xlabel,
                           ylabel=ylabel,
                           title=title,
                           mono=mono;
                           kwargs...)

    Plots.plot(p)

    return p
end

"""
    plot_signal_avg(t, signal; <keyword arguments>)

Plot `signal` channels: mean and ±95% CI.

# Arguments

- `t::Union{Vector{<:Real}, AbstractRange}`
- `signal::Matrix{<:Real}`
- `norm::Bool=false`: normalize the `signal` prior to calculations
- `xlabel::String="Time [s]"`: x-axis label
- `ylabel::String="Amplitude [μV]"`: y-axis label
- `title::String=""`: plot title
- `ylim::Tuple{Real, Real}=(0, 0)`: y-axis limits
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function plot_signal_avg(t::Union{Vector{<:Real}, AbstractRange}, signal::Matrix{<:Real}; norm::Bool=false, xlabel::String="Time [s]", ylabel::String="Amplitude [μV]", title::String="", ylim::Tuple{Real, Real}=(0, 0), mono::Bool=false, kwargs...)

    typeof(t) <: AbstractRange && (t = float(collect(t)))

    mono == true ? palette = :grays : palette = :darktest

    s_normalized = signal
    norm == true && (s_normalized = normalize_zscore(signal))
    s_m, s_s, s_u, s_l = s_msci95(s_normalized)

    ylim == (0, 0) && (ylim = (floor(minimum(s_l), digits=0), ceil(maximum(s_u), digits=0)))
    ylim = _tuple_max(ylim)
    ylim = tuple_order(ylim)

    # plot channel
    p = Plots.plot(xlabel=xlabel,
             ylabel=ylabel,
             xlims=_xlims(t),
             xticks=_xticks(t),
             ylims=ylim,
             title=title,
             palette=palette,
             titlefontsize=8,
             xlabelfontsize=6,
             ylabelfontsize=6,
             xtickfontsize=4,
             ytickfontsize=4;
             kwargs...)
    p = Plots.plot!(t,
              s_u[1:length(t)],
              fillrange=s_l,
              fillalpha=0.35, 
              label=false,
              t=:line,
              c=:grey,
              linewidth=0.5)
    p = Plots.plot!(t,
              s_l[1:length(t)],
              label=false,
              t=:line,
              c=:grey,
              lw=0.5)
    p = Plots.plot!(t,
              s_m[1:length(t)],
              linewidth=0.5,
              label=false,
              t=:line, 
              c=:black)

    return p
end

"""
    eeg_plot_signal_avg(eeg; <keyword arguments>)

Plot `eeg` channels: mean and ±95% CI.

# Arguments

- `eeg::NeuroJ.EEG`: EEG object
- `epoch::Union{Int64, AbstractRange}=0`: epoch number to display
- `channel::Union{Int64, Vector{Int64}, AbstractRange}=0`: channel to display, default is all channels
- `offset::Int64=0`: displayed segment offset in samples
- `len::Int64=0`: displayed segment length in samples, default is 1 epoch or 20 seconds
- `norm::Bool=false`: normalize the `signal` prior to calculations
- `xlabel::String="Time [s]"`: x-axis label
- `ylabel::String="Amplitude [μV]"`: y-axis label
- `title::String=""`: plot title
- `ylim::Tuple{Real, Real}=(0, 0)`: y-axis limits
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_signal_avg(eeg::NeuroJ.EEG; epoch::Union{Int64, AbstractRange}=0, channel::Union{Int64, Vector{Int64}, AbstractRange}=0, offset::Int64=0, len::Int64=0, norm::Bool=false, xlabel::String="Time [s]", ylabel::String="Amplitude [μV]", title::String="", ylim::Tuple{Real, Real}=(0, 0), mono::Bool=false, kwargs...)

    typeof(channel) == Int64 && channel != 0 && throw(ArgumentError("For eeg_plot_signal_avg() channel must contain ≥ 2 channels."))
    eeg_channel_n(eeg, type=:eeg) < eeg_channel_n(eeg, type=:all) && throw(ArgumentError("EEG contains non-eeg channels (e.g. ECG or EMG), remove them before plotting."))

    ylim = _tuple_max(ylim)
    ylim = tuple_order(ylim)

    (epoch != 0 && len != 0) && throw(ArgumentError("Both epoch and len must not be specified."))

    epoch_tmp = epoch
    if epoch != 0
        # convert epochs to offset and len
        typeof(epoch) <: AbstractRange && (epoch = collect(epoch))
        _check_epochs(eeg, epoch)
        length(epoch) > 1 && sort!(epoch)
        len = eeg_epoch_len(eeg) * length(epoch)
        offset = eeg_epoch_len(eeg) * (epoch[1] - 1)
        epoch_tmp = epoch[1]:epoch[end]
        epoch = epoch[1]
    else
        # default length is one epoch or 20 seconds
        len == 0 && (len = _len(eeg, len, 20))
        epoch = floor(Int64, offset / eeg_epoch_len(eeg)) + 1
        epoch_tmp = (floor(Int64, offset / eeg_epoch_len(eeg)) + 1):(ceil(Int64, (offset + len) / eeg_epoch_len(eeg)))
    end

    # select channels, default is all up to 20 channels
    channel == 0 && (channel = _select_channels(eeg, channel, 20))
    _check_channels(eeg, channel)

    # set epoch markers if len > epoch_len
    eeg_tmp, epoch_markers = _get_epoch_markers(eeg, offset, len)

    labels = eeg_labels(eeg)[channel]

    # get time vector
    if length(epoch) == 1 && offset + len <= eeg_epoch_len(eeg)
        t = eeg.eeg_epochs_time[(1 + offset):(offset + len), epoch]
        t[1] = floor(t[1], digits=2)
        t[end] = ceil(t[end], digits=2)
    else
        t = _get_t(eeg_tmp, offset, len)
    end

    _check_offset_len(eeg_tmp, offset, len)

    signal = eeg_tmp.eeg_signals[channel, (1 + offset):(offset + length(t)), 1]

    channel_name = _channel2channel_name(channel)

    t_1, t_s1, t_2, t_s2 = _convert_t(t)

    epoch_tmp = _t2epoch(eeg, offset, len, epoch_tmp)
    epoch_tmp[end] == epoch_tmp[1] && (epoch_tmp = epoch_tmp[1])
    title == "" && (title = "Signal\n[channel: $(channel_name), epoch: $epoch_tmp, time window: $t_s1:$t_s2]")

    p = plot_signal_avg(t,
                        signal,
                        norm=norm,
                        xlabel=xlabel,
                        ylabel=ylabel,
                        title=title,
                        ylim=ylim,
                        mono=mono;
                        kwargs...)

    # add epochs markers
    if norm == true
        s_normalized = normalize_zscore(signal)
    else
        s_normalized = signal
    end
    s_normalized_m, s_normalized_s, s_normalized_u, s_normalized_l = s_msci95(s_normalized)
    ylim = (floor(minimum(s_normalized_l), digits=0), ceil(maximum(s_normalized_u), digits=0))
    ylim = _tuple_max(ylim)
    if length(epoch_markers) > 0 && len + offset > eeg_epoch_len(eeg) && eeg_epoch_n(eeg) > 1
        p = vline!(epoch_markers,
                   linestyle=:dash,
                   linewidth=0.2,
                   linecolor=:black,
                   label="")
        for idx in 1:length(epoch_markers)
            p = Plots.plot!(annotation=((epoch_markers[idx] - 1), ylim[2], Plots.text("E$(floor(Int64, epoch_markers[idx] / (eeg_epoch_len(eeg) / eeg_sr(eeg))))", pointsize=4, halign=:center, valign=:top)))
        end
    end

    Plots.plot(p)

    return p
end

"""
    eeg_plot_avg_details(eeg; <keyword arguments>)

Plot details of averaged `eeg` channels: amplitude, histogram, power density, phase histogram and spectrogram.

# Arguments

- `eeg::NeuroJ.EEG`: EEG object
- `epoch::Union{Int64, AbstractRange}=0`: epoch number to display
- `channel::Union{Int64, Vector{Int64}, AbstractRange}=0`: channel to display, default is all channels
- `offset::Int64=0`: displayed segment offset in samples
- `len::Int64=0`: displayed segment length in samples, default is 1 epoch or 20 seconds
- `norm::Bool=false`: normalize the `signal` prior to calculations
- `mw::Bool=false`: if true use Morlet wavelet convolution
- `mt::Bool=false`: if true use multi-tapered spectrogram
- `frq_lim::Tuple{Real, Real}=(0, 0)`: y-axis limits
- `ncyc::Union{Int64, Tuple{Int64, Int64}}=6`: number of cycles for Morlet wavelet
- `xlabel::String="Time [s]"`: x-axis label
- `ylabel::String="Amplitude [μV]"`: y-axis label
- `title::String=""`: plot title
- `ylim::Tuple{Real, Real}=(0, 0)`: y-axis limits
- `hist::Symbol=:hist`: histogram type: :hist, :kd
- `head::Bool=true`: add head plot
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_signal_avg_details(eeg::NeuroJ.EEG; epoch::Union{Int64, AbstractRange}=0, channel::Union{Int64, Vector{Int64}, AbstractRange}=0, offset::Int64=0, len::Int64=0, norm::Bool=false, mw::Bool=false, mt::Bool=false, frq_lim::Tuple{Real, Real}=(0, 0), ncyc::Union{Int64, Tuple{Int64, Int64}}=6, xlabel::String="Time [s]", ylabel::String="Amplitude [μV]", title::String="", ylim::Tuple{Real, Real}=(0, 0), hist::Symbol=:hist, head::Bool=true, mono::Bool=false, kwargs...)

    typeof(channel) == Int64 && channel != 0 && throw(ArgumentError("For eeg_plot_signal_avg_details() channel must contain ≥ 2 channels."))

    eeg_channel_n(eeg, type=:eeg) < eeg_channel_n(eeg, type=:all) && throw(ArgumentError("EEG contains non-eeg channels (e.g. ECG or EMG), remove them before plotting."))
    hist in [:hist, :kd] || throw(ArgumentError("hist must be :hist or :kd."))
    (epoch != 0 && len != 0) && throw(ArgumentError("Both epoch and len must not be specified."))

    fs = eeg_sr(eeg)
    frq_lim == (0, 0) && (frq_lim = (0, div(fs, 2)))
    frq_lim = tuple_order(frq_lim)
    (frq_lim[1] < 0 || frq_lim[2] > fs / 2) && throw(ArgumentError("frq_lim must be ≥ 0 and ≤ $(fs / 2)."))

    ylim = _tuple_max(ylim)
    ylim = tuple_order(ylim)

    epoch_tmp = epoch
    if epoch != 0
        # convert epochs to offset and len
        typeof(epoch) <: AbstractRange && (epoch = collect(epoch))
        _check_epochs(eeg, epoch)
        length(epoch) > 1 && sort!(epoch)
        len = eeg_epoch_len(eeg) * length(epoch)
        offset = eeg_epoch_len(eeg) * (epoch[1] - 1)
        epoch_tmp = epoch[1]:epoch[end]
        epoch = epoch[1]
    else
        # default length is one epoch or 20 seconds
        len == 0 && (len = _len(eeg, len, 20))
        epoch = floor(Int64, offset / eeg_epoch_len(eeg)) + 1
        epoch_tmp = (floor(Int64, offset / eeg_epoch_len(eeg)) + 1):(ceil(Int64, (offset + len) / eeg_epoch_len(eeg)))
    end

    # select channels, default is all up to 20 channels
    channel == 0 && (channel = _select_channels(eeg, channel, 20))
    _check_channels(eeg, channel)

    # set epoch markers if len > epoch_len
    eeg_tmp, epoch_markers = _get_epoch_markers(eeg, offset, len)

    labels = eeg_labels(eeg)[channel]

    # get time vector
    if length(epoch) == 1 && offset + len <= eeg_epoch_len(eeg)
        t = eeg.eeg_epochs_time[(1 + offset):(offset + len), epoch]
        t[1] = floor(t[1], digits=2)
        t[end] = ceil(t[end], digits=2)
    else
        t = _get_t(eeg_tmp, offset, len)
    end

    _check_offset_len(eeg_tmp, offset, len)

    signal = eeg_tmp.eeg_signals[channel, (1 + offset):(offset + length(t)), 1]

    channel_name = _channel2channel_name(channel)

    t_1, t_s1, t_2, t_s2 = _convert_t(t)

    epoch_tmp = _t2epoch(eeg, offset, len, epoch_tmp)
    epoch_tmp[end] == epoch_tmp[1] && (epoch_tmp = epoch_tmp[1])
    title == "" && (title = "Signals\n[channel: $(channel_name), epoch: $epoch_tmp, time window: $t_s1:$t_s2]")

    p = plot_signal_avg(t,
                        signal,
                        norm=norm,
                        xlabel=xlabel,
                        ylabel=ylabel,
                        title=title,
                        ylim=ylim,
                        mono=mono;
                        kwargs...)

    # add epochs markers
    if norm == true
        s_normalized = normalize_zscore(signal)
    else
        s_normalized = signal
    end
    s_normalized_m, s_normalized_s, s_normalized_u, s_normalized_l = s_msci95(s_normalized)
    ylim = (floor(minimum(s_normalized_l), digits=0), ceil(maximum(s_normalized_u), digits=0))
    ylim = _tuple_max(ylim)
    if length(epoch_markers) > 0 && len + offset > eeg_epoch_len(eeg) && eeg_epoch_n(eeg) > 1
        p = vline!(epoch_markers,
                   linestyle=:dash,
                   linewidth=0.2,
                   linecolor=:black,
                   label="")
        for idx in 1:length(epoch_markers)
            p = Plots.plot!(annotation=((epoch_markers[idx] - 1), ylim[2], Plots.text("E$(floor(Int64, epoch_markers[idx] / (eeg_epoch_len(eeg) / eeg_sr(eeg))))", pointsize=4, halign=:center, valign=:top)))
        end
    end

    # cannot plot electrodes without locations
    eeg.eeg_header[:channel_locations] == false && (head = false)
    eeg_avg = eeg_average(eeg)
    psd = eeg_plot_signal_psd_avg(eeg_tmp, channel=channel, len=len, offset=offset, title="PSD averaged\n[frequency limit: $(frq_lim[1])-$(frq_lim[2]) Hz]", norm=true, mt=mt, legend=false, ylabel="Power [dB]")
    s = eeg_plot_signal_spectrogram(eeg, channel=channel, len=len, offset=offset, mw=mw, mt=mt, frq_lim=frq_lim, ncyc=ncyc, title="Channels spectrogram\n[frequency limit: $(frq_lim[1])-$(frq_lim[2]) Hz]", legend=false, mono=mono)
    ht_a = eeg_plot_histogram(eeg_avg, channel=1, len=len, offset=offset, type=hist, labels=[""], legend=false, title="Signal\nhistogram", mono=mono)
    _, _, _, s_phase = s_hspectrum(s_normalized_m)
    ht_p = plot_histogram(rad2deg.(s_phase), offset=offset, len=len, type=:kd, labels=[""], legend=false, title="Phase\nhistogram", xticks=[-180, 0, 180], linecolor=:black, mono=mono)
    if head == true
        if collect(channel[1]:channel[end]) == channel
            channel_list = string(channel[1]) * ":" * string(channel[end])
        else
            channel_list = "" 
            for idx in 1:(length(channel) - 1)
                channel_list *= string(channel[idx])
                channel_list *= ", "
            end
            channel_list *= string(channel[end])
        end
        hd = eeg_plot_electrodes(eeg, labels=false, selected=channel, small=true, title="Channels\n$channel_list", mono=mono)
        l = @layout [a{0.33h} b{0.2w}; c{0.33h} d{0.2w}; e{0.33h} f{0.2w}]
        p = Plots.plot(p, ht_a, psd, ht_p, s, hd, layout=l)
    else
        l = @layout [a{0.33h} b{0.2w}; c{0.33h} d{0.2w}; e{0.33h} _]
        p = Plots.plot(p, ht_a, psd, ht_p, s, layout=l)
    end

    Plots.plot(p)

    return p
end

"""
    eeg_plot_component_avg(eeg; <keyword arguments>)

Plot `eeg` external or embedded component: mean and ±95% CI.

# Arguments

- `eeg::NeuroJ.EEG`: EEG object
- `c::Union{Array{Float64, 3}, Symbol}`: values to plot; if symbol, than use embedded component
- `epoch::Int64`: epoch to display
- `channel::Union{Int64, Vector{Int64}, AbstractRange}=0`: channels to display, default is all channels
- `xlabel::String="Time [s]"`: x-axis label
- `ylabel::String=""`: y-axis label
- `title::String=""`: plot title
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_component_avg(eeg::NeuroJ.EEG; c::Union{Array{Float64, 3}, Symbol}, epoch::Int64, channel::Union{Int64, Vector{Int64}, AbstractRange}=0, xlabel::String="Time [s]", ylabel::String="", title::String="", mono::Bool=false, kwargs...)

    typeof(c) == Symbol && (c, _ = _get_component(eeg, c))

    size(c) == size(eeg.eeg_signals) || throw(ArgumentError("Size of c ($(size(c))) does not match size of EEG signal ($(size(eeg.eeg_signals))), use another type of plotting function."))

    _check_epochs(eeg, epoch)

    # select channels, default is all up to 20 channels
    channel == 0 && (channel = _select_channels(eeg, channel, 20))
    _check_channels(eeg, channel)

    labels = eeg_labels(eeg)[channel]

    # get time vector
    t = eeg.eeg_epochs_time[:, epoch]

    t_1, t_s1, t_2, t_s2 = _convert_t(t)
    if length(channel) == 1
        channel_name = labels
        labels = [""]
        signal = vec(c)
    else
        channel_name = _channel2channel_name(channel)
    end
    title == "" && (title = "Component\n[channel: $channel_name, epoch: $epoch, time window: $t_s1:$t_s2]")

    c = c[channel, :, epoch]

    p = plot_signal_avg(t,
                        c,
                        labels=labels,
                        xlabel=xlabel,
                        ylabel=ylabel,
                        title=title,
                        mono=mono;
                        kwargs...)

    Plots.plot(p)

    return p
end

"""
    plot_signal_butterfly(t, signal; <keyword arguments>)

Butterfly plot of `signal` channels.

# Arguments

- `t::Union{Vector{<:Real}, AbstractRange}`
- `signal::Matrix{<:Real}`
- `labels::Vector{String}=[""]`: channel labels vector
- `norm::Bool=false`: normalize the `signal` prior to calculations
- `xlabel::String="Time [s]"`: x-axis label
- `ylabel::String="Amplitude [μV]"`: y-axis label
- `title::String=""`: plot title
- `ylim::Tuple`: y-axis limits, default (0, 0)
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function plot_signal_butterfly(t::Union{Vector{<:Real}, AbstractRange}, signal::Matrix{<:Real}; labels::Vector{String}=[""], norm::Bool=false, xlabel::String="Time [s]", ylabel::String="Amplitude [μV]", title::String="", ylim::Tuple{Real, Real}=(0, 0), mono::Bool=false, kwargs...)

    typeof(t) <: AbstractRange && (t = float(collect(t)))

    mono == true ? palette = :grays : palette = :darktest

    channel_n = size(signal, 1)

    if norm == true
        s_normalized = normalize_zscore(reshape(signal, size(signal, 1), size(signal, 2), 1))
    else
        s_normalized = signal
    end

    ylim == (0, 0) && (ylim = (floor(minimum(s_normalized), digits=0), ceil(maximum(s_normalized), digits=0)))
    ylim = _tuple_max(ylim)
    ylim = tuple_order(ylim)

    if labels == [""]
        labels = Vector{String}(undef, channel_n)
        for idx in 1:channel_n
            labels[idx] = ""
        end
    end
    
    # plot channels
    p = Plots.plot(xlabel=xlabel,
             ylabel=ylabel,
             xlims=_xlims(t),
             xticks=_xticks(t),
             ylims=ylim,
             title=title,
             palette=palette,
             titlefontsize=8,
             xlabelfontsize=6,
             ylabelfontsize=6,
             xtickfontsize=4,
             ytickfontsize=4;
             kwargs...)
    for idx in 1:channel_n
        p = Plots.plot!(t,
                  s_normalized[idx, 1:length(t)],
                  t=:line,
                  linecolor=idx,
                  linewidth=0.1,
                  label=labels[idx])
    end

    return p
end

"""
    eeg_plot_signal_butterfly(eeg; <keyword arguments>)

Butterfly plot of `eeg` channels.

# Arguments

# Arguments

- `eeg::NeuroJ.EEG`: EEG object
- `epoch::Union{Int64, AbstractRange}=1`: epoch number to display
- `channel::Union{Int64, Vector{Int64}, AbstractRange}=0`: channel to display, default is all channels
- `offset::Int64=0`: displayed segment offset in samples
- `len::Int64=0`: displayed segment length in samples, default is 1 epoch or 20 seconds
- `norm::Bool=false`: normalize the `signal` prior to calculations
- `xlabel::String="Time [s]"`: x-axis label
- `ylabel::String="Amplitude [μV]"`: y-axis label
- `title::String=""`: plot title
- `ylim::Tuple{Real, Real}=(0, 0)`: y-axis limits
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_signal_butterfly(eeg::NeuroJ.EEG; epoch::Union{Int64, AbstractRange}=0, channel::Union{Int64, Vector{Int64}, AbstractRange}=0, offset::Int64=0, len::Int64=0, norm::Bool=false, xlabel::String="Time [s]", ylabel::String="Amplitude [μV]", title::String="", ylim::Tuple{Real, Real}=(0, 0), mono::Bool=false, kwargs...)

    typeof(channel) == Int64 && channel != 0 && throw(ArgumentError("For eeg_plot_signal_butterfly() channel must contain ≥ 2 channels."))

    eeg_channel_n(eeg, type=:eeg) < eeg_channel_n(eeg, type=:all) && throw(ArgumentError("EEG contains non-eeg channels (e.g. ECG or EMG), remove them before plotting."))

    ylim = _tuple_max(ylim)
    ylim = tuple_order(ylim)

    (epoch != 0 && len != 0) && throw(ArgumentError("Both epoch and len must not be specified."))

    epoch_tmp = epoch
    if epoch != 0
        # convert epochs to offset and len
        typeof(epoch) <: AbstractRange && (epoch = collect(epoch))
        _check_epochs(eeg, epoch)
        length(epoch) > 1 && sort!(epoch)
        len = eeg_epoch_len(eeg) * length(epoch)
        offset = eeg_epoch_len(eeg) * (epoch[1] - 1)
        epoch_tmp = epoch[1]:epoch[end]
        epoch = epoch[1]
    else
        # default length is one epoch or 20 seconds
        len == 0 && (len = _len(eeg, len, 20))
        epoch = floor(Int64, offset / eeg_epoch_len(eeg)) + 1
        epoch_tmp = (floor(Int64, offset / eeg_epoch_len(eeg)) + 1):(ceil(Int64, (offset + len) / eeg_epoch_len(eeg)))
    end

    # select channels, default is all up to 20 channels
    channel == 0 && (channel = _select_channels(eeg, channel, 20))
    _check_channels(eeg, channel)

    # set epoch markers if len > epoch_len
    eeg_tmp, epoch_markers = _get_epoch_markers(eeg, offset, len)

    labels = eeg_labels(eeg)[channel]

    # get time vector
    if length(epoch) == 1 && offset + len <= eeg_epoch_len(eeg)
        t = eeg.eeg_epochs_time[(1 + offset):(offset + len), epoch]
        t[1] = floor(t[1], digits=2)
        t[end] = ceil(t[end], digits=2)
    else
        t = _get_t(eeg_tmp, offset, len)
    end

    _check_offset_len(eeg_tmp, offset, len)

    signal = eeg_tmp.eeg_signals[channel, (1 + offset):(offset + length(t)), 1]

    channel_name = _channel2channel_name(channel)

    t_1, t_s1, t_2, t_s2 = _convert_t(t)

    epoch_tmp = _t2epoch(eeg, offset, len, epoch_tmp)
    epoch_tmp[end] == epoch_tmp[1] && (epoch_tmp = epoch_tmp[1])
    title == "" && (title = "Signals\n[channel: $(channel_name), epoch: $epoch_tmp, time window: $t_s1:$t_s2]")

    p = plot_signal_butterfly(t,
                              signal,
                              offset=offset,
                              labels=labels,
                              norm=norm,
                              xlabel=xlabel,
                              ylabel=ylabel,
                              title=title,
                              ylim=ylim,
                              mono=mono;
                              kwargs...)

    # add epochs markers
    if norm == true
        s_normalized = normalize_zscore(signal)
    else
        s_normalized = signal
    end
    s_normalized_m, s_normalized_s, s_normalized_u, s_normalized_l = s_msci95(s_normalized)
    ylim = (floor(minimum(s_normalized_l), digits=0), ceil(maximum(s_normalized_u), digits=0))
    ylim = _tuple_max(ylim)
    if length(epoch_markers) > 0 && len + offset > eeg_epoch_len(eeg) && eeg_epoch_n(eeg) > 1
        p = vline!(epoch_markers,
                   linestyle=:dash,
                   linewidth=0.2,
                   linecolor=:black,
                   label="")
        for idx in 1:length(epoch_markers)
            p = Plots.plot!(annotation=((epoch_markers[idx] - 1), ylim[2], Plots.text("E$(floor(Int64, epoch_markers[idx] / (eeg_epoch_len(eeg) / eeg_sr(eeg))))", pointsize=4, halign=:center, valign=:top)))
        end
    end

    Plots.plot(p)

    return p
end

"""
    eeg_plot_signal_butterfly_details(eeg; <keyword arguments>)

Plot details butterfly plot of `eeg` channels: amplitude, histogram, power density, phase histogram and spectrogram.

# Arguments

- `eeg::NeuroJ.EEG`: EEG object
- `epoch::Int64=1`: epoch number to display
- `channel::Union{Int64, Vector{Int64}, AbstractRange}=0`: channel to display, default is all channels
- `offset::Int64=0`: displayed segment offset in samples
- `len::Int64=0`: displayed segment length in samples, default is 1 epoch or 20 seconds
- `norm::Bool=false`: normalize the `signal` prior to calculations
- `mw::Bool=false`: if true use Morlet wavelet convolution
- `mt::Bool=false`: if true use multi-tapered periodogram/spectrogram
- `frq_lim::Tuple{Real, Real}=(0, 0)`: y-axis limits
- `ncyc::Union{Int64, Tuple{Int64, Int64}}=6`: number of cycles for Morlet wavelet
- `xlabel::String="Time [s]"`: x-axis label
- `ylabel::String="Amplitude [μV]"`: y-axis label
- `title::String=""`: plot title
- `ylim::Tuple{Real, Real}=(0, 0)`: y-axis limits
- `hist::Symbol=:hist`: histogram type: :hist, :kd
- `head::Bool=true`: add head plot
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_signal_butterfly_details(eeg::NeuroJ.EEG; epoch::Union{Int64, AbstractRange}=0, channel::Union{Int64, Vector{Int64}, AbstractRange}=0, offset::Int64=0, len::Int64=0, norm::Bool=false, mw::Bool=false, mt::Bool=false, frq_lim::Tuple{Real, Real}=(0, 0), ncyc::Union{Int64, Tuple{Int64, Int64}}=6, xlabel::String="Time [s]", ylabel::String="Amplitude [μV]", title::String="", ylim::Tuple{Real, Real}=(0, 0), hist::Symbol=:hist, head::Bool=true, mono::Bool=false, kwargs...)

    typeof(channel) == Int64 && channel != 0 && throw(ArgumentError("For eeg_plot_signal_butterfly_details() channel must contain ≥ 2 channels."))

    eeg_channel_n(eeg, type=:eeg) < eeg_channel_n(eeg, type=:all) && throw(ArgumentError("EEG contains non-eeg channels (e.g. ECG or EMG), remove them before plotting."))
    hist in [:hist, :kd] || throw(ArgumentError("hist must be :hist or :kd."))
    (epoch != 0 && len != 0) && throw(ArgumentError("Both epoch and len must not be specified."))

    fs = eeg_sr(eeg)
    frq_lim == (0, 0) && (frq_lim = (0, div(fs, 2)))
    frq_lim = tuple_order(frq_lim)
    (frq_lim[1] < 0 || frq_lim[2] > fs / 2) && throw(ArgumentError("frq_lim must be ≥ 0 and ≤ $(fs / 2)."))

    ylim = _tuple_max(ylim)
    ylim = tuple_order(ylim)

    epoch_tmp = epoch
    if epoch != 0
        # convert epochs to offset and len
        typeof(epoch) <: AbstractRange && (epoch = collect(epoch))
        _check_epochs(eeg, epoch)
        length(epoch) > 1 && sort!(epoch)
        len = eeg_epoch_len(eeg) * length(epoch)
        offset = eeg_epoch_len(eeg) * (epoch[1] - 1)
        epoch_tmp = epoch[1]:epoch[end]
        epoch = epoch[1]
    else
        # default length is one epoch or 20 seconds
        len == 0 && (len = _len(eeg, len, 20))
        epoch = floor(Int64, offset / eeg_epoch_len(eeg)) + 1
        epoch_tmp = (floor(Int64, offset / eeg_epoch_len(eeg)) + 1):(ceil(Int64, (offset + len) / eeg_epoch_len(eeg)))
    end

    # select channels, default is all up to 20 channels
    channel == 0 && (channel = _select_channels(eeg, channel, 20))
    _check_channels(eeg, channel)

    # set epoch markers if len > epoch_len
    eeg_tmp, epoch_markers = _get_epoch_markers(eeg, offset, len)

    labels = eeg_labels(eeg)[channel]

    # get time vector
    if length(epoch) == 1 && offset + len <= eeg_epoch_len(eeg)
        t = eeg.eeg_epochs_time[(1 + offset):(offset + len), epoch]
        t[1] = floor(t[1], digits=2)
        t[end] = ceil(t[end], digits=2)
    else
        t = _get_t(eeg_tmp, offset, len)
    end

    _check_offset_len(eeg_tmp, offset, len)

    signal = eeg_tmp.eeg_signals[channel, (1 + offset):(offset + length(t)), 1]

    channel_name = _channel2channel_name(channel)

    t_1, t_s1, t_2, t_s2 = _convert_t(t)

    epoch_tmp = _t2epoch(eeg, offset, len, epoch_tmp)
    epoch_tmp[end] == epoch_tmp[1] && (epoch_tmp = epoch_tmp[1])
    title == "" && (title = "Signals\n[channel: $(channel_name), epoch: $epoch_tmp, time window: $t_s1:$t_s2]")

    p = plot_signal_butterfly(t,
                              signal,
                              offset=offset,
                              labels=[""],
                              norm=norm,
                              xlabel=xlabel,
                              ylabel=ylabel,
                              title=title,
                              ylim=ylim,
                              mono=mono;
                              kwargs...)

    # add epochs markers
    if norm == true
        s_normalized = normalize_zscore(signal)
    else
        s_normalized = signal
    end
    s_normalized_m, s_normalized_s, s_normalized_u, s_normalized_l = s_msci95(s_normalized)
    ylim = (floor(minimum(s_normalized_l), digits=0), ceil(maximum(s_normalized_u), digits=0))
    ylim = _tuple_max(ylim)
    if length(epoch_markers) > 0 && len + offset > eeg_epoch_len(eeg) && eeg_epoch_n(eeg) > 1
        p = vline!(epoch_markers,
                   linestyle=:dash,
                   linewidth=0.2,
                   linecolor=:black,
                   label="")
        for idx in 1:length(epoch_markers)
            p = Plots.plot!(annotation=((epoch_markers[idx] - 1), ylim[2], Plots.text("E$(floor(Int64, epoch_markers[idx] / (eeg_epoch_len(eeg) / eeg_sr(eeg))))", pointsize=4, halign=:center, valign=:top)))
        end
    end

    # cannot plot electrodes without locations
    eeg.eeg_header[:channel_locations] == false && (head = false)
    psd = eeg_plot_signal_psd_avg(eeg_tmp, channel=channel, len=len, offset=offset, title="PSD averaged\n[frequency limit: $(frq_lim[1])-$(frq_lim[2]) Hz]", norm=norm, mt=mt, legend=false, ylabel="Power [dB]")
    s = eeg_plot_signal_spectrogram(eeg, channel=channel, len=len, offset=offset, mw=mw, mt=mt, frq_lim=frq_lim, ncyc=ncyc, title="Channels spectrogram\n[frequency limit: $(frq_lim[1])-$(frq_lim[2]) Hz]", legend=false, mono=mono)
    ht_a = eeg_plot_histogram(eeg, channel=1, len=len, offset=offset, type=hist, labels=[""], legend=false, title="Signal\nhistogram", mono=mono)
    _, _, _, s_phase = s_hspectrum(s_normalized_m)
    ht_p = plot_histogram(rad2deg.(s_phase), offset=offset, len=len, type=:kd, labels=[""], legend=false, title="Phase\nhistogram", xticks=[-180, 0, 180], linecolor=:black, mono=mono)
    if head == true
        if collect(channel[1]:channel[end]) == channel
            channel_list = string(channel[1]) * ":" * string(channel[end])
        else
            channel_list = "" 
            for idx in 1:(length(channel) - 1)
                channel_list *= string(channel[idx])
                channel_list *= ", "
            end
            channel_list *= string(channel[end])
        end
        hd = eeg_plot_electrodes(eeg, labels=false, selected=channel, small=true, title="Channels\n$channel_list", mono=mono)
        l = @layout [a{0.33h} b{0.2w}; c{0.33h} d{0.2w}; e{0.33h} f{0.2w}]
        p = Plots.plot(p, ht_a, psd, ht_p, s, hd, layout=l)
    else
        l = @layout [a{0.33h} b{0.2w}; c{0.33h} d{0.2w}; e{0.33h} _]
        p = Plots.plot(p, ht_a, psd, ht_p, s, layout=l)
    end

    Plots.plot(p)

    return p
end

"""
    eeg_plot_component_butterfly(eeg; <keyword arguments>)

Butterfly plot of `eeg` external or embedded component.

# Arguments

- `eeg::NeuroJ.EEG`: EEG object
- `c::Union{Array{Float64, 3}, Symbol}`: values to plot; if symbol, than use embedded component
- `epoch::Int64`: epoch to display
- `channel::Union{Int64, Vector{Int64}, AbstractRange}=0`: channels to display, default is all channels
- `norm::Bool=false`: normalize the `signal` prior to calculations
- `xlabel::String="Time [s]"`: x-axis label
- `ylabel::String=""`: y-axis label
- `title::String=""`: plot title
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_component_butterfly(eeg::NeuroJ.EEG; c::Union{Array{Float64, 3}, Symbol}, epoch::Int64, channel::Union{Int64, Vector{Int64}, AbstractRange}=0, norm::Bool=false, xlabel::String="Time [s]", ylabel::String="", title::String="", mono::Bool=false, kwargs...)

    typeof(c) == Symbol && (c, _ = _get_component(eeg, c))

    size(c) == size(eeg.eeg_signals) || throw(ArgumentError("Size of c ($(size(c))) does not match size of EEG signal ($(size(eeg.eeg_signals))), use another type of plotting function."))

    _check_epochs(eeg, epoch)

    # select channels, default is all up to 20 channels
    channel == 0 && (channel = _select_channels(eeg, channel, 20))
    _check_channels(eeg, channel)

    labels = eeg_labels(eeg)[channel]

    # get time vector
    t = eeg.eeg_epochs_time[:, epoch]

    t_1, t_s1, t_2, t_s2 = _convert_t(t)
    if length(channel) == 1
        channel_name = labels
        labels = [""]
        signal = vec(c)
    else
        channel_name = _channel2channel_name(channel)
    end
    title == "" && (title = "Component\n[channel: $channel_name, epoch: $epoch, time window: $t_s1:$t_s2]")

    c = c[channel, :, epoch]

    p = plot_signal_butterfly(t,
                              c,
                              norm=norm,
                              labels=labels,
                              xlabel=xlabel,
                              ylabel=ylabel,
                              title=title,
                              mono=mono;
                              kwargs...)

    Plots.plot(p)

    return p
end

"""
    plot_psd(signal; <keyword arguments>)

Plot `signal` channel power spectrum density.

# Arguments

- `signal::Vector{<:Real}`
- `fs::Int64`: sampling frequency
- `norm::Bool=true`: normalize powers to dB
- `mw::Bool=false`: if true use Morlet wavelet convolution
- `mt::Bool=false`: if true use multi-tapered periodogram
- `frq_lim::Tuple{Real, Real}=(0, 0)`: x-axis limit
- `ncyc::Union{Int64, Tuple{Int64, Int64}}=6`: number of cycles for Morlet wavelet
- `xlabel::String="Frequency [Hz]"`: x-axis label
- `ylabel::String=""`: y-axis label
- `title::String=""`: plot title
- `mono::Bool=false`: use color or grey palette
- `ax::Symbol=:linlin`: type of axes scaling
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function plot_psd(signal::Vector{<:Real}; fs::Int64, norm::Bool=true, mw::Bool=false, mt::Bool=false, frq_lim::Tuple{Real, Real}=(0, 0), ncyc::Union{Int64, Tuple{Int64, Int64}}=6, xlabel::String="Frequency [Hz]", ylabel::String="", title::String="", mono::Bool=false, ax::Symbol=:linlin, kwargs...)

    (mw == true && mt == true) && throw(ArgumentError("Both mw and mt must not be true."))
    ax in [:linlin, :loglin, :linlog, :loglog] || throw(ArgumentError("ax must be :linlin, :loglin, :linlog or :loglog."))
    frq_lim == (0, 0) && (frq_lim = (0, fs / 2))
    (frq_lim[1] < 0 || frq_lim[2] > fs / 2) && throw(ArgumentError("frq_lim must be ≥ 0 and ≤ $(fs / 2)."))
    frq_lim = tuple_order(frq_lim)

    fs <= 0 && throw(ArgumentError("fs must be > 0."))

    if mw == false
        s_pow, s_frq = s_psd(signal, fs=fs, norm=norm, mt=mt)
    else
        s_pow, s_frq = s_wspectrum(signal, fs=fs, norm=norm, frq_lim=frq_lim, frq_n=length(frq_lim[1]:frq_lim[2]), ncyc=ncyc)
    end

    mono == true ? palette = :grays : palette = :darktest

    ylabel == "" && (norm == true ? ylabel = "Power [dB]" : ylabel = "Power [μV^2/Hz]")

    if ax === :linlin
        p = Plots.plot(s_frq,
                 s_pow,
                 xlabel=xlabel,
                 ylabel=ylabel,
                 xlims=frq_lim,
                 legend=false,
                 t=:line,
                 c=:black,
                 title=title,
                 palette=palette,
                 titlefontsize=8,
                 xlabelfontsize=6,
                 ylabelfontsize=6,
                 xtickfontsize=4,
                 ytickfontsize=4;
                 kwargs...)
    elseif ax === :loglin
        if frq_lim[1] == 0
            frq_lim = (0.1, frq_lim[2])
            @warn "Lower frequency bound truncated to 0.1 Hz"
        end
        s_frq[1] == 0 && (s_frq[1] = 0.1)
        p = Plots.plot(s_frq,
                 s_pow,
                 xaxis=:log10,
                 xticks=([0.1, 1, 10, 100], ["0.1", "1", "10", "100"]),
                 xlabel=xlabel,
                 ylabel=ylabel,
                 xlims=frq_lim,
                 legend=false,
                 t=:line,
                 c=:black,
                 title=title,
                 palette=palette,
                 titlefontsize=8,
                 xlabelfontsize=6,
                 ylabelfontsize=6,
                 xtickfontsize=4,
                 ytickfontsize=4;
                 kwargs...)
    elseif ax === :linlog
        if norm == false
            p = Plots.plot(s_frq,
                     s_pow,
                     yaxis=:log10,
                     xlabel=xlabel,
                     ylabel=ylabel,
                     xlims=frq_lim,
                     legend=false,
                     t=:line,
                     c=:black,
                     title=title,
                     palette=palette,
                     titlefontsize=8,
                     xlabelfontsize=6,
                     ylabelfontsize=6,
                     xtickfontsize=4,
                     ytickfontsize=4;
                     kwargs...)
        else
            p = Plots.plot(s_frq,
                     s_pow,
                     xlabel=xlabel,
                     ylabel=ylabel,
                     xlims=frq_lim,
                     legend=false,
                     t=:line,
                     c=:black,
                     title=title,
                     palette=palette,
                     titlefontsize=8,
                     xlabelfontsize=6,
                     ylabelfontsize=6,
                     xtickfontsize=4,
                     ytickfontsize=4;
                     kwargs...)
        end
    elseif ax === :loglog
        if frq_lim[1] == 0
            frq_lim = (0.1, frq_lim[2])
            @warn "Lower frequency bound truncated to 0.1 Hz"
        end
        s_frq[1] == 0 && (s_frq[1] = 0.1)
        if norm == false
            p = Plots.plot(s_frq,
                     s_pow,
                     xaxis=:log10,
                     yaxis=:log10,
                     xticks=([0.1, 1, 10, 100], ["0.1", "1", "10", "100"]),
                     xlabel=xlabel,
                     ylabel=ylabel,
                     xlims=frq_lim,
                     legend=false,
                     t=:line,
                     c=:black,
                     title=title,
                     palette=palette,
                     titlefontsize=8,
                     xlabelfontsize=6,
                     ylabelfontsize=6,
                     xtickfontsize=4,
                     ytickfontsize=4;
                     kwargs...)
        else
            p = Plots.plot(s_frq,
                     s_pow,
                     xaxis=:log10,
                     xlabel=xlabel,
                     ylabel=ylabel,
                     xlims=frq_lim,
                     legend=false,
                     t=:line,
                     c=:black,
                     title=title,
                     palette=palette,
                     titlefontsize=8,
                     xlabelfontsize=6,
                     ylabelfontsize=6,
                     xtickfontsize=4,
                     ytickfontsize=4;
                     kwargs...)
        end
    end

    return p
end

"""
    plot_psd_avg(signal; <keyword arguments>)

Plot `signal` channels power spectrum density: mean and ±95% CI.

# Arguments

- `signal::Matrix{<:Real}`
- `fs::Int64`: sampling rate
- `norm::Bool=true`: normalize powers to dB
- `mw::Bool=false`: if true use Morlet wavelet convolution
- `mt::Bool=false`: if true use multi-tapered periodogram
- `frq_lim::Tuple{Real, Real}=(0, 0)`: x-axis limit
- `ncyc::Union{Int64, Tuple{Int64, Int64}}=6`: number of cycles for Morlet wavelet
- `labels::Vector{String}=[""]`: channel labels vector
- `xlabel::String="Frequency [Hz]"`: x-axis label
- `ylabel::String=""`: y-axis label
- `title::String=""`: plot title
- `mono::Bool=false`: use color or grey palette
- `ax::Symbol=:linlin`: type of axes scaling
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function plot_psd_avg(signal::Matrix{<:Real}; fs::Int64, norm::Bool=true, mw::Bool=false, mt::Bool=false, frq_lim::Tuple{Real, Real}=(0, 0), ncyc::Union{Int64, Tuple{Int64, Int64}}=6, labels::Vector{String}=[""], xlabel::String="Frequency [Hz]", ylabel::String="", title::String="", mono::Bool=false, ax::Symbol=:linlin, kwargs...)

    (mw == true && mt == true) && throw(ArgumentError("Both mw and mt must not be true."))
    ylabel == "" && (norm == true ? ylabel = "Power [dB]" : ylabel = "Power [μV^2/Hz]")
    ax in [:linlin, :loglin] || throw(ArgumentError("ax must be :linlin or :loglin."))
    mono == true ? palette = :grays : palette = :darktest

    fs <= 0 && throw(ArgumentError("fs must be > 0."))
    s_pow, s_frq = s_psd(signal, fs=fs, norm=norm, mt=mt)
    frq_lim == (0, 0) && (frq_lim = (0, s_frq[end]))
    frq_lim = tuple_order(frq_lim)
    (frq_lim[1] < 0 || frq_lim[2] > s_frq[end]) && throw(ArgumentError("frq_lim must be ≥ 0 and ≤ $(s_frq[end])."))

    norm == true && (ylabel = "Power [dB]")

    channel_n = size(signal, 1)
    signal = reshape(signal, size(signal, 1), size(signal, 2), 1)
    if mw == false
        s_pow, s_frq = s_psd(signal, fs=fs, norm=norm, mt=mt)
    else
        s_pow, s_frq = s_wspectrum(signal, fs=fs, norm=norm, frq_lim=frq_lim, frq_n=length(frq_lim[1]:frq_lim[2]), ncyc=ncyc)
    end
    s_pow = s_pow[:, :, 1]
    s_frq = s_frq[:, :, 1]
    frq_lim == (0, 0) && (frq_lim = (0, s_frq[1, end]))

    s_pow_m, s_pow_s, s_pow_u, s_pow_l = s_msci95(s_pow)
    s_frq = s_frq[1, :]

    # plot channels
    if ax === :linlin
        p = Plots.plot(xlabel=xlabel,
                 ylabel=ylabel,
                 xlims=frq_lim,
                 title=title,
                 palette=palette,
                 titlefontsize=8,
                 xlabelfontsize=6,
                 ylabelfontsize=6,
                 xtickfontsize=4,
                 ytickfontsize=4;
                 kwargs...)
        p = Plots.plot!(s_frq,
                  s_pow_u,
                  fillrange=s_pow_l,
                  fillalpha=0.35,
                  label=false,
                  t=:line,
                  c=:grey,
                  lw=0.5)
        p = Plots.plot!(s_frq,
                  s_pow_l,
                  label=false,
                  t=:line,
                  c=:grey,
                  lw=0.5)
        p = Plots.plot!(s_frq,
                  s_pow_m,
                  label=false,
                  t=:line,
                  c=:black)
    elseif ax === :loglin
        if frq_lim[1] == 0
            frq_lim = (0.1, frq_lim[2])
            @warn "Lower frequency bound truncated to 0.1 Hz"
        end
        s_frq[1] == 0 && (s_frq[1] = 0.1)
        p = Plots.plot(xaxis=:log10,
                 xticks=([0.1, 1, 10, 100], ["0.1", "1", "10", "100"]),
                 xlabel=xlabel,
                 ylabel=ylabel,
                 xlims=frq_lim,
                 title=title,
                 palette=palette,
                 titlefontsize=8,
                 xlabelfontsize=6,
                 ylabelfontsize=6,
                 xtickfontsize=4,
                 ytickfontsize=4;
                 kwargs...)
        p = Plots.plot!(s_frq,
                  s_pow_u,
                  fillrange=s_pow_l,
                  fillalpha=0.35,
                  label=false,
                  t=:line,
                  c=:grey,
                  lw=0.5)
        p = Plots.plot!(s_frq,
                  s_pow_l,
                  label=false,
                  t=:line,
                  c=:grey,
                  lw=0.5)
        p = Plots.plot!(s_frq,
                  s_pow_m,
                  label=false,
                  t=:line,
                  c=:black)
    end

    return p
end

"""
    plot_psd_butterfly(signal; <keyword arguments>)

Butterfly plot of `signal` channels power spectrum density.

# Arguments

- `signal::Matrix{<:Real}`
- `fs::Int64`: sampling rate
- `norm::Bool=true`: normalize powers to dB
- `mw::Bool=false`: if true use Morlet wavelet convolution
- `mt::Bool=false`: if true use multi-tapered periodogram
- `frq_lim::Tuple{Real, Real}=(0, 0)`: x-axis limit
- `ncyc::Union{Int64, Tuple{Int64, Int64}}=6`: number of cycles for Morlet wavelet
- `labels::Vector{String}=[""]`: channel labels vector
- `xlabel::String="Frequency [Hz]"`: x-axis label
- `ylabel::String=""`: y-axis label
- `title::String=""`: plot title
- `mono::Bool=false`: use color or grey palette
- `ax::Symbol=:linlin`: type of axes scaling
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function plot_psd_butterfly(signal::Matrix{<:Real}; fs::Int64, norm::Bool=true, mw::Bool=false, mt::Bool=false, frq_lim::Tuple{Real, Real}=(0, 0), ncyc::Union{Int64, Tuple{Int64, Int64}}=6, labels::Vector{String}=[""], xlabel::String="Frequency [Hz]", ylabel::String="", title::String="", mono::Bool=false, ax::Symbol=:linlin, kwargs...)

    (mw == true && mt == true) && throw(ArgumentError("Both mw and mt must not be true."))
    ylabel == "" && (norm == true ? ylabel = "Power [dB]" : ylabel = "Power [μV^2/Hz]")
    ax in [:linlin, :loglin, :linlog, :loglog] || throw(ArgumentError("ax must be :linlin, :loglin, :linlog or :loglog."))
    mono == true ? palette = :grays : palette = :darktest

    fs <= 0 && throw(ArgumentError("fs must be > 0."))
    s_pow, s_frq = s_psd(signal, fs=fs, norm=norm, mt=mt)
    frq_lim == (0, 0) && (frq_lim = (0, s_frq[end]))
    frq_lim = tuple_order(frq_lim)
    (frq_lim[1] < 0 || frq_lim[2] > s_frq[end]) && throw(ArgumentError("frq_lim must be ≥ 0 and ≤ $(s_frq[end])."))

    norm == true && (ylabel = "Power [dB]")

    channel_n = size(signal, 1)
    signal = reshape(signal, size(signal, 1), size(signal, 2), 1)
    if mw == false
        s_pow, s_frq = s_psd(signal, fs=fs, norm=norm, mt=mt)
    else
        s_pow, s_frq = s_wspectrum(signal, fs=fs, norm=norm, frq_lim=frq_lim, frq_n=length(frq_lim[1]:frq_lim[2]), ncyc=ncyc)
    end
    s_pow = s_pow[:, :, 1]
    s_frq = s_frq[:, :, 1]
    frq_lim == (0, 0) && (frq_lim = (0, s_frq[1, end]))

    if labels == [""]
        labels = Vector{String}(undef, channel_n)
        for idx in 1:channel_n
            labels[idx] = ""
        end
    end

    # plot channels
    if ax === :linlin
        p = Plots.plot(xlabel=xlabel,
                     ylabel=ylabel,
                     xlims=frq_lim,
                     title=title,
                     palette=palette,
                     titlefontsize=8,
                     xlabelfontsize=6,
                     ylabelfontsize=6,
                     xtickfontsize=4,
                     ytickfontsize=4;
                     kwargs...)
            for idx in 1:channel_n
                p = Plots.plot!(s_frq[idx, :],
                          s_pow[idx, :],
                          label=labels[idx],
                          linewidth=0.1,
                          t=:line)
            end
    elseif ax === :loglin
        if frq_lim[1] == 0
            frq_lim = (0.1, frq_lim[2])
            @warn "Lower frequency bound truncated to 0.1 Hz"
        end
        s_frq[:, 1] == zeros(Float64, channel_n) && (s_frq[:, 1] = zeros(channel_n) .+ 0.1)
        p = Plots.plot(xaxis=:log10,
                 xticks=([0.1, 1, 10, 100], ["0.1", "1", "10", "100"]),
                 xlabel=xlabel,
                 ylabel=ylabel,
                 xlims=frq_lim,
                 title=title,
                 palette=palette,
                 titlefontsize=8,
                 xlabelfontsize=6,
                 ylabelfontsize=6,
                 xtickfontsize=4,
                 ytickfontsize=4;
                 kwargs...)
        for idx in 1:channel_n
            p = Plots.plot!(s_frq[idx, :],
                      s_pow[idx, :],
                      label=labels[idx],
                      linewidth=0.1,
                      t=:line)
        end
    elseif ax === :linlog
        if norm == false
            p = Plots.plot(yaxis=:log10,
                     xlabel=xlabel,
                     ylabel=ylabel,
                     xlims=frq_lim,
                     title=title,
                     palette=palette,
                     titlefontsize=8,
                     xlabelfontsize=6,
                     ylabelfontsize=6,
                     xtickfontsize=4,
                     ytickfontsize=4;
                     kwargs...)
            for idx in 1:channel_n
                p = Plots.plot!(s_frq[idx, :],
                          s_pow[idx, :],
                          label=labels[idx],
                          linewidth=0.1,
                          t=:line)
            end
        else
            p = Plots.plot(xlabel=xlabel,
                     ylabel=ylabel,
                     xlims=frq_lim,
                     title=title,
                     palette=palette,
                     titlefontsize=8,
                     xlabelfontsize=6,
                     ylabelfontsize=6,
                     xtickfontsize=4,
                     ytickfontsize=4;
                     kwargs...)
            for idx in 1:channel_n
                p = Plots.plot!(s_frq[idx, :],
                          s_pow[idx, :],
                          label=labels[idx],
                          linewidth=0.1,
                          t=:line)
            end
        end
    elseif ax === :loglog
        if frq_lim[1] == 0
            frq_lim = (0.1, frq_lim[2])
            @warn "Lower frequency bound truncated to 0.1 Hz"
        end
        s_frq[:, 1] == zeros(channel_n) && (s_frq[:, 1] = zeros(channel_n) .+ 0.1)
        if norm == false
            p = Plots.plot(xaxis=:log10,
                     yaxis=:log10,
                     xticks=([0.1, 1, 10, 100], ["0.1", "1", "10", "100"]),
                     xlabel=xlabel,
                     ylabel=ylabel,
                     xlims=frq_lim,
                     title=title,
                     palette=palette,
                     titlefontsize=8,
                     xlabelfontsize=6,
                     ylabelfontsize=6,
                     xtickfontsize=4,
                     ytickfontsize=4;
                     kwargs...)
            for idx in 1:channel_n
                p = Plots.plot!(s_frq[idx, :],
                          s_pow[idx, :],
                          label=labels[idx],
                          linewidth=0.1,
                          t=:line)
            end
        else
            p = Plots.plot(xaxis=:log10,
                     xlabel=xlabel,
                     ylabel=ylabel,
                     xlims=frq_lim,
                     title=title,
                     palette=palette,
                     titlefontsize=8,
                     xlabelfontsize=6,
                     ylabelfontsize=6,
                     xtickfontsize=4,
                     ytickfontsize=4;
                     kwargs...)
            for idx in 1:channel_n
                p = Plots.plot!(s_frq[idx, :],
                          s_pow[idx, :],
                          label=labels[idx],
                          linewidth=0.1,
                          t=:line)
            end
        end
    end

    return p
end

"""
    eeg_plot_signal_psd(eeg; <keyword arguments>)

Plot `eeg` channels power spectrum density.

# Arguments

- `eeg::NeuroJ.EEG`: EEG object
- `epoch::Union{Int64, AbstractRange}=0`: epoch number to display
- `channel::Int64`: channel to display, default is all channels
- `offset::Int64=0`: displayed segment offset in samples
- `len::Int64=0`: displayed segment length in samples, default is 1 epoch or 20 seconds
- `norm::Bool=true`: normalize powers to dB
- `mw::Bool=false`: if true use Morlet wavelet convolution
- `mt::Bool=false`: if true use multi-tapered periodogram
- `frq_lim::Tuple{Real, Real}=(0, 0)`: x-axis limit
- `ncyc::Union{Int64, Tuple{Int64, Int64}}=6`: number of cycles for Morlet wavelet
- `xlabel::String="Frequency [Hz]`: x-axis label
- `ylabel::String=""`: y-axis label
- `title::String=""`: plot title
- `mono::Bool=false`: use color or grey palette
- `ref::Symbol=:abs`: type of PSD reference: :abs absolute power (no reference) or relative to EEG band: :total (total power), :delta, :theta, :alpha, :beta, :beta_high, :gamma, :gamma_1, :gamma_2, :gamma_lower or :gamma_higher 
- `ax::Symbol=:linlin`: type of axes scaling
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_signal_psd(eeg::NeuroJ.EEG; epoch::Union{Int64, AbstractRange}=0, channel::Int64, offset::Int64=0, len::Int64=0, norm::Bool=true, mw::Bool=false, mt::Bool=false, frq_lim::Tuple{Real, Real}=(0, 0), ncyc::Union{Int64, Tuple{Int64, Int64}}=6, xlabel::String="Frequency [Hz]", ylabel::String="", title::String="", mono::Bool=false, ref::Symbol=:abs, ax::Symbol=:linlin, kwargs...)

    (mw == true && mt == true) && throw(ArgumentError("Both mw and mt must not be true."))
    ylabel == "" && (norm == true ? ylabel = "Power [dB]" : ylabel = "Power [μV^2/Hz]")

    eeg_channel_n(eeg, type=:eeg) < eeg_channel_n(eeg, type=:all) && throw(ArgumentError("EEG contains non-eeg channels (e.g. ECG or EMG), remove them before plotting."))

    ref in [:abs, :total, :delta, :theta, :alpha, :beta, :beta_high, :gamma, :gamma_1, :gamma_2, :gamma_lower, :gamma_higher] || throw(ArgumentError("type must be :abs, :total, :delta, :theta, :alpha, :beta, :beta_high, :gamma, :gamma_1, :gamma_2, :gamma_lower or :gamma_higher."))
    ax in [:linlin, :loglin, :linlog, :loglog] || throw(ArgumentError("ax must be :linlin, :loglin, :linlog or :loglog."))

    fs = eeg_sr(eeg)
    frq_lim == (0, 0) && (frq_lim = (0, div(fs, 2)))
    frq_lim = tuple_order(frq_lim)
    (frq_lim[1] < 0 || frq_lim[2] > fs / 2) && throw(ArgumentError("frq_lim must be ≥ 0 and ≤ $(fs / 2)."))

    (epoch != 0 && len != 0) && throw(ArgumentError("Both epoch and len must not be specified."))

    epoch_tmp = epoch
    if epoch != 0
        # convert epochs to offset and len
        typeof(epoch) <: AbstractRange && (epoch = collect(epoch))
        _check_epochs(eeg, epoch)
        length(epoch) > 1 && sort!(epoch)
        len = eeg_epoch_len(eeg) * length(epoch)
        offset = eeg_epoch_len(eeg) * (epoch[1] - 1)
        epoch_tmp = epoch[1]:epoch[end]
        epoch = epoch[1]
    else
        # default length is one epoch or 20 seconds
        len == 0 && (len = _len(eeg, len, 20))
        epoch = floor(Int64, offset / eeg_epoch_len(eeg)) + 1
        epoch_tmp = (floor(Int64, offset / eeg_epoch_len(eeg)) + 1):(ceil(Int64, (offset + len) / eeg_epoch_len(eeg)))
    end

    # set epoch markers if len > epoch_len
    eeg_tmp, _ = _get_epoch_markers(eeg, offset, len)

    labels = eeg_labels(eeg)[channel]

    # get time vector
    if length(epoch) == 1 && offset + len <= eeg_epoch_len(eeg)
        t = eeg.eeg_epochs_time[(1 + offset):(offset + len), epoch]
        t[1] = floor(t[1], digits=2)
        t[end] = ceil(t[end], digits=2)
    else
        t = _get_t(eeg_tmp, offset, len)
    end

    _check_offset_len(eeg_tmp, offset, len)

    signal = eeg_tmp.eeg_signals[channel, (1 + offset):(offset + length(t)), 1]
    labels = eeg_labels(eeg)[channel]

    channel_name = labels
    labels = [""]
    signal = vec(signal)

    t_1, t_s1, t_2, t_s2 = _convert_t(t)

    epoch_tmp = _t2epoch(eeg, offset, len, epoch_tmp)
    epoch_tmp[end] == epoch_tmp[1] && (epoch_tmp = epoch_tmp[1])

    if ref === :abs
        title == "" && (title = "PSD\n[frequency limit: $(frq_lim[1])-$(frq_lim[2]) Hz]\n[channel: $(channel_name), epoch: $epoch_tmp, time window: $t_s1:$t_s2]")
        p = plot_psd(signal,
                     fs=fs,
                     labels=labels,
                     norm=norm,
                     xlabel=xlabel,
                     ylabel=ylabel,
                     title=title,
                     mw=mw,
                     mt=mt,
                     frq_lim=frq_lim,
                     ncyc=ncyc,
                     mono=mono,
                     ax=ax;
                     kwargs...)
    elseif ref === :total
        title == "" && (title = "PSD relative to total power\n[frequency limit: $(frq_lim[1])-$(frq_lim[2]) Hz]\n[channel: $(channel_name), epoch: $epoch_tmp, time window: $t_s1:$t_s2]")
        p = plot_rel_psd(signal,
                         fs=fs,
                         labels=labels,
                         norm=norm,
                         frq_lim=frq_lim,
                         xlabel=xlabel,
                         ylabel=ylabel,
                         title=title,
                         mono=mono,
                         mt=mt,
                         f=nothing,
                         ax=ax;
                         kwargs...)
    else
        title == "" && (title = "PSD relative to $ref power\n[frequency limit: $(frq_lim[1])-$(frq_lim[2]) Hz]\n[channel: $(channel_name), epoch: $epoch_tmp, time window: $t_s1:$t_s2]")
        p = plot_rel_psd(signal,
                         fs=fs,
                         labels=labels,
                         norm=norm,
                         frq_lim=frq_lim,
                         xlabel=xlabel,
                         ylabel=ylabel,
                         title=title,
                         mono=mono,
                         mt=mt,
                         f=eeg_band(eeg, band=ref),
                         ax=ax;
                         kwargs...)
    end
    Plots.plot(p)

    return p
end

"""
    eeg_plot_signal_psd_avg(eeg; <keyword arguments>)

Plot `eeg` channels power spectrum density: mean and ±95% CI.

# Arguments

- `eeg::NeuroJ.EEG`: EEG object
- `epoch::Union{Int64, AbstractRange}=0`: epoch number to display
- `channel::Union{Int64, Vector{Int64}, AbstractRange}=0`: channel to display, default is all channels
- `offset::Int64=0`: displayed segment offset in samples
- `len::Int64=0`: displayed segment length in samples, default is 1 epoch or 20 seconds
- `labels::Vector{String}=[""]`: channel labels vector
- `norm::Bool=true`: normalize powers to dB
- `mw::Bool=false`: if true use Morlet wavelet convolution
- `mt::Bool=false`: if true use multi-tapered periodogram
- `frq_lim::Tuple{Real, Real}=(0, 0)`: x-axis limit
- `ncyc::Union{Int64, Tuple{Int64, Int64}}=6`: number of cycles for Morlet wavelet
- `xlabel::String="Frequency [Hz]`: x-axis label
- `ylabel::String=""`: y-axis label
- `title::String=""`: plot title
- `mono::Bool=false`: use color or grey palette
- `ax::Symbol=:linlin`: type of axes scaling
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_signal_psd_avg(eeg::NeuroJ.EEG; epoch::Union{Int64, AbstractRange}=0, channel::Union{Int64, Vector{Int64}, AbstractRange}=0, offset::Int64=0, len::Int64=0, labels::Vector{String}=[""], norm::Bool=true, mw::Bool=false, mt::Bool=false, frq_lim::Tuple{Real, Real}=(0, 0), ncyc::Union{Int64, Tuple{Int64, Int64}}=6, xlabel::String="Frequency [Hz]", ylabel::String="", title::String="", mono::Bool=false, ax::Symbol=:linlin, kwargs...)

    (mw == true && mt == true) && throw(ArgumentError("Both mw and mt must not be true."))
    ylabel == "" && (norm == true ? ylabel = "Power [dB]" : ylabel = "Power [μV^2/Hz]")
    ax in [:linlin, :loglin] || throw(ArgumentError("ax must be :linlin or :loglin."))
    typeof(channel) == Int64 && channel != 0 && throw(ArgumentError("For eeg_plot_signal_psd() channel must contain ≥ 2 channels."))

    eeg_channel_n(eeg, type=:eeg) < eeg_channel_n(eeg, type=:all) && throw(ArgumentError("EEG contains non-eeg channels (e.g. ECG or EMG), remove them before plotting."))

    fs = eeg_sr(eeg)
    frq_lim == (0, 0) && (frq_lim = (0, div(fs, 2)))
    frq_lim = tuple_order(frq_lim)
    (frq_lim[1] < 0 || frq_lim[2] > fs / 2) && throw(ArgumentError("frq_lim must be ≥ 0 and ≤ $(fs / 2)."))

    (epoch != 0 && len != 0) && throw(ArgumentError("Both epoch and len must not be specified."))

    epoch_tmp = epoch
    if epoch != 0
        # convert epochs to offset and len
        typeof(epoch) <: AbstractRange && (epoch = collect(epoch))
        _check_epochs(eeg, epoch)
        length(epoch) > 1 && sort!(epoch)
        len = eeg_epoch_len(eeg) * length(epoch)
        offset = eeg_epoch_len(eeg) * (epoch[1] - 1)
        epoch_tmp = epoch[1]:epoch[end]
        epoch = epoch[1]
    else
        # default length is one epoch or 20 seconds
        len == 0 && (len = _len(eeg, len, 20))
        epoch = floor(Int64, offset / eeg_epoch_len(eeg)) + 1
        epoch_tmp = (floor(Int64, offset / eeg_epoch_len(eeg)) + 1):(ceil(Int64, (offset + len) / eeg_epoch_len(eeg)))
    end

    # select channels, default is all up to 20 channels
    channel == 0 && (channel = _select_channels(eeg, channel, 20))
    _check_channels(eeg, channel)

    # set epoch markers if len > epoch_len
    eeg_tmp, epoch_markers = _get_epoch_markers(eeg, offset, len)

    labels = eeg_labels(eeg)[channel]

    # get time vector
    if length(epoch) == 1 && offset + len <= eeg_epoch_len(eeg)
        t = eeg.eeg_epochs_time[(1 + offset):(offset + len), epoch]
        t[1] = floor(t[1], digits=2)
        t[end] = ceil(t[end], digits=2)
    else
        t = _get_t(eeg_tmp, offset, len)
    end

    _check_offset_len(eeg_tmp, offset, len)

    signal = eeg_tmp.eeg_signals[channel, (1 + offset):(offset + length(t)), 1]

    channel_name = _channel2channel_name(channel)
    labels = [""]

    t_1, t_s1, t_2, t_s2 = _convert_t(t)

    epoch_tmp = _t2epoch(eeg, offset, len, epoch_tmp)
    epoch_tmp[end] == epoch_tmp[1] && (epoch_tmp = epoch_tmp[1])
    title == "" && (title = "PSD averaged with 95%CI\n[frequency limit: $(frq_lim[1])-$(frq_lim[2]) Hz]\n[channel: $(channel_name), epoch: $epoch_tmp, time window: $t_s1:$t_s2]")

    p = plot_psd_avg(signal,
                     fs=fs,
                     labels=labels,
                     norm=norm,
                     xlabel=xlabel,
                     ylabel=ylabel,
                     title=title,
                     mono=mono,
                     mw=mw,
                     mt=mt,
                     frq_lim=frq_lim,
                     ncyc=ncyc,
                     ax=ax;
                     kwargs...)

    Plots.plot(p)

    return p
end

"""
    eeg_plot_signal_psd_butterfly(eeg; <keyword arguments>)

Plot `eeg` channels power spectrum density: mean and ±95% CI.

# Arguments

- `eeg::NeuroJ.EEG`: EEG object
- `epoch::Union{Int64, AbstractRange}=0`: epoch number to display
- `channel::Union{Int64, Vector{Int64}, AbstractRange}=0`: channel to display, default is all channels
- `offset::Int64=0`: displayed segment offset in samples
- `len::Int64=0`: displayed segment length in samples, default is 1 epoch or 20 seconds
- `labels::Vector{String}=[""]`: channel labels vector
- `norm::Bool=true`: normalize powers to dB
- `mw::Bool=false`: if true use Morlet wavelet convolution
- `mt::Bool=false`: if true use multi-tapered periodogram
- `frq_lim::Tuple{Real, Real}=(0, 0)`: x-axis limit
- `ncyc::Union{Int64, Tuple{Int64, Int64}}=6`: number of cycles for Morlet wavelet
- `xlabel::String="Frequency [Hz]`: x-axis label
- `ylabel::String=""`: y-axis label
- `title::String=""`: plot title
- `mono::Bool=false`: use color or grey palette
- `ax::Symbol=:linlin`: type of axes scaling
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_signal_psd_butterfly(eeg::NeuroJ.EEG; epoch::Union{Int64, AbstractRange}=0, channel::Union{Int64, Vector{Int64}, AbstractRange}=0, offset::Int64=0, len::Int64=0, labels::Vector{String}=[""], norm::Bool=true, mw::Bool=false, mt::Bool=false, frq_lim::Tuple{Real, Real}=(0, 0), ncyc::Union{Int64, Tuple{Int64, Int64}}=6, xlabel::String="Frequency [Hz]", ylabel::String="", title::String="", mono::Bool=false, ax::Symbol=:linlin, kwargs...)

    (mw == true && mt == true) && throw(ArgumentError("Both mw and mt must not be true."))
    ylabel == "" && (norm == true ? ylabel = "Power [dB]" : ylabel = "Power [μV^2/Hz]")
    ax in [:linlin, :loglin, :linlog, :loglog] || throw(ArgumentError("ax must be :linlin, :loglin, :linlog or :loglog."))
    typeof(channel) == Int64 && channel != 0 && throw(ArgumentError("For eeg_plot_signal_psd() channel must contain ≥ 2 channels."))

    eeg_channel_n(eeg, type=:eeg) < eeg_channel_n(eeg, type=:all) && throw(ArgumentError("EEG contains non-eeg channels (e.g. ECG or EMG), remove them before plotting."))

    fs = eeg_sr(eeg)
    frq_lim == (0, 0) && (frq_lim = (0, div(fs, 2)))
    frq_lim = tuple_order(frq_lim)
    (frq_lim[1] < 0 || frq_lim[2] > fs / 2) && throw(ArgumentError("frq_lim must be ≥ 0 and ≤ $(fs / 2)."))

    (epoch != 0 && len != 0) && throw(ArgumentError("Both epoch and len must not be specified."))

    epoch_tmp = epoch
    if epoch != 0
        # convert epochs to offset and len
        typeof(epoch) <: AbstractRange && (epoch = collect(epoch))
        _check_epochs(eeg, epoch)
        length(epoch) > 1 && sort!(epoch)
        len = eeg_epoch_len(eeg) * length(epoch)
        offset = eeg_epoch_len(eeg) * (epoch[1] - 1)
        epoch_tmp = epoch[1]:epoch[end]
        epoch = epoch[1]
    else
        # default length is one epoch or 20 seconds
        len == 0 && (len = _len(eeg, len, 20))
        epoch = floor(Int64, offset / eeg_epoch_len(eeg)) + 1
        epoch_tmp = (floor(Int64, offset / eeg_epoch_len(eeg)) + 1):(ceil(Int64, (offset + len) / eeg_epoch_len(eeg)))
    end

    # select channels, default is all up to 20 channels
    channel == 0 && (channel = _select_channels(eeg, channel, 20))
    _check_channels(eeg, channel)

    # set epoch markers if len > epoch_len
    eeg_tmp, epoch_markers = _get_epoch_markers(eeg, offset, len)

    # get time vector
    if length(epoch) == 1 && offset + len <= eeg_epoch_len(eeg)
        t = eeg.eeg_epochs_time[(1 + offset):(offset + len), epoch]
        t[1] = floor(t[1], digits=2)
        t[end] = ceil(t[end], digits=2)
    else
        t = _get_t(eeg_tmp, offset, len)
    end

    _check_offset_len(eeg_tmp, offset, len)

    signal = eeg_tmp.eeg_signals[channel, (1 + offset):(offset + length(t)), 1]

    channel_name = _channel2channel_name(channel)
    labels = eeg_labels(eeg)[channel]

    t_1, t_s1, t_2, t_s2 = _convert_t(t)

    epoch_tmp = _t2epoch(eeg, offset, len, epoch_tmp)
    epoch_tmp[end] == epoch_tmp[1] && (epoch_tmp = epoch_tmp[1])
    title == "" && (title = "PSD\n[frequency limit: $(frq_lim[1])-$(frq_lim[2]) Hz]\n[channel: $(channel_name), epoch: $epoch_tmp, time window: $t_s1:$t_s2]")

    p = plot_psd_butterfly(signal,
                           fs=fs,
                           labels=labels,
                           norm=norm,
                           xlabel=xlabel,
                           ylabel=ylabel,
                           title=title,
                           mono=mono,
                           mw=mw,
                           mt=mt,
                           frq_lim=frq_lim,
                           ncyc=ncyc,
                           ax=ax;
                           kwargs...)

    Plots.plot(p)

    return p
end

"""
    eeg_plot_component_psd(eeg; <keyword arguments>)

Plot PSD of `eeg` external or embedded component.

# Arguments

- `eeg::NeuroJ.EEG`: EEG object
- `c::Union{Array{Float64, 3}, Symbol}`: values to plot; if symbol, than use embedded component
- `epoch::Int64`: epoch to display
- `channel::Int64`: channel to display
- `norm::Bool=true`: normalize powers to dB
- `mw::Bool=false`: if true use Morlet wavelet convolution
- `mt::Bool=false`: if true use multi-tapered periodogram
- `frq_lim::Tuple{Real, Real}=(0, 0)`: x-axis limit
- `ncyc::Union{Int64, Tuple{Int64, Int64}}=6`: number of cycles for Morlet wavelet
- `xlabel::String="Frequency [Hz]`: x-axis label
- `ylabel::String=""`: y-axis label
- `title::String=""`: plot title
- `mono::Bool=false`: use color or grey palette
- `ax::Symbol=:linlin`: type of axes scaling
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_component_psd(eeg::NeuroJ.EEG; c::Union{Array{Float64, 3}, Symbol}, epoch::Int64, channel::Int64, norm::Bool=true, mw::Bool=false, mt::Bool=false, frq_lim::Tuple{Real, Real}=(0, 0), ncyc::Union{Int64, Tuple{Int64, Int64}}=6, xlabel::String="Frequency [Hz]", ylabel::String="", title::String="", mono::Bool=false, ax::Symbol=:linlin, kwargs...)

    (mw == true && mt == true) && throw(ArgumentError("Both mw and mt must not be true."))
    ylabel == "" && (norm == true ? ylabel = "Power [dB]" : ylabel = "Power [μV^2/Hz]")
    ax in [:linlin, :loglin, :linlog, :loglog] || throw(ArgumentError("ax must be :linlin, :loglin, :linlog or :loglog."))
    typeof(c) == Symbol && (c, _ = _get_component(eeg, c))

    size(c) == size(eeg.eeg_signals) || throw(ArgumentError("Size of c ($(size(c))) does not match size of EEG signal ($(size(eeg.eeg_signals))), use another type of plotting function."))

    _check_epochs(eeg, epoch)
    _check_channels(eeg, channel)

    labels = eeg_labels(eeg)[channel]

    fs = eeg_sr(eeg)
    frq_lim == (0, 0) && (frq_lim = (0, div(fs, 2)))
    frq_lim = tuple_order(frq_lim)
    (frq_lim[1] < 0 || frq_lim[2] > fs / 2) && throw(ArgumentError("frq_lim must be ≥ 0 and ≤ $(fs / 2)."))

    # get time vector
    t = eeg.eeg_epochs_time[:, epoch]
    t_1, t_s1, t_2, t_s2 = _convert_t(t)
    if length(channel) == 1
        channel_name = labels
        labels = [""]
        signal = vec(c)
    else
        channel_name = _channel2channel_name(channel)
    end
    title == "" && (title = "Component PSD\n[frequency limit: $(frq_lim[1])-$(frq_lim[2]) Hz]\n[channel: $(channel_name), epoch: $epoch, time window: $t_s1:$t_s2]")

    c = c[channel, :, epoch]

    p = plot_psd(c,
                 fs=fs,
                 labels=labels,
                 norm=norm,
                 xlabel=xlabel,
                 ylabel=ylabel,
                 title=title,
                 mono=mono,
                 mw=mw,
                 mt=mt,
                 frq_lim=frq_lim,
                 ncyc=ncyc,
                 ax=ax;
                 kwargs...)

    Plots.plot(p)

    return p
end

"""
    eeg_plot_component_psd_avg(eeg; <keyword arguments>)

Plot PSD of `eeg` external or embedded component: mean and ±95% CI.

# Arguments

- `eeg::NeuroJ.EEG`: EEG object
- `c::Union{Array{Float64, 3}, Symbol}`: values to plot; if symbol, than use embedded component
- `epoch::Int64`: epoch to display
- `channel::Union{Int64, Vector{Int64}, AbstractRange}=0`: channels to display, default is all channels
- `norm::Bool=true`: normalize powers to dB
- `mw::Bool=false`: if true use Morlet wavelet convolution
- `mt::Bool=false`: if true use multi-tapered periodogram
- `frq_lim::Tuple{Real, Real}=(0, 0)`: x-axis limit
- `ncyc::Union{Int64, Tuple{Int64, Int64}}=6`: number of cycles for Morlet wavelet
- `xlabel::String="Frequency [Hz]`: x-axis label
- `ylabel::String=""`: y-axis label
- `title::String=""`: plot title
- `mono::Bool=false`: use color or grey palette
- `ax::Symbol=:linlin`: type of axes scaling
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_component_psd_avg(eeg::NeuroJ.EEG; c::Union{Array{Float64, 3}, Symbol}, epoch::Int64, channel::Union{Int64, Vector{Int64}, AbstractRange}=0, norm::Bool=true, mw::Bool=false, mt::Bool=false, frq_lim::Tuple{Real, Real}=(0, 0), ncyc::Union{Int64, Tuple{Int64, Int64}}=6, xlabel::String="Frequency [Hz]", ylabel::String="", title::String="", mono::Bool=false, ax::Symbol=:linlin, kwargs...)

    (mw == true && mt == true) && throw(ArgumentError("Both mw and mt must not be true."))
    ylabel == "" && (norm == true ? ylabel = "Power [dB]" : ylabel = "Power [μV^2/Hz]")
    ax in [:linlin, :loglin] || throw(ArgumentError("ax must be :linlin or :loglin."))
    typeof(c) == Symbol && (c, _ = _get_component(eeg, c))

    size(c) == size(eeg.eeg_signals) || throw(ArgumentError("Size of c ($(size(c))) does not match size of EEG signal ($(size(eeg.eeg_signals))), use another type of plotting function."))

    # select channels, default is all channels
    channel = _select_channels(eeg, channel, 0)
    _check_channels(eeg, channel)

    _check_epochs(eeg, epoch)

    labels = eeg_labels(eeg)[channel]

    # get time vector
    t = eeg.eeg_epochs_time[:, epoch]
    t_1, t_s1, t_2, t_s2 = _convert_t(t)
    if length(channel) == 1
        channel_name = labels
        labels = [""]
        signal = vec(c)
    else
        channel_name = _channel2channel_name(channel)
    end
    title == "" && (title = "Component PSD\n[frequency limit: $(frq_lim[1])-$(frq_lim[2]) Hz]\n[channel: $(channel_name), epoch: $epoch, time window: $t_s1:$t_s2]")

    fs = eeg_sr(eeg)
    c = c[channel, :, epoch]

    p = plot_psd_avg(c,
                     fs=fs,
                     labels=labels,
                     norm=norm,
                     xlabel=xlabel,
                     ylabel=ylabel,
                     title=title,
                     mw=mw,
                     mt=mt,
                     frq_lim=frq_lim,
                     ncyc=ncyc,
                     mono=mono,
                     ax=ax;
                     kwargs...)

    Plots.plot(p)

    return p
end

"""
    eeg_plot_component_psd_butterfly(eeg; <keyword arguments>)

Butterfly plot PSD of `eeg` external or embedded component:.

# Arguments

- `eeg::NeuroJ.EEG`: EEG object
- `c::Union{Array{Float64, 3}, Symbol}`: values to plot; if symbol, than use embedded component
- `epoch::Int64`: epoch to display
- `channel::Union{Int64, Vector{Int64}, AbstractRange}=0`: channels to display, default is all channels
- `norm::Bool=true`: normalize powers to dB
- `mw::Bool=false`: if true use Morlet wavelet convolution
- `mt::Bool=false`: if true use multi-tapered periodogram
- `frq_lim::Tuple{Real, Real}=(0, 0)`: x-axis limit
- `ncyc::Union{Int64, Tuple{Int64, Int64}}=6`: number of cycles for Morlet wavelet
- `xlabel::String="Frequency [Hz]`: x-axis label
- `ylabel::String=""`: y-axis label
- `title::String=""`: plot title
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_component_psd_butterfly(eeg::NeuroJ.EEG; c::Union{Array{Float64, 3}, Symbol}, epoch::Int64, channel::Union{Int64, Vector{Int64}, AbstractRange}=0, norm::Bool=true, mw::Bool=false, mt::Bool=false, frq_lim::Tuple{Real, Real}=(0, 0), ncyc::Union{Int64, Tuple{Int64, Int64}}=6, xlabel::String="Frequency [Hz]", ylabel::String="", title::String="", mono::Bool=false, kwargs...)

    (mw == true && mt == true) && throw(ArgumentError("Both mw and mt must not be true."))
    ylabel == "" && (norm == true ? ylabel = "Power [dB]" : ylabel = "Power [μV^2/Hz]")

    typeof(c) == Symbol && (c, _ = _get_component(eeg, c))

    size(c) == size(eeg.eeg_signals) || throw(ArgumentError("Size of c ($(size(c))) does not match size of EEG signal ($(size(eeg.eeg_signals))), use another type of plotting function."))

    # select channels, default is all channels
    channel = _select_channels(eeg, channel, 0)
    _check_channels(eeg, channel)

    _check_epochs(eeg, epoch)

    labels = eeg_labels(eeg)[channel]

    # get time vector
    t = eeg.eeg_epochs_time[:, epoch]
    t_1, t_s1, t_2, t_s2 = _convert_t(t)
    if length(channel) == 1
        channel_name = labels
        labels = [""]
        signal = vec(c)
    else
        channel_name = _channel2channel_name(channel)
    end
    title == "" && (title = "Component PSD\n[frequency limit: $(frq_lim[1])-$(frq_lim[2]) Hz]\n[channel: $(channel_name), epoch: $epoch, time window: $t_s1:$t_s2]")

    fs = eeg_sr(eeg)
    c = c[channel, :, epoch]

    p = plot_psd_butterfly(c,
                           fs=fs,
                           labels=labels,
                           norm=norm,
                           mw=mw,
                           mt=mt,
                           frq_lim=frq_lim,
                           ncyc=ncyc,
                           xlabel=xlabel,
                           ylabel=ylabel,
                           title=title,
                           mono=mono;
                           kwargs...)

    Plots.plot(p)

    return p
end

"""
    plot_spectrogram(signal; <keyword arguments>)

Plot spectrogram of `signal`.

# Arguments

- `signal::Vector{<:Real}`
- `fs::Int64`: sampling frequency
- `offset::Real`: displayed segment offset in seconds
- `norm::Bool=true`: normalize powers to dB
- `mw::Bool=false`: if true use Morlet wavelet convolution
- `mt::Bool=false`: if true use multi-tapered spectrogram
- `frq_lim::Tuple{Real, Real}=(0, 0)`: y-axis limits
- `ncyc::Union{Int64, Tuple{Int64, Int64}}=6`: number of cycles for Morlet wavelet
- `xlabel::String="Time [s]"`: x-axis label
- `ylabel::String="Frequency [Hz]"`: y-axis label
- `title::String=""`: plot title
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function plot_spectrogram(signal::Vector{<:Real}; fs::Int64, offset::Real=0, norm::Bool=true, mw::Bool=false, mt::Bool=false, frq_lim::Tuple{Real, Real}=(0, 0), ncyc::Union{Int64, Tuple{Int64, Int64}}=6, xlabel="Time [s]", ylabel="Frequency [Hz]", title="", mono::Bool=false, kwargs...)

    (mw == true && mt == true) && throw(ArgumentError("Both mw and mt must not be true."))

    fs < 1 && throw(ArgumentError("fs must be ≥ 1 Hz."))
    frq_lim == (0, 0) && (frq_lim = (0, div(fs, 2)))
    frq_lim = tuple_order(frq_lim)
    (frq_lim[1] < 0 || frq_lim[2] > fs / 2) && throw(ArgumentError("frq_lim must be ≥ 0 and ≤ $(fs / 2)."))

    nfft = length(signal)
    interval = fs
    overlap = round(Int64, fs * 0.85)

    mono == true ? palette = :grays : palette = :darktest

    if mw == false
        if mt == false
            spec = spectrogram(signal, interval, overlap, nfft=nfft, fs=fs, window=hanning)
            spec_power = spec.power
        else
            spec = mt_spectrogram(signal, fs=fs)
            spec_power = spec.power
        end
        norm == true && (spec_power = pow2db.(spec_power))
        spec_frq = spec.freq
        t = collect(spec.time) .+ offset
    else
        _, spec_power, _, spec_frq = s_wspectrogram(signal, fs=fs, frq_lim=frq_lim, frq_n=length(frq_lim[1]:frq_lim[2]), ncyc=ncyc, norm=norm)
        t = linspace(0, size(spec_power, 2)/fs, size(spec_power, 2)) .+ offset
    end

    norm == true ? cb_title = "[dB/Hz]" : cb_title = "[μV^2/Hz]"

    p = Plots.heatmap(t,
                spec_frq,
                spec_power,
                xlabel=xlabel,
                ylabel=ylabel,
                ylims=frq_lim,
                xticks=_xticks(t),
                title=title,
                seriescolor=palette,
                colorbar_title=cb_title,
                titlefontsize=8,
                xlabelfontsize=6,
                ylabelfontsize=6,
                xtickfontsize=4,
                ytickfontsize=4;
                kwargs...)

    return p
end


"""
    eeg_plot_signal_spectrogram(eeg; <keyword arguments>)

Plots spectrogram of `eeg` channel(s).

# Arguments

- `eeg:EEG`
- `epoch::Union{Int64, AbstractRange}=1`: epoch to plot
- `channel::Union{Int64, Vector{Int64}, AbstractRange}`: channel(s) to plot
- `offset::Int64=0`: displayed segment offset in samples
- `len::Int64=0`: displayed segment length in samples, default is 1 epoch or 20 seconds
- `norm::Bool=true`: normalize powers to dB
- `mw::Bool=false`: if true use Morlet wavelet convolution
- `mt::Bool=false`: if true use multi-tapered spectrogram
- `xlabel::String="Time [s]"`: x-axis label
- `ylabel::String=""`: y-axis label
- `title::String=""`: plot title
- `frq_lim::Tuple{Real, Real}=(0, 0)`: y-axis limits
- `ncyc::Union{Int64, Tuple{Int64, Int64}}=6`: number of cycles for Morlet wavelet
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_signal_spectrogram(eeg::NeuroJ.EEG; epoch::Union{Int64, AbstractRange}=0, channel::Union{Int64, Vector{Int64}, AbstractRange}, offset::Int64=0, len::Int64=0, norm::Bool=true, mw::Bool=false, mt::Bool=false, frq_lim::Tuple{Real, Real}=(0, 0), ncyc::Union{Int64, Tuple{Int64, Int64}}=6, xlabel::String="Time [s]", ylabel::String="", title::String="", mono::Bool=false, kwargs...)

    (mw == true && mt == true) && throw(ArgumentError("Both mw and mt must not be true."))

    (epoch != 0 && len != 0) && throw(ArgumentError("Both epoch and len must not be specified."))

    epoch_tmp = epoch
    if epoch != 0
        # convert epochs to offset and len
        typeof(epoch) <: AbstractRange && (epoch = collect(epoch))
        _check_epochs(eeg, epoch)
        length(epoch) > 1 && sort!(epoch)
        len = eeg_epoch_len(eeg) * length(epoch)
        offset = eeg_epoch_len(eeg) * (epoch[1] - 1)
        epoch_tmp = epoch[1]:epoch[end]
        epoch = epoch[1]
    else
        # default length is one epoch or 20 seconds
        len == 0 && (len = _len(eeg, len, 20))
        epoch = floor(Int64, offset / eeg_epoch_len(eeg)) + 1
        epoch_tmp = (floor(Int64, offset / eeg_epoch_len(eeg)) + 1):(ceil(Int64, (offset + len) / eeg_epoch_len(eeg)))
    end

    # select channels, default is all up to 20 channels
    channel == 0 && (channel = _select_channels(eeg, channel, 20))
    _check_channels(eeg, channel)

    # set epoch markers if len > epoch_len
    eeg_tmp, epoch_markers = _get_epoch_markers(eeg, offset, len)

    labels = eeg_labels(eeg)[channel]

    # get time vector
    if length(epoch) == 1 && offset + len <= eeg_epoch_len(eeg)
        t = eeg.eeg_epochs_time[(1 + offset):(offset + len), epoch]
        t[1] = floor(t[1], digits=2)
        t[end] = ceil(t[end], digits=2)
    else
        t = _get_t(eeg_tmp, offset, len)
    end

    _check_offset_len(eeg_tmp, offset, len)

    length(channel) > 1 && len < 4 * eeg_sr(eeg) && throw(ArgumentError("For multi-channel plot, len must be ≥ 4 × EEG sampling rate (4 × $(eeg_sr(eeg)))."))

    fs = eeg_sr(eeg)
    frq_lim == (0, 0) && (frq_lim = (0, div(fs, 2)))
    frq_lim = tuple_order(frq_lim)
    (frq_lim[1] < 0 || frq_lim[2] > fs / 2) && throw(ArgumentError("frq_lim must be ≥ 0 and ≤ $(fs / 2)."))

    signal = eeg_tmp.eeg_signals[channel, (1 + offset):(offset + length(t)), 1]

    if length(channel) == 1
        ylabel = "Frequency [Hz]"
        channel_name = labels
        labels = [""]
        signal = vec(signal)
    else
        channel_name = _channel2channel_name(channel)
    end

    t_1, t_s1, t_2, t_s2 = _convert_t(t)

    epoch_tmp = _t2epoch(eeg, offset, len, epoch_tmp)
    epoch_tmp[end] == epoch_tmp[1] && (epoch_tmp = epoch_tmp[1])
    title == "" && (title = "Spectrogram\n[frequency limit: $(frq_lim[1])-$(frq_lim[2]) Hz]\n[channel: $(channel_name), epoch: $epoch_tmp, time window: $t_s1:$t_s2]")

    offset = eeg.eeg_epochs_time[1]

    if length(channel) == 1
        p = plot_spectrogram(signal,
                             fs=fs,
                             offset=offset,
                             norm=norm,
                             mw=mw,
                             mt=mt,
                             xlabel=xlabel,
                             ylabel=ylabel,
                             frq_lim=frq_lim,
                             ncyc=ncyc,
                             title=title,
                             mono=mono;
                             kwargs...)

        # add epochs markers
        if length(epoch_markers) > 0 && len + offset > eeg_epoch_len(eeg) && eeg_epoch_n(eeg) > 1
            p = vline!(epoch_markers,
                       linestyle=:dash,
                       linewidth=0.2,
                       linecolor=:black,
                       label="")
            for idx in 1:length(epoch_markers)
                p = Plots.plot!(annotation=((epoch_markers[idx] - 1), frq_lim[2], Plots.text("E$(floor(Int64, epoch_markers[idx] / (eeg_epoch_len(eeg) / eeg_sr(eeg))))", pointsize=4, halign=:center, valign=:top)))
            end
        end
    else
        ylabel = "Channel"
        xlabel = "Frequency [Hz]"
        s_pow, s_frq = s_psd(signal, fs=fs, norm=norm, mt=mt)
        norm == true ? cb_title = "[dB/Hz]" : cb_title = "[μV^2/Hz]"
        palette = :darktest
        mono == true && (palette = :grays)
        p = Plots.heatmap(s_frq[1, :],
                    channel,
                    s_pow,
                    xlabel=xlabel,
                    ylabel=ylabel,
                    xlims=frq_lim,
                    yticks=channel,
                    title=title,
                    seriescolor=palette,
                    colorbar_title=cb_title,
                    titlefontsize=8,
                    xlabelfontsize=6,
                    ylabelfontsize=6,
                    xtickfontsize=4,
                    ytickfontsize=4;
                    kwargs...)
    end

    Plots.plot(p)

    return p
end

"""
    eeg_plot_signal_spectrogram_avg(eeg; <keyword arguments>)

Plots spectrogram of `eeg` channel(s).

# Arguments

- `eeg:EEG`
- `epoch::Union{Int64, AbstractRange}=1`: epoch to plot
- `channel::Union{Vector{Int64}, AbstractRange}`: channels to plot
- `offset::Int64=0`: displayed segment offset in samples
- `len::Int64=0`: displayed segment length in samples, default is 1 epoch or 20 seconds
- `norm::Bool=true`: normalize powers to dB
- `mw::Bool=false`: if true use Morlet wavelet convolution
- `mt::Bool=false`: if true use multi-tapered spectrogram
- `xlabel::String="Time [s]"`: x-axis label
- `ylabel::String="Frequency [Hz]"`: y-axis label
- `title::String=""`: plot title
- `frq_lim::Tuple{Real, Real}=(0, 0)`: y-axis limits
- `ncyc::Union{Int64, Tuple{Int64, Int64}}=6`: number of cycles for Morlet wavelet
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_signal_spectrogram_avg(eeg::NeuroJ.EEG; epoch::Union{Int64, AbstractRange}=0, channel::Union{Vector{Int64}, AbstractRange}, offset::Int64=0, len::Int64=0, norm::Bool=true, mw::Bool=false, mt::Bool=false, frq_lim::Tuple{Real, Real}=(0, 0), ncyc::Union{Int64, Tuple{Int64, Int64}}=6, xlabel::String="Time [s]", ylabel::String="Frequency [Hz]", title::String="", mono::Bool=false, kwargs...)

    (mw == true && mt == true) && throw(ArgumentError("Both mw and mt must not be true."))

    length(channel) < 2 && throw(ArgumentError("For eeg_plot_signal_spectrogram_avg() at least  two channels epoch and len must not be specified."))
    _check_channels(eeg, channel)
    (epoch != 0 && len != 0) && throw(ArgumentError("Both epoch and len must not be specified."))

    epoch_tmp = epoch
    if epoch != 0
        # convert epochs to offset and len
        typeof(epoch) <: AbstractRange && (epoch = collect(epoch))
        _check_epochs(eeg, epoch)
        length(epoch) > 1 && sort!(epoch)
        len = eeg_epoch_len(eeg) * length(epoch)
        offset = eeg_epoch_len(eeg) * (epoch[1] - 1)
        epoch_tmp = epoch[1]:epoch[end]
        epoch = epoch[1]
    else
        # default length is one epoch or 20 seconds
        len == 0 && (len = _len(eeg, len, 20))
        epoch = floor(Int64, offset / eeg_epoch_len(eeg)) + 1
        epoch_tmp = (floor(Int64, offset / eeg_epoch_len(eeg)) + 1):(ceil(Int64, (offset + len) / eeg_epoch_len(eeg)))
    end

    # set epoch markers if len > epoch_len
    eeg_tmp, epoch_markers = _get_epoch_markers(eeg, offset, len)

    labels = eeg_labels(eeg)[channel]

    # get time vector
    if length(epoch) == 1 && offset + len <= eeg_epoch_len(eeg)
        t = eeg.eeg_epochs_time[(1 + offset):(offset + len), epoch]
        t[1] = floor(t[1], digits=2)
        t[end] = ceil(t[end], digits=2)
    else
        t = _get_t(eeg_tmp, offset, len)
    end

    _check_offset_len(eeg_tmp, offset, len)

    len < 4 * eeg_sr(eeg) && throw(ArgumentError("For eeg_plot_signal_spectrogram_avg() len must be ≥ 4 × EEG sampling rate (4 × $(eeg_sr(eeg)))."))

    fs = eeg_sr(eeg)
    frq_lim == (0, 0) && (frq_lim = (0, div(fs, 2)))
    frq_lim = tuple_order(frq_lim)
    (frq_lim[1] < 0 || frq_lim[2] > fs / 2) && throw(ArgumentError("frq_lim must be ≥ 0 and ≤ $(fs / 2)."))

    signal = eeg_tmp.eeg_signals[channel, (1 + offset):(offset + length(t)), 1]
    signal = vec(mean(signal, dims=1))

    ylabel == "" && (ylabel = "Amplitude [μV]")
    channel_name = _channel2channel_name(channel)
    t_1, t_s1, t_2, t_s2 = _convert_t(t)
    epoch_tmp = _t2epoch(eeg, offset, len, epoch_tmp)
    epoch_tmp[end] == epoch_tmp[1] && (epoch_tmp = epoch_tmp[1])
    title == "" && (title = "Averaged spectrogram\n[frequency limit: $(frq_lim[1])-$(frq_lim[2]) Hz]\n[channels: $(channel_name), epoch: $epoch_tmp, time window: $t_s1:$t_s2]")

    offset = eeg.eeg_epochs_time[1]

    p = plot_spectrogram(signal,
                         fs=fs,
                         offset=offset,
                         norm=norm,
                         mw=mw,
                         mt=mt,
                         xlabel=xlabel,
                         ylabel=ylabel,
                         frq_lim=frq_lim,
                         ncyc=ncyc,
                         title=title,
                         mono=mono;
                         kwargs...)

    # add epochs markers
    if length(epoch_markers) > 0 && len + offset > eeg_epoch_len(eeg) && eeg_epoch_n(eeg) > 1
        p = vline!(epoch_markers,
                   linestyle=:dash,
                   linewidth=0.2,
                   linecolor=:black,
                   label="")
        for idx in 1:length(epoch_markers)
            p = Plots.plot!(annotation=((epoch_markers[idx] - 1), frq_lim[2], Plots.text("E$(floor(Int64, epoch_markers[idx] / (eeg_epoch_len(eeg) / eeg_sr(eeg))))", pointsize=4, halign=:center, valign=:top)))
        end
    end

    Plots.plot(p)

    return p
end

"""
    eeg_plot_component_spectrogram(eeg; <keyword arguments>)

Plots spectrogram of `eeg` external or embedded component.

# Arguments

- `eeg:EEG`
- `c::Union{Array{Float64, 3}, Symbol}`: values to plot; if symbol, than use embedded component
- `epoch::Int64`: epoch to display
- `channel::Int64`: channel to display
- `norm::Bool=true`: normalize powers to dB
- `mw::Bool=false`: if true use Morlet wavelet convolution
- `mt::Bool=false`: if true use multi-tapered spectrogram
- `frq_lim::Tuple{Real, Real}=(0, 0)`: x-axis limit
- `ncyc::Union{Int64, Tuple{Int64, Int64}}=6`: number of cycles for Morlet wavelet
- `xlabel::String="Frequency [Hz]`: x-axis label
- `ylabel::String=""`: y-axis label
- `title::String=""`: plot title
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_component_spectrogram(eeg::NeuroJ.EEG; c::Union{Array{Float64, 3}, Symbol}, epoch::Int64, channel::Union{Int64, AbstractRange}, norm::Bool=true, mw::Bool=false, mt::Bool=false, frq_lim::Tuple{Real, Real}=(0, 0), ncyc::Union{Int64, Tuple{Int64, Int64}}=6, xlabel::String="Frequency [Hz]", ylabel::String="", title::String="", mono::Bool=false, kwargs...)

    (mw == true && mt == true) && throw(ArgumentError("Both mw and mt must not be true."))

    ylabel == "" && (norm == true ? ylabel = "Power [dB]" : ylabel = "Power [μV^2/Hz]")

    typeof(c) == Symbol && (c, _ = _get_component(eeg, c))

    size(c) == size(eeg.eeg_signals) || throw(ArgumentError("Size of c ($(size(c))) does not match size of EEG signal ($(size(eeg.eeg_signals))), use another type of plotting function."))

    _check_epochs(eeg, epoch)

    # select channels, default is all up to 20 channels
    channel == 0 && (channel = _select_channels(eeg, channel, 20))
    _check_channels(eeg, channel)

    labels = eeg_labels(eeg)[channel]

    # get time vector
    t = eeg.eeg_epochs_time[:, epoch]

    length(channel) > 1 && length(t) < 4 * eeg_sr(eeg) && throw(ArgumentError("For multi-channel plot, len must be ≥ 4 × EEG sampling rate (4 × $(eeg_sr(eeg)))."))

    fs = eeg_sr(eeg)
    frq_lim == (0, 0) && (frq_lim = (0, div(fs, 2)))
    frq_lim = tuple_order(frq_lim)
    (frq_lim[1] < 0 || frq_lim[2] > fs / 2) && throw(ArgumentError("frq_lim must be ≥ 0 and ≤ $(fs / 2)."))

    t_1, t_s1, t_2, t_s2 = _convert_t(t)
    if length(channel) == 1
        channel_name = labels
        labels = [""]
        signal = vec(c)
    else
        channel_name = _channel2channel_name(channel)
    end
    title == "" && (title = "Component spectrogram\n[frequency limit: $(frq_lim[1])-$(frq_lim[2]) Hz]\n[channel: $(channel_name), epoch: $epoch, time window: $t_s1:$t_s2]")

    c = c[channel, :, epoch]
    offset = eeg.eeg_epochs_time[1]

    if length(channel) == 1
        p = plot_spectrogram(c,
                             fs=fs,
                             offset=0,
                             norm=norm,
                             mw=mw,
                             mt=mt,
                             xlabel=xlabel,
                             ylabel=ylabel,
                             frq_lim=frq_lim,
                             ncyc=ncyc,
                             title=title,
                             mono=mono;
                             kwargs...)
    else
        ylabel = "Components"
        xlabel = "Frequency [Hz]"
        s_pow, s_frq = s_psd(c, fs=fs, norm=norm, mt=mt)
        norm == true ? cb_title = "[dB/Hz]" : cb_title = "[μV^2/Hz]"
        palette = :darktest
        mono == true && (palette = :grays)
        p = Plots.heatmap(s_frq[1, :],
                    channel,
                    s_pow,
                    xlabel=xlabel,
                    ylabel=ylabel,
                    xlims=frq_lim,
                    yticks=channel,
                    title=title,
                    seriescolor=palette,
                    colorbar_title=cb_title,
                    titlefontsize=8,
                    xlabelfontsize=6,
                    ylabelfontsize=6,
                    xtickfontsize=4,
                    ytickfontsize=4;
                    kwargs...)
    end

    Plots.plot(p)

    return p
end

"""
    eeg_plot_component_spectrogram_avg(eeg; <keyword arguments>)

Plots spectrogram of `eeg` channel(s).

# Arguments

- `eeg:EEG`
- `c::Union{Array{Float64, 3}, Symbol}`: values to plot; if symbol, than use embedded component
- `epoch::Union{Int64, AbstractRange}=1`: epoch to plot
- `channel::Union{Vector{Int64}, AbstractRange}`: channels to plot
- `offset::Int64=0`: displayed segment offset in samples
- `len::Int64=0`: displayed segment length in samples, default is 1 epoch or 20 seconds
- `norm::Bool=true`: normalize powers to dB
- `mw::Bool=false`: if true use Morlet wavelet convolution
- `mt::Bool=false`: if true use multi-tapered spectrogram
- `xlabel::String="Time [s]"`: x-axis label
- `ylabel::String="Frequency [Hz]"`: y-axis label
- `title::String=""`: plot title
- `frq_lim::Tuple{Real, Real}=(0, 0)`: y-axis limits
- `ncyc::Union{Int64, Tuple{Int64, Int64}}=6`: number of cycles for Morlet wavelet
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_component_spectrogram_avg(eeg::NeuroJ.EEG; c::Union{Array{Float64, 3}, Symbol}, epoch::Union{Int64, AbstractRange}=0, channel::Union{Vector{Int64}, AbstractRange}, offset::Int64=0, len::Int64=0, norm::Bool=true, mw::Bool=false, mt::Bool=false, frq_lim::Tuple{Real, Real}=(0, 0), ncyc::Union{Int64, Tuple{Int64, Int64}}=6, xlabel::String="Time [s]", ylabel::String="Frequency [Hz]", title::String="", mono::Bool=false, kwargs...)

    (mw == true && mt == true) && throw(ArgumentError("Both mw and mt must not be true."))

    typeof(c) == Symbol && (c, _ = _get_component(eeg, c))

    size(c) == size(eeg.eeg_signals) || throw(ArgumentError("Size of c ($(size(c))) does not match size of EEG signal ($(size(eeg.eeg_signals))), use another type of plotting function."))

    length(channel) < 2 && throw(ArgumentError("For eeg_plot_signal_spectrogram_avg() at least  two channels epoch and len must not be specified."))

    (epoch != 0 && len != 0) && throw(ArgumentError("Both epoch and len must not be specified."))

    epoch_tmp = epoch
    if epoch != 0
        # convert epochs to offset and len
        typeof(epoch) <: AbstractRange && (epoch = collect(epoch))
        _check_epochs(eeg, epoch)
        length(epoch) > 1 && sort!(epoch)
        len = eeg_epoch_len(eeg) * length(epoch)
        offset = eeg_epoch_len(eeg) * (epoch[1] - 1)
        epoch_tmp = epoch[1]:epoch[end]
        epoch = epoch[1]
    else
        # default length is one epoch or 20 seconds
        len == 0 && (len = _len(eeg, len, 20))
        epoch = floor(Int64, offset / eeg_epoch_len(eeg)) + 1
        epoch_tmp = (floor(Int64, offset / eeg_epoch_len(eeg)) + 1):(ceil(Int64, (offset + len) / eeg_epoch_len(eeg)))
    end

    # set epoch markers if len > epoch_len
    eeg_tmp, epoch_markers = _get_epoch_markers(eeg, offset, len)

    labels = eeg_labels(eeg)[channel]

    # get time vector
    if length(epoch) == 1 && offset + len <= eeg_epoch_len(eeg)
        t = eeg.eeg_epochs_time[(1 + offset):(offset + len), epoch]
        t[1] = floor(t[1], digits=2)
        t[end] = ceil(t[end], digits=2)
    else
        t = _get_t(eeg_tmp, offset, len)
    end

    _check_offset_len(eeg_tmp, offset, len)

    len < 4 * eeg_sr(eeg) && throw(ArgumentError("For eeg_plot_signal_spectrogram_avg() len must be ≥ 4 × EEG sampling rate (4 × $(eeg_sr(eeg)))."))

    fs = eeg_sr(eeg)
    frq_lim == (0, 0) && (frq_lim = (0, div(fs, 2)))
    frq_lim = tuple_order(frq_lim)
    (frq_lim[1] < 0 || frq_lim[2] > fs / 2) && throw(ArgumentError("frq_lim must be ≥ 0 and ≤ $(fs / 2)."))

    c = c[channel, :, epoch]
    c = vec(mean(c, dims=1))

    ylabel == "" && (ylabel = "Amplitude [μV]")
    channel_name = _channel2channel_name(channel)
    t_1, t_s1, t_2, t_s2 = _convert_t(t)
    epoch_tmp = _t2epoch(eeg, offset, len, epoch_tmp)
    epoch_tmp[end] == epoch_tmp[1] && (epoch_tmp = epoch_tmp[1])
    title == "" && (title = "Averaged component spectrogram\n[frequency limit: $(frq_lim[1])-$(frq_lim[2]) Hz]\n[channels: $(channel_name), epoch: $epoch_tmp, time window: $t_s1:$t_s2]")

    offset = eeg.eeg_epochs_time[1]

    p = plot_spectrogram(c,
                         fs=fs,
                         offset=offset,
                         norm=norm,
                         mw=mw,
                         mt=mt,
                         xlabel=xlabel,
                         ylabel=ylabel,
                         frq_lim=frq_lim,
                         ncyc=ncyc,
                         title=title,
                         mono=mono;
                         kwargs...)

    # add epochs markers
    if length(epoch_markers) > 0 && len + offset > eeg_epoch_len(eeg) && eeg_epoch_n(eeg) > 1
        p = vline!(epoch_markers,
                   linestyle=:dash,
                   linewidth=0.2,
                   linecolor=:black,
                   label="")
        for idx in 1:length(epoch_markers)
            p = Plots.plot!(annotation=((epoch_markers[idx] - 1), frq_lim[2], Plots.text("E$(floor(Int64, epoch_markers[idx] / (eeg_epoch_len(eeg) / eeg_sr(eeg))))", pointsize=4, halign=:center, valign=:top)))
        end
    end

    Plots.plot(p)

    return p
end

"""
    eeg_plot_component_idx_spectrogram(eeg; <keyword arguments>)

Plot spectrogram of indexed `eeg` external or embedded component.

# Arguments

- `eeg::NeuroJ.EEG`: EEG object
- `c::Union{Array{Float64, 3}, Symbol}`: values to plot; if symbol, than use embedded component
- `epoch::Int64`: epoch to display
- `c_idx::Int64`: component index to display, default is all components
- `norm::Bool=true`: normalize powers to dB
- `mw::Bool=false`: if true use Morlet wavelet convolution
- `mt::Bool=false`: if true use multi-tapered spectrogram
- `frq_lim::Tuple{Real, Real}=(0, 0)`: x-axis limit
- `ncyc::Union{Int64, Tuple{Int64, Int64}}=6`: number of cycles for Morlet wavelet
- `xlabel::String="Times [s]`: x-axis label
- `ylabel::String="Frequency [Hz]"`: y-axis label
- `title::String=""`: plot title
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_component_idx_spectrogram(eeg::NeuroJ.EEG; c::Union{Array{Float64, 3}, Symbol}, epoch::Int64, c_idx::Union{Int64, Vector{Int64}, AbstractRange}, norm::Bool=true, mw::Bool=false, mt::Bool=false, frq_lim::Tuple{Real, Real}=(0, 0), ncyc::Union{Int64, Tuple{Int64, Int64}}=6, xlabel::String="Time [s]", ylabel::String="Frequency [Hz]", title::String="", mono::Bool=false, kwargs...)

    (mw == true && mt == true) && throw(ArgumentError("Both mw and mt must not be true."))

    typeof(c) == Symbol && (c, _ = _get_component(eeg, c))

    _check_epochs(eeg, epoch)

    # select components, default is all
    if typeof(c) == Symbol
        c_idx == 0 && (c_idx = _select_cidx(eeg, c, c_idx, 0))
        _check_cidx(eeg, c, c_idx)
    else
        c_idx == 0 && (c_idx = 1:size(c, 1))
        for idx in 1:length(c_idx)
            (c_idx[idx] < 1 || c_idx[idx] > size(c, 1)) && throw(ArgumentError("c_idx must be ≥ 1 and ≤ $(size(c, 1))."))
        end
    end

    fs = eeg_sr(eeg)
    frq_lim == (0, 0) && (frq_lim = (0, div(fs, 2)))
    frq_lim = tuple_order(frq_lim)
    (frq_lim[1] < 0 || frq_lim[2] > fs / 2) && throw(ArgumentError("frq_lim must be ≥ 0 and ≤ $(fs / 2)."))

    labels = Vector{String}()
    for idx in 1:length(c_idx)
        push!(labels, string(c_idx[idx]))
    end

    # get time vector
    t = eeg.eeg_epochs_time[:, epoch]

    t_1, t_s1, t_2, t_s2 = _convert_t(t)
    if length(c_idx) == 1
        labels = [""]
        signal = vec(c)
    end
    title == "" && (title = "Component #$(lpad(string(c_idx), 3, "0")) spectrogram\n[frequency limit: $(frq_lim[1])-$(frq_lim[2]) Hz]\n[epoch: $epoch, time window: $t_s1:$t_s2]")

    c = c[c_idx, :, epoch]

    offset = eeg.eeg_epochs_time[1]

    if length(c_idx) == 1
        p = plot_spectrogram(c,
                             fs=fs,
                             offset=offset,
                             norm=norm,
                             mw=mw,
                             mt=mt,
                             xlabel=xlabel,
                             ylabel=ylabel,
                             frq_lim=frq_lim,
                             ncyc=ncyc,
                             title=title,
                             mono=mono;
                             kwargs...)
    else
        ylabel = "Components"
        xlabel = "Frequency [Hz]"
        s_pow, s_frq = s_psd(c, fs=fs, norm=norm, mt=mt)
        norm == true ? cb_title = "[dB/Hz]" : cb_title = "[μV^2/Hz]"
        palette = :darktest
        mono == true && (palette = :grays)
        p = Plots.heatmap(s_frq[1, :],
                    c_idx,
                    s_pow,
                    xlabel=xlabel,
                    ylabel=ylabel,
                    xlims=frq_lim,
                    yticks=c_idx,
                    title=title,
                    seriescolor=palette,
                    colorbar_title=cb_title,
                    titlefontsize=8,
                    xlabelfontsize=6,
                    ylabelfontsize=6,
                    xtickfontsize=4,
                    ytickfontsize=4;
                    kwargs...)
    end

    Plots.plot(p)

    return p
end

"""
    eeg_plot_component_idx_spectrogram_avg(eeg; <keyword arguments>)

Plot spectrogram of averaged indexed `eeg` external or embedded component.

# Arguments

- `eeg::NeuroJ.EEG`: EEG object
- `c::Union{Array{Float64, 3}, Symbol}`: values to plot; if symbol, than use embedded component
- `epoch::Int64`: epoch to display
- `c_idx::Union{Int64, Vector{Int64}, AbstractRange}=0`: component index to display, default is all components
- `norm::Bool=true`: normalize powers to dB
- `mw::Bool=false`: if true use Morlet wavelet convolution
- `mt::Bool=false`: if true use multi-tapered spectrogram
- `frq_lim::Tuple{Real, Real}=(0, 0)`: x-axis limit
- `ncyc::Union{Int64, Tuple{Int64, Int64}}=6`: number of cycles for Morlet wavelet
- `xlabel::String="Time [s]"`: x-axis label
- `ylabel::String="Frequency [Hz]"`: y-axis label
- `title::String=""`: plot title
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_component_idx_spectrogram_avg(eeg::NeuroJ.EEG; c::Union{Array{Float64, 3}, Symbol}, epoch::Int64, c_idx::Union{Int64, Vector{Int64}, AbstractRange}=0, norm::Bool=true, mw::Bool=false, mt::Bool=false, frq_lim::Tuple{Real, Real}=(0, 0), ncyc::Union{Int64, Tuple{Int64, Int64}}=6, xlabel::String="Time [s]", ylabel::String="Frequency [Hz]", title::String="", mono::Bool=false, kwargs...)

    (mw == true && mt == true) && throw(ArgumentError("Both mw and mt must not be true."))

    typeof(c) == Symbol && (c, _ = _get_component(eeg, c))

    _check_epochs(eeg, epoch)

    # select components, default is all up to 20
    if typeof(c) == Symbol
        c_idx == 0 && (c_idx = _select_cidx(eeg, c, c_idx, 20))
        _check_cidx(eeg, c, c_idx)
    else
        if c_idx == 0
            size(c, 1) > 20 && (c_idx = 1:20)
            size(c, 1) <= 20 && (c_idx = 1:size(c, 1))
        end
        for idx in 1:length(c_idx)
            (c_idx[idx] < 1 || c_idx[idx] > size(c, 1)) && throw(ArgumentError("c_idx must be ≥ 1 and ≤ $(size(c, 1))."))
        end
    end
    length(c_idx) == 1 && throw(ArgumentError("c_idx length must be ≥ 2."))

    fs = eeg_sr(eeg)
    frq_lim == (0, 0) && (frq_lim = (0, div(fs, 2)))
    frq_lim = tuple_order(frq_lim)
    (frq_lim[1] < 0 || frq_lim[2] > fs / 2) && throw(ArgumentError("frq_lim must be ≥ 0 and ≤ $(fs / 2)."))

    labels = Vector{String}()
    for idx in 1:length(c_idx)
        push!(labels, string(c_idx[idx]))
    end

    # get time vector
    t = eeg.eeg_epochs_time[:, epoch]

    t_1, t_s1, t_2, t_s2 = _convert_t(t)
    if length(c_idx) == 1
        labels = [""]
        signal = vec(c)
    end
    title == "" && (title = "Component #$(lpad(string(c_idx), 3, "0")) averaged spectrogram\n[frequency limit: $(frq_lim[1])-$(frq_lim[2]) Hz]\n[epoch: $epoch, time window: $t_s1:$t_s2]")

    c = vec(mean(c[c_idx, :, epoch], dims=1))

    offset = eeg.eeg_epochs_time[1]

    p = plot_spectrogram(c,
                         fs=fs,
                         norm=norm,
                         mw=mw,
                         mt=mt,
                         frq_lim=frq_lim,
                         ncyc=ncyc,
                         xlabel=xlabel,
                         ylabel=ylabel,
                         title=title,
                         mono=mono;
                         kwargs...)

    Plots.plot(p)

    return p
end

"""
    eeg_plot_electrodes(eeg; <keyword arguments>)

Plot `eeg` electrodes.

# Arguments

- `eeg:EEG`
- `channel::Union{Int64, Vector{Int64}, AbstractRange}=0`: channel to display, default is all channels
- `selected::Union{Int64, Vector{Int64}, AbstractRange}=0`: which channel should be highlighted
- `labels::Bool=true`: plot electrode labels
- `head::Bool`=true: plot head
- `head_labels::Bool=false`: plot head labels
- `small::Bool=false`: draws small plot
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_electrodes(eeg::NeuroJ.EEG; channel::Union{Int64, Vector{Int64}, AbstractRange}=0, selected::Union{Int64, Vector{Int64}, AbstractRange}=0, labels::Bool=true, head::Bool=true, head_labels::Bool=false, small::Bool=false, mono::Bool=false, kwargs...)

    eeg.eeg_header[:channel_locations] == false && throw(ArgumentError("Electrode locations not available, use eeg_load_electrodes() first."))
    eeg_channel_n(eeg, type=:eeg) < eeg_channel_n(eeg, type=:all) && throw(ArgumentError("EEG contains non-eeg channels (e.g. ECG or EMG), remove them before plotting."))

    mono == true ? palette = :grays : palette = :darktest

    # select channels, default is all channels
    channel = _select_channels(eeg, channel, 0)
    _check_channels(eeg, channel)

    eeg_tmp = eeg_keep_channel(eeg, channel=channel)
    # selected channels
    if selected != 0
        length(selected) > 1 && sort!(selected)
        for idx in 1:length(selected)
            (selected[idx] < 1 || selected[idx] > eeg_tmp.eeg_header[:channel_n]) && throw(ArgumentError("selected must be ≥ 1 and ≤ $(eeg_tmp.eeg_header[:channel_n])."))
        end
        typeof(selected) <: AbstractRange && (selected = collect(selected))
        length(selected) > 1 && (intersect(selected, channel) == selected || throw(ArgumentError("channel must include selected.")))
        length(selected) == 1 && (intersect(selected, channel) == [selected] || throw(ArgumentError("channel must include selected.")))
    end

    # get axis limits
    loc_x = zeros(eeg_channel_n(eeg_tmp, type=:eeg))
    loc_y = zeros(eeg_channel_n(eeg_tmp, type=:eeg))
    for idx in 1:eeg_channel_n(eeg_tmp, type=:eeg)
        loc_y[idx], loc_x[idx] = pol2cart(eeg_tmp.eeg_header[:loc_radius][idx], 
                                          eeg_tmp.eeg_header[:loc_theta][idx])
    end
    loc_x = round.(loc_x, digits=2)
    loc_y = round.(loc_y, digits=2)
    x_lim = (findmin(loc_x)[1] * 1.8, findmax(loc_x)[1] * 1.8)
    y_lim = (findmin(loc_y)[1] * 1.8, findmax(loc_y)[1] * 1.8)
    
    # get channels positions
    loc_x = zeros(eeg_channel_n(eeg_tmp, type=:eeg))
    loc_y = zeros(eeg_channel_n(eeg_tmp, type=:eeg))
    for idx in 1:eeg_channel_n(eeg_tmp, type=:eeg)
        loc_y[idx], loc_x[idx] = pol2cart(eeg_tmp.eeg_header[:loc_radius][idx], 
                                          eeg_tmp.eeg_header[:loc_theta][idx])
    end
    loc_x = round.(loc_x, digits=2)
    loc_y = round.(loc_y, digits=2)

    if small == true
        plot_size = 200
        marker_size = 2
        labels = false
    else
        plot_size = 400
        marker_size = 4
        font_size = 4
    end

    p = Plots.plot(grid=true,
             framestyle=:none,
             palette=palette,
             size=(plot_size, plot_size),
             markerstrokewidth=0,
             border=:none,
             aspect_ratio=1,
             margins=-plot_size * Plots.px,
             titlefontsize=8;
             kwargs...)
    if selected != 0 && length(selected) == eeg_tmp.eeg_header[:channel_n]
        for idx in 1:eeg_tmp.eeg_header[:channel_n]
            if mono != true
                p = Plots.plot!((loc_x[idx], loc_y[idx]),
                          color=idx,
                          seriestype=:scatter,
                          xlims=x_lim,
                          ylims=x_lim,
                          grid=true,
                          label="",
                          markersize=marker_size,
                          markerstrokewidth=0,
                          markerstrokealpha=0;
                          kwargs...)
            else
                p = Plots.plot!((loc_x[idx], loc_y[idx]),
                          color=:black,
                          seriestype=:scatter,
                          xlims=x_lim,
                          ylims=x_lim,
                          grid=true,
                          label="",
                          markersize=marker_size,
                          markerstrokewidth=0,
                          markerstrokealpha=0;
                          kwargs...)
            end                
        end
    elseif selected == 0
        p = Plots.plot!(loc_x,
                  loc_y,
                  seriestype=:scatter,
                  color=:black,
                  alpha=0.2,
                  xlims=x_lim,
                  ylims=y_lim,
                  grid=true,
                  label="",
                  markersize=marker_size,
                  markerstrokewidth=0,
                  markerstrokealpha=0;
                  kwargs...)
    elseif selected != 0 && length(selected) != eeg_tmp.eeg_header[:channel_n]
        deleteat!(loc_x, selected)
        deleteat!(loc_y, selected)
        p = Plots.plot!(loc_x,
                  loc_y,
                  seriestype=:scatter,
                  color=:black,
                  alpha=0.2,
                  xlims=x_lim,
                  ylims=y_lim,
                  grid=true,
                  label="",
                  markersize=marker_size,
                  markerstrokewidth=0,
                  markerstrokealpha=0;
                  kwargs...)
        eeg_tmp = eeg_keep_channel(eeg, channel=selected)
        loc_x = zeros(eeg_channel_n(eeg_tmp, type=:eeg))
        loc_y = zeros(eeg_channel_n(eeg_tmp, type=:eeg))
        for idx in 1:eeg_channel_n(eeg_tmp, type=:eeg)
            loc_y[idx], loc_x[idx] = pol2cart(eeg_tmp.eeg_header[:loc_radius][idx], 
                                              eeg_tmp.eeg_header[:loc_theta][idx])
        end
        for idx in 1:eeg_tmp.eeg_header[:channel_n]
            if mono != true
                p = Plots.plot!((loc_x[idx], loc_y[idx]),
                          color=idx,
                          seriestype=:scatter,
                          xlims=x_lim,
                          ylims=x_lim,
                          grid=true,
                          label="",
                          markersize=marker_size,
                          markerstrokewidth=0,
                          markerstrokealpha=0;
                          kwargs...)
            else
                p = Plots.plot!((loc_x[idx], loc_y[idx]),
                          color=:black,
                          seriestype=:scatter,
                          xlims=x_lim,
                          ylims=x_lim,
                          grid=true,
                          label="",
                          markersize=marker_size,
                          markerstrokewidth=0,
                          markerstrokealpha=0;
                          kwargs...)
            end
        end
    end
    if labels == true
        for idx in 1:length(eeg_labels(eeg_tmp))
            Plots.plot!(annotation=(loc_x[idx], loc_y[idx] + 0.05, Plots.text(eeg_labels(eeg_tmp)[idx], pointsize=font_size)))
        end
        p = Plots.plot!()
    end
    if head == true
        hd = _draw_head(p, minimum([[loc_x[1]], [loc_y[1]]]), minimum([[loc_x[1]], [loc_y[1]]]), head_labels=false)
        p = Plots.plot!(hd)
    end

    Plots.plot(p)

    return p
end

"""
    eeg_plot_matrix(eeg, m; <keyword arguments>)

Plot matrix `m` of `eeg` channels.

# Arguments

- `eeg:EEG`
- `m::Union{Matrix{<:Real}, Array{Float64, 3}}`: channels by channels matrix
- `epoch::Int64=1`: epoch number to display
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_matrix(eeg::NeuroJ.EEG, m::Union{Matrix{<:Real}, Array{Float64, 3}}; epoch::Int64=1, mono::Bool=false, kwargs...)

    (epoch < 1 || epoch > eeg_epoch_n(eeg)) && throw(ArgumentError("epoch must be ≥ 1 and ≤ $(eeg_epoch_n(eeg))."))
    eeg_channel_n(eeg, type=:eeg) < eeg_channel_n(eeg, type=:all) && throw(ArgumentError("EEG contains non-eeg channels (e.g. ECG or EMG), remove them before plotting."))

    labels = eeg_labels(eeg)
    channel_n = size(m, 1)
    ndims(m) == 3 && (m = m[:, :, epoch])

    mono == true ? palette = :grays : palette = :darktest

    p = Plots.heatmap(m,
                xticks=(1:channel_n, labels),
                yticks=(1:channel_n, eeg_labels(eeg)),
                seriescolor=palette,
                titlefontsize=8,
                xlabelfontsize=6,
                ylabelfontsize=6,
                xtickfontsize=4,
                ytickfontsize=4;
                kwargs...)
    Plots.plot(p)

    return p
end

"""
    eeg_plot_matrix(eeg, cov_m, lags; <keyword arguments>)

Plot covariance matrix `m` of `eeg` channels.

# Arguments

- `eeg:EEG`
- `cov_m::Union{Matrix{<:Real}, Array{Float64, 3}}`: covariance matrix
- `lags::Vector{<:Real}`: covariance lags
- `channel::Union{Int64, Vector{Int64}, AbstractRange, Nothing}`: channel to display
- `epoch::Int64=1`: epoch number to display
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_covmatrix(eeg::NeuroJ.EEG, cov_m::Union{Matrix{<:Real}, Array{Float64, 3}}, lags::Vector{<:Real}; channel::Union{Int64, Vector{Int64}, AbstractRange}=0, epoch::Int64=1, mono::Bool=false, kwargs...)

    (epoch < 1 || epoch > eeg_epoch_n(eeg)) && throw(ArgumentError("epoch must be ≥ 1 and ≤ $(eeg_epoch_n(eeg))."))
    eeg_channel_n(eeg, type=:eeg) < eeg_channel_n(eeg, type=:all) && throw(ArgumentError("EEG contains non-eeg channels (e.g. ECG or EMG), remove them before plotting."))

    mono == true ? palette = :grays : palette = :darktest

    # select channels, default is all channels
    channel = _select_channels(eeg, channel, 0)
    _check_channels(eeg, channel)

    labels = eeg_labels(eeg)
    ndims(cov_m) == 3 && (cov_m = cov_m[:, :, epoch])
    p = []
    for idx in channel
        push!(p,
              Plots.plot(lags,
                   cov_m[idx, :],
                   title="ch: $(labels[idx])",
                   label="",
                   palette=palette,
                   titlefontsize=6,
                   xlabelfontsize=6,
                   ylabelfontsize=6,
                   xtickfontsize=4,
                   ytickfontsize=4,
                   lw=0.5))
    end
    p = Plots.plot(p...; kwargs...)

    return p
end

"""
    plot_histogram(signal; <keyword arguments>)

Plot histogram of `signal`.

# Arguments

- `signal::Vector{<:Real}`
- `type::Symbol`: type of histogram: regular `:hist` or kernel density `:kd`
- `label::String=""`: channel label
- `xlabel::String=""`: x-axis label
- `ylabel::String=""`: y-axis label
- `title::String=""`: plot title
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function plot_histogram(signal::Vector{<:Real}; type::Symbol=:hist, label::String="", xlabel::String="", ylabel::String="", title::String="", mono::Bool=false, kwargs...)

    type in [:hist, :kd] || throw(ArgumentError("type must be :hist or :kd."))

    type === :kd && (type = :density)

    mono == true ? palette = :grays : palette = :darktest

    p = Plots.plot(signal,
             seriestype=type,
             xlabel=xlabel,
             ylabel=ylabel,
             label=label,
             title=title,
             palette=palette,
             grid=false,
             linecolor=:black,
             fillcolor=1,
             linewidth=0.5,
             margins=0Plots.px,
             yticks=false,
             titlefontsize=8,
             xlabelfontsize=6,
             ylabelfontsize=6,
             xtickfontsize=4,
             ytickfontsize=4,
             xticks=[floor(minimum(signal), digits=1), 0, ceil(maximum(signal), digits=1)];
             kwargs...)

    Plots.plot(p)

    return p
end

"""
    plot_histogram(signal; <keyword arguments>)

Plot histogram of `signal`.

# Arguments

- `signal::Matrix{<:Real}`
- `type::Symbol`: type of histogram: :hist or :kd
- `labels::Vector{String}=[""]`
- `xlabel::String=""`: x-axis label
- `ylabel::String=""`: y-axis label
- `title::String=""`: plot title
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function plot_histogram(signal::Matrix{<:Real}; type::Symbol=:hist, labels::Vector{String}=[""], xlabel::String="", ylabel::String="", title::String="", mono::Bool=false, kwargs...)

    channel_n = size(signal, 1)

    mono == true ? palette = :grays : palette = :darktest

    # reverse so 1st channel is on top
    signal = reverse(signal, dims = 1)

    labels == [""] && (labels = repeat([""], channel_n))

    # plot channels
    p = []
    for idx in 1:channel_n
        push!(p, plot_histogram(signal[idx, :],
                                type=type,
                                label="",
                                xlabel=xlabel,
                                ylabel=labels[idx],
                                title=title,
                                linecolor=idx,
                                fillcolor=idx,
                                linewidth=0.5,
                                left_margin=30Plots.px,
                                yticks=true,
                                titlefontsize=8,
                                xlabelfontsize=6,
                                ylabelfontsize=6,
                                xtickfontsize=4,
                                ytickfontsize=4,
                                xticks=[floor(minimum(signal), digits=1), 0, ceil(maximum(signal), digits=1)];
                                kwargs...))
    end

    p = Plots.plot(p...,
             palette=palette,
             layout=(channel_n, 1);
             kwargs...)

    Plots.plot(p)

    return p
end

"""
    eeg_plot_histogram(eeg; <keyword arguments>)

Plot `eeg` channel histograms.

# Arguments

- `eeg::NeuroJ.EEG`: EEG object
- `type::Symbol: type of histogram: :hist or :kd
- `epoch::Int64=1`: epoch number to display
- `channel::Int64`: channel to display
- `offset::Int64=0`: displayed segment offset in samples
- `len::Int64=0`: displayed segment length in samples, default 1 epoch or 20 seconds
- `label::String=""`: channel label
- `xlabel::String=""`: x-axis label
- `ylabel::String=""`: y-axis label
- `title::String=""`: plot title
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_histogram(eeg::NeuroJ.EEG; type::Symbol=:hist, epoch::Int64=1, channel::Int64, offset::Int64=0, len::Int64=0, label::String="", xlabel::String="", ylabel::String="", title::String="", mono::Bool=false, kwargs...)

    offset < 0 && throw(ArgumentError("offset must be ≥ 0."))
    len < 0 && throw(ArgumentError("len must be > 0."))
    (epoch < 1 || epoch > eeg_epoch_n(eeg)) && throw(ArgumentError("epoch must be ≥ 1 and ≤ $(eeg_epoch_n(eeg))."))
    (channel < 1 || channel > eeg_channel_n(eeg)) && throw(ArgumentError("channel must be ≥ 1 and ≤ $(eeg_channel_n(eeg))."))

    # default length is one epoch or 20 seconds
    len = _len(eeg, len, 20)

    # get epochs markers for len > epoch_len
    if len + offset > eeg_epoch_len(eeg) && eeg_epoch_n(eeg) > 1
        eeg_tmp = eeg_epochs(eeg, epoch_n=1)
    else
        eeg_tmp = eeg
    end

    label == "" && (label = eeg_labels(eeg_tmp)[channel])

    (offset < 0 || offset > eeg_epoch_len(eeg_tmp)) && throw(ArgumentError("offset must be > 0 and ≤ $(eeg_epoch_len(eeg_tmp))."))
    (offset + len > eeg_epoch_len(eeg_tmp)) && throw(ArgumentError("offset + len must be ≤ $(eeg_epoch_len(eeg_tmp))."))

    signal = vec(eeg_tmp.eeg_signals[channel, (1 + offset):(offset + len), epoch])

    p = plot_histogram(signal,
                       type=type,
                       labels=label,
                       xlabel=xlabel,
                       ylabel=ylabel,
                       title=title,
                       mono=mono;
                       kwargs...)

    return p
end

"""
    plot_ica(t, ica; <keyword arguments>)

Plot `ica` components against time vector `t`.

# Arguments

- `t::Union{Vector{<:Real}, AbstractRange}`: the time vector
- `ica::Vector{Float64}`
- `label::String=""`: channel label
- `norm::Bool=true`: normalize the `ica` prior to calculations
- `xlabel::String="Time [s]"`: x-axis label
- `ylabel::String="Amplitude [μV]"`: y-axis label
- `title::String=""`: plot title
- `ylim::Tuple{Real, Real}=(0, 0)`: y-axis limits (-ylim:ylim)
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function plot_ica(t::Union{Vector{<:Real}, AbstractRange}, ica::Vector{Float64}; label::String="", norm::Bool=true, xlabel::String="Time [s]", ylabel::String="Amplitude [μV]", title::String="", ylim::Tuple{Real, Real}=(0, 0), mono::Bool=false, kwargs...)

    typeof(t) <: AbstractRange && (t = float(collect(t)))

    mono == true ? palette = :grays : palette = :darktest

    if ylim == (0, 0)
        ylim = (floor(Int64, minimum(ica) * 1.5), ceil(Int64, maximum(ica) * 1.5))
        abs(ylim[1]) > abs(ylim[2]) && (ylim = (ylim[1], abs(ylim[1])))
        abs(ylim[1]) < abs(ylim[2]) && (ylim = (-ylim[2], abs(ylim[2])))
    end

    p = Plots.plot(t,
             ica[1:length(t)],
             xlabel=xlabel,
             ylabel=ylabel,
             label="",
             xlims=_xlims(t),
             xticks=_xticks(t),
             ylims=ylim,
             title=title,
             titlefontsize=8,
             xlabelfontsize=6,
             ylabelfontsize=6,
             xtickfontsize=4,
             ytickfontsize=4,
             palette=palette;
             kwargs...)

    Plots.plot(p)

    return p
end

"""
    eeg_plot_signal_topo(eeg; <keyword arguments>)

Plot topographical view of `eeg` signal.

# Arguments

- `eeg::NeuroJ.EEG`
- `epoch::Union{Int64, AbstractRange}=1`: epochs to display
- `offset::Int64=0`: displayed segment offset in samples
- `len::Int64=0`: displayed segment length in samples, default is 1 second
- `m::Symbol=:shepard`: interpolation method `:shepard` (Shepard), `:mq` (Multiquadratic), `:tp` (ThinPlate)
- `cb::Bool=true`: draw color bar
- `cb_label::String="[A.U.]"`: color bar label
- `title::String=""`: plot title
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_signal_topo(eeg::NeuroJ.EEG; epoch::Union{Int64, AbstractRange}=0, offset::Int64=0, len::Int64=0, m::Symbol=:shepard, cb::Bool=true, cb_label::String="[A.U.]", title::String="", mono::Bool=false, kwargs...)

    eeg_channel_n(eeg, type=:eeg) < eeg_channel_n(eeg, type=:all) && throw(ArgumentError("EEG contains non-eeg channels (e.g. ECG or EMG), remove them before plotting."))

    mono == true ? palette = :grays : palette = :darktest

    m in [:shepard, :mq, :tp] || throw(ArgumentError("m must be :shepard, :mq or :tp."))
    eeg.eeg_header[:channel_locations] == false && throw(ArgumentError("Electrode locations not available, use eeg_load_electrodes() first."))

    (epoch != 0 && len != 0) && throw(ArgumentError("Both epoch and len must not be specified."))

    epoch_tmp = epoch
    if epoch != 0
        # convert epochs to offset and len
        typeof(epoch) <: AbstractRange && (epoch = collect(epoch))
        _check_epochs(eeg, epoch)
        length(epoch) > 1 && sort!(epoch)
        len = eeg_epoch_len(eeg) * length(epoch)
        offset = eeg_epoch_len(eeg) * (epoch[1] - 1)
        epoch_tmp = epoch[1]:epoch[end]
        epoch = epoch[1]
    else
        # default length is one epoch or 20 seconds
        len == 0 && (len = _len(eeg, len, 20))
        epoch = floor(Int64, offset / eeg_epoch_len(eeg)) + 1
        epoch_tmp = (floor(Int64, offset / eeg_epoch_len(eeg)) + 1):(ceil(Int64, (offset + len) / eeg_epoch_len(eeg)))
    end

    # select all channels
    channel = _select_channels(eeg, 0, 0)

    # set epoch markers if len > epoch_len
    eeg_tmp, epoch_markers = _get_epoch_markers(eeg, offset, len)

    labels = eeg_labels(eeg)[channel]

    # get time vector
    if length(epoch) == 1 && offset + len <= eeg_epoch_len(eeg)
        t = eeg.eeg_epochs_time[(1 + offset):(offset + len), epoch]
        t[1] = floor(t[1], digits=2)
        t[end] = ceil(t[end], digits=2)
    else
        t = _get_t(eeg_tmp, offset, len)
    end

    _check_offset_len(eeg_tmp, offset, len)

    signal = eeg_tmp.eeg_signals[channel, (1 + offset):(offset + length(t)), 1]
    s_non_interpolated = mean(signal, dims=2)

    t_1, t_s1, t_2, t_s2 = _convert_t(t)

    epoch_tmp = _t2epoch(eeg, offset, len, epoch_tmp)
    epoch_tmp[end] == epoch_tmp[1] && (epoch_tmp = epoch_tmp[1])
    (title == "" && len > 1) && (title = "Averaged amplitude\n[epoch: $epoch_tmp, time window: $t_s1:$t_s2]")
    (title == "" && len == 1) && (title = "Amplitude\n[epoch: $epoch_tmp, time: $t_s1]")

    # plot signal at electrodes at time
    loc_x = zeros(eeg_channel_n(eeg))
    loc_y = zeros(eeg_channel_n(eeg))
    for idx in 1:eeg_channel_n(eeg)
        loc_y[idx], loc_x[idx] = pol2cart(eeg.eeg_header[:loc_radius][idx], 
                                          eeg.eeg_header[:loc_theta][idx])
    end
    loc_x = round.(loc_x, digits=2)
    loc_y = round.(loc_y, digits=2)
    x_lim = (findmin(loc_x)[1] * 1.8, findmax(loc_x)[1] * 1.8)
    y_lim = (findmin(loc_y)[1] * 1.8, findmax(loc_y)[1] * 1.8)

    # interpolate
    x_lim_int = (findmin(loc_x)[1] * 1.4, findmax(loc_x)[1] * 1.4)
    y_lim_int = (findmin(loc_y)[1] * 1.4, findmax(loc_y)[1] * 1.4)
    interpolation_factor = 100
    interpolated_x = linspace(x_lim_int[1], x_lim_int[2], interpolation_factor)
    interpolated_y = linspace(y_lim_int[1], y_lim_int[2], interpolation_factor)
    interpolated_x = round.(interpolated_x, digits=2)
    interpolated_y = round.(interpolated_y, digits=2)
    interpolation_m = Matrix{Tuple{Float64, Float64}}(undef, interpolation_factor, interpolation_factor)
    @inbounds @simd for idx1 in 1:interpolation_factor
        for idx2 in 1:interpolation_factor
            interpolation_m[idx1, idx2] = (interpolated_x[idx1], interpolated_y[idx2])
        end
    end
    s_interpolated = zeros(interpolation_factor, interpolation_factor)
    electrode_locations = [loc_x loc_y]'
    m === :shepard && (itp = ScatteredInterpolation.interpolate(Shepard(), electrode_locations, s_non_interpolated))
    m === :mq && (itp = ScatteredInterpolation.interpolate(Multiquadratic(), electrode_locations, s_non_interpolated))
    m === :tp && (itp = ScatteredInterpolation.interpolate(ThinPlate(), electrode_locations, s_non_interpolated))
    @inbounds @simd for idx1 in 1:interpolation_factor
        for idx2 in 1:interpolation_factor
            s_interpolated[idx1, idx2] = ScatteredInterpolation.evaluate(itp, [interpolation_m[idx1, idx2][1]; interpolation_m[idx1, idx2][2]])[1]
        end
    end

    s_interpolated = s_normalize_minmax(s_interpolated)

    p = Plots.plot(grid=false,
             framestyle=:none,
             border=:none,
             margins=0Plots.px,
             aspect_ratio=1,
             titlefontsize=8,
             xlabelfontsize=6,
             ylabelfontsize=6,
             xtickfontsize=4,
             ytickfontsize=4,
             title=title,
             palette=palette;
             kwargs...)
    p = Plots.plot!(interpolated_x,
              interpolated_y,
              s_interpolated,
              fill=:darktest,
              seriestype=:heatmap,
              seriescolor=palette,
              colorbar=cb,
              colorbar_title=cb_label,
              clims=(-1, 1),
              levels=10,
              linewidth=0)
    p = Plots.plot!(interpolated_x,
              interpolated_y,
              s_interpolated,
              fill=:darktest,
              seriestype=:contour,
              seriescolor=palette,
              colorbar=cb,
              colorbar_title=cb_label,
              clims=(-1, 1),
              levels=5,
              linecolor=:black,
              linewidth=0.5)
    p = Plots.plot!((loc_x, loc_y),
              color=:black,
              seriestype=:scatter,
              xlims=x_lim,
              ylims=x_lim,
              grid=true,
              label="",
              markersize=2,
              markerstrokewidth=0,
              markerstrokealpha=0)
    # draw head
    pts = Plots.partialcircle(0, 2π, 100, maximum(loc_x))
    x, y = Plots.unzip(pts)
    x = x .* 1.2
    y = y .* 1.2
    head = Shape(x, y)
    nose = Shape([(-0.05, maximum(y)), (0, maximum(y) + 0.1 * maximum(y)), (0.05, maximum(y))])
    ear_l = Shape([(minimum(x), -0.1), (minimum(x) + 0.05 * minimum(x), -0.1), (minimum(x) + 0.05 * minimum(x), 0.1), (minimum(x), 0.1)])
    ear_r = Shape([(maximum(x), -0.1), (maximum(x) + 0.05 * maximum(x), -0.1), (maximum(x) + 0.05 * maximum(x), 0.1), (maximum(x), 0.1)])
    for idx = 0:0.001:1
        peripheral = Shape(x .* (1 + idx), y .* (1 + idx))
        p = Plots.plot!(p, peripheral, fill=nothing, label="", linecolor=:white, linewidth=1)
    end
    p = Plots.plot!(p, head, fill=nothing, label="", linewidth=1)
    p = Plots.plot!(p, nose, fill=nothing, label="", linewidth=1)
    p = Plots.plot!(p, ear_l, fill=nothing, label="", linewidth=1)
    p = Plots.plot!(p, ear_r, fill=nothing, label="", linewidth=1)
    p = Plots.plot!(p, xlims=(x_lim_int), ylims=(y_lim_int))

    Plots.plot(p)

    return p
end

"""
    eeg_plot_acomponent_topo(eeg; <keyword arguments>)

Plot topographical view of `eeg` external or embedded component (array type: many values per channel per epoch).

# Arguments

- `eeg::NeuroJ.EEG`
- `c::Union{Array{<:Real, 3}, Symbol}`: values to plot; if symbol, than use embedded component
- `epoch::Int64`: epoch to display
- `offset::Int64=0`: displayed segment offset in samples
- `len::Int64=0`: displayed segment length in samples, default is 1 second
- `m::Symbol=:shepard`: interpolation method `:shepard` (Shepard), `:mq` (Multiquadratic), `:tp` (ThinPlate)
- `cb_label::String="[A.U.]"`: color bar label
- `title::String=""`: plot title
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_acomponent_topo(eeg::NeuroJ.EEG; epoch::Int64, c::Union{Array{<:Real, 3}, Symbol}, offset::Int64=0, len::Int64=0, m::Symbol=:shepard, cb_label::String="[A.U.]", title::String="", mono::Bool=false, kwargs...)

    eeg_channel_n(eeg, type=:eeg) < eeg_channel_n(eeg, type=:all) && throw(ArgumentError("EEG contains non-eeg channels (e.g. ECG or EMG), remove them before plotting."))

    mono == true ? palette = :grays : palette = :darktest

    m in [:shepard, :mq, :tp] || throw(ArgumentError("m must be :shepard, :mq or :tp."))
    eeg.eeg_header[:channel_locations] == false && throw(ArgumentError("Electrode locations not available, use eeg_load_electrodes() first."))

    typeof(c) == Symbol && (c, _ = _get_component(eeg, c))
    typeof(c) <: Array{<:Real, 3} || throw(ArgumentError("c type must be an array."))
    size(c) == size(eeg.eeg_signals) || throw(ArgumentError("Size of c ($(size(c))) does not match size of EEG signal ($(size(eeg.eeg_signals))), use another type of plotting function."))

    _check_epochs(eeg, epoch)

    offset < 0 && throw(ArgumentError("offset must be ≥ 0."))
    offset + len > eeg_epoch_len(eeg) && throw(ArgumentError("offset + len must be ≤ ($(eeg_epoch_len(eeg)))."))

    len == 0 && (len = eeg_epoch_len(eeg))

    # get time vector
    t = eeg.eeg_epochs_time[(1 + offset):(offset + len), epoch]

    t_1, t_s1, t_2, t_s2 = _convert_t(t)

    s_non_interpolated = c[:, (1 + offset):(offset + len), epoch]
    len > 1 && (s_non_interpolated = mean(s_non_interpolated, dims=2))

    (title == "" && len > 1) && (title = "Component averaged value\n[epoch: $epoch, time window: $t_s1:$t_s2]")
    (title == "" && len == 1) && (title = "Component value\n[epoch: $epoch, time: $t_s1]")

    # plot signal at electrodes at time
    loc_x = zeros(eeg_channel_n(eeg))
    loc_y = zeros(eeg_channel_n(eeg))
    for idx in 1:eeg_channel_n(eeg)
        loc_y[idx], loc_x[idx] = pol2cart(eeg.eeg_header[:loc_radius][idx], 
                                          eeg.eeg_header[:loc_theta][idx])
    end
    loc_x = round.(loc_x, digits=2)
    loc_y = round.(loc_y, digits=2)
    x_lim = (findmin(loc_x)[1] * 1.8, findmax(loc_x)[1] * 1.8)
    y_lim = (findmin(loc_y)[1] * 1.8, findmax(loc_y)[1] * 1.8)

    # interpolate
    x_lim_int = (findmin(loc_x)[1] * 1.4, findmax(loc_x)[1] * 1.4)
    y_lim_int = (findmin(loc_y)[1] * 1.4, findmax(loc_y)[1] * 1.4)
    interpolation_factor = 100
    interpolated_x = linspace(x_lim_int[1], x_lim_int[2], interpolation_factor)
    interpolated_y = linspace(y_lim_int[1], y_lim_int[2], interpolation_factor)
    interpolated_x = round.(interpolated_x, digits=2)
    interpolated_y = round.(interpolated_y, digits=2)
    interpolation_m = Matrix{Tuple{Float64, Float64}}(undef, interpolation_factor, interpolation_factor)
    @inbounds @simd for idx1 in 1:interpolation_factor
        for idx2 in 1:interpolation_factor
            interpolation_m[idx1, idx2] = (interpolated_x[idx1], interpolated_y[idx2])
        end
    end
    s_interpolated = zeros(interpolation_factor, interpolation_factor)
    electrode_locations = [loc_x loc_y]'
    m === :shepard && (itp = ScatteredInterpolation.interpolate(Shepard(), electrode_locations, s_non_interpolated))
    m === :mq && (itp = ScatteredInterpolation.interpolate(Multiquadratic(), electrode_locations, s_non_interpolated))
    m === :tp && (itp = ScatteredInterpolation.interpolate(ThinPlate(), electrode_locations, s_non_interpolated))
    @inbounds @simd for idx1 in 1:interpolation_factor
        for idx2 in 1:interpolation_factor
            s_interpolated[idx1, idx2] = ScatteredInterpolation.evaluate(itp, [interpolation_m[idx1, idx2][1]; interpolation_m[idx1, idx2][2]])[1]
        end
    end

    s_interpolated = s_normalize_minmax(s_interpolated)

    p = Plots.plot(grid=false,
             framestyle=:none,
             border=:none,
             margins=0Plots.px,
             aspect_ratio=1,
             titlefontsize=8,
             xlabelfontsize=6,
             ylabelfontsize=6,
             xtickfontsize=4,
             ytickfontsize=4,
             title=title,
             palette=palette;
             kwargs...)
    p = Plots.plot!(interpolated_x,
              interpolated_y,
              s_interpolated,
              fill=:darktest,
              seriestype=:heatmap,
              seriescolor=palette,
              colorbar_title=cb_label,
              clims=(-1, 1),
              levels=10,
              linewidth=0)
    p = Plots.plot!(interpolated_x,
              interpolated_y,
              s_interpolated,
              fill=:darktest,
              seriestype=:contour,
              seriescolor=palette,
              colorbar_title=cb_label,
              clims=(-1, 1),
              levels=5,
              linecolor=:black,
              linewidth=0.5)
    p = Plots.plot!((loc_x, loc_y),
              color=:black,
              seriestype=:scatter,
              xlims=x_lim,
              ylims=x_lim,
              grid=true,
              label="",
              markersize=2,
              markerstrokewidth=0,
              markerstrokealpha=0)
    # draw head
    pts = Plots.partialcircle(0, 2π, 100, maximum(loc_x))
    x, y = Plots.unzip(pts)
    x = x .* 1.2
    y = y .* 1.2
    head = Shape(x, y)
    nose = Shape([(-0.05, maximum(y)), (0, maximum(y) + 0.1 * maximum(y)), (0.05, maximum(y))])
    ear_l = Shape([(minimum(x), -0.1), (minimum(x) + 0.05 * minimum(x), -0.1), (minimum(x) + 0.05 * minimum(x), 0.1), (minimum(x), 0.1)])
    ear_r = Shape([(maximum(x), -0.1), (maximum(x) + 0.05 * maximum(x), -0.1), (maximum(x) + 0.05 * maximum(x), 0.1), (maximum(x), 0.1)])
    for idx = 0:0.001:1
        peripheral = Shape(x .* (1 + idx), y .* (1 + idx))
        p = Plots.plot!(p, peripheral, fill=nothing, label="", linecolor=:white, linewidth=1)
    end
    p = Plots.plot!(p, head, fill=nothing, label="", linewidth=1)
    p = Plots.plot!(p, nose, fill=nothing, label="", linewidth=1)
    p = Plots.plot!(p, ear_l, fill=nothing, label="", linewidth=1)
    p = Plots.plot!(p, ear_r, fill=nothing, label="", linewidth=1)
    p = Plots.plot!(p, xlims=(x_lim_int), ylims=(y_lim_int))

    Plots.plot(p)

    return p
end

"""
    eeg_plot_weights_topo(eeg; <keyword arguments>)

Topographical plot `eeg` of weights values at electrodes locations.

# Arguments

- `eeg:EEG`
- `epoch::Int64`: epoch to display
- `channel::Union{Int64, Vector{Int64}, AbstractRange}=0`: channel to display, default is all channels
- `weights=Matrix{<:Real}`: weights to plot
- `head::Bool`=true: plot head
- `small::Bool=false`: draws small plot
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_weights_topo(eeg::NeuroJ.EEG; epoch::Int64, weights=Matrix{<:Real}, head::Bool=true, head_labels::Bool=false, small::Bool=false, mono::Bool=false, kwargs...)

    eeg.eeg_header[:channel_locations] == false && throw(ArgumentError("Electrode locations not available, use eeg_load_electrodes() first."))
    eeg_channel_n(eeg, type=:eeg) < eeg_channel_n(eeg, type=:all) && throw(ArgumentError("EEG contains non-eeg channels (e.g. ECG or EMG), remove them before plotting."))

    mono == true ? palette = :grays : palette = :darktest

    # select all channels
    channel = _select_channels(eeg, 0, 0)

    _check_epochs(eeg, epoch)
    size(weights, 1) == eeg_channel_n(eeg) || throw(ArgumentError("Number of weights rows ($(size(weights, 1))) must be equal to number of channels ($(eeg_channel_n(eeg)))."))
    size(weights, 2) == eeg_epoch_n(eeg) || throw(ArgumentError("Number of weights columns ($(size(weights, 2))) must be equal to number of epochs ($(eeg_epoch_n(eeg)))."))
    weights = weights[:, epoch]

    # look for location data
    loc_x = zeros(eeg_channel_n(eeg, type=:eeg))
    loc_y = zeros(eeg_channel_n(eeg, type=:eeg))
    for idx in 1:eeg_channel_n(eeg, type=:eeg)
        loc_y[idx], loc_x[idx] = pol2cart(eeg.eeg_header[:loc_radius][idx], 
                                          eeg.eeg_header[:loc_theta][idx])
    end
    loc_x = round.(loc_x, digits=2)
    loc_y = round.(loc_y, digits=2)
    x_lim = (findmin(loc_x)[1] * 1.8, findmax(loc_x)[1] * 1.8)
    y_lim = (findmin(loc_y)[1] * 1.8, findmax(loc_y)[1] * 1.8)

    if small == true
        plot_size = (400, 400)
        marker_size = 4
        font_size = 4
    else
        plot_size = (800, 800)
        marker_size = 6
        font_size = 6
    end

    p = Plots.plot(grid=true,
             framestyle=:none,
             palette=palette,
             size=plot_size,
             markerstrokewidth=0,
             border=:none,
             aspect_ratio=1,
             margins=-20Plots.px,
             titlefontsize=8;
             kwargs...)
    for idx in 1:eeg.eeg_header[:channel_n]
        p = Plots.plot!((loc_x[idx], loc_y[idx]),
                  color=idx,
                  seriestype=:scatter,
                  xlims=x_lim,
                  ylims=x_lim,
                  grid=true,
                  label="",
                  markersize=marker_size,
                  markerstrokewidth=0,
                  markerstrokealpha=0;
                  kwargs...)
    end

    for idx in channel
        p = Plots.plot!(annotation=(loc_x[idx], loc_y[idx] + 0.05, Plots.text(weights[idx], pointsize=font_size)))
    end

    if head == true
        # for some reason head is enlarged for channel > 1
        eeg = eeg_keep_channel(eeg, channel=1)
        loc_x = zeros(eeg_channel_n(eeg, type=:eeg))
        loc_y = zeros(eeg_channel_n(eeg, type=:eeg))
        for idx in 1:eeg_channel_n(eeg, type=:eeg)
            loc_y[idx], loc_x[idx] = pol2cart(eeg.eeg_header[:loc_radius][idx], 
                                              eeg.eeg_header[:loc_theta][idx])
        end
        hd = _draw_head(p, loc_x, loc_x, head_labels=head_labels)
        Plots.plot!(hd)
    end

    Plots.plot(p)

    return p
end

"""
    eeg_plot_mcomponent_topo(eeg; <keyword arguments>)

Plot topographical view of `eeg` external or embedded component (matrix type: 1 value per channel per epoch).

# Arguments

- `eeg::NeuroJ.EEG`
- `epoch::Int64`: epoch to display
- `c::Union{Matrix{<:Real}, Symbol}`: values to plot; if symbol, than use embedded component
- `m::Symbol=:shepard`: interpolation method `:shepard` (Shepard), `:mq` (Multiquadratic), `:tp` (ThinPlate)
- `cb::Bool=false`: draw color bar
- `cb_label::String="[A.U.]"`: color bar label
- `title::String=""`: plot title
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_mcomponent_topo(eeg::NeuroJ.EEG; epoch::Int64, c::Union{Matrix{<:Real}, Symbol}, m::Symbol=:shepard, cb::Bool=true, cb_label::String="[A.U.]", title::String="", mono::Bool=false, kwargs...)

    eeg_channel_n(eeg, type=:eeg) < eeg_channel_n(eeg, type=:all) && throw(ArgumentError("EEG contains non-eeg channels (e.g. ECG or EMG), remove them before plotting."))

    mono == true ? palette = :grays : palette = :darktest

    m in [:shepard, :mq, :tp] || throw(ArgumentError("m must be :shepard, :mq or :tp."))
    eeg.eeg_header[:channel_locations] == false && throw(ArgumentError("Electrode locations not available, use eeg_load_electrodes() first."))

    typeof(c) == Symbol && (c, _ = _get_component(eeg, c))

    _check_epochs(eeg, epoch)
    typeof(c) <: Matrix{<:Real} || throw(ArgumentError("c type must be a matrix."))
    size(c, 1) == eeg_channel_n(eeg) || throw(ArgumentError("Number of c rows ($(size(c, 1))) must be equal to number of channels ($(eeg_channel_n(eeg)))."))
    size(c, 2) == eeg_epoch_n(eeg) || throw(ArgumentError("Number of c columns ($(size(c, 2))) must be equal to number of epochs ($(eeg_epoch_n(eeg)))."))
    c = c[:, epoch]

    title == "" && (title = "Component value\n[epoch: $epoch]")

    # plot signal at electrodes at time
    loc_x = zeros(eeg_channel_n(eeg))
    loc_y = zeros(eeg_channel_n(eeg))
    for idx in 1:eeg_channel_n(eeg)
        loc_y[idx], loc_x[idx] = pol2cart(eeg.eeg_header[:loc_radius][idx], 
                                          eeg.eeg_header[:loc_theta][idx])
    end
    loc_x = round.(loc_x, digits=2)
    loc_y = round.(loc_y, digits=2)
    x_lim = (findmin(loc_x)[1] * 1.8, findmax(loc_x)[1] * 1.8)
    y_lim = (findmin(loc_y)[1] * 1.8, findmax(loc_y)[1] * 1.8)

    # interpolate
    x_lim_int = (findmin(loc_x)[1] * 1.4, findmax(loc_x)[1] * 1.4)
    y_lim_int = (findmin(loc_y)[1] * 1.4, findmax(loc_y)[1] * 1.4)
    interpolation_factor = 100
    interpolated_x = linspace(x_lim_int[1], x_lim_int[2], interpolation_factor)
    interpolated_y = linspace(y_lim_int[1], y_lim_int[2], interpolation_factor)
    interpolated_x = round.(interpolated_x, digits=2)
    interpolated_y = round.(interpolated_y, digits=2)
    interpolation_m = Matrix{Tuple{Float64, Float64}}(undef, interpolation_factor, interpolation_factor)
    @inbounds @simd for idx1 in 1:interpolation_factor
        for idx2 in 1:interpolation_factor
            interpolation_m[idx1, idx2] = (interpolated_x[idx1], interpolated_y[idx2])
        end
    end
    s_interpolated = zeros(interpolation_factor, interpolation_factor)
    electrode_locations = [loc_x loc_y]'
    m === :shepard && (itp = ScatteredInterpolation.interpolate(Shepard(), electrode_locations, c))
    m === :mq && (itp = ScatteredInterpolation.interpolate(Multiquadratic(), electrode_locations, c))
    m === :tp && (itp = ScatteredInterpolation.interpolate(ThinPlate(), electrode_locations, c))
    @inbounds @simd for idx1 in 1:interpolation_factor
        for idx2 in 1:interpolation_factor
            s_interpolated[idx1, idx2] = ScatteredInterpolation.evaluate(itp, [interpolation_m[idx1, idx2][1]; interpolation_m[idx1, idx2][2]])[1]
        end
    end

    s_interpolated = s_normalize_minmax(s_interpolated)

    p = Plots.plot(grid=false,
             framestyle=:none,
             border=:none,
             margins=0Plots.px,
             aspect_ratio=1,
             titlefontsize=8,
             xlabelfontsize=6,
             ylabelfontsize=6,
             xtickfontsize=4,
             ytickfontsize=4,
             title=title,
             palette=palette;
             kwargs...)
    p = Plots.plot!(interpolated_x,
              interpolated_y,
              s_interpolated,
              fill=:darktest,
              seriestype=:heatmap,
              seriescolor=palette,
              colorbar=cb,
              colorbar_title=cb_label,
              clims=(-1, 1),
              levels=10,
              linewidth=0)
    p = Plots.plot!(interpolated_x,
              interpolated_y,
              s_interpolated,
              fill=:darktest,
              seriestype=:contour,
              seriescolor=palette,
              colorbar=cb,
              colorbar_title=cb_label,
              clims=(-1, 1),
              levels=5,
              linecolor=:black,
              linewidth=0.5)
    p = Plots.plot!((loc_x, loc_y),
              color=:black,
              seriestype=:scatter,
              xlims=x_lim,
              ylims=x_lim,
              grid=true,
              label="",
              markersize=2,
              markerstrokewidth=0,
              markerstrokealpha=0)
    # draw head
    pts = Plots.partialcircle(0, 2π, 100, maximum(loc_x))
    x, y = Plots.unzip(pts)
    x = x .* 1.2
    y = y .* 1.2
    head = Shape(x, y)
    nose = Shape([(-0.05, maximum(y)), (0, maximum(y) + 0.1 * maximum(y)), (0.05, maximum(y))])
    ear_l = Shape([(minimum(x), -0.1), (minimum(x) + 0.05 * minimum(x), -0.1), (minimum(x) + 0.05 * minimum(x), 0.1), (minimum(x), 0.1)])
    ear_r = Shape([(maximum(x), -0.1), (maximum(x) + 0.05 * maximum(x), -0.1), (maximum(x) + 0.05 * maximum(x), 0.1), (maximum(x), 0.1)])
    for idx = 0:0.001:1
        peripheral = Shape(x .* (1 + idx), y .* (1 + idx))
        p = Plots.plot!(p, peripheral, fill=nothing, label="", linecolor=:white, linewidth=1)
    end
    p = Plots.plot!(p, head, fill=nothing, label="", linewidth=1)
    p = Plots.plot!(p, nose, fill=nothing, label="", linewidth=1)
    p = Plots.plot!(p, ear_l, fill=nothing, label="", linewidth=1)
    p = Plots.plot!(p, ear_r, fill=nothing, label="", linewidth=1)
    p = Plots.plot!(p, xlims=(x_lim_int), ylims=(y_lim_int))

    Plots.plot(p)

    return p
end

"""
    eeg_plot_ica_topo(eeg; <keyword arguments>)

Plot topographical view of `eeg` ICAs (each plot is signal reconstructed from this ICA).

# Arguments

- `eeg::NeuroJ.EEG`: EEG object
- `epoch::Int64`: epoch to display
- `offset::Int64=0`: displayed segment offset in samples
- `len::Int64=0`: displayed segment length in samples, default is 1 second
- `ic::Union{Vector{Int64}, AbstractRange}=0`: list of ICAs plot, default is all ICAs
- `m::Symbol=:shepard`: interpolation method `:shepard` (Shepard), `:mq` (Multiquadratic), `:tp` (ThinPlate)
- `cb::Bool=false`: draw color bar
- `cb_label::String="[A.U.]"`: color bar label
- `title::String=""`: plot title
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_ica_topo(eeg::NeuroJ.EEG; epoch::Int64, offset::Int64=0, len::Int64=0, ic::Union{Int64, Vector{Int64}, AbstractRange}=0, m::Symbol=:shepard, cb::Bool=false, cb_label::String="[A.U.]", title::String="", mono::Bool=false, kwargs...)

    eeg_channel_n(eeg, type=:eeg) < eeg_channel_n(eeg, type=:all) && throw(ArgumentError("EEG contains non-eeg channels (e.g. ECG or EMG), remove them before processing."))
    eeg.eeg_header[:channel_locations] == false && throw(ArgumentError("Electrode locations not available, use eeg_load_electrodes() first."))
    :ica in eeg.eeg_header[:components] || throw(ArgumentError("EEG does not contain :ica component. Perform eeg_ica(EEG) first."))
    :ica_mw in eeg.eeg_header[:components] || throw(ArgumentError("EEG does not contain :ica_mw component. Perform eeg_ica(EEG) first."))

    mono == true ? palette = :grays : palette = :darktest

    ica, _ = _get_component(eeg, :ica)
    ica_mw, _ = _get_component(eeg, :ica_mw)

    ic == 0 && (ic = 1:size(ica, 1))

    sort!(ic)
    for idx in 1:length(ic)
        (ic[idx] < 1 || ic[idx] > size(ica, 1)) && throw(ArgumentError("ic must be ≥ 1 and ≤ $(size(ica, 1))."))
    end

    _check_epochs(eeg, epoch)

    offset < 0 && throw(ArgumentError("offset must be ≥ 0."))
    offset + len > eeg_epoch_len(eeg) && throw(ArgumentError("offset + len must be ≤ ($(eeg_epoch_len(eeg)))."))

    len == 0 && (len = eeg_epoch_len(eeg))

    # get time vector
    t = eeg.eeg_epochs_time[(1 + offset):(offset + len), epoch]
    t_1, t_s1, t_2, t_s2 = _convert_t(t)

    p_ica = []
    title_tmp = title

    for idx in 1:length(ic)
        ic_v = setdiff(1:size(ica_mw, 2), idx)
        s_reconstructed = s_ica_reconstruct(eeg.eeg_signals, ic=ica, ic_mw=ica_mw, ic_v=ic_v)
        s_non_interpolated = s_reconstructed[:, (1 + offset):(offset + len), epoch]
        len > 1 && (s_non_interpolated = mean(s_non_interpolated, dims=2))

        (title_tmp == "" && len > 1) && (title = "Component: #$(lpad(string(idx), 3, "0"))\n[epoch: $epoch, time window: $t_s1:$t_s2]")
        (title_tmp == "" && len == 1) && (title = "Component: #$(lpad(string(idx), 3, "0"))\n[epoch: $epoch, time: $t_s1]")

        # plot signal at electrodes at time
        loc_x = zeros(eeg_channel_n(eeg))
        loc_y = zeros(eeg_channel_n(eeg))
        for idx in 1:eeg_channel_n(eeg)
            loc_y[idx], loc_x[idx] = pol2cart(eeg.eeg_header[:loc_radius][idx], 
                                              eeg.eeg_header[:loc_theta][idx])
        end
        x_lim = (findmin(loc_x)[1] * 1.8, findmax(loc_x)[1] * 1.8)
        y_lim = (findmin(loc_y)[1] * 1.8, findmax(loc_y)[1] * 1.8)

        # interpolate
        x_lim_int = (findmin(loc_x)[1] * 1.4, findmax(loc_x)[1] * 1.4)
        y_lim_int = (findmin(loc_y)[1] * 1.4, findmax(loc_y)[1] * 1.4)
        interpolation_factor = 100
        interpolated_x = linspace(x_lim_int[1], x_lim_int[2], interpolation_factor)
        interpolated_y = linspace(y_lim_int[1], y_lim_int[2], interpolation_factor)
        interpolation_m = Matrix{Tuple{Float64, Float64}}(undef, interpolation_factor, interpolation_factor)
        @inbounds @simd for idx1 in 1:interpolation_factor
            for idx2 in 1:interpolation_factor
                interpolation_m[idx1, idx2] = (interpolated_x[idx1], interpolated_y[idx2])
            end
        end
        s_interpolated = zeros(interpolation_factor, interpolation_factor)
        electrode_locations = [loc_x loc_y]'
        m === :shepard && (itp = ScatteredInterpolation.interpolate(Shepard(), electrode_locations, s_non_interpolated))
        m === :mq && (itp = ScatteredInterpolation.interpolate(Multiquadratic(), electrode_locations, s_non_interpolated))
        m === :tp && (itp = ScatteredInterpolation.interpolate(ThinPlate(), electrode_locations, s_non_interpolated))
        @inbounds @simd for idx1 in 1:interpolation_factor
            for idx2 in 1:interpolation_factor
                s_interpolated[idx1, idx2] = ScatteredInterpolation.evaluate(itp, [interpolation_m[idx1, idx2][1]; interpolation_m[idx1, idx2][2]])[1]
            end
        end

        s_interpolated = s_normalize_minmax(s_interpolated)

        p = Plots.plot(grid=false,
                 framestyle=:none,
                 border=:none,
                 margins=0Plots.px,
                 aspect_ratio=1,
                 titlefontsize=8,
                 xlabelfontsize=6,
                 ylabelfontsize=6,
                 xtickfontsize=4,
                 ytickfontsize=4,
                 title=title,
                 palette=palette;
                 kwargs...)
        p = Plots.plot!(interpolated_x,
                  interpolated_y,
                  s_interpolated,
                  fill=:darktest,
                  seriestype=:heatmap,
                  seriescolor=palette,
                  colorbar=cb,
                  colorbar_title=cb_label,
                  clims=(-1, 1),
                  levels=10,
                  linewidth=0)
        p = Plots.plot!(interpolated_x,
                  interpolated_y,
                  s_interpolated,
                  fill=:darktest,
                  seriestype=:contour,
                  seriescolor=palette,
                  colorbar=cb,
                  colorbar_title=cb_label,
                  clims=(-1, 1),
                  levels=5,
                  linecolor=:black,
                  linewidth=0.5)
        p = Plots.plot!((loc_x, loc_y),
                  color=:black,
                  seriestype=:scatter,
                  xlims=x_lim,
                  ylims=x_lim,
                  grid=true,
                  label="",
                  markersize=2,
                  markerstrokewidth=0,
                  markerstrokealpha=0)
        # draw head
        pts = Plots.partialcircle(0, 2π, 100, maximum(loc_x))
        x, y = Plots.unzip(pts)
        x = x .* 1.2
        y = y .* 1.2
        head = Shape(x, y)
        nose = Shape([(-0.05, maximum(y)), (0, maximum(y) + 0.1 * maximum(y)), (0.05, maximum(y))])
        ear_l = Shape([(minimum(x), -0.1), (minimum(x) + 0.05 * minimum(x), -0.1), (minimum(x) + 0.05 * minimum(x), 0.1), (minimum(x), 0.1)])
        ear_r = Shape([(maximum(x), -0.1), (maximum(x) + 0.05 * maximum(x), -0.1), (maximum(x) + 0.05 * maximum(x), 0.1), (maximum(x), 0.1)])
        for idx = 0:0.001:1
            peripheral = Shape(x .* (1 + idx), y .* (1 + idx))
            p = Plots.plot!(p, peripheral, fill=nothing, label="", linecolor=:white, linewidth=1)
        end
        p = Plots.plot!(p, head, fill=nothing, label="", linewidth=1)
        p = Plots.plot!(p, nose, fill=nothing, label="", linewidth=1)
        p = Plots.plot!(p, ear_l, fill=nothing, label="", linewidth=1)
        p = Plots.plot!(p, ear_r, fill=nothing, label="", linewidth=1)
        p = Plots.plot!(p, xlims=(x_lim_int), ylims=(y_lim_int))

        push!(p_ica, p)
    end

    p = eeg_plot_tile(p_ica)

    Plots.plot(p)

    return p
end

"""
    eeg_plot_tile(p)

Plot vector of plots `p` as tiles.

# Arguments

- `p::Vector{Any}`: vector of plots
- `w::Int64=800`: single plot width (px)
- `h::Int64=800`: single plot height (px)
- `rows::Int64=2`: number of rows; if number of plots > 10 then number of rows = rows × 2
- `mono::Bool=false`: use color or grey palette

# Returns

- `p_tiled::Plots.Plot{Plots.GRBackend}`

"""
function eeg_plot_tile(p::Vector{Any}, w::Int64=800, h::Int64=800, rows::Int64=2, mono::Bool=false)
    length(p) > 10 && (rows *= 2)

    mono == true ? palette = :grays : palette = :darktest

    l = (rows, ceil(Int64, length(p) / rows))

    # fill remaining tiles with empty plots
    for idx in (length(p) + 1):l[1]*l[2]
        push!(p, Plots.plot(border=:none, title=""))
    end

    p_tiled = Plots.plot!(p...,
                    layout=l,
                    size=(l[2] * w, l[1] * h),
                    palette=palette)

    return p_tiled
end

"""
    plot_bands(signal; <keyword arguments>)

Plot absolute/relative bands powers of a single-channel `signal`.

# Arguments

- `signal::Vector{<:Real}`
- `fs::Int64`: sampling rate
- `band::Vector{Symbol}=[:delta, :theta, :alpha, :beta, :beta_high, :gamma, :gamma_1, :gamma_2, :gamma_lower, :gamma_higher]`: band names, e.g. [:delta, alpha] (see `eeg_band()`)
- `band_frq::Vector{Tuple{Real, Real}}`: vector of band frequencies
- `type::Symbol`: plots absolute (:abs) or relative power (:rel)
- `norm::Bool=true`: normalize powers to dB
- `xlabel::String=""`: x-axis label
- `ylabel::String=""`: y-axis label
- `title::String=""`: plot title
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function plot_bands(signal::Vector{<:Real}; fs::Int64, band::Vector{Symbol}=[:delta, :theta, :alpha, :beta, :beta_high, :gamma, :gamma_1, :gamma_2, :gamma_lower, :gamma_higher], band_frq::Vector{Tuple{Real, Real}}, type::Symbol, norm::Bool=true, xlabel::String="", ylabel::String="", title::String="", mono::Bool=false, kwargs...)

    fs <= 0 && throw(ArgumentError("fs must be > 0."))
    type in [:abs, :rel] || throw(ArgumentError("type must be :abs or :rel."))
    for idx in 1:length(band)
        band[idx] in [:delta, :theta, :alpha, :beta, :beta_high, :gamma, :gamma_1, :gamma_2, :gamma_lower, :gamma_higher] || throw(ArgumentError("band must be: :delta, :theta, :alpha, :beta, :beta_high, :gamma, :gamma_1, :gamma_2, :gamma_lower or :gamma_higher."))
        band_frq[idx][1] > fs / 2 && (band_frq[idx] = (fs / 2, band_frq[idx][2]))
        band_frq[idx][2] > fs / 2 && (band_frq[idx] = (band_frq[idx][1], fs / 2))
    end

    mono == true ? palette = :grays : palette = :darktest

    total_pow = round(s_total_power(signal, fs=fs), digits=2)
    abs_band_pow = zeros(length(band))
    for idx in 1:length(band)
        abs_band_pow[idx] = round(s_band_power(signal, fs=fs, f=band_frq[idx]), digits=2)
    end
    for idx in 1:length(band)
        abs_band_pow[idx] = round(s_band_power(signal, fs=fs, f=band_frq[idx]), digits=2)
    end
    prepend!(abs_band_pow, total_pow)
    norm == true && (abs_band_pow = pow2db.(abs_band_pow))
    rel_band_pow = abs_band_pow ./ total_pow
    labels = Array{String}(undef, (length(band) + 1))
    labels[1] = "total"
    for idx in 2:(length(band) + 1)
        labels[idx] = String(band[idx - 1])
        labels[idx] = replace(labels[idx], "_" => " ")
        labels[idx] = replace(labels[idx], "alpha" => "α")
        labels[idx] = replace(labels[idx], "beta" => "β")
        labels[idx] = replace(labels[idx], "delta" => "δ")
        labels[idx] = replace(labels[idx], "theta" => "θ")
        labels[idx] = replace(labels[idx], "gamma" => "γ")
        labels[idx] = replace(labels[idx], " high" => "\nhigh")
        labels[idx] = replace(labels[idx], " lower" => "\nlower")
        labels[idx] = replace(labels[idx], " higher" => "\nhigher")
    end
    if type === :abs
        ylabel == "" && (ylabel = "Absolute power")
        norm == true && (ylabel *= " [dB]")
        norm == false && (ylabel *= " [μV^2/Hz]")
        p = Plots.plot(labels,
                 abs_band_pow,
                 seriestype=:bar,
                 label="",
                 xlabel=xlabel,
                 ylabel=ylabel,
                 title=title,
                 palette=palette,
                 titlefontsize=8,
                 xlabelfontsize=6,
                 ylabelfontsize=6,
                 xtickfontsize=8,
                 ytickfontsize=8;
                 kwargs...)
    else
        ylabel == "" && (ylabel = "Relative power")
        p = Plots.plot(labels,
                 rel_band_pow,
                 seriestype=:bar,
                 label="",
                 xlabel=xlabel,
                 ylabel=ylabel,
                 title=title,
                 palette=palette,
                 titlefontsize=8,
                 xlabelfontsize=6,
                 ylabelfontsize=6,
                 xtickfontsize=8,
                 ytickfontsize=8;
                 kwargs...)
    end

    return p
end

"""
    eeg_plot_bands(eeg; <keyword arguments>)

Plots `eeg` channels. If signal is multichannel, only channel amplitudes are plotted. For single-channel signal, the histogram, amplitude, power density and spectrogram are plotted.

# Arguments

- `eeg::NeuroJ.EEG`: EEG object
- `epoch::Union{Int64, AbstractRange}=1`: epochs to display
- `channel::Union{Int64, Vector{Int64}, AbstractRange}`: channels to display
- `offset::Int64=0`: displayed segment offset in samples
- `len::Int64=0`: displayed segment length in samples, default is 1 epoch or 20 seconds
- `band:Vector{Symbols}=:all`: band name, e.g. :delta (see `eeg_band()`)
- `type::Symbol`: plots absolute (:abs) or relative power (:rel)
- `norm::Bool=true`: normalize powers to dB
- `xlabel::String=""`: x-axis label
- `ylabel::String=""`: y-axis label
- `title::String=""`: plot title
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_bands(eeg::NeuroJ.EEG; epoch::Union{Int64, AbstractRange}=1, channel::Union{Int64, Vector{Int64}, AbstractRange}, offset::Int64=0, len::Int64=0, band::Union{Symbol, Vector{Symbol}}=:all, type::Symbol, norm::Bool=true, xlabel::String="", ylabel::String="", title::String="", mono::Bool=false, kwargs...)

    (band === :all && (typeof(channel) != Int64 || length(channel) != 1)) && throw(ArgumentError("For band :all only one channel may be specified."))
    band === :all && (band = [:delta, :theta, :alpha, :beta, :beta_high, :gamma, :gamma_1, :gamma_2, :gamma_lower, :gamma_higher])
    eeg_channel_n(eeg, type=:eeg) < eeg_channel_n(eeg, type=:all) && throw(ArgumentError("EEG contains non-eeg channels (e.g. ECG or EMG), remove them before plotting."))
    offset < 0 && throw(ArgumentError("offset must be ≥ 0."))
    len < 0 && throw(ArgumentError("len must be > 0."))
    (typeof(channel) == Int64 && (channel < 1 || channel > eeg_channel_n(eeg))) && throw(ArgumentError("channel must be ≥ 1 and ≤ $(eeg_channel_n(eeg))."))

    mono == true ? palette = :grays : palette = :darktest

    (epoch != 1 && (offset != 0 || len != 0)) && throw(ArgumentError("For epoch ≠ 1, offset and len must not be specified."))
    typeof(epoch) <: AbstractRange && (epoch = collect(epoch))
    (length(epoch) == 1 && (epoch < 1 || epoch > eeg_epoch_n(eeg))) && throw(ArgumentError("epoch must be ≥ 1 and ≤ $(eeg_epoch_n(eeg))."))
    (length(epoch) > 1 && (epoch[1] < 1 || epoch[end] > eeg_epoch_n(eeg))) && throw(ArgumentError("epoch must be ≥ 1 and ≤ $(eeg_epoch_n(eeg))."))
    if length(epoch) > 1
        sort!(epoch)
        (epoch[1] < 1 || epoch[end] > eeg_epoch_n(eeg)) && throw(ArgumentError("epoch must be ≥ 1 and ≤ $(eeg_epoch_n(eeg))."))
        len = eeg_epoch_len(eeg) * length(epoch)
        offset = eeg_epoch_len(eeg) * (epoch[1] - 1)
        epoch = 1
    end

    # default length is one epoch or 20 seconds
    len = _len(eeg, len, 20)

    # get epochs markers for len > epoch_len
    if len + offset > eeg_epoch_len(eeg) && eeg_epoch_n(eeg) > 1
        eeg_tmp = eeg_epochs(eeg, epoch_n=1)
    else
        eeg_tmp = eeg
    end

    t = collect(0:(1 / eeg_sr(eeg_tmp)):(len / eeg_sr(eeg)))
    t = t .+ (offset / eeg_sr(eeg_tmp))
    t = t[1:(end - 1)]
    t[1] = floor(t[1], digits=2)
    t[end] = ceil(t[end], digits=2)

    (offset < 0 || offset > eeg_epoch_len(eeg_tmp)) && throw(ArgumentError("offset must be > 0 and ≤ $(eeg_epoch_len(eeg_tmp))."))
    (offset + len > eeg_epoch_len(eeg_tmp)) && throw(ArgumentError("offset + len must be ≤ $(eeg_epoch_len(eeg_tmp))."))

    signal = eeg_tmp.eeg_signals[channel, (1 + offset):(offset + length(t)), epoch]

    band_frq = Vector{Tuple{Real, Real}}()
    for idx in 1:length(band)
        push!(band_frq, eeg_band(eeg, band=band[idx]))
    end

    if typeof(band) == Symbol
        typeof(channel) <: AbstractRange && (channel = collect(channel))
        if collect(channel[1]:channel[end]) == channel
            channel_list = string(channel[1]) * ":" * string(channel[end])
        elseif typeof(channel) != Int64
            channel_list = "" 
            for idx in 1:(length(channel) - 1)
                channel_list *= string(channel[idx])
                channel_list *= ", "
            end
            channel_list *= string(channel[end])
        else
            channel_list = string(channel)
        end
        typeof(signal) == Vector{Float64} && (signal = reshape(signal, 1, length(signal)))
        epoch_tmp = epoch
        offset > eeg_epoch_len(eeg) && (epoch_tmp = floor(Int64, offset / eeg_epoch_len(eeg)) + 1)
        title == "" && (title = "$(titlecase(string(band))) power\n[epoch: $epoch_tmp, channel(s): $channel_list]\n[offset: $offset samples, length: $len samples]")
        labels = eeg_labels(eeg)[channel]
        typeof(labels) == String && (labels = [labels])
        p = plot_bands(signal,
                       band=band,
                       band_frq=band_frq,
                       fs=eeg_sr(eeg),
                       type=type,
                       labels=labels,
                       norm=norm,
                       xlabel=xlabel,
                       ylabel=ylabel,
                       title=title,
                       mono=mono;
                       kwargs...)
    else
        signal = vec(signal)
        epoch_tmp = epoch
        offset > eeg_epoch_len(eeg) && (epoch_tmp = floor(Int64, offset / eeg_epoch_len(eeg)) + 1)
        title == "" && (title = "Band powers\n[epoch: $epoch_tmp, channel: $channel ($(eeg_labels(eeg)[channel])), offset: $offset samples, length: $len samples]")

        p = plot_bands(signal,
                       band=band,
                       band_frq=band_frq,
                       fs=eeg_sr(eeg),
                       type=type,
                       norm=norm,
                       xlabel=xlabel,
                       ylabel=ylabel,
                       title=title,
                       mono=mono;
                       kwargs...)
    end

    Plots.plot(p)

    return p
end

"""
    eeg_plot_save(p; file_name::String)

Saves plot as file (PDF/PNG/TIFF). File format is determined using `file_name` extension.

# Arguments

- `p::Union{Plots.Plot{Plots.GRBackend}, GLMakie.Figure}`
- `file_name::String`
"""
function eeg_plot_save(p::Union{Plots.Plot{Plots.GRBackend}, GLMakie.Figure}; file_name::String)

    ext = splitext(file_name)[2]
    ext in [".png", ".pdf", ".jpg", ".tiff"] || throw(ArgumentError("Fiel format must be: .png, .pdf, .tiff or .jpg"))
    isfile(file_name) && @warn "File $file_name will be overwritten."
    if typeof(p) == Plots.Plot{Plots.GRBackend}
        savefig(p, file_name)
    else
        save(file_name, p)
    end

    nothing
end

"""
    eeg_plot_channels(eeg; <keyword arguments>)

Plot values of `c` for selected channels of `eeg`.

# Arguments

- `eeg:NeuroJ.EEG`
- `c::Union{Matrix{Int64}, Matrix{<:Real}, Symbol}`: values to plot; if symbol, than use embedded component
- `channel::Union{Int64, Vector{Int64}, AbstractRange}`: list of channels to plot
- `epoch::Int64`: number of epoch for which `c` should be plotted
- `xlabel::String="Channel"`: x-axis label
- `ylabel::String=""`: y-axis label
- `title::String=""`: plot title
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_channels(eeg::NeuroJ.EEG; c::Union{Matrix{Int64}, Matrix{<:Real}, Symbol}, epoch::Int64, channel::Union{Int64, Vector{Int64}, AbstractRange}=0, xlabel::String="Channel", ylabel::String="", title::String="", mono::Bool=false, kwargs...)

    (epoch < 1 || epoch > eeg_epoch_n(eeg)) && throw(ArgumentError("epoch must be ≥ 1 and ≤ $(eeg_epoch_n(eeg))."))
    channel = _select_channels(eeg, channel, 0)
    _check_channels(eeg, channel)
    labels = eeg_labels(eeg)[channel]

    mono == true ? palette = :grays : palette = :darktest

    if typeof(c) != Symbol
        length(c[:, epoch]) == eeg_channel_n(eeg) || throw(ArgumentError("Length of c ($(length(c))) and number of EEG channels ($(length(channel))) do not match."))
        var = c[channel, epoch]
    else
        c in eeg.eeg_header[:components] || throw(ArgumentError("Component $c not found."))
        component_idx = findfirst(isequal(c), eeg.eeg_header[:components])
        var = eeg.eeg_components[component_idx][channel, epoch]
    end

    p = Plots.plot(var,
             label="",
             xticks=(1:length(labels), labels),
             xlabel=xlabel,
             ylabel=ylabel,
             title=title,
             palette=palette,
             titlefontsize=8,
             xlabelfontsize=6,
             ylabelfontsize=6,
             xtickfontsize=8,
             ytickfontsize=8;
             kwargs...)

    return p
end

"""
    eeg_plot_epochs(eeg; <keyword arguments>)

Plot values of `c` for selected epoch of `eeg`.

# Arguments

- `eeg:NeuroJ.EEG`
- `c::Union{Vector{<:Real}, Symbol}`: values to plot; if symbol, than use embedded component
- `epoch::Union{Int64, Vector{Int64}, AbstractRange}`: list of epochs to plot
- `xlabel::String="Epochs"`: x-axis label
- `ylabel::String=""`: y-axis label
- `title::String=""`: plot title
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_epochs(eeg::NeuroJ.EEG; c::Union{Vector{<:Real}, Symbol}, epoch::Union{Int64, Vector{Int64}, AbstractRange}=0, xlabel::String="Epochs", ylabel::String="", title::String="", mono::Bool=false, kwargs...)

    epoch = _select_epochs(eeg, epoch, 0)
    _check_epochs(eeg, epoch)
    mono == true ? palette = :grays : palette = :darktest

    if typeof(c) != Symbol
        length(c) == eeg_epoch_n(eeg) || throw(ArgumentError("Length of c ($(length(c))) and number of epochs ($(length(epoch))) do not match."))
        var = c[epoch]
    else
        c in eeg.eeg_header[:components] || throw(ArgumentError("Component $c not found."))
        component_idx = findfirst(isequal(c), eeg.eeg_header[:components])
        length(eeg.eeg_components[component_idx]) == eeg_epoch_n(eeg) || throw(ArgumentError("Length of component vector ($(length(eeg.eeg_components[component_idx]))) and number of epochs ($(length(epoch))) do not match."))
        var = eeg.eeg_components[component_idx][epoch]
    end

    p = Plots.plot(var,
             label="",
             xticks=epoch,
             xlabel=xlabel,
             ylabel=ylabel,
             title=title,
             palette=palette,
             linewidth=0.5,
             titlefontsize=8,
             xlabelfontsize=6,
             ylabelfontsize=6,
             xtickfontsize=8,
             ytickfontsize=8;
             kwargs...)

    return p
end

"""
    eeg_plot_filter_response(eeg; <keyword arguments>)

Plot filter response.

# Arguments

- `eeg::NeuroJ.EEG`
- `fprototype::Symbol`: filter class: :fir, :butterworth, :chebyshev1, :chebyshev2, :elliptic
- `ftype::Symbol`: filter type: :lp, :hp, :bp, :bs
- `cutoff::Union{Real, Tuple}`: filter cutoff in Hz (vector for `:bp` and `:bs`)
- `order::Int64`: filter order
- `rp::Real`: dB ripple in the passband
- `rs::Real`: dB attenuation in the stopband
- `window::window::Union{Vector{Float64}, Nothing}`: window, required for FIR filter
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_filter_response(eeg::NeuroJ.EEG; fprototype::Symbol, ftype::Symbol, cutoff::Union{Real, Tuple}, order::Int64=-1, rp::Real=-1, rs::Real=-1, window::Union{Vector{Float64}, Nothing}=nothing, mono::Bool=false, kwargs...)

    mono == true ? palette = :grays : palette = :darktest

    fs = eeg_sr(eeg)
    fprototype in [:fir, :butterworth, :chebyshev1, :chebyshev2, :elliptic] || throw(ArgumentError("fprototype must be :fir, :butterworth, :chebyshev1:, :chebyshev2 or :elliptic."))
    fprototype !== :fir && order < 1 && throw(ArgumentError("order must be > 0."))
    ftype in [:lp, :hp, :bp, :bs] || throw(ArgumentError("ftype must be :bp, :hp, :bp or :bs."))

    if ftype === :lp
        length(cutoff) != 1 && throw(ArgumentError("For :lp filter one frequency must be given."))
        responsetype = Lowpass(cutoff; fs=fs)
    elseif ftype === :hp
        length(cutoff) != 1 && throw(ArgumentError("For :hp filter one frequency must be given."))
        responsetype = Highpass(cutoff; fs=fs)
    elseif ftype === :bp
        length(cutoff) != 2 && throw(ArgumentError("For :bp filter two frequencies must be given."))
        responsetype = Bandpass(cutoff[1], cutoff[2]; fs=fs)
    elseif ftype === :bs
        length(cutoff) != 2 && throw(ArgumentError("For :bs filter two frequencies must be given."))
        cutoff = tuple_order(cutoff)
        responsetype = Bandstop(cutoff[1], cutoff[2]; fs=fs)
    end

    fprototype === :butterworth && (prototype = Butterworth(order))
    if fprototype === :fir
        if window === nothing
            @warn "Using default window for :fir filter: hanning($(3 * floor(Int64, fs / cutoff[1])))."
            window = hanning(3 * floor(Int64, fs / cutoff[1]))
        end
        if ftype === :hp || ftype === :bp || ftype === :bs
            mod(length(window), 2) == 0 && (window = vcat(window[1:((length(window) ÷ 2) - 1)], window[((length(window) ÷ 2) + 1):end]))
        end
        prototype = FIRWindow(window)
    end
    if fprototype === :chebyshev1
        (rs < 0 || rs > eeg_sr(eeg) / 2) && throw(ArgumentError("For :chebyshev1 filter rs must be > 0 and ≤ $(eeg_sr(eeg) / 2)."))
        prototype = Chebyshev1(order, rs)
    end
    if fprototype === :chebyshev2
        (rp < 0 || rp > eeg_sr(eeg) / 2) && throw(ArgumentError("For :chebyshev2 filter rp must be > 0 and ≤ $(eeg_sr(eeg) / 2)."))
        prototype = Chebyshev2(order, rp)
    end
    if fprototype === :elliptic
        (rs < 0 || rs > eeg_sr(eeg) / 2) && throw(ArgumentError("For :elliptic filter rs must be > 0 and ≤ $(eeg_sr(eeg) / 2)."))
        (rp < 0 || rp > eeg_sr(eeg) / 2) && throw(ArgumentError("For :elliptic filter rp must be > 0 and ≤ $(eeg_sr(eeg) / 2)."))
        prototype = Elliptic(order, rp, rs)
    end

    ffilter = digitalfilter(responsetype, prototype)

    if fprototype !== :fir
        H, w = freqresp(ffilter)
        # convert to dB
        H = 20 * log10.(abs.(H))
        # convert rad/sample to Hz
        w = w .* fs / 2 / pi
        x_max = w[end]
        ftype === :hp && (x_max = cutoff * 10)
        p1 = Plots.plot(w,
                  H,
                  title="Filter: $(titlecase(String(fprototype))), type: $(uppercase(String(ftype))), cutoff: $cutoff Hz, order: $order\nFrequency response",
                  xlims=(0, x_max),
                  ylims=(-100, 0),
                  ylabel="Magnitude\n[dB]",
                  xlabel="Frequency [Hz]",
                  label="",
                  titlefontsize=8,
                  xlabelfontsize=6,
                  ylabelfontsize=6,
                  xtickfontsize=4,
                  ytickfontsize=4,
                  palette=palette)
        if length(cutoff) == 1
            p1 = Plots.plot!((0, cutoff),
                       seriestype=:vline,
                       linestyle=:dash,
                       label="")
        else
            p1 = Plots.plot!((0, cutoff[1]),
                       seriestype=:vline,
                       linestyle=:dash,
                       label="")
            p1 = Plots.plot!((0, cutoff[2]),
                       seriestype=:vline,
                       linestyle=:dash,
                       label="")
        end

        phi, w = phaseresp(ffilter)
        phi = rad2deg.(angle.(phi))
        # convert rad/sample to Hz
        w = w .* fs / 2 / pi
        x_max = w[end]
        ftype === :hp && (x_max = cutoff * 10)
        p2 = Plots.plot(w,
                  phi,
                  title="Phase response",
                  ylims=(-180, 180),
                  xlims=(0, x_max),
                  ylabel="Phase\n[°]",
                  xlabel="Frequency [Hz]",
                  label="",
                  titlefontsize=8,
                  xlabelfontsize=6,
                  ylabelfontsize=6,
                  xtickfontsize=4,
                  ytickfontsize=4,
                  palette=palette)
        if length(cutoff) == 1
            p2 = Plots.plot!((0, cutoff),
                       seriestype=:vline,
                       linestyle=:dash,
                       label="")
        else
            p2 = Plots.plot!((0, cutoff[1]),
                       seriestype=:vline,
                       linestyle=:dash,
                       label="")
            p2 = Plots.plot!((0, cutoff[2]),
                       seriestype=:vline,
                       linestyle=:dash,
                       label="")
        end

        tau, w = grpdelay(ffilter)
        tau = abs.(tau)
        # convert rad/sample to Hz
        w = w .* fs / 2 / pi
        x_max = w[end]
        ftype === :hp && (x_max = cutoff * 10)
        p3 = Plots.plot(w,
                  tau,
                  title="Group delay",
                  xlims=(0, x_max),
                  ylabel="Group delay\n[samples]",
                  xlabel="Frequency [Hz]",
                  label="",
                  titlefontsize=8,
                  xlabelfontsize=6,
                  ylabelfontsize=6,
                  xtickfontsize=4,
                  ytickfontsize=4,
                  palette=palette)
        if length(cutoff) == 1
            p3 = Plots.plot!((0, cutoff),
                       seriestype=:vline,
                       linestyle=:dash,
                       label="")
        else
            p3 = Plots.plot!((0, cutoff[1]),
                       seriestype=:vline,
                       linestyle=:dash,
                       label="")
            p3 = Plots.plot!((0, cutoff[2]),
                       seriestype=:vline,
                       linestyle=:dash,
                       label="")
        end

        p = Plots.plot(p1, p2, p3, layout=(3, 1), palette=palette; kwargs...)
    else
        w = range(0, stop=pi, length=1024)
        H = _fir_response(ffilter, w)
        # convert to dB
        H = 20 * log10.(abs.(H))
        # convert rad/sample to Hz
        w = w .* fs / 2 / pi
        x_max = w[end]
        ftype === :hp && (x_max = cutoff * 10)
        p1 = Plots.plot(w,
                  H,
                  title="Filter: $(uppercase(String(fprototype))), type: $(uppercase(String(ftype))), cutoff: $cutoff Hz\nFrequency response",
                  xlims=(0, x_max),
                  ylims=(-100, 0),
                  ylabel="Magnitude\n[dB]",
                  xlabel="Frequency [Hz]",
                  label="",
                  titlefontsize=8,
                  xlabelfontsize=6,
                  ylabelfontsize=6,
                  xtickfontsize=4,
                  ytickfontsize=4,
                  palette=palette)
        if length(cutoff) == 1
            p1 = Plots.plot!((0, cutoff),
                        seriestype=:vline,
                        linestyle=:dash,
                        label="")
        else
            p1 = Plots.plot!((0, cutoff[1]),
                       seriestype=:vline,
                       linestyle=:dash,
                       label="")
            p1 = Plots.plot!((0, cutoff[2]),
                       seriestype=:vline,
                       linestyle=:dash,
                       label="")
        end
        w = range(0, stop=pi, length=1024)
        phi = _fir_response(ffilter, w)
        phi = DSP.unwrap(-atan.(imag(phi), real(phi)))
        # convert rad/sample to Hz
        w = w .* fs / 2 / pi
        x_max = w[end]
        ftype === :hp && (x_max = cutoff * 10)
        p2 = Plots.plot(w,
                  phi,
                  title="Phase response",
                  xlims=(0, x_max),
                  ylabel="Phase\n[rad]",
                  xlabel="Frequency [Hz]",
                  label="",
                  titlefontsize=8,
                  xlabelfontsize=6,
                  ylabelfontsize=6,
                  xtickfontsize=4,
                  ytickfontsize=4,
                  palette=palette)
        if length(cutoff) == 1
            p2 = Plots.plot!((0, cutoff),
                        seriestype=:vline,
                        linestyle=:dash,
                        label="")
        else
            p2 = Plots.plot!((0, cutoff[1]),
                       seriestype=:vline,
                       linestyle=:dash,
                       label="")
            p2 = Plots.plot!((0, cutoff[2]),
                       seriestype=:vline,
                       linestyle=:dash,
                       label="")
        end

        p = Plots.plot(p1, p2, layout=(2, 1), palette=palette; kwargs...)
    end

    return p
end

"""
    eeg_plot_compose(p; <keyword arguments>)

Compose a complex plot of various plots contained in vector `p` using layout `layout`. Layout scheme is:
- `(2, 2)`: 2 × 2 plots, regular layout
- `@layout [a{0.2w} b{0.8w};_ c{0.6}]`: complex layout using Plots.jl `@layout` macro

# Arguments

- `p::Vector{Plots.Plot{Plots.GRBackend}}`: vector of plots
- `layout::Union(Matrix{Any}, Tuple{Int64, Int64}}`: layout
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for `p` vector plots

# Returns

- `pc::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_compose(p::Vector{Plots.Plot{Plots.GRBackend}}; layout::Union{Matrix{Any}, Tuple{Int64, Int64}}, mono::Bool=false, kwargs...)

    mono == true ? palette = :grays : palette = :darktest

    pc = Plots.plot(grid=false,
              framestyle=:none,
              border=:none,
              margins=0Plots.px)
    pc = Plots.plot!(p..., layout=layout, palette=palette; kwargs...)
    Plots.plot(pc)

    return pc
end

"""
    eeg_plot_env(eeg; <keyword arguments>)

Plot envelope of `eeg` channels.

# Arguments

- `eeg::NeuroJ.EEG`
- `type::Symbol`: envelope type: :amp (amplitude over time), :pow (power over frequencies), :spec (frequencies over time)
- `average::Symbol`: averaging method: :no, :mean or :median
- `dims::Union{Int64, Nothing}=nothing`: average over channels (dims = 1), epochs (dims = 2) or channels and epochs (dims = 3)
- `epoch::Int64`: epoch number to display
- `channel::Int64`: channel to display
- `xlabel::String=""`: x-axis label
- `ylabel::String=""`: y-axis label
- `title::String=""`: plot title
- `y_lim::Tuple{Real, Real}=(0, 0)`: y-axis limits
- `frq_lim::Tuple{Real, Real}=(0, 0)`: frequency limit for PSD and spectrogram
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_env(eeg::NeuroJ.EEG; type::Symbol, average::Symbol=:no, dims::Union{Int64, Nothing}=nothing, d::Int64=32, epoch::Int64, channel::Int64, xlabel::String="", ylabel::String="", title::String="", y_lim::Tuple{Real, Real}=(0, 0), frq_lim::Tuple{Real, Real}=(0, 0), mono::Bool=false, kwargs...)

    mono == true ? palette = :grays : palette = :darktest

    type in [:amp, :pow, :spec] || throw(ArgumentError("type must be :amp, :pow or :spec."))

    type === :amp && (d = 32)
    type === :pow && (d = 8)
    type === :spec && (d = 8)

    type === :amp && (type = :amplitude)
    type === :pow && (type = :power)
    type === :spec && (type = :spectrogram)

    average in [:no, :mean, :median] || throw(ArgumentError("average must be :no, :mean or :median."))
    (epoch < 1 || epoch > eeg_epoch_n(eeg)) && throw(ArgumentError("epoch must be ≥ 1 and ≤ $(eeg_epoch_n(eeg))."))
    (channel < 1 || epoch > eeg_channel_n(eeg)) && throw(ArgumentError("channel must be ≥ 1 and ≤ $(eeg_channel_n(eeg))."))
    average === :no && (dims = nothing)
    (average !== :no && dims == nothing) && throw(ArgumentError("dims must be ≥ 1 and ≤ 3."))
    (average !== :no && (dims < 1 || dims > 3)) && throw(ArgumentError("dims must be ≥ 1 and ≤ 3."))

    fs = eeg_sr(eeg)
    frq_lim == (0, 0) && (frq_lim = (0, div(fs, 2)))
    frq_lim = tuple_order(frq_lim)
    (frq_lim[1] < 0 || frq_lim[2] > fs / 2) && throw(ArgumentError("frq_lim must be ≥ 0 and ≤ $(fs / 2)."))

    t = eeg.eeg_epochs_time[:, epoch]
    t[1] = floor(t[1], digits=2)
    t[end] = ceil(t[end], digits=2)

    if average === :no
        type === :amplitude && ((e, t) = eeg_tenv(eeg, d=d))
        type === :power && ((e, t) = eeg_penv(eeg, d=d))
        type === :spectrogram && ((e, t) = eeg_senv(eeg, d=d))
    elseif average === :mean
        type === :amplitude && ((e, e_u, e_l, t) = eeg_tenv_mean(eeg, dims=dims, d=d))
        type === :power && ((e, e_u, e_l, t) = eeg_penv_mean(eeg, dims=dims, d=d))
        type === :spectrogram && ((e, e_u, e_l, t) = eeg_senv_mean(eeg, dims=dims, d=d))
    elseif average === :median
        type === :amplitude && ((e, e_u, e_l, t) = eeg_tenv_median(eeg, dims=dims, d=d))
        type === :power && ((e, e_u, e_l, t) = eeg_penv_median(eeg, dims=dims, d=d))
        type === :spectrogram && ((e, e_u, e_l, t) = eeg_senv_median(eeg, dims=dims, d=d))
    end

    type === :amplitude && (xlabel == "" && (xlabel = "Time [s]"))
    type === :amplitude && (ylabel == "" && (ylabel = "Amplitude [μV]"))
    (type === :amplitude && y_lim == (0,0)) && (y_lim = (-200, 200))
    type === :amplitude && (x_lim = _xlims(t))
    type === :amplitude && (x_ticks = _xticks(t))

    type === :power && (xlabel == "" && (xlabel = "Frequency [Hz]"))
    type === :power && (t = linspace(t[1], t[end], length(t)))
    type === :power && (ylabel == "" && (ylabel = "Power [dB/Hz]"))
    type === :power && (x_lim = (frq_lim[1], frq_lim[end]))
    type === :power && (x_ticks = round.(linspace(frq_lim[1], frq_lim[end], 10), digits=1))
    (type === :power && y_lim == (0,0)) && (y_lim = (-50, 50))

    type === :spectrogram && (xlabel == "" && (xlabel = "Time [s]"))
    type === :spectrogram && (ylabel == "" && (ylabel = "Frequency [Hz]"))
    type === :spectrogram && (x_lim = _xlims(t))
    (type === :spectrogram && y_lim == (0,0)) && (y_lim = frq_lim)
    type === :spectrogram && (x_ticks = _xticks(t))

    channel_name = eeg_labels(eeg)[channel]
    t_1, t_s1, t_2, t_s2 = _convert_t(t)

    if dims == 1
        e = e[:, epoch]
        average !== :no && (e_u = e_u[:, epoch]; e_l = e_l[:, epoch])
        title == "" && (title = "Envelope: $type\n[averaged channels, epoch: $epoch, time window: $t_s1:$t_s2]")
    elseif dims == 2
        e = e[:, channel]
        e_u = e_u[:, channel]
        e_l = e_l[:, channel]
        title == "" && (title = "Envelope: $type\n[$average averaged epochs, channel: $channel_name, time window: $t_s1:$t_s2]")
    elseif dims == 3
        title == "" && (title = "Envelope: $type\n[$average averaged channels and epochs, time window: $t_s1:$t_s2]")
    else
        e = e[channel, :, epoch]
        title == "" && (title = "Envelope: $type\n[channel: $channel_name, epoch: $epoch, time window: $t_s1:$t_s2]")
    end

    p = Plots.plot(t,
             e,
             label="",
             legend=false,
             title=title,
             xlabel=xlabel,
             xlims=x_lim,
             xticks=x_ticks,
             ylabel=ylabel,
             ylims=y_lim,
             yguidefontrotation=0,
             linewidth=0.5,
             color=:black,
             grid=true,
             titlefontsize=8,
             xlabelfontsize=6,
             ylabelfontsize=6,
             xtickfontsize=4,
             ytickfontsize=4,
             palette=palette;
             kwargs...)
    if average !== :no
        p = Plots.plot!(t,
                  e_u,
                  fillrange=e_l,
                  fillalpha=0.35, 
                  label=false,
                  t=:line,
                  c=:grey,
                  linewidth=0.5)
        p = Plots.plot!(t,
                  e_l,
                  label=false,
                  t=:line,
                  c=:grey,
                  lw=0.5)
    end

    Plots.plot(p)

    return p
end

"""
    eeg_plot_ispc(eeg1, eeg2; <keyword arguments>)

Plot ISPC `eeg1` and `eeg2` channels/epochs.

# Arguments

- `eeg1:NeuroJ.EEG`
- `eeg2:NeuroJ.EEG`
- `channel1::Int64`: channel to plot
- `channel2::Int64`: channel to plot
- `epoch1::Int64`: epoch to plot
- `epoch2::Int64`: epoch to plot
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_ispc(eeg1::NeuroJ.EEG, eeg2::NeuroJ.EEG; channel1::Int64, channel2::Int64, epoch1::Int64, epoch2::Int64, mono::Bool=false, kwargs...)

    mono == true ? palette = :grays : palette = :darktest

    ispc, ispc_angle, signal_diff, phase_diff, s1_phase, s2_phase = eeg_ispc(eeg1, eeg2, channel1=channel1, channel2=channel2, epoch1=epoch1, epoch2=epoch2)

    ispc = ispc[1]
    ispc = round(ispc, digits=2)
    ispc_angle = ispc_angle[1]
    signal_diff = signal_diff[1, :, 1]
    phase_diff = phase_diff[1, :, 1]
    s1_phase = s1_phase[1, :, 1]
    s2_phase = s2_phase[1, :, 1]

    signal1 = @view eeg1.eeg_signals[channel1, :, epoch1]
    signal2 = @view eeg2.eeg_signals[channel2, :, epoch2]
    t = eeg1.eeg_epochs_time[:, epoch1]

    p1 = Plots.plot(t, signal1, color=:black, lw=0.2)
    p1 = Plots.plot!(t, signal2, color=:grey, lw=0.2, title="Signals", legend=false, xlabel="Time [s]", ylabel="Amplitude [μv]")

    p2 = Plots.plot(t, signal_diff, color=:black, lw=0.2, title="Signals difference", legend=false, xlabel="Time [s]", ylabel="Amplitude [μv]")

    p3 = Plots.plot(t, s1_phase, color=:black, lw=0.2)
    p3 = Plots.plot!(t, s2_phase, color=:grey, lw=0.2, title="Phases", legend=false, xlabel="Time [s]", ylabel="Angle [rad]")

    p4 = Plots.plot(t, phase_diff, color=:black, lw=0.2, title="Phases difference", legend=false, xlabel="Time [s]", ylabel="Angle [rad]")

    p5 = Plots.plot([0, s1_phase[1]], [0, 1], projection=:polar, yticks=false, color=:black, lw=0.2, legend=nothing, title="Phases")
    for idx in 2:length(phase_diff)
        p5 = Plots.plot!([0, s1_phase[idx]], [0, 1], projection=:polar, color=:black, lw=0.2)
    end

    p5 = Plots.plot!([0, s2_phase[1]], [0, 1], projection=:polar, yticks=false, color=:grey, lw=0.2, legend=nothing)
    for idx in 2:length(phase_diff)
        p5 = Plots.plot!([0, s2_phase[idx]], [0, 1], projection=:polar, color=:grey, lw=0.2)
    end

    p6 = Plots.plot([0, phase_diff[1]], [0, 1], projection=:polar, yticks=false, color=:black, lw=0.2, legend=nothing, title="Phases difference and ISPC = $ispc")
    for idx in 2:length(phase_diff)
        p6 = Plots.plot!([0, phase_diff[idx]], [0, 1], projection=:polar, color=:black, lw=0.2)
    end
    p6 = Plots.plot!([0, ispc_angle], [0, ispc], lw=1, color=:red)
    
    p = Plots.plot(p1, p2, p3, p4, p5, p6,
             layout=(3, 2),
             titlefontsize=8,
             xlabelfontsize=6,
             ylabelfontsize=6,
             xtickfontsize=4,
             ytickfontsize=4,
             palette=palette;
             kwargs...)

    return p
end

"""
    eeg_plot_itpc(eeg; <keyword arguments>)

Plot ITPC (Inter-Trial-Phase Clustering) at time `t` over epochs/trials of `channel` of `eeg`.

# Arguments

- `eeg:NeuroJ.EEG`
- `channel::Int64`: channel to plot
- `t::Int64`: time point to plot
- `z::Bool=false`: plot ITPCz instead of ITPC
- `w::Union{Vector{<:Real}, Nothing}=nothing`: optional vector of epochs/trials weights for wITPC calculation
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_itpc(eeg::NeuroJ.EEG; channel::Int64, t::Int64, z::Bool=false, w::Union{Vector{<:Real}, Nothing}=nothing, mono::Bool=false, kwargs...)

    mono == true ? palette = :grays : palette = :darktest

    itpc, itpcz, itpc_angle, itpc_phases = eeg_itpc(eeg, channel=channel, t=t, w=w)
    itpc = round(itpc, digits=2)
    itpcz = round(itpcz, digits=2)
    t = eeg_s2t(eeg, t=t)

    p1 = Plots.plot(itpc_phases,
              seriestype=:histogram,
              bins=(length(itpc_phases) ÷ 10),
              xticks=[-3.14, 0, 3.14],
              xlims=(-pi, pi),
              fill=:lightgrey,
              title="Phase angles across trials\nchannel: $channel",
              xlabel="Phase angle [rad]",
              ylabel="Count/bin")

    if z == false
        if w === nothing
            p2 = Plots.plot([0, itpc_phases[1]], [0, 1], projection=:polar, yticks=false, color=:black, lw=0.2, legend=nothing, title="Phase differences\nITPC at $t s = $itpc")
        else
            p2 = Plots.plot([0, itpc_phases[1]], [0, 1], projection=:polar, yticks=false, color=:black, lw=0.2, legend=nothing, title="Phase differences\nwITPC at $t s = $itpc")
        end
    else
        if w === nothing
            p2 = Plots.plot([0, itpc_phases[1]], [0, 1], projection=:polar, yticks=false, color=:black, lw=0.2, legend=nothing, title="Phase differences\nITPCz at $t s = $itpcz")
        else
            nothing && (p2 = Plots.plot([0, itpc_phases[1]], [0, 1], projection=:polar, yticks=false, color=:black, lw=0.2, legend=nothing, title="Phase differences\nwITPCz at $t s = $itpcz"))
        end
    end
    for idx in 2:length(itpc_phases)
        p2 = Plots.plot!([0, itpc_phases[idx]], [0, 1], projection=:polar, color=:black, lw=0.2)
    end
    itpcz > 1 && (itpcz = 1)
    z == false && (p2 = Plots.plot!([0, itpc_angle], [0, itpc], lw=1, color=:red))
    z == true && (p2 = Plots.plot!([0, itpc_angle], [0, itpcz], lw=1, color=:red))

    p = Plots.plot(p1, p2,
             legend=false,
             titlefontsize=8,
             xlabelfontsize=6,
             ylabelfontsize=6,
             xtickfontsize=4,
             ytickfontsize=4,
             margins=10Plots.px,
             palette=palette;
             kwargs...)

    return p
end

"""
    eeg_plot_pli(eeg1, eeg2; <keyword arguments>)

Plot pli `eeg1` and `eeg2` channels/epochs.

# Arguments

- `eeg1:NeuroJ.EEG`
- `eeg2:NeuroJ.EEG`
- `channel1::Int64`: channel to plot
- `channel2::Int64`: channel to plot
- `epoch1::Int64`: epoch to plot
- `epoch2::Int64`: epoch to plot
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_pli(eeg1::NeuroJ.EEG, eeg2::NeuroJ.EEG; channel1::Int64, channel2::Int64, epoch1::Int64, epoch2::Int64, mono::Bool=false, kwargs...)

    mono == true ? palette = :grays : palette = :darktest

    pli, signal_diff, phase_diff, s1_phase, s2_phase = eeg_pli(eeg1, eeg2, channel1=channel1, channel2=channel2, epoch1=epoch1, epoch2=epoch2)

    pli = pli[1]
    pli = round(pli, digits=2)
    signal_diff = signal_diff[1, :, 1]
    phase_diff = phase_diff[1, :, 1]
    s1_phase = s1_phase[1, :, 1]
    s2_phase = s2_phase[1, :, 1]

    signal1 = @view eeg1.eeg_signals[channel1, :, epoch1]
    signal2 = @view eeg2.eeg_signals[channel2, :, epoch2]
    t = eeg1.eeg_epochs_time[:, epoch1]

    p1 = Plots.plot(t, signal1, color=:black, lw=0.2)
    p1 = Plots.plot!(t, signal2, color=:grey, lw=0.2, title="Signals", legend=false, xlabel="Time [s]", ylabel="Amplitude [μv]")

    p2 = Plots.plot(t, signal_diff, color=:black, lw=0.2, title="Signals difference", legend=false, xlabel="Time [s]", ylabel="Amplitude [μv]")

    p3 = Plots.plot(t, s1_phase, color=:black, lw=0.2)
    p3 = Plots.plot!(t, s2_phase, color=:grey, lw=0.2, title="Phases", legend=false, xlabel="Time [s]", ylabel="Angle [rad]")

    p4 = Plots.plot(t, phase_diff, color=:black, lw=0.2, title="Phases difference", legend=false, xlabel="Time [s]", ylabel="Angle [rad]")

    p5 = Plots.plot([0, s1_phase[1]], [0, 1], projection=:polar, yticks=false, color=:black, lw=0.2, legend=nothing, title="Phases")
    for idx in 2:length(phase_diff)
        p5 = Plots.plot!([0, s1_phase[idx]], [0, 1], projection=:polar, color=:black, lw=0.2)
    end

    p5 = Plots.plot!([0, s2_phase[1]], [0, 1], projection=:polar, yticks=false, color=:grey, lw=0.2, legend=nothing)
    for idx in 2:length(phase_diff)
        p5 = Plots.plot!([0, s2_phase[idx]], [0, 1], projection=:polar, color=:grey, lw=0.2)
    end

    p6 = Plots.plot([0, phase_diff[1]], [0, 1], projection=:polar, yticks=false, color=:black, lw=0.2, legend=nothing, title="Phases difference and PLI = $pli")
    for idx in 2:length(phase_diff)
        p6 = Plots.plot!([0, phase_diff[idx]], [0, 1], projection=:polar, color=:black, lw=0.2)
    end
    
    p = Plots.plot(p1, p2, p3, p4, p5, p6,
             layout=(3, 2),
             titlefontsize=8,
             xlabelfontsize=6,
             ylabelfontsize=6,
             xtickfontsize=4,
             ytickfontsize=4,
             palette=palette;
             kwargs...)

    return p
end

"""
    eeg_plot_itpc_s(eeg; <keyword arguments>)

Plot spectrogram of ITPC (Inter-Trial-Phase Clustering) for `channel` of `eeg`.

# Arguments

- `eeg::NeuroJ.EEG`
- `channel::Int64`
- `frq_lim::Tuple{Real, Real}`: frequency bounds for the spectrogram
- `frq_n::Int64`: number of frequencies
- `frq::Symbol=:lin`: linear (:lin) or logarithmic (:log) frequencies
- `z::Bool=false`: plot ITPCz instead of ITPC
- `w::Union{Vector{<:Real}, Nothing}=nothing`: optional vector of epochs/trials weights for wITPC calculation
- `xlabel::String="Time [s]"`: x-axis label
- `ylabel::String="Frequency [Hz]"`: y-axis label
- `title::String="ITPC spectrogram"`: plot title
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_itpc_s(eeg::NeuroJ.EEG; channel::Int64, frq_lim::Tuple{Real, Real}, frq_n::Int64, frq::Symbol=:lin, z::Bool=false, w::Union{Vector{<:Real}, Nothing}=nothing, xlabel::String="Time [s]", ylabel::String="Frequency [Hz]", title::String="", mono::Bool=false, kwargs...)

    mono == true ? palette = :grays : palette = :darktest
        title == "" && (title = "ITPC spectrogram\nchannel: $channel")
    
    itpc_s, itpc_z_s, frq_list = eeg_itpc_s(eeg, channel=channel, frq_lim=frq_lim, frq_n=frq_n, frq=frq)

    z == false && (s = itpc_s)
    z == true && (s = itpc_z_s)

    p = Plots.heatmap(eeg.eeg_epochs_time[:, 1],
                frq_list,
                s,
                title=title,
                xlabel=xlabel,
                ylabel=ylabel,
                xticks=_xticks(eeg.eeg_epochs_time[:, 1]),
                titlefontsize=8,
                xlabelfontsize=6,
                ylabelfontsize=6,
                xtickfontsize=4,
                ytickfontsize=4,
                seriescolor=palette;
                kwargs...)

    return p
end


"""
    eeg_plot_itpc_f(eeg; <keyword arguments>)

Plot time-frequency plot of ITPC (Inter-Trial-Phase Clustering) for `channel` of `eeg` for frequency `f`.

# Arguments

- `eeg::NeuroJ.EEG`
- `channel::Int64`
- `f::Int64`: frequency to plot
- `frq_lim::Tuple{Real, Real}`: frequency bounds for the spectrogram
- `frq_n::Int64`: number of frequencies
- `frq::Symbol=:lin`: linear (:lin) or logarithmic (:log) frequencies
- `z::Bool=false`: plot ITPCz instead of ITPC
- `w::Union{Vector{<:Real}, Nothing}=nothing`: optional vector of epochs/trials weights for wITPC calculation
- `xlabel::String="Time [s]"`: x-axis label
- `ylabel::String="Frequency [Hz]"`: y-axis label
- `title::String=""`: plot title
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_itpc_f(eeg::NeuroJ.EEG; channel::Int64, frq_lim::Tuple{Real, Real}, frq_n::Int64, frq::Symbol=:lin, f::Int64, z::Bool=false, w::Union{Vector{<:Real}, Nothing}=nothing, xlabel::String="Time [s]", ylabel::String="ITPC", title::String="", mono::Bool=false, kwargs...)

    mono == true ? palette = :grays : palette = :darktest
        f < 0 && throw(ArgumentError("f must be > 0."))
    f > eeg_sr(eeg) ÷ 2 && throw(ArgumentError("f must be ≤ $(eeg_sr(eeg) ÷ 2)."))

    itpc_s, itpc_z_s, frq_list = eeg_itpc_s(eeg, channel=channel, frq_lim=frq_lim, frq_n=frq_n, frq=frq, w=w)
    title == "" && (title = "ITPC at frequency $(vsearch(f, frq_list)) Hz\nchannel: $channel")

    z == false && (s = @view itpc_s[vsearch(f, frq_list), :])
    z == true && (s = @view itpc_z_s[vsearch(f, frq_list), :])

    p = Plots.plot(eeg.eeg_epochs_time[:, 1],
             s,
             title=title,
             xlabel=xlabel,
             ylabel=ylabel,
             xticks=_xticks(eeg.eeg_epochs_time[:, 1]),
             titlefontsize=8,
             xlabelfontsize=6,
             ylabelfontsize=6,
             xtickfontsize=4,
             ytickfontsize=4,
             seriescolor=palette,
             label=false;
             kwargs...)

    return p
end

"""
    eeg_plot_connections(eeg; <keyword arguments>)

Plot connections between `eeg` electrodes.

# Arguments

- `eeg:EEG`
- `m::Matrix{<:Real}`: matrix of connections weights
- `threshold::Float64`: plot all connection above threshold
- `threshold_type::Symbol=:g`: rule for thresholding: :eq =, :geq ≥, :leq ≤, :g >, :l <
- `labels::Bool=false`: plot electrode labels
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_connections(eeg::NeuroJ.EEG; m::Matrix{<:Real}, threshold::Float64, threshold_type::Symbol=:g, labels::Bool=true, mono::Bool=false, kwargs...)

    mono == true ? palette = :grays : palette = :darktest

    threshold_type in [:eq, :geq, :leq, :g, :l] || throw(ArgumentError("threshold_type must be :eq, :geq, :leq, :g, :l."))

    eeg.eeg_header[:channel_locations] == false && throw(ArgumentError("Electrode locations not available, use eeg_load_electrodes() first."))
    eeg_channel_n(eeg, type=:eeg) < eeg_channel_n(eeg, type=:all) && throw(ArgumentError("EEG contains non-eeg channels (e.g. ECG or EMG), remove them before plotting."))

    # select channels, default is all channels
    channel = length(eeg_labels(eeg))

    # look for location data
    loc_x = zeros(eeg_channel_n(eeg, type=:eeg))
    loc_y = zeros(eeg_channel_n(eeg, type=:eeg))
    for idx in 1:eeg_channel_n(eeg, type=:eeg)
        loc_y[idx], loc_x[idx] = pol2cart(eeg.eeg_header[:loc_radius][idx], 
                                          eeg.eeg_header[:loc_theta][idx])
    end
    loc_x = round.(loc_x, digits=2)
    loc_y = round.(loc_y, digits=2)
    x_lim = (findmin(loc_x)[1] * 1.8, findmax(loc_x)[1] * 1.8)
    y_lim = (findmin(loc_y)[1] * 1.8, findmax(loc_y)[1] * 1.8)

    p = Plots.plot(grid=true,
             framestyle=:none,
             palette=palette,
             markerstrokewidth=0,
             border=:none,
             aspect_ratio=1,
             margins=-20Plots.px,
             titlefontsize=8;
             kwargs...)
    p = Plots.plot!(loc_x,
              loc_y,
              seriestype=:scatter,
              color=:black,
              alpha=0.2,
              xlims=x_lim,
              ylims=y_lim,
              grid=true,
              label="",
              markersize=4,
              markerstrokewidth=0,
              markerstrokealpha=0;
              kwargs...)
    if labels == true
        for idx in 1:length(eeg_labels(eeg))
            Plots.plot!(annotation=(loc_x[idx], loc_y[idx] + 0.05, Plots.text(eeg_labels(eeg)[idx], pointsize=4)))
        end
        p = Plots.plot!()
    end
    # for some reason head is enlarged for channel > 1
    eeg_tmp = eeg_keep_channel(eeg, channel=1)
    loc_x = zeros(eeg_channel_n(eeg_tmp, type=:eeg))
    loc_y = zeros(eeg_channel_n(eeg_tmp, type=:eeg))
    loc_y[1], loc_x[1] = pol2cart(eeg_tmp.eeg_header[:loc_radius][1], 
                                  eeg_tmp.eeg_header[:loc_theta][1])
    hd = _draw_head(p, loc_x, loc_x, head_labels=false)
    Plots.plot!(hd)

    loc_x = zeros(eeg_channel_n(eeg, type=:eeg))
    loc_y = zeros(eeg_channel_n(eeg, type=:eeg))
    for idx in 1:eeg_channel_n(eeg, type=:eeg)
        loc_y[idx], loc_x[idx] = pol2cart(eeg.eeg_header[:loc_radius][idx], 
                                          eeg.eeg_header[:loc_theta][idx])
    end

    for idx1 in 1:size(m, 1)
        for idx2 in 1:size(m, 1)
            if threshold_type === :g
                if m[idx1, idx2] > threshold
                    Plots.plot!([loc_x[idx1], loc_x[idx2]], [loc_y[idx1], loc_y[idx2]], lw=0.2, lc=:black, legend=false)
                end
            elseif threshold_type === :l
                if m[idx1, idx2] < threshold
                    Plots.plot!([loc_x[idx1], loc_x[idx2]], [loc_y[idx1], loc_y[idx2]], lw=0.2, lc=:black, legend=false)
                end
            elseif threshold_type === :eq
                if m[idx1, idx2] == threshold
                    Plots.plot!([loc_x[idx1], loc_x[idx2]], [loc_y[idx1], loc_y[idx2]], lw=0.2, lc=:black, legend=false)
                end
            elseif threshold_type === :leq
                if m[idx1, idx2] <= threshold
                    Plots.plot!([loc_x[idx1], loc_x[idx2]], [loc_y[idx1], loc_y[idx2]], lw=0.2, lc=:black, legend=false)
                end
            elseif threshold_type === :geq
                if m[idx1, idx2] >= threshold
                    Plots.plot!([loc_x[idx1], loc_x[idx2]], [loc_y[idx1], loc_y[idx2]], lw=0.2, lc=:black, legend=false)
                end
            end
        end
    end

    Plots.plot(p)

    return p
end

"""
    plot_psd_3dw(signal; <keyword arguments>)

Plot 3-d waterfall plot of `signal` channels power spectrum density.

# Arguments

- `signal::Matrix{Float64}`
- `fs::Int64`: sampling frequency
- `norm::Bool=true`: normalize powers to dB
- `mw::Bool=false`: if true use Morlet wavelet convolution
- `mt::Bool=false`: if true use multi-tapered periodogram
- `frq_lim::Tuple{Real, Real}=(0, 0)`: x-axis limit
- `ncyc::Union{Int64, Tuple{Int64, Int64}}=6`: number of cycles for Morlet wavelet
- `xlabel::String="Frequency [Hz]"`: x-axis label
- `ylabel::String="Channel"`: y-axis label
- `zlabel::String=""`: y-axis label
- `title::String=""`: plot title
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function plot_psd_3dw(signal::Matrix{Float64}; fs::Int64, norm::Bool=true, mw::Bool=false, mt::Bool=false, frq_lim::Tuple{Real, Real}=(0, 0), ncyc::Union{Int64, Tuple{Int64, Int64}}=6, xlabel::String="Frequency [Hz]", ylabel::String="Channel", zlabel::String="", title::String="", mono::Bool=false, kwargs...)

    (mw == true && mt == true) && throw(ArgumentError("Both mw and mt must not be true."))

    frq_lim == (0, 0) && (frq_lim = (0, fs / 2))
    (frq_lim[1] < 0 || frq_lim[2] > fs / 2) && throw(ArgumentError("frq_lim must be ≥ 0 and ≤ $(fs / 2)."))
    frq_lim = tuple_order(frq_lim)

    fs <= 0 && throw(ArgumentError("fs must be > 0."))

    mono == true ? palette = :grays : palette = :darktest

    zlabel == "" && (norm == true ? zlabel = "Power [dB]" : zlabel = "Power [μV^2/Hz]")

    if mw == false
        p_tmp, f_tmp = s_psd(signal[1, :], fs=fs, norm=norm, mt=mt)
    else
        p_tmp, f_tmp = s_wspectrum(signal[1, :], fs=fs, norm=norm, frq_lim=frq_lim, frq_n=length(frq_lim[1]:frq_lim[2]), ncyc=ncyc)
    end

    channel_n = size(signal, 1)
    s_pow = zeros(channel_n, length(p_tmp))
    s_frq = zeros(length(f_tmp))
    for channel_idx in 1:channel_n
        s = @view signal[channel_idx, :]
        if mw == false
            s_pow[channel_idx, :], s_frq = s_psd(s, fs=fs, norm=norm, mt=mt)
        else
            s_pow[channel_idx, :], s_frq = s_wspectrum(s, fs=fs, norm=norm, frq_lim=frq_lim, frq_n=length(frq_lim[1]:frq_lim[2]), ncyc=ncyc)
        end
    end

    channel = ones(length(s_frq))

    p = Plots.plot(s_frq,
             channel,
             s_pow[1, :],
             xlabel=xlabel,
             ylabel=ylabel,
             zlabel=zlabel,
             xlims=frq_lim,
             legend=false,
             title=title,
             palette=palette,
             lw=0.2,
             lc=1,
             titlefontsize=8,
             xlabelfontsize=6,
             ylabelfontsize=6,
             xtickfontsize=4,
             ytickfontsize=4;
             kwargs...)

    for channel_idx in 2:channel_n
        if mono == false
            p = Plots.plot!(s_frq,
                      channel .* channel_idx,
                      s_pow[channel_idx, :],
                      lw=0.2,
                      lc=channel_idx;
                      kwargs...)
        else
            p = Plots.plot!(s_frq,
                      channel .* channel_idx,
                      s_pow[channel_idx, :],
                      lw=0.2,
                      lc=:black;
                      kwargs...)
        end            
    end
    p = Plots.plot!(yticks=collect(1:channel_n); 
              kwargs...)

    return p
end

"""
    eeg_plot_signal_psd_3d(eeg; <keyword arguments>)

Plot 3-d waterfall plot of `eeg` channels power spectrum density.

# Arguments

- `eeg::NeuroJ.EEG`: EEG object
- `epoch::Union{Int64, AbstractRange}=0`: epoch number to display
- `channel::Int64`: channel to display, default is all channels
- `offset::Int64=0`: displayed segment offset in samples
- `len::Int64=0`: displayed segment length in samples, default is 1 epoch or 20 seconds
- `type::Symbol=:w`: plot type: :w waterfall, :s surface
- `norm::Bool=true`: normalize powers to dB
- `mw::Bool=false`: if true use Morlet wavelet convolution
- `mt::Bool=false`: if true use multi-tapered periodogram
- `frq_lim::Tuple{Real, Real}=(0, 0)`: x-axis limit
- `ncyc::Union{Int64, Tuple{Int64, Int64}}=6`: number of cycles for Morlet wavelet
- `xlabel::String="Frequency [Hz]`: x-axis label
- `ylabel::String="Channel"`: y-axis label
- `zlabel::String=""`: y-axis label
- `title::String=""`: plot title
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_signal_psd_3d(eeg::NeuroJ.EEG; epoch::Union{Int64, AbstractRange}=0, channel::Union{Vector{Int64}, AbstractRange}, offset::Int64=0, len::Int64=0, type::Symbol=:w, norm::Bool=true, mw::Bool=false, mt::Bool=false, frq_lim::Tuple{Real, Real}=(0, 0), ncyc::Union{Int64, Tuple{Int64, Int64}}=6, xlabel::String="Frequency [Hz]", ylabel::String="Channel", zlabel::String="", title::String="", mono::Bool=false, kwargs...)

    (mw == true && mt == true) && throw(ArgumentError("Both mw and mt must not be true."))
    ylabel == "" && (norm == true ? ylabel = "Power [dB]" : ylabel = "Power [μV^2/Hz]")
    type in [:w, :s] || throw(ArgumentError("type must be :w or :s."))
    eeg_channel_n(eeg, type=:eeg) < eeg_channel_n(eeg, type=:all) && throw(ArgumentError("EEG contains non-eeg channels (e.g. ECG or EMG), remove them before plotting."))
    _check_channels(eeg, channel)

    fs = eeg_sr(eeg)
    frq_lim == (0, 0) && (frq_lim = (0, div(fs, 2)))
    frq_lim = tuple_order(frq_lim)
    (frq_lim[1] < 0 || frq_lim[2] > fs / 2) && throw(ArgumentError("frq_lim must be ≥ 0 and ≤ $(fs / 2)."))

    (epoch != 0 && len != 0) && throw(ArgumentError("Both epoch and len must not be specified."))

    epoch_tmp = epoch
    if epoch != 0
        # convert epochs to offset and len
        typeof(epoch) <: AbstractRange && (epoch = collect(epoch))
        _check_epochs(eeg, epoch)
        length(epoch) > 1 && sort!(epoch)
        len = eeg_epoch_len(eeg) * length(epoch)
        offset = eeg_epoch_len(eeg) * (epoch[1] - 1)
        epoch_tmp = epoch[1]:epoch[end]
        epoch = epoch[1]
    else
        # default length is one epoch or 20 seconds
        len == 0 && (len = _len(eeg, len, 20))
        epoch = floor(Int64, offset / eeg_epoch_len(eeg)) + 1
        epoch_tmp = (floor(Int64, offset / eeg_epoch_len(eeg)) + 1):(ceil(Int64, (offset + len) / eeg_epoch_len(eeg)))
    end

    # set epoch markers if len > epoch_len
    eeg_tmp, _ = _get_epoch_markers(eeg, offset, len)

    labels = eeg_labels(eeg)[channel]

    # get time vector
    if length(epoch) == 1 && offset + len <= eeg_epoch_len(eeg)
        t = eeg.eeg_epochs_time[(1 + offset):(offset + len), epoch]
        t[1] = floor(t[1], digits=2)
        t[end] = ceil(t[end], digits=2)
    else
        t = _get_t(eeg_tmp, offset, len)
    end

    _check_offset_len(eeg_tmp, offset, len)

    signal = eeg_tmp.eeg_signals[channel, (1 + offset):(offset + length(t)), 1]

    t_1, t_s1, t_2, t_s2 = _convert_t(t)

    epoch_tmp = _t2epoch(eeg, offset, len, epoch_tmp)
    epoch_tmp[end] == epoch_tmp[1] && (epoch_tmp = epoch_tmp[1])
    title == "" && (title = "PSD\n[frequency limit: $(frq_lim[1])-$(frq_lim[2]) Hz]\n[channels: $channel, epoch: $epoch_tmp, time window: $t_s1:$t_s2]")

    if type ===:w
        p = plot_psd_3dw(signal,
                         fs=fs,
                         norm=norm,
                         xlabel=xlabel,
                         ylabel=ylabel,
                         zlabel=zlabel,
                         mw=mw,
                         mt=mt,
                         frq_lim=frq_lim,
                         ncyc=ncyc,
                         title=title,
                         mono=mono;
                         kwargs...)
    else
        p = plot_psd_3ds(signal,
                         fs=fs,
                         norm=norm,
                         xlabel=xlabel,
                         ylabel=ylabel,
                         zlabel=zlabel,
                         mw=mw,
                         mt=mt,
                         frq_lim=frq_lim,
                         ncyc=ncyc,
                         title=title,
                         mono=mono;
                         kwargs...)
    end

    Plots.plot(p)

    return p
end

"""
    plot_psd_3ds(signal; <keyword arguments>)

Plot 3-d surface plot of `signal` channels power spectrum density.

# Arguments

- `signal::Matrix{Float64}`
- `fs::Int64`: sampling frequency
- `norm::Bool=true`: normalize powers to dB
- `mw::Bool=false`: if true use Morlet wavelet convolution
- `mt::Bool=false`: if true use multi-tapered periodogram
- `frq_lim::Tuple{Real, Real}=(0, 0)`: x-axis limit
- `ncyc::Union{Int64, Tuple{Int64, Int64}}=6`: number of cycles for Morlet wavelet
- `xlabel::String="Frequency [Hz]"`: x-axis label
- `ylabel="Channel"`: y-axis label
- `zlabel::String=""`: y-axis label
- `title::String=""`: plot title
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function plot_psd_3ds(signal::Matrix{Float64}; fs::Int64, norm::Bool=true, mw::Bool=false, mt::Bool=false, frq_lim::Tuple{Real, Real}=(0, 0), ncyc::Union{Int64, Tuple{Int64, Int64}}=6, xlabel="Frequency [Hz]", ylabel="Channel", zlabel::String="", title="", mono::Bool=false, kwargs...)

    (mw == true && mt == true) && throw(ArgumentError("Both mw and mt must not be true."))

    frq_lim == (0, 0) && (frq_lim = (0, fs / 2))
    (frq_lim[1] < 0 || frq_lim[2] > fs / 2) && throw(ArgumentError("frq_lim must be ≥ 0 and ≤ $(fs / 2)."))
    frq_lim = tuple_order(frq_lim)

    fs <= 0 && throw(ArgumentError("fs must be > 0."))

    mono == true ? palette = :grays : palette = :darktest

    zlabel == "" && (norm == true ? zlabel = "Power [dB]" : zlabel = "Power [μV^2/Hz]")

    if mw == false
        p_tmp, f_tmp = s_psd(signal[1, :], fs=fs, norm=norm, mt=mt)
    else
        p_tmp, f_tmp = s_wspectrum(signal[1, :], fs=fs, norm=norm, frq_lim=frq_lim, frq_n=length(frq_lim[1]:frq_lim[2]), ncyc=ncyc)
    end

    channel_n = size(signal, 1)
    s_pow = zeros(channel_n, length(p_tmp))
    s_frq = zeros(length(f_tmp))
    for channel_idx in 1:channel_n
        s = @view signal[channel_idx, :]
        if mw == false
                s_pow[channel_idx, :], s_frq = s_psd(s, fs=fs, norm=norm, mt=mt)
        else
            s_pow[channel_idx, :], s_frq = s_wspectrum(s, fs=fs, norm=norm, frq_lim=frq_lim, frq_n=length(frq_lim[1]:frq_lim[2]))
        end
    end

    channel = 1:channel_n

    p = Plots.plot(s_frq,
             channel,
             s_pow,
             seriestype=:surface,
             xlabel=xlabel,
             ylabel=ylabel,
             zlabel=zlabel,
             xlims=frq_lim,
             yticks=collect(1:channel_n),
             legend=false,
             title=title,
             palette=palette,
             titlefontsize=8,
             xlabelfontsize=6,
             ylabelfontsize=6,
             xtickfontsize=4,
             ytickfontsize=4;
             kwargs...)

    return p
end

"""
    plot_rel_psd(signal; <keyword arguments>)

Plot relative `signal` channel power spectrum density.

# Arguments

- `signal::Vector{<:Real}`
- `fs::Int64`: sampling frequency
- `norm::Bool=true`: normalize powers to dB
- `mt::Bool=false`: if true use multi-tapered periodogram
- `frq_lim::Tuple{Real, Real}=(0, 0)`: x-axis limit
- `xlabel::String="Frequency [Hz]"`: x-axis label
- `ylabel::String=""`: y-axis label
- `title::String=""`: plot title
- `mono::Bool=false`: use color or grey palette
- `f::Union{Tuple{Real, Real}, Nothing}=nothing`: calculate power relative to frequency range or total power
- `ax::Symbol=:linlin`: type of axes scaling
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function plot_rel_psd(signal::Vector{<:Real}; fs::Int64, norm::Bool=true, mt::Bool=false, frq_lim::Tuple{Real, Real}=(0, 0), xlabel::String="Frequency [Hz]", ylabel::String="", title::String="", mono::Bool=false, f::Union{Tuple{Real, Real}, Nothing}, ax::Symbol=:linlin, kwargs...)

    (mw == true && mt == true) && throw(ArgumentError("Both mw and mt must not be true."))
    ax in [:linlin, :loglin, :linlog, :loglog] || throw(ArgumentError("ax must be :linlin, :loglin, :linlog or :loglog."))

    fs <= 0 && throw(ArgumentError("fs must be > 0."))
    (frq_lim[1] < 0 || frq_lim[2] > fs / 2) && throw(ArgumentError("frq_lim must be ≥ 0 and ≤ $(fs / 2)."))
    frq_lim == (0, 0) && (frq_lim = (0, fs / 2))
    frq_lim = tuple_order(frq_lim)
    if f !== nothing
        f = tuple_order(f)
        (f[1] < 0 || f[2] > fs / 2) && throw(ArgumentError("f must be ≥ 0 and ≤ $(fs / 2)."))
    end
    s_pow, s_frq = s_rel_psd(signal, fs=fs, norm=norm, mt=mt, f=f)

    mono == true ? palette = :grays : palette = :darktest

    ylabel == "" && (norm == true ? ylabel = "Power [dB]" : ylabel = "Power [μV^2/Hz]")

    if ax === :linlin
        p = Plots.plot(s_frq,
                 s_pow,
                 xlabel=xlabel,
                 ylabel=ylabel,
                 xlims=frq_lim,
                 legend=false,
                 t=:line,
                 c=:black,
                 title=title,
                 palette=palette,
                 titlefontsize=8,
                 xlabelfontsize=6,
                 ylabelfontsize=6,
                 xtickfontsize=4,
                 ytickfontsize=4;
                 kwargs...)
    elseif ax === :loglin
        if frq_lim[1] == 0
            frq_lim = (0.1, frq_lim[2])
            @warn "Lower frequency bound truncated to 0.1 Hz"
        end
        s_frq[1] == 0 && (s_frq[1] = 0.1)
        p = Plots.plot(s_frq,
                 s_pow,
                 xaxis=:log10,
                 xticks=([0.1, 1, 10, 100], ["0.1", "1", "10", "100"]),
                 xlabel=xlabel,
                 ylabel=ylabel,
                 xlims=frq_lim,
                 legend=false,
                 t=:line,
                 c=:black,
                 title=title,
                 palette=palette,
                 titlefontsize=8,
                 xlabelfontsize=6,
                 ylabelfontsize=6,
                 xtickfontsize=4,
                 ytickfontsize=4;
                 kwargs...)
    elseif ax === :linlog
        if norm == false
            p = Plots.plot(s_frq,
                     s_pow,
                     yaxis=:log10,
                     xlabel=xlabel,
                     ylabel=ylabel,
                     xlims=frq_lim,
                     legend=false,
                     t=:line,
                     c=:black,
                     title=title,
                     palette=palette,
                     titlefontsize=8,
                     xlabelfontsize=6,
                     ylabelfontsize=6,
                     xtickfontsize=4,
                     ytickfontsize=4;
                     kwargs...)
        else
            p = Plots.plot(s_frq,
                     s_pow,
                     xlabel=xlabel,
                     ylabel=ylabel,
                     xlims=frq_lim,
                     legend=false,
                     t=:line,
                     c=:black,
                     title=title,
                     palette=palette,
                     titlefontsize=8,
                     xlabelfontsize=6,
                     ylabelfontsize=6,
                     xtickfontsize=4,
                     ytickfontsize=4;
                     kwargs...)
        end
    elseif ax === :loglog
        if frq_lim[1] == 0
            frq_lim = (0.1, frq_lim[2])
            @warn "Lower frequency bound truncated to 0.1 Hz"
        end
        s_frq[1] == 0 && (s_frq[1] = 0.1)
        if norm == false
            p = Plots.plot(s_frq,
                     s_pow,
                     xaxis=:log10,
                     yaxis=:log10,
                     xticks=([0.1, 1, 10, 100], ["0.1", "1", "10", "100"]),
                     xlabel=xlabel,
                     ylabel=ylabel,
                     xlims=frq_lim,
                     legend=false,
                     t=:line,
                     c=:black,
                     title=title,
                     palette=palette,
                     titlefontsize=8,
                     xlabelfontsize=6,
                     ylabelfontsize=6,
                     xtickfontsize=4,
                     ytickfontsize=4;
                     kwargs...)
        else
            p = Plots.plot(s_frq,
                     s_pow,
                     xaxis=:log10,
                     xlabel=xlabel,
                     ylabel=ylabel,
                     xlims=frq_lim,
                     legend=false,
                     t=:line,
                     c=:black,
                     title=title,
                     palette=palette,
                     titlefontsize=8,
                     xlabelfontsize=6,
                     ylabelfontsize=6,
                     xtickfontsize=4,
                     ytickfontsize=4;
                     kwargs...)
        end
    end

    return p
end

"""
    eeg_plot_electrode(eeg; <keyword arguments>)

Plot `eeg` electrodes.

# Arguments

- `eeg:EEG`
- `channel::Int64`: channel to display
- `mono::Bool=false`: use color or grey palette
- `kwargs`: optional arguments for plot() function

# Returns

- `p::Plots.Plot{Plots.GRBackend}`
"""
function eeg_plot_electrode(eeg::NeuroJ.EEG; channel::Int64, kwargs...)

    eeg.eeg_header[:channel_locations] == false && throw(ArgumentError("Electrode locations not available, use eeg_load_electrodes() first."))
    eeg_channel_n(eeg, type=:eeg) < eeg_channel_n(eeg, type=:all) && throw(ArgumentError("EEG contains non-eeg channels (e.g. ECG or EMG), remove them before plotting."))

    _check_channels(eeg, channel)

    # get axis limits
    loc_x = zeros(eeg_channel_n(eeg, type=:eeg))
    loc_y = zeros(eeg_channel_n(eeg, type=:eeg))
    for idx in 1:eeg_channel_n(eeg, type=:eeg)
        loc_y[idx], loc_x[idx] = pol2cart(eeg.eeg_header[:loc_radius][idx], 
                                          eeg.eeg_header[:loc_theta][idx])
    end
    loc_x = round.(loc_x, digits=2)
    loc_y = round.(loc_y, digits=2)
    x_lim = (findmin(loc_x)[1] * 1.8, findmax(loc_x)[1] * 1.8)
    y_lim = (findmin(loc_y)[1] * 1.8, findmax(loc_y)[1] * 1.8)

    eeg_tmp = eeg_keep_channel(eeg, channel=channel)
    loc_y_ch, loc_x_ch = pol2cart(eeg_tmp.eeg_header[:loc_radius][1], 
                                  eeg_tmp.eeg_header[:loc_theta][1])
    loc_x_ch = round(loc_x_ch, digits=2)
    loc_y_ch = round(loc_y_ch, digits=2)
    p = Plots.plot((loc_x_ch, loc_y_ch),
             seriestype=:scatter,
             grid=true,
             framestyle=:none,
             size=(200, 200),
             border=:none,
             aspect_ratio=1,
             margins=-200Plots.px,
             titlefontsize=8,
             color=:black,
             fillcolor=:black,
             xlims=x_lim,
             ylims=x_lim,
             label="",
             markersize=2,
             markerstrokewidth=0,
             markerstrokealpha=0;
             kwargs...)
    hd = _draw_head(p, minimum([[loc_x[1]], [loc_y[1]]]), minimum([[loc_x[1]], [loc_y[1]]]), head_labels=false)
    p = Plots.plot!(hd)
    Plots.plot(p)

    return p
end

"""
    eeg_plot_electrodes3d(eeg; <keyword arguments>)

Plot `eeg` electrodes.

# Arguments

- `eeg:EEG`
- `channel::Union{Int64, Vector{Int64}, AbstractRange}=0`: channel to display, default is all channels
- `selected::Union{Int64, Vector{Int64}, AbstractRange}=0`: which channel should be highlighted
- `labels::Bool=true`: plot electrode labels
- `head_labels::Bool=false`: plot head labels
- `mono::Bool=false`: use color or grey palette

# Returns

- `f::GLMakie.Figure`
"""
function eeg_plot_electrodes3d(eeg::NeuroJ.EEG; channel::Union{Int64, Vector{Int64}, AbstractRange}=0, selected::Union{Int64, Vector{Int64}, AbstractRange}=0, labels::Bool=true, head_labels::Bool=true, mono::Bool=false)

    eeg.eeg_header[:channel_locations] == false && throw(ArgumentError("Electrode locations not available, use eeg_load_electrodes() first."))
    eeg_channel_n(eeg, type=:eeg) < eeg_channel_n(eeg, type=:all) && throw(ArgumentError("EEG contains non-eeg channels (e.g. ECG or EMG), remove them before plotting."))

    mono == true ? palette = :grays : palette = :darktest

    # select channels, default is all channels
    channel = _select_channels(eeg, channel, 0)
    _check_channels(eeg, channel)

    eeg_tmp = eeg_keep_channel(eeg, channel=channel)
    # selected channels
    if selected != 0
        length(selected) > 1 && sort!(selected)
        for idx in 1:length(selected)
            (selected[idx] < 1 || selected[idx] > eeg_tmp.eeg_header[:channel_n]) && throw(ArgumentError("selected must be ≥ 1 and ≤ $(eeg_tmp.eeg_header[:channel_n])."))
        end
        typeof(selected) <: AbstractRange && (selected = collect(selected))
        length(selected) > 1 && (intersect(selected, channel) == selected || throw(ArgumentError("channel must include selected.")))
        length(selected) == 1 && (intersect(selected, channel) == [selected] || throw(ArgumentError("channel must include selected.")))
    end

    # use Cartesian coordinates
    if :loc_x in keys(eeg_tmp.eeg_header) && :loc_y in keys(eeg_tmp.eeg_header) && :loc_z in keys(eeg_tmp.eeg_header)
        loc_x = eeg_tmp.eeg_header[:loc_x]
        loc_y = eeg_tmp.eeg_header[:loc_y]
        loc_z = eeg_tmp.eeg_header[:loc_z]
    else
        @warn "EEG does not contain Cartesian 3D coordinates, trying spherical coordinates."
        if :loc_radius_sph in keys(eeg_tmp.eeg_header) && :loc_theta_sph in keys(eeg_tmp.eeg_header) && :loc_phi_sph in keys(eeg_tmp.eeg_header)
            loc_x = zeros(eeg_channel_n(eeg_tmp, type=:eeg))
            loc_y = zeros(eeg_channel_n(eeg_tmp, type=:eeg))
            loc_z = zeros(eeg_channel_n(eeg_tmp, type=:eeg))
            for idx in 1:eeg_channel_n(eeg_tmp, type=:eeg)
                loc_y[idx], loc_z[idx], loc_x[idx] = sph2cart(eeg_tmp.eeg_header[:loc_radius_sph][idx], 
                                                              eeg_tmp.eeg_header[:loc_theta_sph][idx], 
                                                              eeg_tmp.eeg_header[:loc_phi_sph][idx])
            end
        else
            throw(ArgumentError("EEG does not contain Cartesian 3D nor spherical coordinates."))
        end
    end

    loc_x = round.(loc_x, digits=2)
    loc_y = round.(loc_y, digits=2)
    loc_z = round.(loc_z, digits=2)
    x_lim = (findmin(loc_x)[1] * 1.2, findmax(loc_x)[1] * 1.2)
    y_lim = (findmin(loc_y)[1] * 1.2, findmax(loc_y)[1] * 1.2)
    z_lim = (findmin(loc_z)[1] * 1.2, findmax(loc_z)[1] * 1.2)

    plot_size = 800
    marker_size = 15
    font_size = 15

    f = Figure(; resolution=(plot_size, plot_size))
    ax = Axis3(f[1, 1]; aspect=(1, 1, 0.5), perspectiveness=0.5, limits = (y_lim, x_lim, z_lim))
    hidedecorations!(ax, grid=true, ticks=true)
    if selected != 0 && length(selected) == eeg_tmp.eeg_header[:channel_n]
        for idx in 1:eeg_tmp.eeg_header[:channel_n]
            if mono != true
                GLMakie.scatter!(ax, -loc_y[idx], loc_x[idx], loc_z[idx], markersize=marker_size)
            else
                GLMakie.scatter!(ax, -loc_y[idx], loc_x[idx], loc_z[idx], markersize=marker_size, color=:black)
            end                
        end
    elseif selected == 0
        GLMakie.scatter!(ax, -loc_y, loc_x, loc_z, markersize=marker_size, color=:gray)
    elseif selected != 0 && length(selected) != eeg_tmp.eeg_header[:channel_n]
        loc_x_tmp = deepcopy(loc_x)
        loc_y_tmp = deepcopy(loc_y)
        loc_z_tmp = deepcopy(loc_z)
        deleteat!(loc_x_tmp, selected)
        deleteat!(loc_y_tmp, selected)
        deleteat!(loc_z_tmp, selected)
        GLMakie.scatter!(ax, -loc_y_tmp, loc_x_tmp, loc_z_tmp, markersize=marker_size, color=:grey)
        eeg_tmp = eeg_keep_channel(eeg, channel=selected)
        for idx in 1:eeg_tmp.eeg_header[:channel_n]
            if mono != true
                GLMakie.scatter!(ax, -loc_y[idx], loc_x[idx], loc_z[idx], markersize=marker_size)
            else
                GLMakie.scatter!(ax, -loc_y[idx], loc_x[idx], loc_z[idx], markersize=marker_size, color=:black)
            end                
        end
    end
    if labels == true
        for idx in 1:length(eeg_labels(eeg_tmp))
            GLMakie.text!(ax, eeg_labels(eeg_tmp)[idx], position=(-loc_y[idx], loc_x[idx], loc_z[idx]), textsize=font_size)
        end
    end
    if head_labels == true
        GLMakie.text!(ax, "N", position=(0, 1, 0), textsize = font_size)
        GLMakie.text!(ax, "I", position=(0, -1, 0), textsize = font_size)
        GLMakie.text!(ax, "L", position=(-1, 0, 0.5), textsize = font_size)
        GLMakie.text!(ax, "R", position=(1, 0, 0.5), textsize = font_size)
    end
    f

    return f
end