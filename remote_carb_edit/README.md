# Remote carb delete and edit

Lets a caregiver app (LoopFollow) delete or edit a carb entry that Loop created within the last 24 hours, through the same OTP-protected APNS remote command path as remote carbs.

Payload keys:

- Delete: `carbs-delete` carrying the entry's `syncIdentifier` (Loop uploads it on every Carb Correction treatment).
- Edit: `carbs-edit` carrying the `syncIdentifier`, plus the required replacement values `carbs-edit-entry` (g), `carbs-edit-absorption-time` (hours) and `carbs-edit-start-time` (ISO 8601). `carbs-edit-food-type` is optional and keeps the existing food type when absent. An edit missing any required value is rejected before validation.
- Both: `otp`, `sent-at` and `expiration` are required, in addition to the usual `remote-address` and `entered-by`.

Edits keep the entry's `syncIdentifier`. Replacement values are validated with the same limits as remote carb entries (absorption time range, maximum carb amount, start time window).

Loop acknowledges each command through the existing return push (`encrypted_return_notification`): `command_status` `success` / `failed`, `command_type` `carbs_delete` / `carbs_edit`, and `sync_identifier` identifying the entry. Failures also post the usual Nightscout Note with the error text. Loop shows a local notification for both outcomes using the remote carbs notification categories.

Touches Loop, LoopKit and NightscoutService. Generated against LoopWorkspace `dev` (3.14.8). Apply from the LoopWorkspace folder:

```
git apply --whitespace=nowarn dev_remote_carb_edit.patch
```
