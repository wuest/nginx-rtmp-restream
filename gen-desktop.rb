#!/usr/bin/env ruby

def query(prompt, default=nil)
  print prompt + (default.nil? ? '' : " (#{default})") + '> '
  answer = gets.strip
  if answer.empty?
    if default.nil?
      return query(prompt, default)
    else
      return default
    end
  end
  answer
end

def query_yn(prompt, default=nil)
  answer = query(prompt, default)
  return query_yn(prompt, default) unless /^[yn]/i.match(answer)
  /^y/i.match(answer)
end

def docker_info
  name = query('Desired docker image name', 'rtmp-relay')
  wp   = query('Local web port', '8080').to_i
  unless wp > 0 && wp < 65535
    puts "Web port must be a valid port number"
    exit
  end

  rp   = query('Local rtmp port', '1935').to_i
  unless rp > 0 && rp < 65535
    puts "RTMP port must be a valid port number"
    exit
  end
  unless rp != wp
    puts "Web and RTMP ports must differ"
    exit
  end

  { web: wp, rtmp: rp, image: name }
end

def instance_info
  profile = query('Profile name')
  scenes  = query('Scene collection name')
  { profile: profile, scenes: scenes }
end

def obs_instances(instances = [])
  puts 'Currently known OBS instances:'
  instances.each { |i| puts "Profile: #{i[:profile]} (#{i[:scenes]})" }
  puts

  if query_yn('Add an OBS instance?', 'n')
    return obs_instances(instances + [instance_info])
  end
  instances
end

def write_shell(fd, docker, obs)
  fd.puts("#!/bin/sh")
  fd.puts
  fd.puts("[[ $(docker ps -f 'name=#{docker[:image]}' --format '{{.Names}}') == rtmp-relay ]] || docker run -d -p 127.0.0.1:#{docker[:web]}:8080 -p 127.0.0.1:#{docker[:rtmp]}:1935 --name #{docker[:image]} #{docker[:image]}:latest")
  fd.puts
  obs.each do |o|
    fd.puts("obs -m --profile '#{o[:profile]}' --collection '#{o[:scenes]}' &")
  end
end

def write_desktop(shell_path)
  File.open('rtmp-obs-relay.desktop', 'w') do |fd|
    fd.puts('[Desktop Entry]')
    fd.puts('Version=1.0')
    fd.puts('Name=RTMP Multiplexed OBS Studio')
    fd.puts('GenericName=Streaming/Recording Software')
    fd.puts('Comment=Free and Open Source Streaming/Recording Software')
    fd.puts("Exec=#{shell_path}")
    fd.puts('Icon=obs')
    fd.puts('Terminal=false')
    fd.puts('Type=Application')
    fd.puts('Categories=AudioVideo;Recorder;')
    fd.puts('StartupNotify=false')
  end
end

def main
  docker = docker_info
  obs    = obs_instances

  shell_path = query('Shell script target (empty to simply display)', '')

  if shell_path.empty?
    write_shell($stdout, docker, obs)
    exit
  end

  f = File.open(shell_path, 'w')
  write_shell(f, docker, obs)
  f.close
  File.chmod(0755, shell_path)

  if query_yn('Write desktop file?')
    write_desktop(shell_path)

    puts "Make sure to move #{shell_path} somewhere into PATH (e.g. $HOME/bin)"
    puts "Move rtmp-obs-relay.desktop to a directory used by your desktop"
    puts "environment (often $HOME/.local/share/applications)"
    puts
    puts "If the RTMP service ever fails to connect, remember to check docker's status."
  end
end

main
