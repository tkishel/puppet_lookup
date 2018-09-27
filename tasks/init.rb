#!/opt/puppetlabs/puppet/bin/ruby

require 'facter'
require 'json'
require 'open3'
require 'puppet'
require 'timeout'

Puppet.initialize_settings

# Read parameters, set defaults, and validate values.
#
# TODO or N/A: --default, --facts, --knock-out-prefix, --type

def read_parameters
  input = read_stdin
  output = {}

  output['key']                = input['key']
  output['target']             = (input['target'])             ? input['target']        : Puppet[:certname]
  output['environment']        = (input['environment'])        ? input['environment']   : Puppet[:environment]
  output['compile']            = (input['compile'])            ? '--compile'            : ''
  output['explain']            = (input['explain'])            ? '--explain'            : ''
  output['explain_options']    = (input['explain_options'])    ? '--explain-options'    : ''
  output['merge']              = (input['merge'])              ? input['merge']         : 'first'
  output['merge_hash_arrays']  = (input['merge_hash_arrays'])  ? '--merge-hash-arrays'  : ''
  output['sort_merged_arrays'] = (input['sort_merged_arrays']) ? '--sort-merged-arrays' : ''
  output['render_as']          = (input['render_as'])          ? input['render_as']     : 'json'

  # Render the output as plain text when explain is specified, unless an output format is specified.
  if input['explain'] || input['explain_options']
    output['render_as'] = 's' unless input['render_as']
  end

  # Validate parameter values or return errors.

  valid_merge_options     = %w[first unique hash deep]
  valid_render_as_options = %w[s json yaml]

  return_error("Parameter 'key' contains illegal characters")                    unless safe_string?(output['key'])
  return_error("Parameter 'target' contains illegal characters")                 unless safe_string?(output['target'])
  return_error("Parameter 'environment' contains illegal characters")            unless safe_string?(output['environment'])
  return_error("Parameter 'merge' is limited to #{valid_merge_options}")         unless valid_merge_options.include?(output['merge'])
  return_error("Parameter 'render_as' is limited to #{valid_render_as_options}") unless valid_render_as_options.include?(output['render_as'])

  output
end

# Read parameters as JSON from STDIN.

def read_stdin
  input = {}
  begin
    Timeout.timeout(3) do
      input = JSON.parse(STDIN.read)
    end
  rescue Timeout::Error
    return_error('Cannot read parameters as JSON from STDIN')
  end
  input
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
  result[:results] = (params['render-as'] == 'json') ? JSON.parse(command_results[:stdout]) : command_results[:stdout]
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
  '--node', params['target'],
  '--environment', params['environment'],
  params['compile'],
  params['explain'],
  params['explain_options'],
  '--merge', params['merge'],
  params['merge_hash_arrays'],
  params['sort_merged_arrays'],
  '--render-as', params['render_as'],
]

results = execute_command(command, options)

# The puppet lookup command exits with a status of 1 if the key is not found.

if results[:stderr] != '' || (results[:stdout] != '' && results[:status] != 0)
  return_command_error(params, results)
else
  return_command_results(params, results)
end
