import ICRC72Service "orchestratorService";

module {
  public type ReplayId = Nat;

  public type ReplayState = {
    #Pending;
    #Running;
    #Completed : Nat;
    #Canceled : Nat;
    #Errored : Text;
  };

  public type ReplayStatusUpdate = {
    replayId : ReplayId;
    status : ReplayState;
  };

  public type ReplayStatusUpdateResult = {
    #Ok : Null;
    #Err : ICRC72Service.GenericError;
  };

  public type ReplayStatus = {
    replayId : ReplayId;
    namespace : Text;
    initialConfig : ICRC72Service.ICRC16Map;
    filter : ?Text;
    skip : ?(Nat, Nat);
    stats : ICRC72Service.ICRC16Map;
    range : (Nat, ?Nat);
    status : ReplayState;
  };

  public type ReplayQuerySlice = {
    #ByPublisher : Principal;
    #ByNamespace : Text;
    #BySubscriber : Principal;
    #ByBroadcaster : Principal;
    #ByReplayId : ReplayId;
  };

  public type ReplayFilter = {
    statistics : ??[Text];
    slice : [ReplayQuerySlice];
  };

  public type Service = actor {
    icrc77_replay_status : ([ReplayStatusUpdate]) -> async [ReplayStatusUpdateResult];
    icrc77_get_replays : ({ prev : ?Nat; take : ?Nat; filter : ?ReplayFilter }) -> async [ReplayStatus];
  };
};
