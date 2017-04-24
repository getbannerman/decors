module Decors
    class DecoratorBase
        attr_reader :decorated_class, :decorated_method, :decorator_args, :decorator_kwargs, :decorator_block

        def initialize(decorated_class, decorated_method, *args, **kwargs, &block)
            @decorated_class = decorated_class
            @decorated_method = decorated_method
            @decorator_args = args
            @decorator_kwargs = kwargs
            @decorator_block = block
        end

        def call(instance, *args, &block)
            undecorated_call(instance, *args, &block)
        end

        def undecorated_call(instance, *args, &block)
            decorated_method.bind(instance).call(*args, &block)
        end

        def decorated_method_name
            decorated_method.name
        end
    end
end
