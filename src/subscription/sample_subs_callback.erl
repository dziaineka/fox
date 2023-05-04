-module(sample_subs_callback).
-behaviour(fox_subs_worker).

-export([init/2, handle/3, terminate/2]).

-include("fox.hrl").

-type(state() :: term()).


%%% module API

-spec init(pid(), list()) -> {ok, state()}.
init(Channel, Args) ->
    put('$module', ?MODULE),
    logger:notice("sample_subs_callback:init pid:~p channel:~p args:~0p", [self(), Channel, Args]),

    Exchange = <<"my_exchange">>,
    [Q, RK] = Args,

    ok = fox:declare_exchange(Channel, Exchange),

    #'queue.declare_ok'{} = fox:declare_queue(Channel, Q),
    ok = fox:bind_queue(Channel, Q, Exchange, RK),

    State = {Exchange, Q, RK},
    {ok, State}.


-spec handle(term(), pid(), state()) -> {ok, state()}.
handle(#'basic.consume_ok'{} = Data, Channel, State) ->
    logger:notice(
        "sample_subs_callback:handle basic.consume_ok pid:~p, channel:~p, Data:~0p",
        [self(), Channel, Data]),
    {ok, State};

handle({#'basic.deliver'{delivery_tag = Tag}, #amqp_msg{payload = Payload}}, Channel, State) ->
    logger:notice(
        "sample_subs_callback:handle basic.deliver pid:~p, channel:~p, Payload:~0p",
        [self(), Channel, Payload]),
    amqp_channel:cast(Channel, #'basic.ack'{delivery_tag = Tag}),
    {ok, State};

handle(#'basic.cancel'{} = Data, Channel, State) ->
    logger:notice(
        "sample_subs_callback:handle basic.cancel pid:~p, channel:~p, Data:~0p",
        [self(), Channel, Data]),
    {ok, State};

handle(Data, Channel, State) ->
    logger:error(
        "sample_subs_callback:handle pid:~p, channel:~p, unknown data:~0p",
        [self(), Channel, Data]),
    {ok, State}.


-spec terminate(pid(), state()) -> ok.
terminate(Channel, State) ->
    logger:notice(
        "sample_subs_callback:terminate pid:~p, channel:~p state:~0p",
        [self(), Channel, State]),
    {Exchange, Q, RK} = State,
    fox:unbind_queue(Channel, Q, Exchange, RK),
    fox:delete_queue(Channel, Q),
    ok.
