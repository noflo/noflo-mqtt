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
  c.tearDown = (callback) ->
    c.client.end() if c.client
    c.client = null
    do callback

  c.forwardBrackets =
    message: ['out', 'error']

  sendMessage = (input, output) ->
    topic = input.getData 'topic'
    message = input.getData 'message'
    unless typeof message is 'string'
      message = JSON.stringify message

    qos = if input.hasData('qos') then input.getData('qos') else 0
    retain = if input.hasData('retain') then input.getData('retain') else false
    c.client.publish topic.data, message,
      qos: qos
      retain: retain
    , (err) ->
      return output.sendDone err if err
      output.sendDone
        out: message

  c.process (input, output) ->
    return unless input.hasData 'topic', 'message'
    return if input.attached('qos').length and not input.hasData 'qos'
    return if input.attached('retain').length and not input.hasData 'retain'
    unless c.client
      return unless input.hasData 'broker'
      return if input.attached('port').length and not input.hasData 'port'
      broker = input.getData 'broker'
      port = if input.hasData('port') then input.getData('port') else 1883
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
