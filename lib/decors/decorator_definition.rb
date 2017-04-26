module Decors
    module DecoratorDefinition
        def define_mixin_decorator(decorator_name, decorator_class)
            define_decorator(decorator_name, decorator_class, mixin: true)
        end

        def define_decorator(decorator_name, decorator_class, mixin: false)
            method_definer = mixin ? :define_method : :define_singleton_method

            send(method_definer, decorator_name) do |*params, &blk|
                extend(singleton_class? ? Decors::MethodAdded::SingletonListener : Decors::MethodAdded::StandardListener)

                declared_decorators << [decorator_class, params, blk]
            end
        end
    end
end
