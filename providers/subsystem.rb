#
# Cookbook: aix
# License: Apache 2.0
#
# Copyright 2008-2015, Chef Software, Inc.
# Copyright 2015, Bloomberg Finance L.P.
#

require 'chef/mixin/shell_out'

include Chef::Mixin::ShellOut

def whyrun_supported?
  true
end

def load_current_resource
  @current_resource = Chef::Resource::AixSubsystem.new(@new_resource.name)
  @current_resource.enabled = false
end

action :create do
  command = ['-p', new_resource.program]
  command << ['-u', Etc.getpwuid(new_resource.user)]
  command << ['-a', "#{new_resource.arguments.join(' ')}"] if new_resource.arguments
  command << ['-t', new_resource.subsystem_synonym] if new_resource.subsystem_synonym
  command << ['-G', new_resource.subsystem_group] if new_resource.subsystem_group
  command << ['-e', new_resource.standard_error] if new_resource.standard_error
  command << ['-i', new_resource.standard_input] if new_resource.standard_input
  command << ['-o', new_resource.standard_output] if new_resource.standard_output

  if @current_resource.enabled
    unless @current_resource.subsystem_name == @new_resource.subsystem_name
      command << ['-s', @new_resource.subsystem_name]
    end

    converge_by('change subsystem entry') do
      shell_out(["chssys -s #{@current_resource.subsystem_name}"].concat(command).flatten.join(' '))
    end
  else
    converge_by('enable subsystem entry') do
      shell_out(["mkssys -s #{@new_resource.subsystem_name}"].concat(command).flatten.join(' '))
    end
  end
end

action :delete do
  if @current_resource.enabled
    converge_by('remove subsystem entry') do
      shell_out("rmssys -s #{@current_resource.service_name}")
    end
  end
end
