Puppet::Parser::Functions::newfunction(:resource_permute) do |args|
  Puppet::Parser::Functions.autoloader.loadall

  require 'erb'

  raise Puppet::ParseError, ("resource_permute(): wrong number of arguments (#{args.length}; must be 3)") if args.length != 3

  # First arg: resource type for createion
  # Second arg: the hash of permutable resourece paramaters
  # Third arg: common paramaters that will belong to all resources created

  rec_type    = args[0]
  unique_hash = args[1]
  common_hash = args[2]

  unless rec_type.is_a? String
    raise Puppet::Error, "resource_permute(): resource type must be a string"
  end

  unless unique_hash.is_a? Hash
    raise Puppet::Error, "resource_permute(): unique must be a hash"
  end

  unless common_hash.is_a? Hash
    raise Puppet::Error, "resource_permute(): common must be a hash"
  end

  # Class borrowed from:
  # https://github.com/lucasdicioccio/laborantin/blob/master/lib/laborantin/core/parameter_hash.rb
  class ParameterHash < Hash
    # Recursively yields all the possible configurations of parameters (a new hash).
    # No order is supported on the recursion, and it is not planned to.
    def each_config(remaining=self.keys, cfg={}, &blk)
      key = remaining.pop
      if key
        self[key].each do |val|
          cfg[key] = val
          each_config(remaining.dup, cfg, &blk)
        end
      else
        yield cfg
      end
    end

    def to_s
      keys.inject(''){|s,k| s + "\t- #{k}: #{self[k]}.\n"}
    end
  end

  params = ParameterHash.new.replace(unique_hash)
  params.each_config do |cfg|
    title = cfg

    # if we have a common_hash, copy the enrtries out for us in the finished
    # resource
    if common_hash.is_a?(Hash)
      common_hash.keys.each do |key|
        cfg["#{key}"] = common_hash["#{key}"]
      end
    end
    # Set the title on the finished resource
    fin = {}
    fin["#{title}"] = title
    # Call out to create_resoruces to do the actual work
    function_create_resources([rec_type,fin])
  end

end

