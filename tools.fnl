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
  (match (io.open arguments.path :w)
    (nil msg) msg
    file (let [content (file:read :*a)
               value   (content:gsub arguments.old_text arguments.new_text]
               (file:write value)))))

{:defs [bash read] : handlers}
