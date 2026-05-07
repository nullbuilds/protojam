@abstract
class_name AbstractTransitionProvider
extends Resource
## Provides an instance of a transition on-demand.
## 
## This is an abstraction layer allowing nodes like [NodeSwapper] to get
## customized instances of transitions when needed.

## Gets a transition instance.
## 
## Custom implementations should override this to construct or return the
## desired transition type with any parameters pre-configured.
@abstract
func provide() -> AbstractTransition
