-module(sample_channel_consumer).
-behaviour(fox_channel_consumer).

-export([init/2, handle/3, terminate/2]).

-include("fox.hrl").
-include_lib("amqp_client/include/amqp_client.hrl").

-type(state() :: term()).


%%% module API

-spec init(pid(), list()) -> {ok, state()} | {{subscribe, [#'basic.consume'{}]}, state()}.
init(ChannelPid, Args) ->
    ?d("sample_channel_consumer:init channel:~p args:~p", [ChannelPid, Args]),

    Exchange = <<"my_exchange">>,
    Queue1 = <<"my_queue">>,
    Queue2 = <<"other_queue">>,
    RoutingKey1 = <<"my_key">>,
    RoutingKey2 = <<"my_key_2">>,

    ok = fox:declare_exchange(ChannelPid, Exchange),

    ok = fox:declare_queue(ChannelPid, Queue1),
    ok = fox:bind_queue(ChannelPid, Queue1, Exchange, RoutingKey1),

    ok = fox:declare_queue(ChannelPid, Queue2),
    ok = fox:bind_queue(ChannelPid, Queue2, Exchange, RoutingKey2),

    State = {Exchange, [{Queue1, RoutingKey1}, {Queue2, RoutingKey2}]},

    BC1 = #'basic.consume'{queue = Queue1},
    BC2 = #'basic.consume'{queue = Queue2},
    {{subscribe, [BC1, BC2]}, State}.


-spec handle(term(), pid(), state()) -> {ok, state()}.
handle({#'basic.deliver'{delivery_tag = Tag}, #amqp_msg{payload = Payload}}, ChannelPid, State) ->
    ?d("sample_channel_consumer:handle basic.deliver, Payload:~p", [Payload]),
    amqp_channel:cast(ChannelPid, #'basic.ack'{delivery_tag = Tag}),
    {ok, State};

handle(Data, _ChannelPid, State) ->
    error_logger:error_msg("sample_channel_consumer:handle, unknown data:~p", [Data]),
    {ok, State}.


-spec terminate(pid(), state()) -> ok.
terminate(ChannelPid, State) ->
    ?d("sample_channel_consumer:terminate channel:~p, state:~p", [ChannelPid, State]),
    {Exchange, Bindings} = State,
    lists:foreach(fun({Queue, RoutingKey}) ->
                          ok = fox:unbind_queue(ChannelPid, Queue, Exchange, RoutingKey),
                          ok = fox:delete_queue(ChannelPid, Queue)
                  end, Bindings),
    ok = fox:delete_exchange(ChannelPid, Exchange),
    ok.
