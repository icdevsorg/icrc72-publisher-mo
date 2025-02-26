
import Publisher "../";
shared (deployer) actor class Example<system>()  = this {

  type PublisherClass = Publisher.Publisher;

  public shared func hello() : async Text {
    return "Hello, World!";
  };  

};