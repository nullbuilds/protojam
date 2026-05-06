class_name LicensedCreditEntry
extends CreditEntry
## A credit entry for a licensed work.

## The name of the licensor
@export var licensor: String = ""

## The licensed work.
@export var work: String = ""

## The licensed the work is under.
@export var license: CreditableLicense = null

## A link to the licensor or the work.
@export var url: String = ""
