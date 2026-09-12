@tool
@abstract
class_name EventOutcome
extends Resource

@abstract func apply(event: Event) -> EventOutcomeWidget
@abstract func describe(run: Run) -> String
