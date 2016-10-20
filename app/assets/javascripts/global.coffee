@color_group = (group_name) ->
  $("input[name='" + group_name + "']:not(:checked)").parent().removeClass('selected')
  $("input[name='" + group_name + "']:checked").parent().addClass('selected')

@fadeAndRemove = (element) ->
  $(element).fadeOut(500, -> $(element).remove())

@addGlobalNoTouchToBody = ->
  $('body').addClass('no-touch') if (document.documentElement.ontouchstart == undefined)

@setFocusToField = (element_id) ->
  val = $(element_id).val()
  $(element_id).focus().val('').val(val)

@wideContainer = ->
  if $('[data-object~="wide-container"]').length > 0
    $('.container').addClass('wide-container')

@extensionsReady = ->
  clipboardReady()
  datepickerReady()
  tooltipsReady()
  typeaheadReady()

@globalReady = ->
  window.$isDirty = false
  # $("#global-search").typeahead(
  #   remote: root_url + 'search?q=%QUERY'
  # )
  # setFocusToField("#search")
  extensionsReady()
  $('[data-object~="form-load"]').submit()

# These functions get called on initial page visit and on turbolink page changes
@turbolinksReady = ->
  globalReady()
  designsReady()
  domainsReady()
  filtersReady()
  reportsReady()
  sheetsReady()
  variablesReady()
  signaturesReady()
  subjectsReady()
  projectsReady()
  eventsReady()
  randomizationsReady()
  usersReady()
  fileDragReady()
  randomizationSchemesReady()
  addGlobalNoTouchToBody()
  wideContainer()

# These functions only get called on the initial page visit (no turbolinks)
@initialLoadReady = ->
  turbolinksReady()
  timeoutReady()

$(window).onbeforeunload = -> return "You haven't saved your changes." if window.$isDirty
$(document).ready(initialLoadReady)
$(document)
  .on('turbolinks:load', turbolinksReady)
  .on('turbolinks:click', -> confirm("You haven't saved your changes.") if window.$isDirty)
  .on('click', '[data-object~="suppress-click"]', -> false)
  .on('click', '[data-object~="remove-self"]', ->
    $(this).remove()
    false
  )
  .on('click', '[data-object~="remove"]', ->
    plural = if $(this).data('count') == 1 then '' else 's'
    if $(this).data('count') in [0, undefined] or ($(this).data('count') and confirm('Removing this option will PERMANENTLY ERASE DATA you have collected. Are you sure you want to RESET responses that used this option from ' + $(this).data('count') + ' sheet' + plural +  '?'))
      $($(this).data('target')).remove()
      false
    else
      false
  )
  .on('click', '[data-object~="modal-show"]', ->
    $($(this).data('target')).modal({ dynamic: true })
    false
  )
  .on('click', '[data-object~="modal-hide"]', ->
    $($(this).data('target')).modal('hide')
    false
  )
  .on('click', '[data-object~="submit"]', ->
    $($(this).data('target')).submit()
    false
  )
  .on('click', '[data-object~="submit-and-disable"]', ->
    $(this).prop('disabled', true)
    $($(this).data('target')).submit()
    false
  )
  .on('mouseenter', '[data-object~="hover-show"]', ->
    return false unless document.documentElement.ontouchstart == undefined
    $('[data-object~="hover-show"]').each( (index, element) ->
      $($(element).data('target')).hide()
    )
    $($(this).data('target')).show()
  )
  .on('mouseleave', '[data-object~="hover-show"]', ->
    $($(this).data('target')).hide()
  )
  .on('change', '.checkbox input:checkbox', ->
    color_group($(this).attr('name'))
  )
  .keydown( (e) ->
    # p will enter the search box, Esc will exit
    if e.which == 80 and not $("input, textarea, select, a").is(":focus")
      $("#global-search").focus()
      e.preventDefault()
      return
    $("#global-search").blur() if $("#global-search").is(':focus') and e.which == 27
    if $("#interactive_design_modal").is(':visible')
      hideInteractiveDesignModal()     if e.which == 27
    if e.which == 77 and not $("input, textarea, select, a").is(":focus")
      if $('#preview-mode').length == 1 and $('#edit-mode').length == 1 and $('#edit-mode').parent().hasClass('active')
        $('#preview-mode').click()
      else
        $('#edit-mode').click()
      e.preventDefault()
      return
    # Key is 'w'
    if not (e.metaKey or e.ctrlKey) and e.which == 87 and not $("input, textarea, select, a").is(":focus")
      $('.container').toggleClass('wide-container')
      e.preventDefault()
      return
  )
  .on('click', '[data-object~="settings-save"]', ->
    window.$isDirty = false
    $($(this).data('target')).submit()
    false
  )
  .on('click', '[data-object~="toggle-visibility"]', ->
    $($(this).data('target')).toggle()
    false
  )
  # .on('typeahead:selected', "#global-search", (event, datum) ->
  #   $(this).val(datum['value'])
  #   $("#global-search-form").submit()
  # )
  .on('keydown', "#global-search", (e) ->
    $("#global-search-form").submit() if e.which == 13
  )
  .on('change', ':input', ->
    if $("#isdirty").val() == '1'
      window.$isDirty = true
  )
  .on('click', '[data-object~="toggle-delete-buttons"]', ->
    $($(this).data('target-show')).show()
    $($(this).data('target-hide')).hide()
    false
  )
