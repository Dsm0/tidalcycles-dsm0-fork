fs = require('fs')
spawn = require('child_process').spawn

{$, Range} = require 'atom'

execPath = "/usr/local/bin/ghci"
bootFilePath = __dirname + "/BootTidal.hs"

module.exports =
class REPL
  repl = null

  constructor: (serializeState) ->
    console.log('start')
    @start()
    atom.commands.add 'atom-text-editor', 'tidal:eval': => @eval()

  doSpawn: ->
    @repl = spawn(execPath, ["-XOverloadedStrings"])
    @repl.stdout.on('data', (data) -> console.log(data.toString('utf8')))
    @repl.stderr.on('data', (data) -> console.log(data.toString('utf8')))

  initTidal: ->
    commands = fs.readFileSync(bootFilePath).toString().split('\n')

    (@writeLine(command) for command in commands)

  write: (command) ->
    @repl.stdin.write(command)

  writeLine: (command)->
    @write(command)
    @write('\n')

  start: ->
    @doSpawn()
    @initTidal()

  getEditor: ->
    atom.workspace.getActiveEditor()

  eval: ->
    # return unless @editorIsSC()
    [expression, range] = @currentExpression()
    @evalWithRepl(expression, range)

  evalWithRepl: (expression, range)->
    return unless expression

    doIt = () =>
      if range?
        unflash = @evalFlash(range)

      onSuccess = () ->
        unflash?('eval-success')

      onError = (error) =>
        if error.type is 'SyntaxError'
          unflash?('eval-syntax-error')
          if path
            # offset syntax error by position of selected text in file
            row = range.getRows()[0] + error.error.line
            col = error.error.charPos
            @openToSyntaxError(path, parseInt(row), parseInt(col))
        else
          # runtime error
          unflash?('eval-error')
      # TODO: tmp on only sucess flash
      @write(expression)
      @write('\n')
      onSuccess()
    doIt()

  destroy: ->
    @repl.kill()

  currentExpression: ->
    editor = @getEditor()
    return unless editor?

    selection = editor.getLastSelection()
    expression = selection.getText()

    if expression
      range = selection.getBufferRange()
    else
     # execute the line you are on
      pos = editor.getCursorBufferPosition()
      row = editor.getCursorScreenRow()

      if row?
        range = new Range([row, 0], [row + 1, 0])
        expression = editor.lineForBufferRow(row)
      else
        range = null
        expression = null

    [expression, range]

  evalFlash: (range) ->
    editor = @getEditor()
    marker = editor.markBufferRange(range, invalidate: 'touch')

    decoration = editor.decorateMarker(
      marker,
      type: 'line',
      class: "eval-flash"
    )
    # return fn to flash error/success and destroy the flash

    (cssClass) ->
      decoration.update(type: 'line', class: cssClass)
      destroy = ->
        marker.destroy()
      setTimeout(destroy, 100)
