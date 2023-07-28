import {transform} from 'stream-transform';
import {pipeline, Readable, Writable} from "stream";

class DummyData extends Readable {

  constructor() {
    super();
    this.numReads = 0;
  }

  _read() {
    // Push incrementing values forever
    this.push(JSON.stringify({'string': 'read_' + this.numReads}));
    this.numReads++;
  }
}

class Stopper extends Writable {
  constructor() {
    super({
      objectMode: true,
      highWaterMark: 1, // Allow just one item in buffer; apply backpressure otherwise
    });
  }

  // Accept chunks extremely slowly; discard the chunk data
  _write(chunk, encoding, callback) {
    console.log('wrote one out');
    setTimeout(callback, 1000);
  }
}

pipeline(
  new DummyData(),
  transform(data => data), // Comment out this line, the test runs forever. Leave it in, run out of memory pretty quick.
  new Stopper(),
  () => { },
);
