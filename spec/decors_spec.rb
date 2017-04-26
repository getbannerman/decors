require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Decors do
    before { stub_class(:TestClass) { extend Decors::DecoratorDefinition } }
    before {
        stub_class(:Spy) {
            def self.passed_args(*args, **kwargs, &block)
                arguments(args: args, kwargs: kwargs, evald_block: block&.call)
            end

            def self.arguments(*); end
        }
    }

    context 'when simple case decorator' do
        before {
            stub_class(:SimpleDecorator, inherits: [::Decors::DecoratorBase]) {
                def initialize(decorated_class, decorated_method, *deco_args, **deco_kwargs, &deco_block)
                    super
                    Spy.passed_args(*deco_args, **deco_kwargs, &deco_block)
                end

                def call(instance, *args, &block)
                    super
                    Spy.passed_args(*args, &block)
                end
            }

            TestClass.class_eval { define_decorator :SimpleDecorator, SimpleDecorator }
        }

        context 'It receive all the parameters at initialization' do
            it { expect(SimpleDecorator).to receive(:new).with(TestClass, anything, 1, 2, a: 3).and_call_original }
            it { expect(Spy).to receive(:arguments).with(args: [1, 2], kwargs: { a: 3 }, evald_block: 'ok') }

            after {
                TestClass.class_eval {
                    SimpleDecorator(1, 2, a: 3) { 'ok' }
                    def test_method(*); end

                    def test_method_not_decorated(*); end
                }
            }
        end

        context 'It receive the instance and the arguments passed to the method when called' do
            let(:instance) { TestClass.new }
            before {
                TestClass.class_eval {
                    SimpleDecorator()
                    def test_method(*args, &block)
                        Spy.passed_args(*args, &block)
                    end

                    def test_method_not_decorated; end
                }
            }

            it { expect_any_instance_of(SimpleDecorator).to receive(:call).with(instance, 1, a: 2, b: 3, &proc { 'yes' }) }
            it { expect(Spy).to receive(:arguments).with(args: [1], kwargs: { a: 2, b: 3 }, evald_block: 'yes').twice }

            after {
                instance.test_method(1, a: 2, b: 3) { 'yes' }
                instance.test_method_not_decorated
            }
        end
    end

    context 'when decorator is defining a method during initialization' do
        before {
            stub_class(:StrangeDecorator, inherits: [::Decors::DecoratorBase]) {
                def initialize(decorated_class, decorated_method, *deco_args, **deco_kwargs, &deco_block)
                    super
                    decorated_class.send(:define_method, :foo) { 42 }
                end

                def call(*)
                    super * 2
                end
            }

            TestClass.class_eval { define_decorator :StrangeDecorator, StrangeDecorator }
        }

        before {
            TestClass.class_eval {
                StrangeDecorator()
                StrangeDecorator()
                def test_method
                    5
                end
            }
        }

        it { expect(TestClass.new.test_method).to eq 5 * 2 * 2 }
        it { expect(TestClass.new.foo).to eq 42 }
    end

    context 'when mutiple decorators' do
        before {
            Spy.class_eval {
                @ordered_calls = []

                class << self
                    attr_reader :ordered_calls

                    def calling(name)
                        self.ordered_calls << name
                    end
                end
            }

            stub_class(:Deco1, inherits: [::Decors::DecoratorBase]) {
                def call(*)
                    Spy.calling(:deco1_before)
                    super
                    Spy.calling(:deco1_after)
                end
            }

            stub_class(:Deco2, inherits: [::Decors::DecoratorBase]) {
                def call(*)
                    Spy.calling(:deco2_before)
                    super
                    Spy.calling(:deco2_after)
                end
            }

            TestClass.class_eval {
                define_decorator :Deco1, Deco1
                define_decorator :Deco2, Deco2

                Deco2()
                Deco1()
                def test_method(*)
                    Spy.calling(:inside)
                end
            }
        }

        before { TestClass.new.test_method }
        it { expect(Spy.ordered_calls).to eq [:deco2_before, :deco1_before, :inside, :deco1_after, :deco2_after] }
    end

    context 'when method has return value' do
        before {
            stub_class(:ModifierDeco, inherits: [::Decors::DecoratorBase])

            TestClass.class_eval {
                define_decorator :ModifierDeco, ModifierDeco

                ModifierDeco()
                def test_method
                    :ok
                end
            }
        }

        it { expect(TestClass.new.test_method).to eq :ok }
    end

    context 'when method has arguments' do
        before {
            stub_class(:ModifierDeco, inherits: [::Decors::DecoratorBase])

            TestClass.class_eval {
                define_decorator :ModifierDeco, ModifierDeco

                ModifierDeco()
                def test_method(*args, &block)
                    Spy.passed_args(*args, &block)
                end
            }
        }

        it { expect(Spy).to receive(:arguments).with(args: [1, 2, 3], kwargs: { a: :a }, evald_block: 'yay') }
        after { TestClass.new.test_method(1, 2, 3, a: :a) { 'yay' } }
    end

    context 'when changing arguments given to the method' do
        before {
            stub_class(:ModifierDeco, inherits: [::Decors::DecoratorBase]) {
                def call(instance, *)
                    undecorated_call(instance, 1, 2, 3, a: :a, &proc { 'yay' })
                end
            }

            TestClass.class_eval {
                define_decorator :ModifierDeco, ModifierDeco

                ModifierDeco()
                def test_method(*args, &block)
                    Spy.passed_args(*args, &block)
                end
            }
        }

        it { expect(Spy).to receive(:arguments).with(args: [1, 2, 3], kwargs: { a: :a }, evald_block: 'yay') }
        after { TestClass.new.test_method }
    end

    context 'when method is recursive' do
        before {
            stub_class(:AddOneToArg, inherits: [::Decors::DecoratorBase]) {
                def call(instance, *args)
                    undecorated_call(instance, args.first + 1)
                end
            }

            TestClass.class_eval {
                define_decorator :AddOneToArg, AddOneToArg

                AddOneToArg()
                def test_method(n)
                    return 0 if n.zero?
                    n + test_method(n - 2)
                end
            }
        }

        it { expect(TestClass.new.test_method(4)).to eq 5 + 4 + 3 + 2 + 1 }
    end

    context 'when already has a method_added' do
        before {
            stub_module(:TestMixin) {
                def method_added(*)
                    Spy.called
                end
            }
            stub_class(:Deco, inherits: [::Decors::DecoratorBase])
        }
        it { expect(Spy).to receive(:called) }

        after {
            TestClass.class_eval {
                extend TestMixin

                define_decorator :Deco, Deco

                def test_method; end
            }
        }
    end

    context 'when inherited' do
        before {
            stub_class(:Deco, inherits: [::Decors::DecoratorBase])

            TestClass.class_eval {
                define_decorator :Deco, Deco

                Deco()
                def test_method
                    :ok
                end
            }
        }

        it {
            stub_class(:TestClass2, inherits: [TestClass])
            TestClass2.class_eval {
                Deco()
                def test_method
                    :ko
                end
            }

            expect(TestClass.new.test_method).to eq :ok
            expect(TestClass2.new.test_method).to eq :ko
        }

        it {
            stub_class(:TestClass3, inherits: [TestClass])

            TestClass3.class_eval {
                Deco()
                def test_method
                    "this is #{super}"
                end
            }

            expect(TestClass3.new.test_method).to eq 'this is ok'
        }
    end

    context 'when decorating a class method' do
        before {
            stub_class(:Deco, inherits: [::Decors::DecoratorBase]) {
                def call(*)
                    super
                    Spy.called
                end
            }
        }

        context 'when mixin extended on the class (singleton method in class)' do
            before {
                TestClass.class_eval {
                    define_decorator :Deco, Deco

                    Deco()
                    def self.test_method
                        :ok
                    end
                }
            }

            it { expect(Spy).to receive(:called) }
            after { TestClass.test_method }
        end

        context 'when mixin extended on the class (singleton method in singleton class)' do
            before {
                TestClass.class_eval {
                    class << self
                        extend Decors::DecoratorDefinition

                        define_decorator :Deco, Deco

                        Deco()
                        def self.test_method
                            :ok
                        end
                    end
                }
            }

            it { expect(Spy).to receive(:called) }
            after { TestClass.singleton_class.test_method }
        end

        context 'when mixin extended on the class (method in singleton class of singleton class)' do
            before {
                TestClass.class_eval {
                    class << self
                        class << self
                            extend Decors::DecoratorDefinition

                            define_decorator :Deco, Deco

                            Deco()
                            def test_method
                                :ok
                            end
                        end
                    end
                }
            }

            it { expect(Spy).to receive(:called) }
            after { TestClass.singleton_class.test_method }
        end

        context 'when mixin extended on the class (method in singleton class)' do
            before {
                TestClass.class_eval {
                    class << self
                        extend Decors::DecoratorDefinition

                        define_decorator :Deco, Deco

                        Deco()
                        def test_method
                            :ok
                        end
                    end
                }
            }

            it { expect(Spy).to receive(:called) }
            after { TestClass.test_method }
        end

        context 'when mixin extended on the class (both method in singleton class and singleton method in class)' do
            before {
                TestClass.class_eval {
                    define_decorator :Deco, Deco

                    Deco()
                    def self.test_method__in_class
                        :ok
                    end

                    def self.untest_method__in_class
                    end

                    class << self
                        extend Decors::DecoratorDefinition

                        define_decorator :Deco, Deco

                        Deco()
                        def test_method__in_singleton
                            :ok
                        end

                        def untest_method__in_singleton
                        end
                    end
                }
            }

            it { expect(Spy).to receive(:called) and TestClass.test_method__in_class }
            it { expect(Spy).to receive(:called) and TestClass.test_method__in_singleton }
            it { expect(Spy).to_not receive(:called) and TestClass.untest_method__in_class }
            it { expect(Spy).to_not receive(:called) and TestClass.untest_method__in_singleton }
        end
    end
end
