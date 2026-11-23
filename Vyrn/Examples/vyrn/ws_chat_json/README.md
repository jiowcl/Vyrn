# JSON WebSocket chat

Product-style demo: **one JSON object per text frame**, plus **binary ping/pong**.

| Direction | Format |
|-----------|--------|
| Client → server (text) | `{"t":"hello"}`, `{"t":"nick","name":"Alice"}`, `{"t":"chat","msg":"hi"}`, `{"t":"who"}` |
| Server → client (text) | `{"t":"sys","msg":…}`, `{"t":"chat",…}`, `{"t":"tick",…}`, `{"t":"who",…}` |
| Client → server (binary) | UTF-8 bytes `ping` |
| Server → client (binary) | `{"t":"pong","uptime":N}` as binary frame |

## Run

```text
Vyrn.exe serve examples\vyrn\ws_chat_json\chat.vyrn --port 8766
```

Or `run.cmd`, then **http://127.0.0.1:8766/**.

`client.html`: nick field + **Set nick** (or `/nick NAME` in the composer); optional nick is sent after connect.

Compare with the prefix protocol in `examples/vyrn/ws_chat/` (port 8765).

## Notes

- No `json.*` builtin — payloads built with `string.char(34/123/125)` + concat (`{` cannot appear inside `"..."` literals).
- Room counters use top-level **`let`** upvalues (same pattern as `ws_chat`).
