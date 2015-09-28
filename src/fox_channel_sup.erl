-module(fox_channel_sup).
-behaviour(supervisor).

-export([start_link/0, start_worker/3, init/1]).

-include("otp_types.hrl").
-include("fox.hrl").


-spec(start_link() -> {ok, pid()}).
start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).


-spec start_worker(pid(), module(), list()) -> {ok | pid()}.
start_worker(ChannelPid, ConsumerModule, ConsumerModuleArgs) ->
    supervisor:start_child(?MODULE, [ChannelPid, ConsumerModule, ConsumerModuleArgs]).


-spec(init(gs_args()) -> sup_init_reply()).
init(_Args) ->
    Worker = {fox_channel_consumer,
              {fox_channel_consumer, start_link, []},
              transient, 2000, worker,
              [fox_channel_consumer]},
    {ok, {{simple_one_for_one, 10, 60}, [Worker]}}.
