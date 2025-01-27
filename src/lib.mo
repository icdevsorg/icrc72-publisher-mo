import MigrationTypes "migrations/types";
import MigrationLib "migrations";
import BTree "mo:stableheapbtreemap/BTree";
import OrchestrationService "../../icrc72-orchestrator.mo/src/service";

import Buffer "mo:base/Buffer";
import D "mo:base/Debug";
import Error "mo:base/Error";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Star "mo:star/star";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Timer "mo:base/Timer";
import TT "../../timerTool/src/";
import ICRC72Subscriber "../../icrc72-subscriber.mo/src/";
import ICRC72BroadcasterService "../../icrc72-broadcaster.mo/src/service";
import ClassPlusLib "mo:class-plus";

module {

  public let Migration = MigrationLib;

  public type State = MigrationTypes.State;

  public type CurrentState = MigrationTypes.Current.State;

  public type Environment = MigrationTypes.Current.Environment;
  public type NewEvent = MigrationTypes.Current.NewEvent;
  public type EmitableEvent = MigrationTypes.Current.EmitableEvent;
  public type Event = MigrationTypes.Current.Event;
  public type EventNotification = MigrationTypes.Current.EventNotification;
  public type PublicationRegistration = MigrationTypes.Current.PublicationRegistration;
  public type PublicationRecord = MigrationTypes.Current.PublicationRecord;
  public type PublicationDeleteResult = OrchestrationService.PublicationDeleteResult;
  public type PublicationIdentifier = OrchestrationService.PublicationIdentifier;
  public type ICRC16Map = MigrationTypes.Current.ICRC16Map;
  public type InitArgs = MigrationTypes.Current.InitArgs;
  


  public let BTree = MigrationTypes.Current.BTree;
  public let Vector = MigrationTypes.Current.Vector;
  public let Set = MigrationTypes.Current.Set;
  public let CONST = MigrationTypes.Current.CONST;
  public let Map = MigrationTypes.Current.Map;
  public type Stats = MigrationTypes.Current.Stats;


  public let init = Migration.migrate;

  

  public func IncrementalIDStrategy(namespace: Text, state: CurrentState): Nat {

    //D.print("          PUBLISHER: IncrementalIDStrategy: " # debug_show(BTree.toArray(state.previousEventIDs)));

    //D.print("          PUBLISHER: IncrementalIDStrategy: " # debug_show(namespace));

    let prev = BTree.get(state.previousEventIDs, Text.compare, namespace);

    //D.print("          PUBLISHER: IncrementalIDStrategy: " # debug_show(prev));

    let (prevId, lastIndex) = switch(prev){
      case(?val) (?val.0, val.1);
      case(null) (null, 0);
    };

    //D.print("          PUBLISHER: IncrementalIDStrategy: " # debug_show(prevId) # " " # debug_show(lastIndex)); 

    let id = switch(prevId){
      case(?val) {
        let id = val + 1;
        id;
      };
      case(null) {
        0;
      };
    };

    //D.print("          PUBLISHER: IncrementalIDStrategy: " # debug_show(id));

    ignore BTree.insert(state.previousEventIDs, Text.compare, namespace, (id, (lastIndex+1)));

    //D.print("          PUBLISHER: IncrementalIDStrategy: toArray " # debug_show(BTree.toArray(state.previousEventIDs)));

    return id;
  };

  public func initialState() : State {#v0_0_0(#data)};
  public let currentStateVersion = #v0_1_0(#id);

  public let ONE_MINUTE = 60000000000 : Nat; //NanoSeconds
  public let FIVE_MINUTES = 300000000000 : Nat; //NanoSeconds
  public let ONE_SECOND = 1000000000 : Nat; //NanoSeconds
  public let THREE_SECONDS = 3000000000 : Nat; //NanoSeconds

  public type ClassPlus = ClassPlusLib.ClassPlus<
    Publisher, 
    State,
    InitArgs,
    Environment>;

  public func ClassPlusGetter(item: ?ClassPlus) : () -> Publisher {
    ClassPlusLib.ClassPlusGetter<Publisher, State, InitArgs, Environment>(item);
  };

  public func Init<system>(config : {
      manager: ClassPlusLib.ClassPlusInitializationManager;
      initialState: State;
      args : ?InitArgs;
      pullEnvironment : ?(() -> Environment);
      onInitialize: ?(Publisher -> async*());
      onStorageChange : ((State) ->())
    }) :()-> Publisher{

      D.print("Publisher Init");
      switch(config.pullEnvironment){
        case(?val) {
          D.print("pull environment has value");
         
        };
        case(null) {
          D.print("pull environment is null");
        };
      };  
      ClassPlusLib.ClassPlus<system,
        Publisher, 
        State,
        InitArgs,
        Environment>({config with constructor = Publisher}).get;
    };



  public class Publisher(stored: ?State, class_caller: Principal, canister: Principal, initial_class_argsargs: ?InitArgs, environment_passed: ?Environment, storageChanged: (State) -> ()){

    public let debug_channel = {
      var publish = true;
      var startup = true;
      var announce = true;
    };

    public var vecLog = Vector.new<Text>();

    private func d(doLog : Bool, message: Text) {
      if(doLog){
        Vector.add(vecLog, Nat.toText(Int.abs(Time.now())) # " " # message);
        if(Vector.size(vecLog) > 5000){
          vecLog := Vector.new<Text>();
        };
        D.print(message);
      };
    };

    let environment = switch(environment_passed){
      case(?val) val;
      case(null) {
        D.trap("Environment is required");
      };
    };

    var state : CurrentState = switch(stored){
      case(null) {
        let #v0_1_0(#data(foundState)) = init(initialState(),currentStateVersion, null, canister);
        foundState;
      };
      case(?val) {
        let #v0_1_0(#data(foundState)) = init(val, currentStateVersion, null, canister);
        foundState;
      };
    };

    public func getState() : CurrentState {state};

    public func getEnvironment() : Environment {environment};

    storageChanged(#v0_1_0(#data(state)));

    public var Orchestrator : OrchestrationService.Service = actor(
      Principal.toText(environment.icrc72OrchestratorCanister));

    

    private func natNow(): Nat{Int.abs(Time.now())};

    private func getMinBroadcaster(item: Set.Set<Principal>): ?Principal {
      if(Set.size(item) == 0){
        return null;
      };
      ?Set.toArray(item)[0];
    };


    // delete publication
    public func deletePublication(publicationId: PublicationIdentifier): async* PublicationDeleteResult {
      let ?publication = switch(publicationId){
        case(#namespace(val)){
          let ?foundPublicationId = BTree.get(state.publicationsByNamespace, Text.compare, val) else {
            return ?#Err(#NotFound);
          };
          BTree.get(state.publications, Nat.compare, foundPublicationId);
        };
        case(#publicationId(val)){
          BTree.get(state.publications, Nat.compare, val);
        };
      } else {
        return ?#Err(#NotFound);
      };

      let result = try{
        await Orchestrator.icrc72_delete_publication([{publication= publicationId;memo = null}]);
      } catch(e){
        return ?#Err(#GenericError({error_code=2943845; message=Error.message(e)}));
      };

      switch(result[0]){
        case(?#Ok(val)) {
          ignore BTree.delete(state.publications, Nat.compare, publication.id);
          ignore BTree.delete(state.publicationsByNamespace, Text.compare, publication.namespace);
          ?#Ok(val);
        };
        case(?#Err(val)) {
          ?#Err(val);
        };
        case(null) {
          ?#Err(#GenericError({error_code=3939484; message="Unknown Error"}));
        };
      };
    };
    // update publication
    public func updatePublication(updates: [OrchestrationService.PublicationUpdateRequest]): async* [OrchestrationService.PublicationUpdateResult] {

      let result = try{
        await Orchestrator.icrc72_update_publication(updates);
      } catch(e){
        return [?#Err(#GenericError({error_code=2943845; message=Error.message(e)}))];
      };

      return result;
    };

    private func getNextBroadcaster( item: Set.Set<Principal>, lastItem : Nat): ?Principal {
      if(Set.size(item) == 0){
        return null;
      };
      let thisItem = if(lastItem + 1 >= Set.size(item) ){
        0;
      } else {
        lastItem + 1;
      };
      let found = Set.toArray(item)[thisItem];
      ?found;
    };

    //allows a program to handle events that were not published
    public func publishWithHandler<system>(events: [NewEvent], handler: (NewEvent) -> ()) : [?Nat] {
      debug d(debug_channel.announce, "          PUBLISHER: Publishing Events with Handler: " # debug_show(events));
      let results = publish<system>(events);
      var x = 0;
      for(item in results.vals()){
        if(item == null){
          handler(events[x]);
        };
        x := x + 1;
      };
      results;
    };

    public func publishAsync<system>(events: [NewEvent]): async [?Nat] {
      debug d(debug_channel.announce, "          PUBLISHER: Publishing Events Async: " # debug_show(events));

      let results = processEvents(events);
     

      //no actions, just trigger the batch
      let groups = Map.new<Principal, Buffer.Buffer<EmitableEvent>>();

      let procItems = Vector.toArray(state.pendingEvents);
      Vector.clear(state.pendingEvents);
      for(item in procItems.vals()){
        
        let group = switch(Map.get(groups, Map.phash, item.broadcaster)){
          case(?val) val;
          case(null) {
            let newGroup = Buffer.Buffer<EmitableEvent>(1);
            ignore Map.put(groups, Map.phash, item.broadcaster, newGroup);
            newGroup;
          };
        };
        group.add(item);
      };

      let accumulator = Buffer.Buffer<async [?ICRC72BroadcasterService.PublishResult]>(1);
      for(item in Map.entries(groups)){
        //todo: check for size and split if needed
        let icrc72BroadcasterService : ICRC72BroadcasterService.Service = actor(Principal.toText(item.0));
        accumulator.add(icrc72BroadcasterService.icrc72_publish(Buffer.toArray(item.1)));
        if(accumulator.size() > 0){
          for(thisAccumulator in accumulator.vals()){
            try{
              ignore await thisAccumulator;
            } catch(e){
              debug d(debug_channel.publish, "          PUBLISHER: Error publishing event: " # debug_show(item.0) # Error.message(e));
              //todo: do we refile them?

              //todo: we need to hand this to the client to see if they want to refile
              for(thisItem in Buffer.toArray(item.1).vals()){
                Vector.add(state.pendingEvents, thisItem);
              };
            };
          };
          accumulator.clear();
        };
      };
      results;
    };


    private func processEvents(events: [NewEvent]): [?Nat]{
      debug d(debug_channel.announce, "          PUBLISHER: Processing Events: " # debug_show(events));
      let results = Vector.new<?Nat>();

      label proc for(item in events.vals()){
        debug d(debug_channel.announce, "          PUBLISHER: Processing Event: " # debug_show(item));

        //guarantee that the event has a broadcaster
        let ?broadcasters = BTree.get(state.broadcasters, Text.compare, item.namespace) else {
          debug d(debug_channel.announce, "          PUBLISHER: Can't find broadcaster for Namespace: " # debug_show(BTree.toArray(state.broadcasters)));
          Vector.add(results, null);
          continue proc;
        };

        let prev = BTree.get(state.previousEventIDs, Text.compare, item.namespace);

        let (prevId, lastIndex) = switch(prev){
          case(?val) (?val.0, val.1);
          case(null) (null, 0);
        };

        //make sure we have a registered broadcaster before continuing
        let broadcasterSize = Set.size(broadcasters);
        let ?foundBroadcaster = if(broadcasterSize == 0){
          debug d(debug_channel.announce, "          PUBLISHER: No Broadcasters for Namespace: " # item.namespace);
          Vector.add(results, null);
          continue proc;
        } else if(broadcasterSize == 1){
          getMinBroadcaster(broadcasters);
        } else {
          getNextBroadcaster(broadcasters, lastIndex);
        };
   
        let thisId = switch(environment.generateId){
          case(?val) val(item.namespace, state);
          case(null) IncrementalIDStrategy(item.namespace, state);
        };

        let timestamp = natNow();
        let publisher = canister;

        //todo: need to add headers?

        Vector.add(results, ?thisId);

        let emitableEvent = {
          broadcaster = foundBroadcaster;
          eventId = thisId;
          prevEventId = prevId;
          timestamp = timestamp;
          namespace = item.namespace;
          source = publisher;
          data = item.data;
          headers = item.headers;
        };

        debug d(debug_channel.announce, "          PUBLISHER: Emitable Event: " # debug_show(emitableEvent));

        Vector.add(state.pendingEvents, emitableEvent : EmitableEvent);
      };
      debug d(debug_channel.announce, "          PUBLISHER: Process Events Results: " # debug_show(results));
      Vector.toArray(results);
    };

    //publish function that enques the event
    public func publish<system>(events: [NewEvent]): [?Nat] {
      debug d(debug_channel.announce, "          PUBLISHER: Publishing Events: " # debug_show(events));
      let results = processEvents(events);

      //todo: set the timer or call the coallation function
 
      if(state.drainEventId == null){
        debug d(debug_channel.publish, "          PUBLISHER: Setting Drain Event " #debug_show(natNow()));
        state.drainEventId := ?environment.tt.setActionASync<system>(natNow(), {actionType = CONST.publisher.actions.drain; params = to_candid(())}, FIVE_MINUTES);
      } else {
        debug d(debug_channel.publish, "          PUBLISHER: Drain Event Already Set");
      };
        
      results;
    };

    public func filePublication( publicationRecord : PublicationRecord): () {
      debug d(debug_channel.publish, "          PUBLISHER: Filing Publication: " # debug_show(publicationRecord));
      ignore BTree.insert(state.publications, Nat.compare, publicationRecord.id, publicationRecord);
      ignore BTree.insert(state.publicationsByNamespace, Text.compare, publicationRecord.namespace, publicationRecord.id);
    };

    //add new publication
    public func registerPublications(publications: [PublicationRegistration]): async* [OrchestrationService.PublicationRegisterResult] {
      debug d(debug_channel.publish, "          PUBLISHER: Registering Publications: " # debug_show(publications));

      /* if(environment.icrc72Subscriber.getState().readyForSubscription == false){
        debug d(debug_channel.publish, "          PUBLISHER: Orchestrator not ready to register publications");
        return [?#Err(#GenericBatchError("Orchestrator not ready to register publications"))];
      }; */

      let result = try{
        await Orchestrator.icrc72_register_publication(publications);
      } catch(e){
        return [?#Err(#GenericBatchError("Network Error:" # Error.message(e)))];
      };

      debug d(debug_channel.publish, "          PUBLISHER: Registering Publications Result: " # debug_show(result));

      //what do we need to do with them?  anything?  Likely we should store them....or at least listen if we're ready to listen for them.
      var index = 0;
      for(item in result.vals()){
        switch(item){
          case(null) {}; //wasn't processed; let client handle
          case(?#Ok(val)) {
            filePublication({
              id = val;
              namespace = publications[index].namespace;
            });
          };
          case(?#Err(#Exists(val))){
            filePublication({
              id = val;
              namespace = publications[index].namespace;
            });
          };
          case(?#Err(_)){}; //Error, let client handle
        };
        index := index + 1;
      };
      result;
    };

    public func fileBroadcaster( broadcaster: Principal, namespace: Text): () {

      debug d(debug_channel.publish, "          PUBLISHER: Filing Broadcaster: " # debug_show(broadcaster) # " Namespace: " # namespace # " canister: " # namespace);

      let broadcasters = switch(BTree.get(state.broadcasters, Text.compare, namespace)){
        case(null) {
          debug d(debug_channel.publish, "          PUBLISHER: Creating Broadcaster Collection" # namespace);
          let col = Set.new<Principal>();
          ignore BTree.insert(state.broadcasters, Text.compare, namespace, col);
          col
        };
        case(?val) {val};
      };

      if(Set.has(broadcasters, Set.phash, broadcaster)){
       
          debug d(debug_channel.publish, "          PUBLISHER: Broadcaster Already Exists: " # debug_show(broadcaster) # " Namespace: " # namespace);
      } else {
          debug d(debug_channel.publish, "          PUBLISHER: Adding Broadcaster: " # debug_show(broadcaster) # " Namespace: " # namespace);
          Set.add(broadcasters, Set.phash, broadcaster);
      };
    };

    public func removeBroadcaster( broadcaster: Principal, namespace: Text): () {

      debug d(debug_channel.publish, "          PUBLISHER: Removing Broadcaster: " # debug_show(broadcaster) # " Namespace: " # namespace # " canister: " # namespace);

      let broadcasters = switch(BTree.get(state.broadcasters, Text.compare, namespace)){
        case(null) {
          debug d(debug_channel.publish, "          PUBLISHER: Removing Broadcaster Collection but already null" # namespace);
          return;
        };
        case(?val) {val};
      };

      if(Set.has<Principal>(broadcasters, Set.phash, broadcaster)){
      
          debug d(debug_channel.publish, "          PUBLISHER: Broadcaster removal: " # debug_show(broadcaster) # " Namespace: " # namespace);
          Set.delete(broadcasters, Set.phash, broadcaster);
          if(Set.size(broadcasters) == 0){
            ignore BTree.delete(state.broadcasters, Text.compare, namespace);
          };
      } else {
        debug d(debug_channel.publish, "          PUBLISHER: already removed: " # debug_show(broadcaster) # " Namespace: " # namespace);
        ignore BTree.delete(state.broadcasters, Text.compare, namespace);
        return;
      };
      
    };

    private func handleBroadcasterEvents<system>(notification: EventNotification) :  async* (){
      debug d(debug_channel.publish, "          PUBLISHER: Handling Broadcaster Events" # debug_show(notification));

      if(notification.source != environment.icrc72OrchestratorCanister and (await* environment.icrc72Subscriber.validateBroadcaster(notification.source)) == false){
        debug d(debug_channel.publish, "          PUBLISHER: handleBroadcasterEvents Not from Orchestrator or broadcaster");
        //todo: log something
        return ;
      };

      let #Map(data) = notification.data else {
        debug d(debug_channel.publish, "               PUBLISHER: Invalid data " # debug_show(notification));
        return ;
      };

      label proc for(thisData in data.vals()){
        debug d(debug_channel.publish, "          PUBLISHER: Handling Broadcaster Event: " # debug_show((thisData.0, CONST.broadcasters.publisher.broadcasters.add)));
        if(thisData.0 == CONST.broadcasters.publisher.broadcasters.add){

          debug d(debug_channel.publish, "          PUBLISHER: Adding Broadcasters");

          let #Array(brodcasterBlobsArray) = thisData.1 else continue proc;

          

          for(thisBroadcasterArray in brodcasterBlobsArray.vals()){
            debug d(debug_channel.publish, "          PUBLISHER: Adding Broadcaster: " # debug_show(thisBroadcasterArray));
            let #Array(thisBroadcaster) = thisBroadcasterArray else return ;
            let #Text(publicationNamespace) = thisBroadcaster[0] else return ;
            let #Blob(principalBlob) = thisBroadcaster[1] else return ;
            let principal = Principal.fromBlob(principalBlob);

            debug d(debug_channel.publish, "          PUBLISHER: Adding Broadcaster: " # debug_show(principal) # " Namespace: " # publicationNamespace);

            //todo: can be optimized
            let currentSize = do?{state.broadcasters |>
              BTree.get(_, Text.compare, publicationNamespace) |>
              Set.size(_!)};

            debug d(debug_channel.publish, "          PUBLISHER: Adding Broadcaster: " # debug_show(currentSize));
             

            fileBroadcaster(principal, publicationNamespace);

            if(currentSize == null or currentSize == ?0){
              switch(environment.onPublisherReady){
                case(?val){
                  val<system>(state, environment, publicationNamespace);
                };
                case(null){};
              };
            } else {
              debug d(debug_channel.publish, "          PUBLISHER: Already has broadcasters");
            };

            
            
          };
        } else if(thisData.0 == CONST.broadcasters.publisher.broadcasters.remove){

          debug d(debug_channel.publish, "          PUBLISHER: Removing Broadcasters");

          let #Array(brodcasterBlobsArray) = thisData.1 else continue proc;  

          for(thisBroadcasterArray in brodcasterBlobsArray.vals()){
            debug d(debug_channel.publish, "          PUBLISHER: Adding Broadcaster: " # debug_show(thisBroadcasterArray));
            let #Array(thisBroadcaster) = thisBroadcasterArray else return;
            let #Text(publicationNamespace) = thisBroadcaster[0] else return;
            let #Blob(principalBlob) = thisBroadcaster[1] else return;
            let principal = Principal.fromBlob(principalBlob);

            removeBroadcaster(principal, publicationNamespace);
            
          };
        } else if(notification.namespace == CONST.publisher.broadcasters.error){
          debug d(debug_channel.publish, "          PUBLISHER: Error Adding Broadcasters");
          state.error := ?debug_show(notification);
        };
      };

      debug d(debug_channel.publish, "          PUBLISHER: Handling Broadcaster Events Complete");

      return;

      
    };

    private func handleDrainPublisher<system>(id: TT.ActionId, action: TT.Action) : async* Star.Star<TT.ActionId, TT.Error> {

      debug d(debug_channel.publish, "          PUBLISHER: Draining Publisher");

      if(state.eventsProcessing == true){
        //delay to next round
        debug d(debug_channel.publish, "          PUBLISHER: Already Running");
        ignore environment.tt.setActionASync<system>(natNow(), {actionType = CONST.publisher.actions.drain; params = to_candid(())}, FIVE_MINUTES);
        return #trappable(id);
      };

      state.eventsProcessing := true;
      state.drainEventId := null;

      let groups = Map.new<Principal, Buffer.Buffer<EmitableEvent>>();

      debug d(debug_channel.publish, "          PUBLISHER: Processing Events: " # debug_show(Vector.size(state.pendingEvents)));

      let procItems = Vector.toArray(state.pendingEvents);
      Vector.clear(state.pendingEvents);
      for(item in procItems.vals()){
        let group = switch(Map.get(groups, Map.phash, item.broadcaster)){
          case(?val) val;
          case(null) {
            let newGroup = Buffer.Buffer<EmitableEvent>(1);
            ignore Map.put(groups, Map.phash, item.broadcaster, newGroup);
            newGroup;
          };
        };
        group.add(item);
      };

      let accumulator = Buffer.Buffer<((Principal, Buffer.Buffer<EmitableEvent>) ,async [?ICRC72BroadcasterService.PublishResult])>(1);
      for(item in Map.entries(groups)){
        //todo: check for size and split if needed
        let icrc72BroadcasterService : ICRC72BroadcasterService.Service = actor(Principal.toText(item.0));
        accumulator.add(item, icrc72BroadcasterService.icrc72_publish(Buffer.toArray(item.1)));
        debug d(debug_channel.publish, "          PUBLISHER: Publishing to: " # debug_show(item.0) # " Count: " # debug_show(item.1.size()));
      };

      if(accumulator.size() > 0){
        for(thisAccumulator in accumulator.vals()){
          try{
            let result = await thisAccumulator.1;
            var idx = 0;
            for(thisItem in result.vals()){
              switch(thisItem){
                case(?#Ok(val)) {
                  debug d(debug_channel.publish, "          PUBLISHER: Published to: " # debug_show(thisAccumulator.0.0) # " Result: " # debug_show(thisItem));
                  //call interceptor
                  switch(environment.onEventPublished){
                    case(?val){
                      val<system>(thisAccumulator.0.1.get(idx), thisItem);
                    };
                    case(null){};
                  };
                };
                case(?#Err(err)) {
                  debug d(debug_channel.publish, "          PUBLISHER: Published to: " # debug_show(thisAccumulator.0.0) # " Result: " # debug_show(result));
                  //todo: call interceptor
                  let requeue = switch(environment.onEventPublishError){
                    case(?val){
                      val<system>(thisAccumulator.0.1.get(idx), err);
                    };
                    case(null){
                      true;
                    };
                  };
                  if requeue  Vector.add(state.pendingEvents, thisAccumulator.0.1.get(idx));
                };
                case(null) {
                  debug d(debug_channel.publish, "          PUBLISHER: Error publishing event null: " # debug_show(thisAccumulator.0.0));
                  let requeue = switch(environment.onEventPublishError){
                    case(?val){
                      val<system>(thisAccumulator.0.1.get(idx), #GenericError({error_code=2834; message="Null Response"}));
                    };
                    case(null){
                      true;
                    };
                  };
                  if requeue Vector.add(state.pendingEvents, thisAccumulator.0.1.get(idx));
                };
              };
              idx := idx + 1;
            };
          } catch(e){
            debug d(debug_channel.publish, "          PUBLISHER: Error publishing event: " # debug_show(thisAccumulator.0.0) # Error.message(e));
            //todo: do we refile them?
            

            //todo: we need to hand this to the client to see if they want to refile
            for(thisItem in Buffer.toArray(thisAccumulator.0.1).vals()){
              let requeue = switch(environment.onEventPublishError){
                case(?val){
                  val<system>(thisItem, #GenericError({error_code= 2835; message=Error.message(e)}));
                };
                case(null){
                  true;
                };
              };
              if requeue Vector.add(state.pendingEvents, thisItem);
            };
          };
        };
        accumulator.clear();
      };

      state.eventsProcessing := false;

      return #awaited(id);
    };

    private var _isInit = false;

    public func initializeSubscriptions() : async() {
      if(_isInit == true) return;
      _isInit := true;
      debug d(debug_channel.startup, "          PUBLISHER: Initializing Publisher");
      //can only be called once 
      
      
      
      environment.tt.registerExecutionListenerAsync(?CONST.publisher.actions.drain, handleDrainPublisher);


      environment.icrc72Subscriber.registerExecutionListenerAsync(?(CONST.publisher.sys # Principal.toText(canister)), handleBroadcasterEvents);

      let subscriptionResult = await environment.icrc72Subscriber.registerSubscriptions([{
        namespace = CONST.publisher.sys # Principal.toText(canister);
        config = [];
        memo = null
      }]);

      try{
        await environment.icrc72Subscriber.initializeSubscriptions();
      } catch(e){
        _isInit := false;
        state.error := ?("Error initializing subscriber" # Error.message(e));
        return;
      };

      debug d(debug_channel.startup, "          PUBLISHER: Subscription Result: " # debug_show(subscriptionResult));
    };


    /* broadcasters: [(Text, [Principal])];
    publications: [(Nat, PublicationRecord)];
    previousEventIds: [(Text, (Nat, Nat))];
    pendingEvents: [EmitableEvent];
    drainEventId: ?Nat;
    eventsProcessing: Bool;
    readyForPublications: Bool;
    error: ?Text;
    tt: TT.Stats;
    subscriber: ICRC72Subscriber.Stats;
    orchestrator: Principal; */
    public func stats(): Stats {
      return {
        icrc72OrchestratorCanister = environment.icrc72OrchestratorCanister;
        broadcasters = Iter.toArray(Iter.map<(Text, Set.Set<Principal>), (Text, [Principal])>(BTree.entries(state.broadcasters), func(nat:Text, vec: Set.Set<Principal>) { (nat, Set.toArray(vec)) }));
        publications = Iter.toArray(Iter.map<(Nat, PublicationRecord), (Nat, PublicationRecord)>(BTree.entries(state.publications), func(nat:Nat, record: PublicationRecord) { (nat, record) }));
        previousEventIds = Iter.toArray(Iter.map<(Text, (Nat, Nat)), (Text, (Nat, Nat))>(BTree.entries(state.previousEventIDs), func(nat:Text, record: (Nat, Nat)) { (nat, record) }));
        pendingEvents = Vector.toArray(state.pendingEvents);
        drainEventId = state.drainEventId;
        eventsProcessing = state.eventsProcessing;
        readyForPublications = state.readyForPublications;
        error = state.error;
        tt = environment.tt.getStats();
            icrc72Subscriber = environment.icrc72Subscriber.stats();
        orchestrator = environment.icrc72OrchestratorCanister;
        log = Vector.toArray(vecLog);
      };

    };
  };

 
}