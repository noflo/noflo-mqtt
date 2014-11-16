noflo = require 'noflo'
mqtt = require 'mqtt'
chai = require 'chai' unless chai
SendMessage = require '../components/SendMessage.coffee'

describe 'SendMessage component', ->
  c = null
  topic = null
  message = null
  broker = null
  beforeEach ->
    c = SendMessage.getComponent()
    topic = noflo.internalSocket.createSocket()
    message = noflo.internalSocket.createSocket()
    broker = noflo.internalSocket.createSocket()
    c.inPorts.topic.attach topic
    c.inPorts.message.attach message
    c.inPorts.broker.attach broker

  describe 'sending message to a topic', ->
    it 'should produce the message', (done) ->
      client = mqtt.createClient 1883, 'localhost'
      client.subscribe 'noflo'
      client.on 'message', (t, m) ->
        chai.expect(t).to.equal 'noflo'
        chai.expect(m).to.equal 'hello world'
        done()
      broker.send 'localhost'
      topic.send 'noflo'
      message.send 'hello world'
