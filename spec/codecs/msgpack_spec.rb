# encoding: utf-8
require "logstash-core"
require "logstash/devutils/rspec/spec_helper"
require "logstash/codecs/msgpack"
require "logstash/event"
require "insist"

describe LogStash::Codecs::Msgpack do
  subject do
    next LogStash::Codecs::Msgpack.new
  end

  context "#decode" do
    it "should return an event from msgpack data" do
      data = {"foo" => "bar", "baz" => {"bah" => ["a","b","c"]}, "@timestamp" => "2014-05-30T02:52:17.929Z"}
      subject.decode(MessagePack.pack(data)) do |event|
        insist { event.is_a? LogStash::Event }
        insist { event.get("foo") } == data["foo"]
        insist { event.get("baz") } == data["baz"]
        insist { event.get("bah") } == data["bah"]
        insist { event.get("@timestamp").to_iso8601 } == data["@timestamp"]
      end
    end
  end

  context "#encode" do
    it "should return msgpack data from pure ruby hash" do
      data = {"foo" => "bar", "baz" => {"bah" => ["a","b","c"]}, "@timestamp" => "2014-05-30T02:52:17.929Z"}
      event = LogStash::Event.new(data)
      got_event = false
      subject.on_event do |e, d|
        insist { MessagePack.unpack(d)["foo"] } == data["foo"]
        insist { MessagePack.unpack(d)["baz"] } == data["baz"]
        insist { MessagePack.unpack(d)["bah"] } == data["bah"]
        insist { MessagePack.unpack(d)["@timestamp"] } == "2014-05-30T02:52:17.929Z"
        insist { MessagePack.unpack(d)["@timestamp"] } == event.get("@timestamp").to_iso8601
        got_event = true
      end
      subject.encode(event)
      insist { got_event }
    end

    it "should return msgpack data from deserialized json with normalization" do
      data = LogStash::Json.load('{"foo": "bar", "baz": {"bah": ["a","b","c"]}, "@timestamp": "2014-05-30T02:52:17.929Z"}')
      event = LogStash::Event.new(data)
      got_event = false
      subject.on_event do |e, d|
        insist { MessagePack.unpack(d)["foo"] } == data["foo"]
        insist { MessagePack.unpack(d)["baz"] } == data["baz"]
        insist { MessagePack.unpack(d)["bah"] } == data["bah"]
        insist { MessagePack.unpack(d)["@timestamp"] } == "2014-05-30T02:52:17.929Z"
        insist { MessagePack.unpack(d)["@timestamp"] } == event.get("@timestamp").to_iso8601
        got_event = true
      end
      subject.encode(event)
      insist { got_event }
    end
  end

end
