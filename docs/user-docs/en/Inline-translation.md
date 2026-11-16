# Inline English translation

Keep Easydict running and grant it Accessibility access. In an editable text field, type
`/en 明天见、` or `/en 明天见|`. The final `、` or `|` starts translation; fullwidth `｜`
and a backslash are also supported. Easydict replaces the command with the complete English translation
using installed Apple translation models on this Mac. The command must begin at the start of the
field or after whitespace, and end immediately before the caret.

The surrounding text and clipboard are preserved. Typing, clicking, moving the caret,
or switching apps while translation is pending prevents replacement. A failed request
leaves the command intact and shows an explanation; delete and retype the terminator to retry.

This custom build requires macOS 26 or later and installed source/target language packs.
Download Chinese (Mandarin, Simplified) and English (US) once in System Settings → General →
Language & Region → Translation Languages. Translation requests cannot download packs and never
fall back to an online provider. Language detection, OCR and speech use Apple’s local facilities;
online translation/AI providers, web search shortcuts, telemetry and update checks are disabled.
Apple Dictionary and imported MDict dictionaries remain available. This is a fixed policy for
this build, so no API key or online service selection is needed.

This feature works in text fields that expose their text, selection and replacement
through macOS Accessibility. Secure fields and unsupported controls remain untouched.
Pasting a complete command also triggers translation.
