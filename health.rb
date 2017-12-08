#!/usr/bin/env ruby
require 'net/http'
require 'json'


$SCRIPT_VERSION = "1.2"

def print_usage_and_exit
  puts "Storj stat updater v#{$SCRIPT_VERSION}"
  puts "Usage: #{$0} email [daemon address] [daemon port]"
  puts "  address defaults to 127.0.0.1"
  puts "  port defaults to 45015"
  exit(2)
end

print_usage_and_exit if [nil, "-h", "--help"].include? ARGV[0]


$EMAIL = ARGV[0]
$DAEMON_ADDR = ARGV[1] || "127.0.0.1"
$DAEMON_PORT = ARGV[2] || 45015

$BASE_DIR = File.expand_path File.dirname __FILE__
$NOW = Time.now


def fmt_uptime(ms)
  "#{ms/24/3600/1000}d#{(ms/3600/1000)%24}h#{(ms/60/1000)%60}m#{(ms/1000)%60}s"
end

def fmt_allocation(str)
  str =~ /^(\d+)(B|KB|MB|GB|TB)$/
  return $1.to_i * {'B'=>1, 'KB'=>1024, 'MB'=>1024*1024, 'GB'=>1024*1024*1024, 'TB'=>1024*1024*1024*1024}[$2]
end

def get_log_info(node_id, logs_dir)
  stat = Hash[%w(publish offer consignment download upload).map{|n| [n.to_sym, {last:nil, count:0}] }]
  def event(name, line, stat)
    stat[name][:last] = line
    stat[name][:count] += 1
  end
  File.new("#{logs_dir}/#{node_id}_#{$NOW.year}-#{$NOW.month}-#{$NOW.day}.log").each do |line|
    if line.include? "PUBLISH"
      event(:publish, line, stat)
    elsif line.include? "OFFER"
      event(:offer, line, stat)
    elsif line.include? "consignment"
      event(:consignment, line, stat)
    elsif line.include? "download"
      event(:download, line, stat)
    elsif line.include? "upload"
      event(:upload, line, stat)
    end
  end
  stat.each{|k,v| v[:last] = v[:last] && JSON.load(v[:last])["timestamp"] }
  return stat
end

def get_api_node(bridge_uri, id)
	n = 5
	n.times do |iter|
		begin
			return JSON.load(Net::HTTP.get(URI(bridge_uri+"/contacts/"+id)))
		rescue
			if iter < n-1
				puts "ERROR getting #{id}, retrying #{iter+1}/#{n-1}..."
				sleep(iter+1)
			else
				raise
			end
		end
	end
end

def get_my_nodes_stats
  puts "Getting nodes data..."
  sock = TCPSocket.new $DAEMON_ADDR, $DAEMON_PORT
  sock.gets
  sock.puts '{"method":"status","arguments":["[Function]"],"callbacks":{"0":["0"]},"links":[]}'
  status = JSON.load(sock.gets)["arguments"][1]
  sock.close

  status.map do |node|
    puts "Node #{node['id']}:"

    puts "  getting API info..."
    bridge_uri = node["config"]["bridgeUri"] || node["config"]["bridges"][0]['url']
	api_node = get_api_node(bridge_uri, node["id"])
    puts "  getting LOG info..."
    log_info = get_log_info(node["id"], node["config"]["loggerOutputFile"])

    is_linux = !!(RUBY_PLATFORM =~ /linux/)
    is_windows = !is_linux && !!(RUBY_PLATFORM =~ /cygwin|mswin|mingw|bccwin|wince|emx/)

    {
      email: $EMAIL,
      node_id: node["id"],
      status: node["state"],
      address: node["config"]["rpcAddress"],
      port: node["config"]["rpcPort"],
      agent: api_node["userAgent"],
      localtime: Time.now.to_i,
      os: is_linux ? 1 : is_windows ? 2 : 0,
      ver: "rb#{$SCRIPT_VERSION}",

      uptime: fmt_uptime(node["meta"]["uptimeMs"]),
      peers: node["meta"]["farmerState"]["totalPeers"],
      drc: node["meta"]["farmerState"]["dataReceivedCount"],
      restarts: node["meta"]["numRestarts"],
      lcs: api_node["lastContractSent"],
      SpaceAvailable: api_node["spaceAvailable"],

      share_allocated: fmt_allocation(node["config"]["storageAllocation"]),
      share_used: node["meta"]["farmerState"]["spaceUsedBytes"],

      ls: api_node["lastSeen"],
      lt: api_node["lastTimeout"],
      tr: api_node["timeoutRate"],
      rt: api_node["responseTime"].to_i,
      reputation: api_node["reputation"],
      delta: node["meta"]["farmerState"]["ntpStatus"]["delta"].to_i,
      offers: node["meta"]["farmerState"]["contractCount"],
      bridge_status: node["meta"]["farmerState"]["bridgesConnectionStatus"], #3:"connected", 2:"confirming", 1:"connecting", 0:"disconnected"

      last_offer: log_info[:offer][:last],
      last_upload: log_info[:upload][:last],
      last_publish: log_info[:publish][:last],
      last_download: log_info[:download][:last],
      last_consignment: log_info[:consignment][:last],

      upload_count: log_info[:upload][:count],
      publish_count: log_info[:publish][:count],
      download_count: log_info[:download][:count],
      consignment_count: log_info[:consignment][:count],
    }
  end
end

stats = get_my_nodes_stats
puts ""
puts "Sending..."
stats.each do |stat|
  puts "  node #{stat[:node_id]}:"
  stat.each{|k,v| puts "    #{k}:#{' '*(17-k.size)} #{v}" }
  uri = URI('https://api.storj.maxrival.com/v1/')
  res = Net::HTTP.post_form(uri, stat)
  puts "  response: #{res.body}"
end
puts "Done."
