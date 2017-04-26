module Decors
    module MethodAdded
        module Handler
            private

            def declared_decorators
                @declared_decorators ||= []
            end

            # method addition handling is the same for singleton and instance method
            def handle_method_addition(clazz, method_name)
                # @_ignore_additions allows to temporarily disable the hook
                return if @_ignore_additions || declared_decorators.empty?
                decorator_class, params, blk = declared_decorators.pop

                decorated_method = clazz.instance_method(method_name)

                @_ignore_additions = true
                decorator = decorator_class.new(clazz, decorated_method, *params, &blk)
                @_ignore_additions = false

                clazz.send(:define_method, method_name) { |*args, &block| decorator.call(self, *args, &block) }
            end
        end

        module StandardListener
            include ::Decors::MethodAdded::Handler

            def method_added(meth)
                super
                handle_method_addition(self, meth)
            end

            def singleton_method_added(meth)
                super
                handle_method_addition(singleton_class, meth)
            end
        end

        module ForwardToSingletonListener
            def singleton_method_added(meth)
                super
                singleton_class.send(:handle_method_addition, singleton_class, meth)
            end
        end

        module SingletonListener
            include ::Decors::MethodAdded::Handler

            def singleton_method_added(meth)
                super
                handle_method_addition(singleton_class, meth)
            end
        end
    end
end
