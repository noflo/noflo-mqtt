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
    control: true
  c.inPorts.add 'port',
    datatype: 'number'
    description: 'Port of the MQTT broker'
    required: no
    control: true
  c.inPorts.add 'qos',
    datatype: 'integer'
    description: 'Quality of Service flag'
    required: no
    control: true
  c.inPorts.add 'retain',
    datatype: 'boolean'
    description: 'Whether to retain the latest message on broker'
    required: no
    control: true
  c.outPorts.add 'out',
    datatype: 'string'
  c.outPorts.add 'error',
    datatype: 'object'

  c.client = null
  c.forwardBrackets =
    message: ['out', 'error']

  sendMessage = (input, output) ->
    return unless c.client
    message = input.getData 'message'
    topic = input.getData 'topic'
    unless typeof message is 'string'
      message = JSON.stringify message

    qos = if input.has('qos') then input.getData('qos') else 0
    retain = if input.has('retain') then input.getData('retain') else false
    retain = c.params.retain or false
    c.client.publish topic, message
      qos: qos
      retain: retain
    , (err) ->
      return output.sendDone err if err
      output.sendDone
        out: message

  c.process (input, output) ->
    return unless input.has 'topic', 'message'
    unless c.client
      return unless input.has 'broker'
      broker = input.getData 'broker'
      port = if input.has('port') then input.getData('port') else 1883
      brokerUrl = url.format
        hostname: broker
        port: port
        protocol: 'mqtt'
        slashes: true
      c.client = mqtt.connect brokerUrl
      c.client.once 'connect', ->
        sendMessage input, output
      c.client.on 'error', (e) ->
        c.error e
        c.client = null
      c.client.on 'close', ->
        c.client = null
      return
    sendMessage input, output
