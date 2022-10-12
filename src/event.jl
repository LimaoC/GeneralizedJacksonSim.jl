"""
This file contains the Event implementation and related functionality.
"""

"""A generic abstract Event type."""
abstract type Event end

"""An event that signifies an arrival into the system?"""
struct ArrivalEvent <: Event end

"""An event that signifies the end of a service."""
struct EndOfServiceEvent <: Event end

"""An event that ends the simulation."""
struct EndSimEvent <: Event end

"""An event that prints a log of the current simulation state."""
struct LogStateEvent <: Event end

"""
    TimedEvent

# Fields
- `event::Event`: the stored event
- `time::Float64`: the time at which the event takes place (starts)
"""
struct TimedEvent
    event::Event
    time::Float64
end

"""
Returns true if the first event takes place earlier than the second event.
"""
isless(te1::TimedEvent, te2::TimedEvent) = te1.time < te2.time

"""
Process an arrival event.

On arrival, if the server is free (no jobs in the buffer/queue), the job starts to receive
service. If the server is busy, the job queues for service and waits for its turn. Jobs may
arrive either after finishing service at another node, or directly from the outside world.

The service duration is gamma distributed.
"""
function process_event(time::Float64, state::State, event::ArrivalEvent)
    return []
end
