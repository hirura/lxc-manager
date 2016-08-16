# coding: utf-8

require 'pty'
require 'timeout'

class LxcManager
	class CliAgent
		@@logger = LxcManager::Logger.instance
		@@out = nil
		@@columns = 200
		@@timeout = 300
		@@enable_realtime_output = false

		def self.open local_shell, logger: @@logger, out: @@out
			logger.info "#{self.to_s}##{__method__}"
			if block_given?
				cli_agent = self.new( local_shell['shell_command'], local_shell['shell_prompt'], logger: logger, out: out )
				yield cli_agent
				cli_agent.close logger: logger, out: out
			else
				cli_agent = self.new( local_shell['shell_command'], local_shell['shell_prompt'], logger: logger, out: out )
			end
		end

		def initialize login_shell, prompt, logger: @@logger, out: @@out, timeout: @@timeout
			@login_shell = login_shell
			@jump = Array.new
			@jump.push( {
				prompt: prompt,
				logger: logger,
				out: out,
			} )

			@i, @o, @pid = PTY.spawn( "COLUMNS=#{@@columns} #{@login_shell}" )
			def @i.my_expect( wait, logger: @@logger, out: @@out, timeout: @@timeout )
				ret = ""
				tmp1 = ""
				tmp2 = ""
				loop{
					Timeout.timeout( timeout ){
						tmp1 = self.readpartial(8192)
					}
					if @@enable_realtime_output
						unless logger == nil
							logger.debug tmp1
						end
						unless out == nil
							out.print tmp1
							out.flush
						end
					end
					ret += tmp1
					if tmp2.size < 80
						tmp2 += tmp1
					else
						tmp2 = tmp1
					end
					break if tmp2 =~ wait
				}
				return ret
			end
			@o.sync = true

			begin
				@i.my_expect( @jump[0][:prompt], logger: @jump[0][:logger], out: @jump[0][:out], timeout: timeout )

				command = "stty cols #{@@columns}"
				@o.puts command
				@i.my_expect( @jump[0][:prompt], logger: @jump[0][:logger], out: @jump[0][:out], timeout: timeout )
			rescue => e
				raise "Failed: Login: #{@login_shell}: #{e.backtrace.join("\n")}"
			end
		end

		def jump type, target: {}, logger: @jump.last[:logger], out: @jump.last[:out], timeout: @@timeout
			logger.info "#{self.class}##{__method__}"
			logger.debug "#{self.class}##{__method__}: " + "type: #{type}"
			case type
			when :ssh
				begin
					ssh_address = target[:address]
					ssh_port = target[:port]
					ssh_user = target[:user]
					ssh_auth = target[:auth]
					ssh_password = target[:password]

					command = "LANG=C ssh #{ssh_address} -p #{ssh_port} -l #{ssh_user} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
					logger.debug "#{self.class}##{__method__}: " + "command: #{command}"

					case ssh_auth
					when :password
						@o.puts command
						@i.my_expect( /[pP]assword.*?:.*?/, logger: logger, out: out )

						command = ssh_password
					end

					@o.puts command
					ret_str_raw = ret_str_raw = @i.my_expect( target[:prompt], logger: logger, out: out, timeout: timeout )
					logger.debug "#{self.class}##{__method__}: " + "ret_str_raw: #{ret_str_raw}"
				rescue
					@o.write "\003"
					@i.my_expect( @jump.last[:prompt], logger: logger, out: out, timeout: timeout )
					raise "Failed: Jump: ssh #{ssh_address} -p #{ssh_port} -l #{ssh_user}"
				end

				@jump.push( {
					prompt:  target[:prompt],
					logger: logger,
					out: out,
				} )
			when :exit
				begin
					target = @jump[-2]

					command = "exit"
					logger.debug "#{self.class}##{__method__}: " + "command: #{command}"

					@o.puts command
					ret_str_raw = @i.my_expect( target[:prompt], logger: logger, out: out, timeout: timeout )
					logger.debug "#{self.class}##{__method__}: " + "ret_str_raw: #{ret_str_raw}"
				rescue
					@o.write "\003"
					@i.my_expect( @jump.last[:prompt], logger: logger, out: out, timeout: timeout )
					raise "Failed: Jump: exit"
				end

				@jump.pop
			when :logout
				begin
					target = @jump[-2]

					command = "logout"
					logger.debug "#{self.class}##{__method__}: " + "command: #{command}"

					@o.puts command
					ret_str_raw = @i.my_expect( target[:prompt], logger: logger, out: out, timeout: timeout )
					logger.debug "#{self.class}##{__method__}: " + "ret_str_raw: #{ret_str_raw}"
				rescue
					@o.write "\003"
					@i.my_expect( @jump.last[:prompt], logger: logger, out: out, timeout: timeout )
					raise "Failed: Jump: logout"
				end

				@jump.pop
			else
				logger.debug "#{self.class}##{__method__}: " + "type: #{type}: undefined type"
				raise "Undefined jump type"
			end
		end

		def run command_str, logger: @jump.last[:logger], out: @jump.last[:out], timeout: @@timeout
			logger.info "#{self.class}##{__method__}"
			logger.debug "#{self.class}##{__method__}: " + "command: #{command_str}"
			line_num_of_command_str = command_str.split("\n").size
			command = command_str
			@o.puts command
			ret_str_raw = @i.my_expect( @jump.last[:prompt], logger: logger, out: out, timeout: timeout )
			ret_str = ret_str_raw.chomp.gsub( "#{command}", "" ).sub( /^.+[\r\n]+/, "" ).split("\n")[(line_num_of_command_str-1)..-2].map{ |l| l.chomp.split("\r").last }.join("\n")
			logger.debug "#{self.class}##{__method__}: " + "ret_str_raw: #{ret_str_raw}"
			return ret_str
		end

		def exit_status logger: @jump.last[:logger], out: @jump.last[:out], timeout: @@timeout
			logger.info "#{self.class}##{__method__}"
			command = "echo $?"
			@o.puts command
			ret_str_raw = @i.my_expect( @jump.last[:prompt], logger: logger, out: out, timeout: timeout )
			ret_num = ret_str_raw.split("\n")[1].chomp.to_i
			logger.debug "#{self.class}##{__method__}: exit_status: #{ret_num}"
			return ret_num
		end

		def close logger: nil, out: nil
			logger.info "#{self.class}##{__method__}"
			t = Process.detach( @pid )
			@o.close
			@i.close
			begin
				Timeout.timeout( @@timeout ){
					t.join
				}
			rescue Timeout::Error
				logger.warn "#{self.class}##{__method__}: " + "Timeout::Error occued"
				t.kill
			end
		end
	end
end

if __FILE__ == $0
	local_shell = {
		shell_command: "/bin/bash --login",
		shell_prompt:  /^[\[]?.+[:@].+ .+[\]]?[\#\$] /,
	}
	host = {
		name: "localhost",
		address: "127.0.0.1",
		port: "22",
		user: "root",
		password: "rootroot",
		prompt:  /^[\[]?.+[:@].+ .+[\]]?[\#\$] /,
	}

	s = LxcManager::CliAgent.open( local_shell, logger: nil, out: nil )

	str = "ls -logtrsh"
	puts "===== run '#{str}' ====="
	ret = s.run str
	puts ret
	puts s.exit_status

	str = ""
	str += "echo \"\n"
	str += "aaa\n"
	str += "bbb\n"
	str += "\""
	puts "===== run '#{str}' ====="
	ret = s.run str
	puts ret
	puts s.exit_status

	s.close

	LxcManager::CliAgent.open( local_shell, logger: nil, out: nil ){ |s|
		str = "ls -logtrsh"
		puts "===== run '#{str}' ====="
		ret = s.run str
		puts ret
		puts s.exit_status

		s.jump( :ssh, target: host )

		str = "ls -logtrsh"
		puts "===== run '#{str}' ====="
		ret = s.run str
		puts ret
		puts s.exit_status

		s.jump( :exit )

		str = "ls -logtrsh"
		puts "===== run '#{str}' ====="
		ret = s.run str
		puts ret
		puts s.exit_status

		s.jump( :ssh, target: host )

		str = "ls -logtrsh"
		puts "===== run '#{str}' ====="
		ret = s.run str
		puts ret
		puts s.exit_status

		s.jump( :logout )

		str = "ls -logtrsh"
		puts "===== run '#{str}' ====="
		ret = s.run str
		puts ret
		puts s.exit_status

		str = "echo 'abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz'"
		puts "===== run '#{str}' ====="
		ret = s.run str
		puts ret
		puts s.exit_status

		str = "stty -a"
		puts "===== run '#{str}' ====="
		ret = s.run str
		puts ret
		puts s.exit_status

		str = "for i in $(seq 0 10); do echo -n $i; sleep 1; done"
		puts "===== run '#{str}' ====="
		ret = s.run str
		puts ret
		puts s.exit_status
	}
end

