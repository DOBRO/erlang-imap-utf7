# imap_utf7

IMAP UTF-7 encoding/decoding library for Erlang.

From RFC 3501, section 5.1.3. "[Mailbox International Naming Convention](https://datatracker.ietf.org/doc/html/rfc3501#section-5.1.3)":
> By convention, international mailbox names in IMAP4rev1 are specified
> using a modified version of the UTF-7 encoding described in [UTF-7].

This library provides functions for encoding/decoding Erlang UTF-8 binaries to and from modified UTF-7 encoding
in accordance with RFC 3501.

## Examples

Encoding:

```erlang
> imap_utf7:encode(<<"Входящие"/utf8>>).
<<"&BBIERQQ+BDQETwRJBDgENQ-">>

> imap_utf7:encode(<<"Boîte de réception"/utf8>>).
<<"Bo&AO4-te de r&AOk-ception">>

> imap_utf7:encode(<<"收件箱"/utf8>>).
<<"&ZTZO9nux-">>

> imap_utf7:encode(<<"受信トレイ"/utf8>>).
<<"&U9dP4TDIMOwwpA-">>

> imap_utf7:encode(<<"Inbox">>).
<<"Inbox">>
```

Decoding:

```erlang
> imap_utf7:decode(<<"&BBIERQQ+BDQETwRJBDgENQ-">>).
<<208,146,209,133,208,190,208,180,209,143,209,137,208,184,
  208,181>>

> imap_utf7:decode(<<"&BBIERQQ+BDQETwRJBDgENQ-">>) =:= <<"Входящие"/utf8>>.
true

> imap_utf7:decode(<<"Bo&AO4-te de r&AOk-ception">>).
<<"Boîte de réception"/utf8>>

> imap_utf7:decode(<<"&ZTZO9nux-">>) =:= <<"收件箱"/utf8>>.
true

> imap_utf7:decode(<<"&U9dP4TDIMOwwpA-">>) =:= <<"受信トレイ"/utf8>>.
true

> imap_utf7:decode(<<"Inbox">>).
<<"Inbox">>
```
