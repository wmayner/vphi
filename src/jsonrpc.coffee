###
A wrapper around jQuery's AJAX post that exposes it as a JSON-RPC 2.0 client.
###

# TODO document jQuery dependency
class Client
  constructor: (config) ->
    @url = "http://#{config['hostname']}:#{config['port']}"

  request: (method, params, cb) ->
    payload =
      'method': method
      'params': params
      'jsonrpc': '2.0'
      'id': null
    console.log JSON.stringify(payload)
    response = $.ajax(
      type: 'POST'
      url: @url
      data: payload
      success: cb
      dataType: 'jsonmmp'
    )

exports.Client = Client
