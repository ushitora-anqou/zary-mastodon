require "mastodon"
require "sanitize"
require "ostruct"
require "pp"

class MastoClient
  def initialize(host, access_token)
    @rest = Mastodon::REST::Client.new(base_url: host, bearer_token: access_token)
    @stream = Mastodon::Streaming::Client.new(base_url: host, bearer_token: access_token)
  end

  def stream
    @stream.user do |event|
      next unless event.is_a?(Mastodon::Status)
      next unless event.attributes["reblog"].nil?
      next if event.account.bot?
      next unless event.visibility == "public" or event.visibility == "unlisted"
      next unless event.account.url =~ /mstdn\.anqou\.net/

      yield event, @rest
    end
  end
end

class DummyClient
  class DummyRest
    def create_status(msg, options)
      pp(["out", { msg: msg, options: options }])
    end
  end

  def stream
    rest = DummyRest.new
    while gets
      event = OpenStruct.new({
        id: 100,
        account: OpenStruct.new({ acct: "dummyuser0" }),
        content: $_,
      })
      pp(["in", event])
      yield event, rest
    end
  end
end

client = if ENV.key? "MASTODON_ACCESS_TOKEN"
    puts "Use MastoClient..."
    MastoClient.new("https://mstdn.anqou.net", ENV["MASTODON_ACCESS_TOKEN"])
  else
    puts "Use DummyClient..."
    DummyClient.new
  end

client.stream do |event, rest|
  content = Sanitize.fragment(event.content)

  case content
  when /わいわい/
    rest.create_status("@#{event.account.acct} :bar_ter__: ＜わいわいするなわくわくしろ", in_reply_to_id: event.id)
  end
end
