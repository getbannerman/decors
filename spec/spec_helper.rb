require File.expand_path('../../lib/decors', __FILE__)

module SpecHelpers
    def stub_class(class_name, inherits: [], &class_eval)
        klass = stub_const(class_name.to_s, Class.new(*inherits))
        klass.class_eval(&class_eval) if class_eval
        klass
    end

    def stub_module(module_name, &module_eval)
        mod = stub_const(module_name.to_s, Module.new)
        mod.module_eval(&module_eval) if module_eval
        mod
    end
end

RSpec.configure do |config|
    config.include SpecHelpers
end
