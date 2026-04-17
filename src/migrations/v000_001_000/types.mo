import Time "mo:core/Time";
import Nat "mo:core/Nat";
import Principal "mo:core/Principal";
import Text "mo:core/Text";
import Star "mo:star/star";
import ListLib "mo:core/List";
import BTreeLib "mo:stableheapbtreemap/BTree";
import SetLib "mo:core/Set";
import Iter "mo:core/Iter";
import Order "mo:core/Order";
import CM "../../../../../../ICDevs/projects/icrc-fungible-group/champ_map/src/lib";
import TT "mo:timer-tool";
import ICRC72Subscriber "../../../../icrc72-subscriber.mo/src/";
import BroadcasterService "../../broadcasterService";
// please do not import any types from your project outside migrations folder here
// it can lead to bugs when you change those types later, because migration types should not be changed
// you should also avoid importing these types anywhere in your project directly from here
// use MigrationTypes.Current property instead


module {

  public let BTree = BTreeLib;
  public module Set {
    public type Set<T> = SetLib.Set<T>;
    public let phash = Principal.compare;
    public let thash = Text.compare;
    public let nhash = Nat.compare;

    public func new<T>() : Set<T> = SetLib.empty<T>();
    public func size<T>(self : Set<T>) : Nat = SetLib.size(self);
    public func has<T>(self : Set<T>, compare : (T, T) -> Order.Order, value : T) : Bool = SetLib.contains(self, compare, value);
    public func add<T>(self : Set<T>, compare : (T, T) -> Order.Order, value : T) : () = SetLib.add(self, compare, value);
    public func remove<T>(self : Set<T>, compare : (T, T) -> Order.Order, value : T) : () = SetLib.remove(self, compare, value);
    public func delete<T>(self : Set<T>, compare : (T, T) -> Order.Order, value : T) : Bool {
      if (SetLib.contains(self, compare, value)) {
        SetLib.remove(self, compare, value);
        true;
      } else {
        false;
      };
    };
    public func toArray<T>(self : Set<T>) : [T] = SetLib.toArray(self);
    public func fromIter<T>(iter : Iter.Iter<T>, compare : (T, T) -> Order.Order) : Set<T> = SetLib.fromIter(iter, compare);
    public func keys<T>(self : Set<T>) : Iter.Iter<T> = SetLib.values(self);
  };

  public module Map {
    public type HashUtils<K> = CM.HashUtils<K>;
    public type Map<K, V> = { var inner : CM.Map<K, V> };
    public let ihash = CM.ihash;
    public let nhash = CM.nhash;
    public let thash = CM.thash;
    public let phash = CM.phash;
    public let bhash = CM.bhash;

    public func new<K, V>() : Map<K, V> = { var inner = CM.empty<K, V>() };
    public func get<K, V>(self : Map<K, V>, hashUtils : HashUtils<K>, key : K) : ?V = CM.get(self.inner, hashUtils, key);
    public func put<K, V>(self : Map<K, V>, hashUtils : HashUtils<K>, key : K, value : V) : () {
      self.inner := CM.put(self.inner, hashUtils, key, value);
    };
    public func remove<K, V>(self : Map<K, V>, hashUtils : HashUtils<K>, key : K) : () {
      self.inner := CM.remove(self.inner, hashUtils, key);
    };
    public func entries<K, V>(self : Map<K, V>) : Iter.Iter<(K, V)> = CM.entries(self.inner);
    public func toArray<K, V>(self : Map<K, V>) : [(K, V)] = CM.toArray(self.inner);
    public func size<K, V>(self : Map<K, V>) : Nat = CM.size(self.inner);
    public func fromIter<K, V>(iter : Iter.Iter<(K, V)>, hashUtils : HashUtils<K>) : Map<K, V> = {
      var inner = CM.fromIter(iter, hashUtils)
    };
  };

  public module Vector {
    public type Vector<T> = ListLib.List<T>;

    public func new<T>() : Vector<T> = ListLib.empty<T>();
    public func init<T>(size : Nat, initValue : T) : Vector<T> = ListLib.repeat(initValue, size);
    public func size<T>(self : Vector<T>) : Nat = ListLib.size(self);
    public func add<T>(self : Vector<T>, value : T) : () = ListLib.add(self, value);
    public func addFromIter<T>(self : Vector<T>, iter : Iter.Iter<T>) : () = ListLib.addAll(self, iter);
    public func clear<T>(self : Vector<T>) : () = ListLib.clear(self);
    public func vals<T>(self : Vector<T>) : Iter.Iter<T> = ListLib.values(self);
    public func toArray<T>(self : Vector<T>) : [T] = ListLib.toArray(self);
    public func getOpt<T>(self : Vector<T>, index : Nat) : ?T {
      if (index < ListLib.size(self)) {
        ?ListLib.at(self, index)
      } else {
        null
      }
    };
    public func put<T>(self : Vector<T>, index : Nat, value : T) : () = ListLib.put(self, index, value);
    public func indexOf<T>(element : T, self : Vector<T>, equal : (T, T) -> Bool) : ?Nat = ListLib.indexOf(self, equal, element);
    public func iterateItems<T>(self : Vector<T>, f : (Nat, T) -> ()) : () {
      var index : Nat = 0;
      for (item in ListLib.values(self)) {
        f(index, item);
        index += 1;
      };
    };
  };

  public type Namespace = Text;

  public type ICRC16Property = {
    name : Text;
    value : ICRC16;
    immutable : Bool;
  };

  public type ICRC16 = {
    #Array : [ICRC16];
    #Blob : Blob;
    #Bool : Bool;
    #Bytes : [Nat8];
    #Class : [ICRC16Property];
    #Float : Float;
    #Floats : [Float];
    #Int : Int;
    #Int16 : Int16;
    #Int32 : Int32;
    #Int64 : Int64;
    #Int8 : Int8;
    #Map : [(Text, ICRC16)];
    #ValueMap : [(ICRC16, ICRC16)];
    #Nat : Nat;
    #Nat16 : Nat16;
    #Nat32 : Nat32;
    #Nat64 : Nat64;
    #Nat8 : Nat8;
    #Nats : [Nat];
    #Option : ?ICRC16;
    #Principal : Principal;
    #Set : [ICRC16];
    #Text : Text;
  };

  //ICRC3 Value
  public type Value = {
    #Nat : Nat;
    #Int : Int;
    #Text : Text;
    #Blob : Blob;
    #Array : [Value];
    #Map : [(Text, Value)];
  };

  public type ICRC16Map = [(Text, ICRC16)];

  public type NewEvent = {
    namespace : Text;
    data : ICRC16;
    headers : ?ICRC16Map;
  };

  public type EmitableEvent = {
    broadcaster: Principal;
    eventId : Nat;
    prevEventId : ?Nat;
    timestamp : Nat;
    namespace : Text;
    source : Principal;
    data : ICRC16;
    headers : ?ICRC16Map;
  };



  public type Event = {
    eventId : Nat;
    prevEventId : ?Nat;
    timestamp : Nat;
    namespace : Text;
    source : Principal;
    data : ICRC16;
    headers : ?ICRC16Map;
  };

  public type EventNotification = {
      notificationId : Nat;
      eventId : Nat;
      prevEventId : ?Nat;
      timestamp : Nat;
      namespace : Text;
      data : ICRC16;
      source : Principal;
      headers : ?ICRC16Map;
      filter : ?Text;
  };

  public let CONST = {
    publisher = {
      actions = {
        drain = "icrc72:publisher:drain";
      };
      sys = "icrc72:publisher:sys:";
      broadcasters = {
        add = "icrc72:publisher:broadcaster:add";
        remove = "icrc72:publisher:broadcaster:remove";
        error = "icrc72:publisher:broadcaster:error";
      };
      replay = {
        add = "icrc77:publisher:replay:add";
        remove = "icrc77:publisher:replay:remove";
      };
    };
    broadcasters = {
      publisher={
        broadcasters = {
          add = "icrc72:broadcaster:publisher:broadcaster:add";
          remove = "icrc72:broadcaster:publisher:broadcaster:remove";
        };
      }
    };
    subscriber = {
      timers = {
        sendConfirmations = "icrc72:subscriber:timers:sendConfirmations";
      };
      sys = "icrc72:subscriber:sys:";
      broadcasters = {
        add = "icrc72:subscriber:broadcaster:add";
        remove = "icrc72:subscriber:broadcaster:remove";
        error = "icrc72:subscriber:broadcaster:error";
      };
    };
  };

  public type PublicationRegistration = {
    namespace : Text; // The namespace of the publication for categorization and filtering
    config : ICRC16Map; // Additional configuration or metadata about the publication
    memo: ?Blob;
    // publishers : ?[Principal]; // Optional list of publishers authorized to publish under this namespace
    // subscribers : ?[Principal]; // Optional list of subscribers authorized to subscribe to this namespace
    // mode : Nat; // Publication mode (e.g., sequential, ranked, etc.)
  };

  public type NewPublicationRegistration = {
    namespace : Text; // The namespace of the publication for categorization and filtering
    config : ICRC16Map; // Additional configuration or metadata about the publication
    memo: ?Blob;

    // publishers : ?[Principal]; // Optional list of publishers authorized to publish under this namespace
    // subscribers : ?[Principal]; // Optional list of subscribers authorized to subscribe to this namespace
    // mode : Nat; // Publication mode (e.g., sequential, ranked, etc.)
  };

  public type SubscriptionRegistration = {
    namespace : Text; // The namespace of the publication for categorization and filtering
    config : ICRC16Map; // Additional configuration or metadata about the publication
    memo: ?Blob;
  };


  public type SubscriberInterface = {
    handleNotification : ([Nat]) -> async ();
    registerSubscription : (SubscriptionRegistration) -> async Nat;
  };

  public type InitArgs ={
    restore : ?{
      previousEventIDs : [(Text, (Nat, Nat))]; //IDUsed, BroadcasterUsed
      pendingEvents: [EmitableEvent];
    };
  };

  public type Environment = {
    var addRecord: ?(([(Text, Value)], ?[(Text,Value)]) -> Nat);
    var generateId: ?((Text, State) -> Nat);
    icrc72Subscriber : ICRC72Subscriber.Subscriber;
    var icrc72OrchestratorCanister : Principal;
    var onEventPublishError : ?(<system>(NewEvent, BroadcasterService.PublishError) -> Bool);
    var onEventPublished : ?(<system>(NewEvent, ?BroadcasterService.PublishResult) -> ());
    var onPublisherReady : ?(<system>(State, Environment, Text) -> ());
    var icrc77ReplayNotify : ?(<system>(State, Environment, Nat, Text, (Nat, ?Nat), Principal) -> ()); // replayId, namespace, range, broadcaster
    tt: TT.TimerTool;
  };

  public type PublicationRecord = {
    namespace : Text;
    id: Nat;
  };

  public type Stats = {
    broadcasters: [(Text, [Principal])];
    publications: [(Nat, PublicationRecord)];
    previousEventIds: [(Text, (Nat, Nat))];
    pendingEvents: [EmitableEvent];
    replays: [(Nat, (Text, ?Principal, ?Text, ?(Nat, Nat), (Nat, ?Nat)))]; // ICRC77 replays
    replayStatus: [(Nat, (Nat, Bool))]; // ICRC77 replay status tracking
    eventHistory: [(Nat, Event)]; // Event history for replay functionality
    drainEventId: ?TT.ActionId;
    eventsProcessing: Bool;
    readyForPublications: Bool;
    error: ?Text;
    tt: TT.Stats;
    icrc72OrchestratorCanister: Principal;
    icrc72Subscriber: ICRC72Subscriber.Stats;
    orchestrator: Principal;
    log: [Text];
  };

  ///MARK: State
  public type State = {
    broadcasters : BTree.BTree<Text, Set.Set<Principal>>;
    publications : BTree.BTree<Nat, PublicationRecord>;
    publicationsByNamespace : BTree.BTree<Text, Nat>; 
    previousEventIDs : BTree.BTree<Text, (Nat, Nat)>; //Namespace, Publication, IDUsed
    pendingEvents: Vector.Vector<EmitableEvent>;
    replays : BTree.BTree<Nat, (Text, ?Principal, ?Text, ?(Nat, Nat), (Nat, ?Nat))>; //replayId -> (namespace, broadcaster, filter, skip, range)
    replayStatus: BTree.BTree<Nat, (Nat, Bool)>; //replayId -> (lastEventIdPublished, isCompleted)
    eventHistory : BTree.BTree<Nat, Event>; // eventId -> Event for replay functionality
 

    var drainEventId : ?TT.ActionId;
    var eventsProcessing : Bool;
    var readyForPublications: Bool;
    var error: ?Text;
  };
};