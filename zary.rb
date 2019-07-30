require "mastodon"
require "sanitize"

MASTODON_HOST = "https://mstdn.anqou.net"

raise "set MASTODON_ACCESS_TOKEN" unless ENV.key? "MASTODON_ACCESS_TOKEN"

rest = Mastodon::REST::Client.new(base_url: MASTODON_HOST, bearer_token: ENV["MASTODON_ACCESS_TOKEN"])
stream = Mastodon::Streaming::Client.new(base_url: MASTODON_HOST, bearer_token: ENV["MASTODON_ACCESS_TOKEN"])
stream.user do |event|
  #pp event

  next unless event.is_a?(Mastodon::Status)
  next unless event.attributes["reblog"].nil?
  next if event.account.bot?
  next unless event.visibility == "public" or event.visibility == "unlisted"
  next unless event.account.url =~ /mstdn\.anqou\.net/

  content = Sanitize.fragment(event.content)

  if content =~ /わいわい/
    puts "===== WAIWAI ====="
    p event
    rest.create_status("@#{event.account.acct} :bar_ter__: ＜わいわいするなわくわくしろ", in_reply_to_id: event.id)
  end
end
