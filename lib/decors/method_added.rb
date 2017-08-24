require 'decors/utils'

module Decors
    module MethodAdded
        module Handler
            private

            METHOD_CALLED_TOO_EARLY_HANDLER = ->(*) {
                raise 'You cannot call a decorated method before its decorator is initialized'
            }

            def declared_decorators
                @declared_decorators ||= []
            end

            # method addition handling is the same for singleton and instance method
            def handle_method_addition(clazz, method_name)
                # @_ignore_additions allows to temporarily disable the hook
                return if @_ignore_additions || declared_decorators.empty?
                decorator_class, params, blk = declared_decorators.pop

                undecorated_method = clazz.instance_method(method_name)
                decorator = METHOD_CALLED_TOO_EARLY_HANDLER
                clazz.send(:define_method, method_name) { |*args, &block| decorator.call(self, *args, &block) }
                decorated_method = clazz.instance_method(method_name)
                @_ignore_additions = true
                decorator = decorator_class.new(clazz, undecorated_method, decorated_method, *params, &blk)
                @_ignore_additions = false
                clazz.send(Decors::Utils.method_visibility(undecorated_method), method_name)
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

        module SingletonListener
            include ::Decors::MethodAdded::Handler

            def singleton_method_added(meth)
                super
                handle_method_addition(singleton_class, meth)
            end

            def self.extended(base)
                ObjectSpace.each_object(base).first.send(:extend, ForwardToSingletonListener)
            end

            module ForwardToSingletonListener
                def singleton_method_added(meth)
                    super
                    singleton_class.send(:handle_method_addition, singleton_class, meth)
                end
            end
        end
    end
end
