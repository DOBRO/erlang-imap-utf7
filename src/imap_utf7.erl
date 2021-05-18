%% Copyright (c) 2021, Sergei Semichev <chessvegas@chessvegas.com>. All Rights Reserved.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%    http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.

%%%------------------------------------------------------------------------------
%%%
%%%   See RFC 3501, section 5.1.3 "Mailbox International Naming Convention"
%%%   https://datatracker.ietf.org/doc/html/rfc3501
%%%
%%%------------------------------------------------------------------------------

-module(imap_utf7).

-export([encode/1, decode/1]).


%%%------------------------------------------------------------------------------
%%%   API
%%%------------------------------------------------------------------------------

%% encode/1
-spec encode(binary()) -> binary().
encode(<<>>) ->
    <<>>;
encode(Bin) when is_binary(Bin)->
    encode(Bin, <<>>, <<>>).

%% decode/1
-spec decode(binary()) -> binary().
decode(<<>>) ->
    <<>>;
decode(Bin) when is_binary(Bin) ->
    decode(Bin, <<>>, <<>>).


%%%------------------------------------------------------------------------------
%%%   Internal functions
%%%------------------------------------------------------------------------------

%% encode/3
-spec encode(binary(), binary(), binary()) -> binary().
encode(<<>>, <<>>, Acc) ->
    Acc;
encode(<<>>, TmpBuf, Acc) ->
    << Acc/bits, (modified_base64(TmpBuf))/bits >>;
encode(<< Char, Rest/bits >>, TmpBuf, Acc) when ((Char >= 16#20) andalso (Char =< 16#7e)) ->
    Base64 = modified_base64(TmpBuf),
    case Char of
        $& -> % "&" (0x26)
            encode(Rest, <<>>, << Acc/bits, Base64/bits, "&-" >>);
        _  -> % printable US-ASCII
            encode(Rest, <<>>, << Acc/bits, Base64/bits, Char >>)
    end;
encode(<< Char, Rest/bits >>, TmpBuf, Acc) ->
    encode(Rest, << TmpBuf/bits, Char >>, Acc).


%% decode/3
-spec decode(binary(), binary(), binary()) -> binary().
decode(<<>>, <<>>, Acc) ->
    Acc;
decode(<< $&, $-, Rest/bits >>, _B64Buf, Acc) -> % replace "&-" with "&"
    decode(Rest, <<>>, << Acc/bits, $& >>);
decode(<< $&, C, Rest/bits >>, B64Buf, Acc) -> % start accumulate Base64 buffer
    decode(Rest, << B64Buf/bits, C >>, Acc);
decode(<< $-, Rest/bits >>, <<>>, Acc) -> % leave character '-' in case of empty Base64 buffer
    decode(Rest, <<>>, << Acc/bits, $- >>);
decode(<< $-, Rest/bits >>, B64Buf, Acc) -> % decode Base64 substring and reset buffer
    Decoded = base64_utf7_decode(B64Buf),
    decode(Rest, <<>>, << Acc/bits, Decoded/bits >>);
decode(<< C, Rest/bits >>, <<>>, Acc) -> % empty Base64 buffer, add US-ASCII character to Acc
    decode(Rest, <<>>, << Acc/bits, C >>);
decode(<< C, Rest/bits >>, B64Buf, Acc) -> % add character to non-empty Base64 buffer
    decode(Rest, << B64Buf/bits, C >>, Acc).


%% modified_base64/1
-spec modified_base64(binary()) -> binary().
modified_base64(<<>>) ->
    <<>>;
modified_base64(Bin) ->
    Base64 = base64_utf7_encode(Bin),
    << $&, (replace(strip_base64(Base64), $/, $,))/bits, $- >>.


%% base64_utf7_encode/1
-spec base64_utf7_encode(binary()) -> binary().
base64_utf7_encode(<<>>) ->
    <<>>;
base64_utf7_encode(Bin) ->
    base64:encode(to_utf16(Bin)).

%% base64_utf7_decode/1
-spec base64_utf7_decode(binary()) -> binary().
base64_utf7_decode(<<>>) ->
    <<>>;
base64_utf7_decode(Bin0) ->
    % Replace commas with slashes:
    Bin = replace(Bin0, $,, $/),

    % From https://en.wikipedia.org/wiki/Base64 :
    % Because Base64 is a six-bit encoding,
    % and because the decoded values are divided into 8-bit octets on a modern computer,
    % every four characters of Base64-encoded text (4 sextets = 4 × 6 = 24 bits)
    % represents three octets of unencoded text or data (3 octets = 3*8 = 24 bits).
    % This means that when the length of the unencoded input is not a multiple of three,
    % the encoded output must have padding added so that its length is a multiple of four.
    %
    % Here we calculate the number of padding characters '='.
    PaddingsNumber = case (erlang:byte_size(Bin) rem 4) of
        0   -> 0;
        Rem -> 4 - Rem
    end,

    % Decode Base64:
    Padding = case PaddingsNumber of
        0 -> <<>>;
        1 -> << $= >>;
        2 -> << $=, $= >>
    end,
    Base64Decoded = base64:decode(<< Bin/bits, Padding/bits >>),

    % Decode from UTF-16 (Big Endian) to UTF-8:
    from_utf16(Base64Decoded).


%% to_utf16/1
-spec to_utf16(binary()) -> binary().
to_utf16(Bin) ->
    to_utf16(Bin, <<>>).


%% to_utf16/2
-spec to_utf16(binary(), binary()) -> binary().
to_utf16(<<>>, Acc) ->
    Acc;
to_utf16(Bin, Acc) ->
    case Bin of
        << U/utf8, Rest/bits >> ->
            to_utf16(Rest, << Acc/bits, U/utf16-big >>);
        << C, Rest/bits >> ->
            to_utf16(Rest, << Acc/bits, 0, C >>)
    end.


%% from_utf16/1
-spec from_utf16(binary()) -> binary().
from_utf16(Bin) ->
    from_utf16(Bin, <<>>).

%% from_utf16/2
-spec from_utf16(binary(), binary()) -> binary().
from_utf16(<<>>, Acc) ->
    Acc;
from_utf16(Bin, Acc) ->
    << U/utf16-big, Rest/bits >> = Bin,
    from_utf16(Rest, << Acc/bits, U/utf8 >>).


%% strip_base64/1
-spec strip_base64(binary()) -> binary().
strip_base64(<<>>) ->
    <<>>;
strip_base64(Bin) ->
    PrefixSize = erlang:byte_size(Bin) - 1,
    case Bin of
        << Prefix:PrefixSize/binary, $= >> ->
            strip_base64(Prefix);
        _ ->
            Bin
    end.


%% replace/3
-spec replace(binary(), non_neg_integer(), non_neg_integer()) -> binary().
replace(Bin, Char1, Char2) ->
    replace(Bin, Char1, Char2, <<>>).


%% replace/4
-spec replace(binary(), non_neg_integer(), non_neg_integer(), binary()) -> binary().
replace(<<>>, _Char1, _Char2, Acc) ->
    Acc;
replace(<< Char1, Rest/bits >>, Char1, Char2, Acc) ->
    replace(Rest, Char1, Char2, << Acc/bits, Char2 >>);
replace(<< C, Rest/bits >>, Char1, Char2, Acc) ->
    replace(Rest, Char1, Char2, << Acc/bits, C >>).
