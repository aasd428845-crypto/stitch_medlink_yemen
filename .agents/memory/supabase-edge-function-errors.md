---
name: Supabase Edge Function errors in Flutter
description: Non-2xx Edge Function calls throw FunctionException before returning a response.
---

`supabase_flutter` throws `FunctionException` for non-2xx Edge Function responses, so code that only checks `FunctionResponse.status` will never translate those errors.

**Why:** duplicate-account and validation failures otherwise reach the UI as raw `FunctionException(status: ..., details: ..., reasonPhrase: ...)` text.

**How to apply:** catch `FunctionException`, extract `details['error']` or its string payload, and pass it through the app's localized error mapper before rethrowing a user-safe message.