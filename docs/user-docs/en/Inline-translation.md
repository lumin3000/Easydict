# Inline English translation

Keep Easydict running and grant it Accessibility access. In an editable text field, type
`/en 明天见、` or `/en 明天见|`. The final `、` or `|` starts translation; a backslash is
also supported. Easydict replaces the command with the complete English translation
using its built-in AI translation service. The command must begin at the start of the
field or after whitespace, and end immediately before the caret.

The surrounding text and clipboard are preserved. Typing, clicking, moving the caret,
or switching apps while translation is pending prevents replacement. A failed request
leaves the command intact; delete and retype the terminator to retry.

This feature works in text fields that expose their text, selection and replacement
through macOS Accessibility. Secure fields and unsupported controls remain untouched.
Keyboard paste of a complete command also triggers translation.
