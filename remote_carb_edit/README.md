# Remote carb delete and edit

Lets a caregiver app (LoopFollow) delete or edit a carb entry that Loop created within the last 24 hours, through the same OTP-protected APNS remote command path as remote carbs.

Payload keys: `carbs-delete` or `carbs-edit` carrying the entry's `syncIdentifier` (Loop uploads it on every Carb Correction treatment), plus for edits `carbs-edit-entry` (g), `carbs-edit-absorption-time` (hours), `carbs-edit-food-type`, `carbs-edit-start-time`. `otp`, `sent-at` and `expiration` are required. Edits keep the `syncIdentifier`. Loop replies through the existing return notification with `command_type` `carbs_delete` / `carbs_edit` and `sync_identifier`.

Touches Loop, LoopKit and NightscoutService. Generated against LoopWorkspace `dev` (3.14.8). Apply from the LoopWorkspace folder:

```
git apply --whitespace=nowarn dev_remote_carb_edit.patch
```
