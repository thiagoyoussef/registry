@flash_notice = (msg) ->
  $('#flash').find('div').removeClass('bg-danger')
  $('#flash').find('div').addClass('bg-success')
  $('#flash').find('div').html(msg)
  $('#flash').show()

@flash_alert = (msg) ->
  $('#flash').find('div').removeClass('bg-success')
  $('#flash').find('div').addClass('bg-danger')
  $('#flash').find('div').html(msg)
  $('#flash').show()

$(document).on 'ready page:load', ->
  today = new Date()
  tomorrow = new Date(today)
  tomorrow.setDate(today.getDate() + 1)

  $('.datepicker').datepicker(
    dateFormat: "yy-mm-dd",
    maxDate: tomorrow
  );