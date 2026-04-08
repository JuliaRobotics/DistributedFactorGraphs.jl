# ==============================================================================
# Timestamps
# ==============================================================================

# delta timestamps
calcDeltatime(from::Nanosecond, to::Nanosecond) = Dates.value(to - from) / 10^9

function calcDeltatime_ns(from::TimeDateZone, to::TimeDateZone)
    # TODO (-)(x::TimeDateZone, y::TimeDateZone) was very slow so manually calculated here
    # return Dates.value(convert(Nanosecond, to - from)) / 10^9
    # calculate the "fast part" (microsecond) of the delta timestamp in nanoseconds
    fast_to = convert(Nanosecond, Microsecond(to)) + Nanosecond(to)
    fast_from = convert(Nanosecond, Microsecond(from)) + Nanosecond(from)
    delta_fast = fast_to - fast_from
    # calculate the "slow part" (zoned date time) of the delta timestamp in nanoseconds
    delta_zoned = convert(Nanosecond, ZonedDateTime(to) - ZonedDateTime(from))
    return delta_zoned + delta_fast
end

function calcDeltatime(from::TimeDateZone, to::TimeDateZone)
    # TODO (-)(x::TimeDateZone, y::TimeDateZone) was very slow so manually calculated here
    # return Dates.value(convert(Nanosecond, to - from)) / 10^9
    return Dates.value(calcDeltatime_ns(from, to)) / 10^9
end

calcDeltatime(from_node, to_node) = calcDeltatime(from_node.timestamp, to_node.timestamp)

Timestamp(args...) = TimeDateZone(args...)
Timestamp(t::Nanosecond, zone = tz"UTC") = Timestamp(Val(:unix), t, zone)
Timestamp(t::Microsecond, zone = tz"UTC") = Timestamp(Val(:unix), Nanosecond(t), zone)
function Timestamp(epoch::Val{:unix}, t::Nanosecond, zone = tz"UTC")
    return TimeDateZone(TimeDate(1970) + t, zone)
end
function Timestamp(epoch::Val{:unix}, t::Float64, zone = tz"UTC")
    return Timestamp(epoch, Nanosecond(t * 10^9), zone)
end
Timestamp(t::Float64, zone = tz"UTC") = Timestamp(Val(:unix), t, zone)
function Timestamp(epoch::Val{:rata}, t::Float64, zone = tz"UTC")
    return TimeDateZone(convert(DateTime, Millisecond(t * 10^3)), zone)
end

function now_tdz(zone = tz"UTC")
    t = time()
    return Timestamp(t, zone)
end
