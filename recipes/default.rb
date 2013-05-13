#
# Cookbook Name:: serial-console
# Recipe:: default
#
# Copyright (C) 2013 Derrick Bryant
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#
case node.platform
when 'centos', 'redhat'
  # Handle grub serial port
  #ruby_block "comment_out_grub_splashimage" do
  #  block do
  #    file = Chef::Util::FileEdit.new("/boot/grub/grub.conf")
  #    file.insert_line_if_no_match("/^(splashimage.*)$/", "##{1}")
  #    file.write_file
  #  end
  #end 

  # Remove hiddenline from grub.conf
  execute "comment_out_hiddenmenu" do
    command "sed -i '/^hiddenmenu/s/^/#/' /boot/grub/grub.conf"
    action :run
    only_if "grep ^hiddenmenu /boot/grub/grub.conf"
  end 
  
  # Remove splash from grub.conf
  execute "comment_out_splashimage" do
    command "sed -i '/^splash/s/^/#/' /boot/grub/grub.conf"
    action :run
    only_if "grep ^splash /boot/grub/grub.conf"
  end 

  # Add serial line to grub 
  #ruby_block "insert_grub_serial_line" do
  #  block do
  #    file = Chef::Util::FileEdit.new("/boot/grub/grub.conf")
  #    file.insert_line_after_match("/^timeout/", "serial --unit=0 --speed=#{node[:serial_console][:tty]} --word=8 --parity=no --stop=1")
  #    file.write_file
  #  end
  #end 
  
  # Add terminal line to grub 
  ruby_block "insert_grub_terminal_line" do
    block do
      file = Chef::Util::FileEdit.new("/boot/grub/grub.conf")
      file.insert_line_after_match("/^timeout/", "terminal --timeout=10 serial console")
      file.write_file
    end
  end 

  # Start tty
  execute "start-serial-console" do
    command "/sbin/initctl start #{node[:serial_console][:tty]}"
    action :nothing
  end

  # Stop tty
  execute "stop-serial-console" do
    command "/sbin/initctl stop #{node[:serial_console][:tty]}"
    action :nothing
  end
  
  # Add tty to securetty
  ruby_block "insert_line_securetty" do
    block do
      file = Chef::Util::FileEdit.new("/etc/securetty")
      file.insert_line_if_no_match("/#{node[:serial_console][:tty]}/", "#{node[:serial_console][:tty]}")
      file.write_file
    end
  end 
  
  # Install init conf file
  template "/etc/init/#{node[:serial_console][:tty]}.conf" do
    source "tty.erb"
    owner "root"
    group "root"
    mode "0600"
    action :delete if node[:serial_console][:disable]
    notifies :run, "execute[start-serial-console]"
  end
  
  # If disabled, stop 
  if node[:serial_console][:disable]
    notifies :run, "execute[stop-serial-console]"
  end
end
