(local rl (require :readline))
(local oai (require :openai))
(local cjson (require :cjson))

(local tools (require :tools))

(local client (oai.new (os.getenv :OPENAI_API_KEY)))
(tset client :api_base (os.getend :OPENAI_BASE_URL))

(local model "qwen3.5:9b")
(local chat (client:new_chat_session {: model 
                                      :tools tools.defs
                                      :reasoning_effort :none})) ; FIXME: reasoning_effort not working

(fn handle-tool [name arguments tool_call_id]
  (let [handler (. tools :handlers name)
        result (handler (cjson.decode arguments))
        content (cjson.encode result)]
      (chat:send {:role :tool : tool_call_id : content})))

(fn handle-tools [chat tool_calls]
  (each [_ {:function {: name : arguments} : id} (ipairs tool_calls)]
    (match (rl.readline (.. "tool_call: [" name "] " arguments))
      "yes" (print (handle-tool name arguments id))
      _ (print "user refused"
    ))))

(while true ; TODO: use for
  (let [prompt (rl.readline "> ")]
    (match (chat:send prompt)
      {: tool_calls} (handle-tools chat tool_calls)
      message (print message)
           )))
