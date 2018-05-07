# Transient-Zone-Theory

This is an indicator I created for analyzing a stochastic process by classifying the series in different states.

## STOCHASTIC PROCESSES
Basic Notion
Often the systems we consider that evolve in time and we are interested in their dynamic behavior, usually involving some degree of randomness. This like:
The length of a queue.
The number of students passing the SAT each year.
The temperature outside.
The number of data packets in a network.

A stochastic process Xt or X(t) is a family of random variables index by a parameter t (usually time).
Formally, a stochastic process is a mapping from the sample space S to functions of t.
With each element e of S associated as Xt(e).
For a given value of e, Xt(e) is a function of time.
For a given value of t, Xt(e) is a random variable
For a given value of e and t, Xt(e) is a (fixed) number.
The function Xt(e) associated with a given value e is called the realization of the stochastic process (a.k.a. trajectory or sample path).

## Markov Process
A stochastic process is called a Markov Process when it has the Markov property:
The future path of a markov process, given its current state, and the past history before, depends only on the current state (not on how this state has been reached).
The current state contains all the information (summary of the past) that is needed to characterize the future (stochastic) behaviour of the process.
Given the state of the process at an instant its future and past are independent.

Example: A process with independent increments is always a Markov process (the increment is independent of all the previous increments which have given rise to the current state).

## Markov Chain
The use of the term Markov Chain in the literature is ambiguous: it defines that the process is either a discrete time process or a discrete state process.
Without loss of generality we can index the discrete instants of time by integers.
A Markov chain is thus a process Xn, n = 1,0,...
Similarly we can denote the states of the system by integers Xn = 0, 1,...(the set of states can be finite or countably infinite).
In the following we additionally assume that the process is time homogeneous.
A Markov Process of this kind is characterized by the (one-step) transition probabilities (transition from state i to j):
Time homogeneity: the transition probability does not depend on n.

## Classification of States
A set of states is closed, if none of its states leads to any of the states outside the set.
A single state which alone forms a closed set is called an absorbing state.
For an absorbing state, we have p = 1.
One may reach an absorbing state from other states, but one can’t get out.

Each state is either transient or recurrent.
A state i is transient if the probability of returning to the state is <1.
There is a non-zero probability that the system never returns to this state.
A state i is recurrent if the probability of returning to the state is 1.
With certainty, the system sometimes returns to this state.

Recurrent states are further classified according to the expectation of the Time it takes to return to the state:
Positive recurrent: expectation of first return time < 
Null recurrent: expectation of first return time = 


## The Theory

Proposition 1: Let XT(t) be the value of a stochastic process at any time t relative to time-frame T. Then, almost-surely, there exists positive integers k, h such that every value g[XT(t) -k, XT(t) + k] is h(T) - recurrent.

Definition 1: A value XT(t0) is h(T) - recurrent if whenever XT(t0) is between the high and low value of the period T, then at least one of the previous or next h periods passes through XT(t0).
