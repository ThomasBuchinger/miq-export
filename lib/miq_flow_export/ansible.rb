json_arguments = '<<INCLUDE_ANSIBLE_MODULE_JSON_ARGS>>'

begin
  args = JSON.parse(json_arguments)
  
rescue JSON::ParserError => err
  STDERR.puts('No ansible module')
end
