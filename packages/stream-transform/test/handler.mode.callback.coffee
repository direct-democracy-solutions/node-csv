
import { Writable } from 'node:stream'
import { pipeline } from 'node:stream/promises'
import { generate } from 'csv-generate'
import { transform } from '../lib/index.js'

describe 'handler.mode.callback', ->

  it 'handler with callback with parallel 1', ->
    chunks = []
    r = new Writable
      write: (chunk, _, callback) ->
        chunks.push chunk.toString()
        callback()
    await pipeline(
      generate length: 1000
    ,
      transform parallel: 1, (chunk, callback) -> callback null, chunk
    ,
      r
    )
    chunks.join('').split('\n').length.should.eql 1000

  it 'handler with callback with parallel 2', ->
    count = 0
    clear = setInterval ->
      count++
    , 10
    chunks = []
    r = new Writable
      write: (chunk, _, callback) ->
        chunks.push chunk.toString()
        callback()
    await pipeline(
      generate columns: 10, objectMode: true, length: 1000
    ,
      transform parallel: 2, (chunk, callback) ->
        callback null, JSON.stringify(chunk)+'\n'
    ,
      r
    )
    clearInterval(clear)
    count.should.be.above 1
