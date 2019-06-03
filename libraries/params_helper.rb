module Bobby
  class ParamsHelper
    def initialize(recipe)
      @recipe = recipe
    end

    def params_config
      @recipe.node['bobby']['params']
    end

    def finalize_value(val)
      pc = params_config
      keys = pc.keys

      new_val = val
      if new_val.is_a?(String)
        keys.each do |k|
          next unless pc[k].is_a?(String)

          new_val = new_val.gsub('{%s}' % k, pc[k])
        end
      end

      new_val
    end

    def [](k)
      params_config[k]
    end
  end
end
