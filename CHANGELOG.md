# Decors changelog

## Version 0.3 (Released August 24, 2017)

- (feature) expose decorated method before and after decoration (https://github.com/getbannerman/decors/issues/10)
  :warning: this is a breaking change. `decorated_method` that was referring to the method before decoration now refers to the method after decoration. `undecorated_method` refers to the method before decoration.

## Version 0.2 (Released May 10, 2017)

- (bugfix) nested singleton handling (https://github.com/getbannerman/decors/issues/2)
- (bugfix) keep method visibility (https://github.com/getbannerman/decors/issues/3)


## Version 0.1 (Released April 24, 2017)

- First implementation
