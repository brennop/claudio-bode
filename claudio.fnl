(local rl (require :readline))
(local oai (require :openai))
(local cjson (require :cjson))
(local fennel (require :fennel))

(local tools (require :tools))

(local client (oai.new (os.getenv :OPENAI_API_KEY)))
(tset client :api_base (os.getenv :OPENAI_BASE_URL))

(local model "qwen3.5:9b")
(local chat (client:new_chat_session {: model 
                                      :tools tools.defs
                                      :reasoning_effort :none})) ; FIXME: reasoning_effort not working

(local claudio {})

(fn claudio.request [data]
  (let [response (chat:send data)]
    (print (fennel.view response))
    (match response
      {: tool_calls} (claudio.handle-tools chat tool_calls)
      message (print message))))

(fn claudio.handle-tool [name arguments tool_call_id]
  (let [handler (. tools :handlers name)
        result (handler (cjson.decode arguments))
        content (cjson.encode result)]
      (print :tool_result (fennel.view result))
      (claudio.request {:role :tool : tool_call_id : content})))

(fn claudio.handle-tools [chat tool_calls]
  (each [_ {:function {: name : arguments} : id} (ipairs tool_calls)]
    (match (rl.readline (.. "tool_call: [" name "] " arguments " (yes/no?) >"))
      "yes" (claudio.handle-tool name arguments id)
      _ (print "user refused"))))

(while true ; TODO: use for
  (let [prompt (rl.readline "> ")]
    (claudio.request prompt)))
