require 'mechanize'
require 'yaml'

class FetchInfo
	def initialize conf
	begin
		agent = Mechanize.new
		# p agent.proxy_uri()
		agent.user_agent_alias = "Windows IE 9"
		url = 'http://hr.itc.inventec/itchr/Duty/DutyAllV1.aspx'
		user, pass = conf['user'], conf['pw']

		agent.add_auth(url, user, pass, nil, 'ITC')
		page = agent.get(url)

		fm = page.forms[0]
		@total_text = page.at('#b0')['value']
		@today_start_text = page.at('#lToday').text
	rescue Exception => e
		puts "authentication failed!"
		exit
	end
	end
	
	def get_info
		format @total_text, @today_start_text
		[@total, @today_start]
	end

	def print
		puts @total_text
		puts @today_start_text
	end

	protected
	def format total_text, today_start_text
		@total = nil
		if /^(\d+)\.?(\d+)?/=~total_text
			h = $1
			m = ("0.#{$2}".to_f * 60).to_i
			@total = "#{h}:#{m}"
		else
			puts total_text
		end

		@today_start = nil
		if /(\d+:\d+)$/=~today_start_text
			@today_start = $1
		else
			puts today_start_text
		end
	end
end

class Mytime
	def initialize time
		# p time
		if time.class==String
			to_arr(time)
		elsif time.class==Array
			@h = time[0]
			@m = time[1]
		else
			puts "Error on new Mytime, time=#{time}."
		end
	end

	def to_a
		[@h, @m]
	end
	def to_s
		hh = @h
		hh = "0#{@h}" if @h<10
		mm = @m
		mm = "0#{@m}" if @m<10
		"#{hh}:#{mm}"
	end

	def + time
		# p time
		t2 = Mytime.new(time).to_a
		t2_arr = [@h+t2[0], @m+t2[1]]
		if (t2_arr[1])>=60
			t2_arr[0]+=1; t2_arr[1]-=60
		end
		Mytime.new(t2_arr)
	end

	def - time
		t2 = Mytime.new(time).to_a
		t2_arr = [@h-t2[0], @m-t2[1]]
		if t2_arr[1]<0
			t2_arr[0]-=1; t2_arr[1]+=60
		end
		t2_arr[0]-=1 if t2[0]<12
		Mytime.new(t2_arr)
	end
	
	protected
	def to_arr time
		if /^(\d+):(\d+)$/=~ time
			@h = $1.to_i
			@m = $2.to_i
		else
			puts "Error on to_a, time=#{time}."
		end
	end
end

def main conf
	ie = FetchInfo.new(conf)
	ie.print
	puts ''
	info = ie.get_info
	ha = {"16:00"=> (Mytime.new("16:00")-info[1]+info[0]).to_s,
		"17:00" => (Mytime.new("17:00")-info[1]+info[0]).to_s,
		"18:00" => (Mytime.new("18:00")-info[1]+info[0]).to_s}
	ha.each{|k, v|
		puts "#{k}=>#{v}"
	}
end

ENV.update('HTTP_PROXY'=>nil)
# p ENV['HTTP_PROXY']

$conf = YAML::load_file('config.yml')['user_info']
# t1 = Time.new
main($conf)
# t2 = Time.new
# puts "Time spent: #{t2-t1}"
