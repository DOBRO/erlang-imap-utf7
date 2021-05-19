# imap_utf7

[![imap_utf7 on Hex.pm](https://img.shields.io/hexpm/v/imap_utf7.svg?color=yellow)](https://hex.pm/packages/imap_utf7)
[![CI Status](https://github.com/DOBRO/erlang-imap-utf7/workflows/Build/badge.svg?branch=master)](https://github.com/DOBRO/erlang-imap-utf7/actions?query=workflow%3ABuild+branch%3Amaster)
[![Code coverage](https://codecov.io/gh/DOBRO/erlang-imap-utf7/branch/master/graph/badge.svg)](https://codecov.io/gh/DOBRO/erlang-imap-utf7)
![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)

The library provides functions for encoding/decoding Erlang UTF-8 binaries to and from modified UTF-7 encoding
in accordance with RFC 3501.

From RFC 3501, section 5.1.3. "[Mailbox International Naming Convention](https://datatracker.ietf.org/doc/html/rfc3501#section-5.1.3)":
> By convention, international mailbox names in IMAP4rev1 are specified
> using a modified version of the UTF-7 encoding described in [UTF-7].

## Functions

### Encoding

```erlang
imap_utf7:encode(MailboxName) -> MailboxNameEncoded
  when
    MailboxName         :: binary(),
    MailboxNameEncoded  :: binary().
```

Encodes UTF-8 `MailboxName` and returns `MailboxNameEncoded` in a modified UTF-7 encoding.

### Decoding

```erlang
imap_utf7:decode(MailboxNameEncoded) -> MailboxName
  when
    MailboxNameEncoded  :: binary(),
    MailboxName         :: binary().
```

Decodes UTF-7 `MailboxNameEncoded` end returns `MailboxName` in UTF-8 encoding.

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

## Building and testing

```bash
# using rebar3:
$ rebar3 compile
$ rebar3 dialyzer
$ rebar3 ct
$ rebar3 cover
```
