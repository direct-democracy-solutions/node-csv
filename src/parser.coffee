
{EventEmitter} = require 'events'

###

Parsing
=======

The library extend the [EventEmitter][event] and emit the following events:

*   *row*   
  Emitted by the parser on each line with the line content as an array of fields.
*   *end*   
  Emitted when no more data will be parsed.
*   *error*   
  Emitted when an error occured.

###
Parser = (csv) ->
  @csv = csv
  @options = csv.options.from
  @state = csv.state
  # Counter
  @lines = 0
  # Internal usage, state related
  @buf = ''
  @quoting = false
  @field = ''
  @lastC = ''
  @nextChar = null
  @closingQuote = 0
  @line = [] # Current line being processed
  @
Parser.prototype.__proto__ = EventEmitter.prototype

###

`write(chars)`
--------------

Parse a string which may hold multiple lines.
Private state object is enriched on each character until 
transform is called on a new line.

###
Parser.prototype.write =  (chars, end) ->
  csv = @csv
  ltrim = @options.trim or @options.ltrim
  rtrim = @options.trim or @options.rtrim
  chars = @buf + chars
  l = chars.length
  delimLength = if @options.rowDelimiter then @options.rowDelimiter.length else 0
  i = 0
  # Strip UTF-8 BOM
  i++ if @lines is 0 and csv.options.from.encoding is 'utf8' and 0xFEFF is chars.charCodeAt 0
  while i < l
    # we stop if
    # - the last chars aren't the delimiters
    # - this isnt the last line (the end argument)
    break if (i+delimLength >= l and chars.substr(i, @options.rowDelimiter.length) isnt @options.rowDelimiter) and not end
    # we stop if
    # - the last chars are an espace char
    # - this isnt the last line (the end argument)
    break if (i+@options.escape.length >= l and chars.substr(i, @options.escape.length) is @options.escape) and not end
    char = if @nextChar then @nextChar else chars.charAt i
    @lastC = char # this should be removed, only used in buggy end function
    @nextChar = chars.charAt i + 1
    # Auto discovery of rowDelimiter, unix, mac and windows supported
    if not @options.rowDelimiter? and ( @nextChar is '\n' or @nextChar is '\r' )
      @options.rowDelimiter = @nextChar
      @options.rowDelimiter += '\n' if @nextChar is '\r' and chars.charAt(i+2) is '\n'
      delimLength = @options.rowDelimiter.length
    # Parse that damn char
    # Note, shouldn't we have sth like chars.substr(i, @options.escape.length)
    isReallyEscaped = false
    if char is @options.escape
      # Make sure the escape is really here for escaping:
      # If escape is same as quote, and escape is first char of a field 
      # and it's not quoted, then it is a quote
      # Next char should be an escape or a quote
      escapeIsQuote = @options.escape is @options.quote
      isEscape = @nextChar is @options.escape
      isQuote = @nextChar is @options.quote
      if not ( escapeIsQuote and not @field and not @quoting ) and ( isEscape or isQuote )
        i++
        # isReallyEscaped = true
        char = @nextChar
        @nextChar = chars.charAt i + 1
        @field += char
        i++
        continue
    if not isReallyEscaped and char is @options.quote
      if @quoting
        # Make sure a closing quote is followed by a delimiter
        # If we have a next character and 
        # it isnt a rowDelimiter and 
        # it isnt an column delimiter
        areNextCharsRowDelimiters = @options.rowDelimiter and chars.substr(i+1, @options.rowDelimiter.length) is @options.rowDelimiter
        if @nextChar and not areNextCharsRowDelimiters and @nextChar isnt @options.delimiter
          return @error new Error "Invalid closing quote at line #{@lines+1}; found #{JSON.stringify(@nextChar)} instead of delimiter #{JSON.stringify(@options.delimiter)}"
        @quoting = false
        @closingQuote = i
        i++
        continue
      else if not @field
        @quoting = true
        i++
        continue
      # Otherwise, treat quote as a regular character
    # Between two columns
    isDelimiter = (char is @options.delimiter)
    isRowDelimiter = (@options.rowDelimiter and chars.substr(i, @options.rowDelimiter.length) is @options.rowDelimiter)
    if not @quoting and (isDelimiter or isRowDelimiter)
      if rtrim
        if @closingQuote
          @field = @field.substr 0, @closingQuote
        else
          @field = @field.trimRight()
      @line.push @field
      @closingQuote = 0
      @field = ''
      # End of row, flush the row
      if isRowDelimiter
        @emit 'row', @line
        # Some cleanup for the next row
        @line = []
        i += @options.rowDelimiter.length
        @nextChar = chars.charAt i
        continue
    else if not @quoting and (char is ' ' or char is '\t')
      # Discard space unless we are quoting, in a field
      @field += char unless ltrim and not @field
    else
      @field += char
    i++
  # Ok, maybe we still have some char that are left, 
  # we stored them for next call
  @buf = ''
  while i < l
    @buf += chars.charAt i
    i++

Parser.prototype.end = ->
  @write '', true
  if @quoting
    return @error new Error "Quoted field not terminated at line #{@lines+1}"
  # dump open record
  if @field or @lastC is @options.delimiter or @lastC is @options.quote
    if @options.trim or @options.rtrim
      @field = @field.trimRight()
    # console.log "PUSH: |#{@field}"
    @line.push @field
    @field = ''
  if @line.length > 0
    @emit 'row', @line
  @emit 'end', null

Parser.prototype.error = (e) ->
  @emit 'error', e

module.exports = (csv) -> new Parser csv
module.exports.Parser = Parser

###
[event]: http://nodejs.org/api/events.html
###

