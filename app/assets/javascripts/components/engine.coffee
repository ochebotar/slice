@engineReady = ->
  expressionsReady()
  if $("[data-object~=expressions-input]").length > 0
    sendExpression($("[data-object~=expressions-input]"), { setup: "1" })

@expressionsReady = ->
  $("[data-object~=expressions-textcomplete]").each( ->
    $this = $(this)
    $this.textcomplete(
      [
        {
          name: "reserved-words"
          match: /(^|\s)(and|or|xor|between|is|at|true|false|nil|null|entered|present|any|missing|unentered|blank)$/
          search: (term, callback) ->
            words = [] # ["and", "or", "is"]
            resp = $.map(words, (word) ->
              if word.indexOf(term) == 0
                word
              else
                null
            )
            callback(resp)
          replace: (value) -> return "$1#{value}"
        },
        {
          match: /(^|\s)([a-zA-Z]\w*)$/
          search: (term, callback) ->
            $.getJSON("#{$this.data("textcomplete-url")}", { search: term })
              .done((resp) -> callback(resp))
              .fail(-> callback([]))
          replace: (value) ->
            return "$1#{value}"
          cache: true
        }
      ]
    )
  )

@addToDebugConsole = (value) ->
  $("#debug-console").prepend("#{value}<br>")

@sendExpression = (element, params = {}) ->
  addToDebugConsole $(element).val()
  params["expression"] = $(element).val()
  $("#run-ms").html("...")
  $("#subjects-count").html("<i class=\"d-inline-block fas fa-circle-notch fa-spin\"></i>")
  $.post($(element).data("url"), params, null, "script")
    .fail(->
      $("#current-tokens").html("<div class=\"engine-container\">error</div>")
      $("#run-ms").html("")
      $("#sobjects-table").html("")
      $("#engine-tree").html("")
      $("#subjects-count").html("<i class=\"d-inline-block fas fa-exclamation-circle text-danger\"></i> Error parsing expression.")
    )

@clearExistingTimeouts = (element) ->
  if element.data("timeouts")?
    for timeout in element.data("timeouts")
      clearTimeout(timeout)
  element.data("timeouts", [])

$(document)
  .on("keyup", "[data-object~=expressions-input]", (event) ->
    return if event.which in [9, 12, 16, 17, 18, 20, 27, 33, 34, 35, 36, 37, 38, 39, 40, 91, 93]
    $this = $(this)
    clearExistingTimeouts($this)
    timeout = setTimeout(sendExpression.bind(null, $this), 250 * 1)
    $this.data("timeouts").push(timeout)
  )
