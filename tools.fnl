(local mcp (require :mcp))

(local handlers {})

(local bash {:type :function
             :function {:name :bash
                        :description "Run a shell command and return its ouput"
                        :parameters {:type :object
                                     :properties {:command {:type :string
                                                            :description "The shell command to run"}}
                                     :required [:command]}}})

(fn handlers.bash [arguments]
  (: (io.popen arguments.command) :read :*a))

(local read {:type :function
             :function {:name :read
                        :description "Read file contents"
                        :parameters {:type :object
                                     :properties {:path {:type :string
                                                         :description "The file path"}}
                                     :required [:path]}}})

(fn handlers.read [arguments]
  (match (io.open arguments.path)
    (nil msg) msg
    file (file:read :*a)))

(local edit
       {:type :function
        :function {:name :edit
                   :description "Edit file contents"
                   :parameters {:type :object
                                :properties {:path {:type :string
                                                    :description "The file path"}
                                             :old_text {:type :string
                                                        :description "Exact text to find"}
                                             :new_text {:type :string
                                                        :description "Text replacement"}}
                                :required [:path :old_text :new_text]}}})

(fn handlers.edit [arguments]
  (let [content (with-open [file (io.open arguments.path :r)]
                  (file:read :*a))
        value (content:gsub arguments.old_text arguments.new_text)]
    (with-open [file (io.open arguments.path :w)]
      (file:write value))))

;; MCP servers: set MCP_SERVERS="name=url,name2=url2" to pull in tools
;; from MCP servers you already have running, e.g.
;;   MCP_SERVERS="git=http://127.0.0.1:8765/mcp" fennel claudio.fnl
(local defs [bash read edit])

(fn connect-mcp-server [name url]
  (match (pcall mcp.connect url)
    (true client) (let [{:defs mcp-defs :handlers mcp-handlers} (mcp.tools client name)]
                    (each [_ def (ipairs mcp-defs)]
                      (table.insert defs def))
                    (each [tool-name handler (pairs mcp-handlers)]
                      (tset handlers tool-name handler)))
    (false err) (io.stderr:write "mcp: couldn't connect to " name " (" url "): " (tostring err) "\n")))

(each [entry (string.gmatch (or (os.getenv :MCP_SERVERS) "") "[^,]+")]
  (let [name (entry:match "^(.-)=")
        url (entry:match "=(.+)$")]
    (when (and name url)
      (connect-mcp-server name url))))

{: defs : handlers}
