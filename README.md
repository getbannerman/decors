# Decors

#### Yet another implementation of Python Decorators/Java annotations in ruby

Here are other implementations:
- https://github.com/wycats/ruby_decorators
- https://github.com/michaelfairley/method_decorators
- https://github.com/fredwu/ruby_decorators
- https://gist.github.com/reu/2762650

[See why](#faq) we decided to implement this differently.

## Install

Add `gem 'decors'` to your Gemfile
Then run `bundle`

## Usage

#### Basic usage

```ruby
# Create a new decorator
module DB
    class WithinTransaction < ::Decors::DecoratorBase
        def call(*)
            DB.transaction { super }
        end
    end
end

# Define the alias on the class/module you want to use it
class Item
    define_decorator :WithinTransaction, DB::WithinTransaction

    # From now on you can use the decorator to decorate any method/singleton method

    WithinTransaction()
    def do_stuff_in_db
        # do_stuff_in_db within a db transaction
    end

    WithinTransaction()
    def self.do_stuff_in_db
        # do_stuff_in_db within a db transaction
    end
end
```

#### Mixin usage

```ruby
# Create a new decorator
module DbDecorator
    class WithinTransaction < ::Decors::DecoratorBase; end
    class LogBeforeDbHit < ::Decors::DecoratorBase; end

    # define decorator that can be mixed with other classes/modules
    define_mixin_decorator :WithinTransaction, WithinTransaction
    define_mixin_decorator :LogBeforeDbHit, LogBeforeDbHit
end

class Item
    extend DbDecorator

    WithinTransaction()
    LogBeforeDbHit()
    def do_stuff_in_db
        # do_stuff_in_db within a db transaction
    end
end
```

#### Argument modification

Sometimes you want the decorator to modify your method arguments. For example a generic way to define an api that handles pagination and filtering.

```ruby
    module Api
        class SimpleApi < ::Decors::DecoratorBase
            attr_reader :model_store, :pagination, :filtering

            def initialize(*, model_store, pagination:, filtering:)
                @model_store = model_store
                @pagination = pagination
                @filtering = filtering
                super
            end

            def call(this, *)
                models, page, per_page = paginate(filter(model_store.all))

                super(this, models, page: page, per_page: per_page)
            end

            ...
        end
    end

    class ItemController
        SimpleApi(Item, pagination: true, filtering: true)
        def index(items, page:, per_page:)
            render json: { items: items.map(&:as_json), page: page, per_page: per_page }
        end
    end
```

## FAQ

#### What is going on under the wood?
```ruby
    class User
        define_decorator :Delay, Async::Delay

        Delay(priority: :high)
        def delayed_computation(*args, &blk)
            # CODE here
        end
    end

    # Is strictly equivalent to

    class User
        def secret_computation(*args, &blk)
            Async::Delay.new(User, User.instance_method(:secret_computation), priority: :high)
                .call(self, *args, &blk) do
                    # CODE here
                end
        end
    end
```



#### What is the difference between this and method modifiers?

Method modifiers modify methods, specifically those are class methods which:

1. Take the instance method name (symbol) as first argument
2. Change subsequent calls to that method
3. return the same symbol

The limitation of those are:
- They often come after the method which hurts lisibility
- If they come before the method you cannot have other argument than the method_name
- nesting those is a pain

with decorator you can do the following

```ruby
    class User
        ...

        Delay(priority: :high)
        Retry(3)
        DbTransaction()
        def secret_computation
            # computation inside transaction retried up to 3 times if an error occurs.
            # All that performed async
        end
    end

    # VS

    class User
        ...

        db_transaction def secret_computation
        end

        retry_when_failing :secret_computation, 3
        handle_async :secret_computation, priority: :high

    end
```

#### Why another implementation of this ?

Most of the implementation use the unary operator `+@` syntax to define the decorator which leads to a lost reference to the caller instance. This imply a global state of what are the current decorators to apply to the next method definition (which is not always threadsafe depending on the implementation).

Current implementations wasn't handling nested singleton (see https://github.com/getbannerman/decors/issues/2)

Current implementations have a rather large footprint. A class that needs a decorated method have all of its method definition hooked on the `method_added` callback. In our case it's only added at the decorator call. And we'll soon support callback removal after method definition.

The obvious drawback of our approach are: The syntax that might be less comprehensive for a new comer, and the namespacing which we handle via aliasing at decorator declaration.

#### What is that weird syntax?

By convention we use ConstantName case for the decorators in order not to mix them with other method call/DSL.
This is not enforced and you can have the text case you like.

Note that, this syntax is also used in other gems such as [Contract](https://github.com/egonSchiele/contracts.ruby)

## License

Copyright (c) 2017 [Bannerman](https://github.com/getbannerman), [Vivien Meyet](https://github.com/vmeyet)

Licensed under the [MIT license](http://fredwu.mit-license.org/).
