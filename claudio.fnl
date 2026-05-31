#!/usr/bin/env fennel

(local rl (require :readline))
(local oai (require :openai))
(local cjson (require :cjson))
(local fennel (require :fennel))

(local tools (require :tools))

(local client (oai.new (os.getenv :OPENAI_API_KEY)))
(tset client :api_base (os.getenv :OPENAI_BASE_URL))

(local chat (client:new_chat_session {:model "qwen3.5:9b" :tools tools.defs}))

(local claudio {})

(fn stream_callback [_ {:choices [{:delta {: reasoning : content}}]}]
  (io.write "\27[2m" (tostring (or reasoning "")))
  (io.write "\27[0m" (tostring (or content "")))
  (io.flush))

(fn claudio.request [data]
  (chat:append_message data)
  (let [_ (chat:generate_response true {: stream_callback})]
    (match (chat:last_message)
      {: tool_calls} (claudio.handle-tools tool_calls))))

(fn claudio.handle-tool [name arguments tool_call_id]
  (let [handler (. tools :handlers name)
        (_ result) (pcall handler (cjson.decode arguments))
        content (cjson.encode result)]
    (print result)
    (claudio.request {:role :tool : tool_call_id : content}))) ; TODO: don't request here, just append and request later

(fn claudio.handle-tools [tool_calls]
  (each [_ {:function {: name : arguments} : id} (ipairs tool_calls)]
    (match (rl.readline (.. "\nPode? [" name "] " arguments " >"))
      "pode" (claudio.handle-tool name arguments id)
      _ (print "não pode")))) ; maybe add to chat messages?

(each [content #(rl.readline "\n> ")]
  (claudio.request {:role :user : content}))

(rl.save_history)
