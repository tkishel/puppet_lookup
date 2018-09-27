#!/opt/puppetlabs/puppet/bin/ruby

require 'facter'
require 'json'
require 'open3'
require 'puppet'
require 'timeout'

Puppet.initialize_settings

# Read parameters, set defaults, and validate values.
#
# TDB: --default, --explain-options, --facts, --type --knock-out-prefix, --merge-hash-arrays, --sort-merged-arrays

def read_parameters
  params = read_stdin

  params['key']         = (params['key'])         ? params['key']         : ''
  params['target']      = (params['target'])      ? params['target']      : Puppet[:certname]
  params['environment'] = (params['environment']) ? params['environment'] : Puppet[:environment]
  params['merge']       = (params['merge'])       ? params['merge']       : 'first'
  params['compile']     = (params['compile'])     ? '--compile'           : ''
  params['explain']     = (params['explain'])     ? '--explain'           : ''
  params['render']      = (params['render'])      ? params['render']      : 'json'

  # Validate parameter values or return errors.

  merge_options  = %w[first unique hash deep]
  render_options = %w[s json yaml]

  return_error("Parameter 'key' contains illegal characters")         unless safe_string?(params['key'])
  return_error("Parameter 'target' contains illegal characters")      unless safe_string?(params['target'])
  return_error("Parameter 'environment' contains illegal characters") unless safe_string?(params['environment'])
  return_error("Parameter 'merge' is limited to #{merge_options}")    unless merge_options.include?(params['merge'])
  return_error("Parameter 'render' is limited to #{render_options}")  unless render_options.include?(params['render'])

  params
end

# Read parameters as JSON from STDIN.

def read_stdin
  params = {}
  begin
    Timeout.timeout(3) do
      params = JSON.parse(STDIN.read)
    end
  rescue Timeout::Error
    return_error('Cannot read parameters as JSON from STDIN')
  end
  params
end

# Validate strings.
#
# While handled by task.json, validate in the task for defense in depth.

def safe_string?(param)
  return true unless param
  (param =~ %r{^[a-z0-9\.\_\-\:]+$}) != nil
end

# Execute a command with an array of arguments and return the result as a hash.

def execute_command(command, args = [])
  # Convert each element of the args array to a string.
  args = args.reject { |a| a.empty? }.map(&:to_s)
  # Execute the command with the arguments passed as a variable length argument list using the asterisk operator.
  stdout, stderr, status = Open3.capture3(command, *args)
  # Merge the command and args into a string.
  command_line = args.unshift(command).join(' ')
  { command: command_line, status: status.exitstatus, stdout: stdout.strip, stderr: stderr.strip }
end

# Return an error and exit.

def return_error(message)
  result = {}
  result[:_error] = {
    msg:     message,
    kind:    'puppet_lookup/failure',
    details: {}
  }
  puts result.to_json
  exit 1
end

# Return the error results of a command and exit.

def return_command_error(params, command_results)
  result = {}
  result[:status]  = 'failure'
  result[:command] = command_results[:command]
  result[:error]   = command_results[:stderr]
  result[:params]  = params
  puts result.to_json
  exit 1
end

# Return the results of a command and exit.

def return_command_results(params, command_results)
  result = {}
  result[:status]  = 'success'
  result[:command] = command_results[:command]
  result[:results] = (params['render'] == 'json') ? JSON.parse(command_results[:stdout]) : command_results[:stdout]
  puts result.to_json
  exit 0
end

######
# Main
######

# Master or Compile Master validation.

unless File.exist?('/opt/puppetlabs/bin/puppetserver')
  return_error('This node does not appear to be a master or compile master')
end

params = read_parameters

command = 'puppet'
options = [
  'lookup',
  params['key'],
  '--node',          params['target'],
  '--environment',   params['environment'],
  '--merge',         params['merge'],
  '--render-as',     params['render'],
  params['compile'],
  params['explain'],
]

results = execute_command(command, options)

# The puppet lookup command exits with a status of 1 if the key is not found.

if results[:stderr] != '' || (results[:stdout] != '' && results[:status] != 0)
  return_command_error(params, results)
else
  return_command_results(params, results)
end
