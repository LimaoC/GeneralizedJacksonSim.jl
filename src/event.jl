"""
This file contains the Event implementation and related functionality.
"""

"""A generic abstract Event type."""
abstract type Event end

"""
An event that signifies an arrival from inside the system (i.e., another server) to the
server `q`.
"""
@with_kw struct ArrivalEvent <: Event
    q::Int = 1
end

"""
An event that signifies an arrival from outside the system to the server `q`.
"""
@with_kw struct ExternalArrivalEvent <: Event
    q::Int = 1
end

"""An event that signifies the end of a service at the `q`th server."""
struct EndOfServiceEvent <: Event
    q::Int
end

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
    process_event(time::Float64, state::State, event::ExternalArrivalEvent)

Process an arrival event from outside the system.

On arrival, if the server is free (no jobs in the buffer/queue), the job starts to receive
service. If the server is busy, the job queues for service and waits for its turn.

The time between external arrival events for a given server is exponentially distributed,
and the service duration is gamma distributed.
"""
function process_event(time::Float64, state::State, event::ExternalArrivalEvent)
    state.queues[event.q] += 1  # add to queue
    new_timed_events = TimedEvent[]

    # prepare next external arrival for this particular server
    push!(new_timed_events,
          TimedEvent(ExternalArrivalEvent(q), time + next_arrival_time(state, event.q)))

    # start serving this job if it is the only one in the queue
    if state.queues[event.q] == 1
        push!(new_timed_events,
              TimedEvent(EndOfServiceEvent(event.q), time + next_service_time(state, 1)))
    end
    return new_timed_events
end
