# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

@toggleOptions = (element) ->
  if $(element).val() in ['dropdown', 'checkbox', 'radio']
    $('[data-object~="options"]').show()
  else
    $('[data-object~="options"]').hide()
  if $(element).val() in ['integer', 'numeric']
    $('[data-object~="number"]').show()
  else
    $('[data-object~="number"]').hide()
  if $(element).val() in ['date']
    $('[data-object~="date"]').show()
  else
    $('[data-object~="date"]').hide()

@checkForBlankOptions = () ->
  blank_options = $('[data-object~="option-name"]').filter( () ->
    $.trim($(this).val()) == ''
  )
  blank_options.parent().parent().addClass('error')
  unless $('#variable_variable_type').val() not in ['dropdown', 'checkbox', 'radio'] or blank_options.size() == 0 or confirm('Options with blank names will be removed. Proceed anyways?')
    return false
  true

@checkMinMax = () ->
  $('[data-object~="minmax"]').parent().parent().removeClass('error')
  number_fields = $('[data-object~="minmax"]').filter( () ->
    (isNaN(parseInt($.trim($(this).val()))) and $.trim($(this).val()).length > 0) or parseInt($.trim($(this).val())) < parseInt($(this).attr('min')) or parseInt($.trim($(this).val())) > parseInt($(this).attr('max'))
  )
  number_fields.parent().parent().addClass('error')
  if number_fields.size() > 0
    alert('Some numeric fields are out of range!')
    return false
  true

@checkSoftMinMax = () ->
  $('[data-object~="minmax"]').parent().parent().removeClass('warning')
  number_fields = $('[data-object~="minmax"]').filter( () ->
    (isNaN(parseInt($.trim($(this).val()))) and $.trim($(this).val()).length > 0) or parseInt($.trim($(this).val())) < parseInt($(this).data('soft-minimum')) or parseInt($.trim($(this).val())) > parseInt($(this).data('soft-maximum'))
  )
  number_fields.parent().parent().addClass('warning')
  if number_fields.size() > 0 and !confirm('Some numeric fields are out of the recommended range. Proceed anyways?')
    return false
  true

# Select dates that don't parse as dates, and are not blank
# or dates where the value is less than the hard minimum
# or dates where the value is greater than the hard maximum
@checkDateMinMax = () ->
  $('[data-object~="dateminmax"]').parent().parent().removeClass('error')
  date_fields = $('[data-object~="dateminmax"]').filter( () ->
    (isNaN(Date.parse($.trim($(this).val()))) and $.trim($(this).val()).length > 0) or Date.parse($.trim($(this).val())) < Date.parse($(this).data('date-hard-minimum')) or Date.parse($.trim($(this).val())) > Date.parse($(this).data('date-hard-maximum'))
  )
  date_fields.parent().parent().addClass('error')
  if date_fields.size() > 0
    alert('Some dates are out of range!')
    return false
  true

@checkSoftDateMinMax = () ->
  $('[data-object~="dateminmax"]').parent().parent().removeClass('warning')
  date_fields = $('[data-object~="dateminmax"]').filter( () ->
    (isNaN(Date.parse($.trim($(this).val()))) and $.trim($(this).val()).length > 0) or Date.parse($.trim($(this).val())) < Date.parse($(this).data('date-soft-minimum')) or Date.parse($.trim($(this).val())) > Date.parse($(this).data('date-soft-maximum'))
  )
  date_fields.parent().parent().addClass('warning')
  if date_fields.size() > 0 and !confirm('Some dates are out of the recommended range. Proceed anyways?')
    return false
  true

jQuery ->
  $('#add_more_options').on('click', () ->
    $.post(root_url + 'variables/add_option', $("form").serialize() + "&_method=post", null, "script")
    false
  )

  $(document)
    .on('change', '#variable_variable_type', () -> toggleOptions($(this)))

  $('#options[data-object~="sortable"]').sortable( placeholder: "well alert alert-block" )

  $(document).on('click', '[data-object~="form-check-before-submit"]', () ->
    if checkForBlankOptions() == false
      return false
    $($(this).data('target')).submit()
    false
  )

  $(document).on('click', '[data-object~="variable-check-before-submit"]', () ->
    if checkMinMax() == false
      return false
    if checkDateMinMax() == false
      return false
    if checkSoftMinMax() == false
      return false
    if checkSoftDateMinMax() == false
      return false
    $($(this).data('target')).submit()
    false
  )
