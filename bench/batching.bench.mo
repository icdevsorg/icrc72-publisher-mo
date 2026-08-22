import BaseBuffer "mo:base/Buffer";
import Bench "mo:bench";
import List "mo:core/List";
import PureList "mo:core/pure/List";

module {
  public func init() : Bench.Bench {
    let bench = Bench.Bench();
    bench.name("Publisher batch collection comparison");
    bench.description("Compares Buffer, Core List, and PureList for publisher-style append, array conversion, and traversal.");
    bench.rows([
      "build+array Buffer",
      "build+array Core List",
      "build+array PureList",
      "build+array+traverse Buffer",
      "build+array+traverse Core List",
      "build+array+traverse PureList",
    ]);
    bench.cols(["10", "100", "1k", "10k"]);

    let sizes = [10, 100, 1_000, 10_000];

    func bufferBatch(size : Nat) : [Nat] {
      let values = BaseBuffer.Buffer<Nat>(size);
      var index = 0;
      while (index < size) { values.add(index); index += 1 };
      BaseBuffer.toArray(values)
    };

    func coreListBatch(size : Nat) : [Nat] {
      let values = List.empty<Nat>();
      var index = 0;
      while (index < size) { List.add(values, index); index += 1 };
      List.toArray(values)
    };

    func pureListBatch(size : Nat) : [Nat] {
      var values = PureList.empty<Nat>();
      var index = 0;
      while (index < size) { values := PureList.pushFront(values, index); index += 1 };
      PureList.toArray(PureList.reverse(values))
    };

    func traverse(values : [Nat]) : Nat {
      var sum = 0;
      for (value in values.vals()) { sum += value };
      sum
    };

    bench.runner(func(row : Text, col : Text) {
      let index = if (col == "10") 0 else if (col == "100") 1 else if (col == "1k") 2 else 3;
      let size = sizes[index];
      if (row == "build+array Buffer") ignore bufferBatch(size)
      else if (row == "build+array Core List") ignore coreListBatch(size)
      else if (row == "build+array PureList") ignore pureListBatch(size)
      else if (row == "build+array+traverse Buffer") ignore traverse(bufferBatch(size))
      else if (row == "build+array+traverse Core List") ignore traverse(coreListBatch(size))
      else ignore traverse(pureListBatch(size));
    });
    bench
  };
};
