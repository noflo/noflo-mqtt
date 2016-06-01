noflo = require 'noflo'
mqtt = require 'mqtt'
url = require 'url'

# @runtime noflo-nodejs

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
    topic = input.get 'topic'
    console.log 'TOPIC', topic
    return unless topic.type is 'data'
    message = input.getData 'message'
    console.log 'MESSAGE', message, topic
    unless typeof message is 'string'
      message = JSON.stringify message

    qos = if input.has('qos') then input.getData('qos') else 0
    retain = if input.has('retain') then input.getData('retain') else false
    console.log topic.data, message, qos, retain
    c.client.publish topic.data, message,
      qos: qos
      retain: retain
    , (err) ->
      return output.sendDone err if err
      output.sendDone
        out: message

  c.process (input, output) ->
    return unless input.has 'topic', 'message'
    unless c.client
      console.log 'INIT CLIENT'
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
        console.log 'SEND on CONNECT'
        sendMessage input, output
      c.client.on 'error', (e) ->
        c.error e
        c.client = null
      c.client.on 'close', ->
        c.client = null
      return
    console.log 'SEND direct'
    sendMessage input, output

  c.shutdown = ->
    c.client.end() if c.client
    c.client = null

  c
