
import each from 'each'
import fs from 'fs'
import path from 'path'
import { exec } from 'child_process'

import { fileURLToPath } from 'url'
__dirname = path.dirname fileURLToPath import.meta.url
dir = path.resolve __dirname, '../samples'
samples = fs.readdirSync(dir).filter (sample) -> /\.js$/.test sample

describe 'Samples', ->
  
  each samples, (sample) ->
    it "Sample #{sample}", (callback) ->
      exec "node --trace-gc --inspect --max-old-space-size=100 #{path.resolve dir, sample}", (err) ->
        callback err
