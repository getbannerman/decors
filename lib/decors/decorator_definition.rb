module Decors
    module DecoratorDefinition
        def define_mixin_decorator(decorator_name, decorator_class)
            define_decorator(decorator_name, decorator_class, mixin: true)
        end

        def define_decorator(decorator_name, decorator_class, mixin: false)
            method_definer = mixin ? :define_method : :define_singleton_method

            send(method_definer, decorator_name) do |*params, &blk|
                ctx = self.singleton_class? ? ObjectSpace.each_object(self).first : self
                ctx.send(:extend, MethodAddedListener)
                ctx.declared_decorators << [decorator_class, params, blk]
            end
        end
    end
end
