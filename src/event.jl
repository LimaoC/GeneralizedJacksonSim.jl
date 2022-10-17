"""
This file contains the Event implementation and related functionality.
"""

"""A generic abstract Event type."""
abstract type Event end

"""
An event that signifies an arrival from outside the system to the server `q`.
"""
struct ExternalArrivalEvent <: Event
    q::Int64
end
struct CustomerExternalArrivalEvent <: Event
    q::Int64
end

"""An event that signifies the end of a service at the `q`th server."""
struct EndOfServiceEvent <: Event
    q::Int64
end
struct CustomerEndOfServiceEvent <: Event
    q::Int64
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

function process_event(time::Float64, state::State, event::Event) end

"""
    process_event(time::Float64, state::QueueNetworkState, event::ExternalArrivalEvent)

Process an arrival event from outside the system, and spawns a list of events that occur as
a consequence of this arrival.

On arrival, if the server is free (no jobs in the buffer/queue), the job starts to receive
service. If the server is busy, the job queues for service and waits for its turn.

The time between external arrival events for a given server is exponentially distributed,
and the service duration is gamma distributed.
"""
function process_event(time::Float64, state::QueueNetworkState, event::ExternalArrivalEvent)
    q = event.q
    state.queues[q] += 1  # add to queue
    state.arrivals[q] += 1  # record arrival
    new_timed_events = TimedEvent[]

    # prepare next external arrival for this particular server
    push!(new_timed_events,
        TimedEvent(ExternalArrivalEvent(q), time + next_arrival_time(state, q)))

    # start serving this job if it is the only one in the queue
    if state.queues[q] == 1
        push!(new_timed_events,
            TimedEvent(EndOfServiceEvent(q), time + next_service_time(state, q)))
    end
    return new_timed_events
end

"""
    process_event(time::Float64, state::QueueNetworkState, event::EndOfServiceEvent)

Process an end-of-service event, and spawns a list of events that occur as a consequence of
this end of service.

When a job completes service at a buffer, it either leaves the system, or moves to another
buffer (both happen immediately). After completing service in server i, a job moves to
server j with probability P[i, j], where P is the routing matrix.
"""
function process_event(time::Float64, state::QueueNetworkState, event::EndOfServiceEvent)
    q = event.q
    state.queues[q] -= 1  # remove from queue
    @assert state.queues[q] >= 0
    new_timed_events = TimedEvent[]

    # if there is another customer in the queue, start serving them
    if state.queues[q] > 0
        service_time = next_service_time(state, q)
        push!(new_timed_events, TimedEvent(EndOfServiceEvent(q), time + service_time))
    end

    # simulate the next location for this job; indices 1:L are the probabilities of moving
    # to another server in the system, and the last index is the probability of exiting
    # the system
    L = state.net.L
    next_loc_weights = state.net.P[q, :]
    push!(next_loc_weights, 1 - sum(next_loc_weights))
    @assert sum(next_loc_weights) == 1
    next_loc = sample(1:L+1, Weights(next_loc_weights))

    if next_loc <= L
        state.queues[next_loc] += 1  # job is staying in the system
        state.arrivals[next_loc] += 1  # record arrival

        # start serving job if it is the only one in the queue
        if state.queues[next_loc] == 1
            service_time = next_service_time(state, next_loc)
            push!(new_timed_events,
                TimedEvent(EndOfServiceEvent(next_loc), time + service_time))
        end
    end
    return new_timed_events
end

"""
    process_event(time::Float64, state::CustomerQueueNetworkState,
                  event::CustomerExternalArrivalEvent)

Process an arrival event from outside the system, and spawns a list of events that occur as
a consequence of this arrival.

On arrival, a Customer is created with arrival time `time`. If the server is free (no jobs
in the buffer/queue), the job starts to receive. If the server is busy, the job queues for
service and waits for its turn.

The time between external arrival events for a given server is exponentially distributed,
and the service duration is gamma distributed.
"""
function process_event(time::Float64, state::CustomerQueueNetworkState,
                       event::CustomerExternalArrivalEvent)
    q = event.q
    enqueue!(state.queues[q], Customer(time, -1.0))  # add new customer to queue
    state.arrivals[q] += 1  # record arrival
    new_timed_events = TimedEvent[]

    # prepare next external arrival for this particular server
    push!(new_timed_events,
        TimedEvent(CustomerExternalArrivalEvent(q), time + next_arrival_time(state, q)))

    # start serving this job if it is the only one in the queue
    if length(state.queues[q]) == 1
        push!(new_timed_events,
            TimedEvent(CustomerEndOfServiceEvent(q), time + next_service_time(state, q)))
    end
    return new_timed_events
end

"""
    process_event(time::Float64, state::QueueNetworkState, event::EndOfServiceEvent)

Process an end-of-service event, and spawns a list of events that occur as a consequence of
this end of service.

When a job completes service at a buffer, it either leaves the system, or moves to another
buffer (both happen immediately). After completing service in server i, a job moves to
server j with probability P[i, j], where P is the routing matrix.
"""
function process_event(time::Float64, state::CustomerQueueNetworkState,
                       event::CustomerEndOfServiceEvent)
    q = event.q
    customer = dequeue!(state.queues[q])  # remove from queue
    @assert length(state.queues[q]) >= 0
    new_timed_events = TimedEvent[]

    # if there is another customer in the queue, start serving them
    if length(state.queues[q]) > 0
        push!(new_timed_events,
            TimedEvent(CustomerEndOfServiceEvent(q), time + next_service_time(state, q)))
    end

    # simulate the next location for this job; indices 1:L are the probabilities of moving
    # to another server in the system, and the last index is the probability of exiting
    # the system
    L = state.net.L
    next_loc_weights = state.net.P[q, :]
    push!(next_loc_weights, 1 - sum(next_loc_weights))
    @assert sum(next_loc_weights) == 1
    next_loc = sample(1:L+1, Weights(next_loc_weights))

    if next_loc <= L
        enqueue!(state.queues[next_loc], customer)  # job is staying in the system
        state.arrivals[next_loc] += 1  # record arrival

        # start serving job if it is the only one in the queue
        if length(state.queues[next_loc]) == 1
            service_time = next_service_time(state, next_loc)
            push!(new_timed_events,
                TimedEvent(CustomerEndOfServiceEvent(next_loc), time + service_time))
        end
    else # job leaving the system 
        customer.departure = time
        push!(state.departed_customers, customer)
    end
    return new_timed_events
end
