module Decors
    module Utils
        class << self
            def method_visibility(method)
                if method.owner.private_method_defined?(method.name)
                    :private
                elsif method.owner.protected_method_defined?(method.name)
                    :protected
                elsif method.owner.public_method_defined?(method.name)
                    :public
                else
                    fail ArgumentError, 'Unkwnown method'
                end
            end
        end
    end
end
