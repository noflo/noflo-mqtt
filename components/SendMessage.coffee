noflo = require 'noflo'
mqtt = require 'mqtt'
url = require 'url'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Send a message to a MQTT topic'
  c.inPorts.add 'topic',
    datatype: 'string'
    description: 'MQTT topic to send message to'
    required: yes
  c.inPorts.add 'message',
    datatype: 'string'
    description: 'Message to send to the broker'
    required: yes
  c.inPorts.add 'broker',
    datatype: 'string'
    description: 'Hostname of the MQTT broker'
    required: yes
  c.inPorts.add 'port',
    datatype: 'number'
    description: 'Port of the MQTT broker'
    required: no
  c.inPorts.add 'qos',
    datatype: 'integer'
    description: 'Quality of Service flag'
    required: no
  c.inPorts.add 'retain',
    datatype: 'boolean'
    description: 'Whether to retain the latest message on broker'
    required: no
  c.outPorts.add 'out',
    datatype: 'string'
  c.outPorts.add 'error',
    datatype: 'object'

  c.client = null

  sendMessage = (data, out, callback) ->
    unless typeof data.message is 'string'
      data.message = JSON.stringify data.message

    qos = c.params.qos or 0
    retain = c.params.retain or false
    c.client.publish data.topic, data.message,
      qos: qos
      retain: retain
    , (err) ->
      return callback err if err
      out.beginGroup data.topic
      out.send data.message
      out.endGroup()
      do callback

  noflo.helpers.WirePattern c,
    in: ['topic', 'message']
    params: ['broker', 'port', 'qos', 'retain']
    forwardGroups: true
    async: true
  , (data, groups, out, callback) ->
    unless c.client
      port = c.params.port or 1883
      brokerUrl = url.format
        hostname: c.params.broker
        port: c.params.port
        protocol: 'mqtt'
        slashes: true
      c.client = mqtt.connect brokerUrl
      c.client.once 'connect', ->
        sendMessage data, out, callback
      c.client.on 'error', (e) ->
        c.error e
        c.client = null
      c.client.on 'close', ->
        c.client = null
      return
    sendMessage data, out, callback
